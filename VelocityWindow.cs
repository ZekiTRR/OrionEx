using Avalonia;
using Avalonia.Animation;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.Presenters;
using Avalonia.Controls.Templates;
using Avalonia.Input;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Media.Imaging;
using Avalonia.Platform;
using Avalonia.Platform.Storage;
using Avalonia.Styling;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class VelocityWindow : Window
{
    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly VelocityOptions _options;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly SemaphoreSlim _operations = new(1, 1);
    private readonly CancellationTokenSource _lifetime = new();
    private readonly Dictionary<string, Bitmap> _images = new();
    private readonly Dictionary<Guid, string> _cleanContent = new();
    private readonly Dictionary<Guid, string> _filePaths = new();
    private readonly Dictionary<Guid, long> _messageSerials = new();
    private readonly Dictionary<string, TaskCompletionSource<bool>> _snapshots = new();
    private readonly HashSet<string> _selectedClients = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _knownClients = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, Button> _navigation = new();
    private readonly NativeWebView _editor = new() { IsVisible = false, Background = Brush.Parse("#080808") };
    private readonly Grid _root = new();
    private readonly Grid _body = new() { ColumnDefinitions = new("60,*") };
    private readonly Grid _workspaceView = new() { ColumnDefinitions = new("270,1,*") };
    private readonly Grid _codeArea = new() { RowDefinitions = new("*,1,170") };
    private readonly Grid _page = new() { IsVisible = false };
    private readonly StackPanel _tabs = new() { Orientation = Orientation.Horizontal };
    private readonly StackPanel _scripts = new() { Spacing = 2, Margin = new(8) };
    private readonly TextBox _search = new() { PlaceholderText = "Search Explorer...", BorderThickness = new(0), Background = Brushes.Transparent, FontSize = 12, VerticalContentAlignment = VerticalAlignment.Center };
    private readonly TextBlock _connection = new() { FontSize = 11, TextTrimming = TextTrimming.CharacterEllipsis, VerticalAlignment = VerticalAlignment.Center };
    private readonly TextBlock _cursor = new() { Text = "Ln 1, Col 1", FontSize = 10, Foreground = Brush.Parse("#777777"), VerticalAlignment = VerticalAlignment.Center };
    private readonly TextBox _output = new() { IsReadOnly = true, AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, BorderThickness = new(0), Background = Brushes.Transparent, FontFamily = new("Consolas"), FontSize = 11, Padding = new(12, 4) };
    private readonly ScrollViewer _outputScroll = new() { VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
    private readonly Border _modal = new() { IsVisible = false, Background = Brush.Parse("#B3000000"), Padding = new(30) };
    private readonly Border _toast = new() { Opacity = 0, IsHitTestVisible = false, Background = Brush.Parse("#171717"), BorderBrush = Brush.Parse("#333333"), BorderThickness = new(1), CornerRadius = new(4), Padding = new(10, 3), MaxWidth = 430, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
    private readonly TextBlock _toastText = new() { FontSize = 11, TextTrimming = TextTrimming.CharacterEllipsis };
    private readonly Image _backgroundImage = new() { Stretch = Stretch.UniformToFill, IsHitTestVisible = false };
    private Border _explorer = null!;
    private Border _terminal = null!;
    private GridSplitter _explorerSplitter = null!;
    private GridSplitter _terminalSplitter = null!;
    private EditorTabState _activeTab;
    private string _currentPage = "editor";
    private bool _editorReady, _disposed, _sourceAssigned, _closingForOrion, _returnRequested, _returned, _allowClose;
    private int _nativeDialogDepth, _toastVersion;
    private TaskCompletionSource<string?>? _modalCompletion;
    private Bitmap? _backgroundBitmap;
    private IBrush Accent => Brush.Parse(_options.Accent);
    private static IBrush Line => Brush.Parse("#191919");

    internal VelocityWindow(Uri monacoAddress, string scriptsDirectory,
        EditorWorkspaceState workspace, Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _workspace = workspace.CloneDetached();
        _returnToOrion = returnToOrion;
        _options = VelocityOptions.Load();
        if (_workspace.Tabs.Count == 0) _workspace.Tabs.Add(new EditorTabState { Title = "Script 1.lua" });
        _activeTab = _workspace.Tabs.FirstOrDefault(t => t.Id == _workspace.ActiveTabId) ?? _workspace.Tabs[0];
        _workspace.ActiveTabId = _activeTab.Id;
        foreach (var tab in _workspace.Tabs) _cleanContent[tab.Id] = tab.Content;
        Title = "Velocity";
        Width = _options.WindowWidth; Height = _options.WindowHeight; MinWidth = 560; MinHeight = 360;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        WindowDecorations = WindowDecorations.None;
        CanResize = _options.AllowResize;
        Topmost = _options.Topmost;
        Background = Brush.Parse(_options.Background);
        Foreground = Brush.Parse("#CCCCCC");
        FontFamily = new("avares://Orion/Assets/Velocity/Fonts#Inter, Segoe UI");
        FontSize = 12;
        TextOptions.SetTextRenderingMode(this, TextRenderingMode.SubpixelAntialias);
        RequestedThemeVariant = ThemeVariant.Dark;
        BuildStyles();
        BuildShell();
        RenderTabs();
        ApplyPanels();
        LoadBackground();
        InitializeWindowSizing();
        _editor.WebMessageReceived += EditorMessageReceived;
        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.ClientsChanged += BridgeClientsChanged;
        _bridge.LogReceived += BridgeLogReceived;
        foreach (var log in _bridge.GetLogSnapshot().TakeLast(100)) AppendLog(log.Level, log.Message);
        RefreshClients();
        Opened += WindowOpened;
        Closing += WindowClosing;
        Closed += WindowClosed;
        KeyDown += WindowKeyDown;
        _ = RefreshScriptsAsync();
    }

    private void BuildStyles()
    {
        var button = new Style(s => s.OfType<Button>().Class("velocity"));
        button.Setters.Add(new Setter(TemplatedControl.BackgroundProperty, Brushes.Transparent));
        button.Setters.Add(new Setter(TemplatedControl.BorderThicknessProperty, new Thickness(0)));
        button.Setters.Add(new Setter(TemplatedControl.ForegroundProperty, Brush.Parse("#CCCCCC")));
        button.Setters.Add(new Setter(TemplatedControl.CornerRadiusProperty, new CornerRadius(3)));
        button.Setters.Add(new Setter(TemplatedControl.TemplateProperty, new FuncControlTemplate<Button>((control, _) =>
            new Border
            {
                [!Border.BackgroundProperty] = control[!TemplatedControl.BackgroundProperty],
                [!Border.BorderBrushProperty] = control[!TemplatedControl.BorderBrushProperty],
                [!Border.BorderThicknessProperty] = control[!TemplatedControl.BorderThicknessProperty],
                [!Border.CornerRadiusProperty] = control[!TemplatedControl.CornerRadiusProperty],
                [!Border.PaddingProperty] = control[!TemplatedControl.PaddingProperty],
                Child = new ContentPresenter
                {
                    [!ContentPresenter.ContentProperty] = control[!ContentControl.ContentProperty],
                    [!ContentPresenter.HorizontalContentAlignmentProperty] = control[!ContentControl.HorizontalContentAlignmentProperty],
                    [!ContentPresenter.VerticalContentAlignmentProperty] = control[!ContentControl.VerticalContentAlignmentProperty]
                }
            })));
        Styles.Add(button);
        var splitter = new Style(s => s.OfType<GridSplitter>());
        splitter.Setters.Add(new Setter(Layoutable.MinWidthProperty, 0d));
        splitter.Setters.Add(new Setter(Layoutable.MinHeightProperty, 0d));
        splitter.Setters.Add(new Setter(TemplatedControl.TemplateProperty, new FuncControlTemplate<GridSplitter>((_, _) => new Border { Background = Line })));
        Styles.Add(splitter);
        var hover = new Style(s => s.OfType<Button>().Class("velocity").Class(":pointerover"));
        hover.Setters.Add(new Setter(TemplatedControl.BackgroundProperty, Brush.Parse("#202020")));
        hover.Setters.Add(new Setter(TemplatedControl.ForegroundProperty, Brushes.White));
        Styles.Add(hover);
        var disabled = new Style(s => s.OfType<Button>().Class("velocity").Class(":disabled"));
        disabled.Setters.Add(new Setter(Visual.OpacityProperty, .35));
        Styles.Add(disabled);
        _toast.Transitions = new Transitions { new DoubleTransition { Property = OpacityProperty, Duration = TimeSpan.FromMilliseconds(180) } };
    }

    private Button MakeButton(string text, Action action, string? icon = null, string? tip = null)
    {
        var button = new Button
        {
            Classes = { "velocity" }, Content = icon is null ? text : IconLabel(icon, text),
            Height = 30, Padding = new(8, 4), Cursor = new(StandardCursorType.Hand),
            HorizontalContentAlignment = HorizontalAlignment.Center, VerticalContentAlignment = VerticalAlignment.Center
        };
        button.Click += (_, _) => { if (!_disposed) action(); };
        ToolTip.SetTip(button, tip ?? text);
        return button;
    }

    private Control Asset(string path, double size = 20)
    {
        try
        {
            if (!_images.TryGetValue(path, out var bitmap))
            {
                using var stream = AssetLoader.Open(new Uri("avares://Orion/Assets/Velocity/" + path));
                _images[path] = bitmap = new Bitmap(stream);
            }
            var image = new Image { Source = bitmap, Width = size, Height = size, Stretch = Stretch.Uniform, Opacity = .8 };
            RenderOptions.SetBitmapInterpolationMode(image, BitmapInterpolationMode.HighQuality);
            return image;
        }
        catch (Exception ex) when (ex is IOException or ArgumentException or InvalidOperationException)
        { return new TextBlock { Text = "◇", Width = size, FontSize = size * .85, TextAlignment = TextAlignment.Center }; }
    }

    private Control IconLabel(string icon, string text)
    {
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, VerticalAlignment = VerticalAlignment.Center };
        row.Children.Add(Asset(icon, 18));
        if (text.Length > 0) row.Children.Add(new TextBlock { Text = text, VerticalAlignment = VerticalAlignment.Center, FontSize = 12 });
        return row;
    }

    private static Border Box(Control content, Thickness? border = null) => new()
    { Child = content, BorderBrush = Line, BorderThickness = border ?? new Thickness(1), Background = Brushes.Transparent };

    private static void Put(Grid grid, Control control, int row = 0, int column = 0)
    { Grid.SetRow(control, row); Grid.SetColumn(control, column); grid.Children.Add(control); }

    private void BuildShell()
    {
        var frame = new Grid { RowDefinitions = new("35,*") };
        _root.Children.Add(_backgroundImage);
        _root.Children.Add(frame);
        var header = new Grid { ColumnDefinitions = new("60,*,Auto"), Background = Brushes.Transparent };
        var logo = Asset("Vel/Vel_meteor-HQ.png", 26);
        logo.HorizontalAlignment = HorizontalAlignment.Center;
        logo.VerticalAlignment = VerticalAlignment.Center;
        Put(header, logo);
        var windowControls = new StackPanel { Orientation = Orientation.Horizontal };
        windowControls.Children.Add(MakeButton("—", () => WindowState = WindowState.Minimized, tip: "Minimize"));
        windowControls.Children.Add(MakeButton("□", ToggleMaximize, tip: "Maximize / Restore"));
        windowControls.Children.Add(MakeButton("×", () => _ = ReturnAsync(), tip: "Close Velocity and return to Orion"));
        foreach (var c in windowControls.Children) { c.Width = 45; c.Height = 34; }
        Put(header, windowControls, column: 2);
        header.PointerPressed += (_, e) =>
        {
            if (!e.GetCurrentPoint(this).Properties.IsLeftButtonPressed || e.Source is Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
            if (e.ClickCount == 2) ToggleMaximize();
            else BeginMoveDrag(e);
        };
        Put(frame, Box(header, new(0, 0, 0, 1)));
        Put(frame, _body, 1);
        var rail = new Grid { RowDefinitions = new("Auto,*,Auto") };
        var top = new StackPanel();
        AddNavigation(top, "editor", "Editor", "Sidebar/BoxCode.png");
        AddNavigation(top, "clients", "Clients", "Settings/Settings_Logging.png");
        AddNavigation(top, "about", "About this port", "Sidebar/NewsHome.png");
        Put(rail, top);
        var bottom = new StackPanel();
        AddNavigation(bottom, "theme", "Appearance", "Sidebar/Brush_Themes-Paint.png");
        AddNavigation(bottom, "settings", "Settings", "Bt/Cog_Settings-Fluent.png");
        Put(rail, bottom, 2);
        Put(_body, Box(rail, new(0, 0, 1, 0)));
        var content = new Grid();
        content.Children.Add(_workspaceView); content.Children.Add(_page);
        Put(_body, content, column: 1);
        BuildExplorer();
        Put(_workspaceView, _codeArea, column: 2);
        var editorHost = new Grid { RowDefinitions = new("40,*") };
        var tabHeader = new Grid { ColumnDefinitions = new("*,32") };
        Put(tabHeader, new ScrollViewer { Content = _tabs, HorizontalScrollBarVisibility = ScrollBarVisibility.Auto, VerticalScrollBarVisibility = ScrollBarVisibility.Disabled });
        Put(tabHeader, MakeButton("+", () => Run(() => AddTabAsync()), tip: "New tab · Ctrl+T"), column: 1);
        Put(editorHost, Box(tabHeader, new(0, 0, 0, 1)));
        var loading = new StackPanel { Spacing = 12, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        loading.Children.Add(new TextBlock { Text = "Starting Monaco...", HorizontalAlignment = HorizontalAlignment.Center });
        loading.Children.Add(MakeButton("Reload editor", () => Run(ReloadEditorAsync)));
        var browserHost = new Grid { ClipToBounds = true };
        browserHost.Children.Add(loading); browserHost.Children.Add(_editor);
        Put(editorHost, browserHost, 1);
        _codeArea.RowDefinitions[0].MinHeight = 120;
        Put(_codeArea, editorHost);
        _terminalSplitter = new GridSplitter { Background = Line, ResizeDirection = GridResizeDirection.Rows, ResizeBehavior = GridResizeBehavior.PreviousAndNext, HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        _terminalSplitter.DragCompleted += (_, _) => { _options.TerminalHeight = Math.Clamp(_terminal.Bounds.Height, 140, 400); SaveOptions(); };
        Put(_codeArea, _terminalSplitter, 1);
        BuildTerminal();
        _toast.Child = _toastText;
        // Toasts occupy native chrome, never overlap the child HWND editor.
        Put(header, _toast, column: 1);
        _root.Children.Add(_modal);
        Content = Box(_root);
        UpdateNavigation();
    }

    private void AddNavigation(StackPanel host, string page, string title, string asset)
    {
        var button = MakeButton("", () => ShowPage(page), asset, title);
        button.Content = Asset(asset, 25); button.Height = 52;
        button.HorizontalAlignment = HorizontalAlignment.Stretch;
        button.BorderThickness = new(3, 0, 0, 0);
        _navigation[page] = button;
        host.Children.Add(button);
    }

    private void UpdateNavigation()
    {
        foreach (var (name, button) in _navigation)
        {
            button.BorderBrush = name == _currentPage ? Accent : Brushes.Transparent;
            button.Opacity = name == _currentPage ? 1 : .65;
        }
    }

    private void WindowOpened(object? sender, EventArgs e)
    {
        RevealEditor();
        if (!_options.WelcomeSeen) _ = WelcomeAsync();
    }

    private void RevealEditor()
    {
        if (_disposed) return;
        _editor.IsVisible = _currentPage == "editor" && !_modal.IsVisible && _nativeDialogDepth == 0;
        if (!_sourceAssigned)
        {
            _sourceAssigned = true;
            _editor.Source = new UriBuilder(_monacoAddress) { Query = "theme=velocity&bg=%23080808" }.Uri;
        }
    }

    private void Run(Func<Task> action) => _ = RunAsync(action);
    private async Task RunAsync(Func<Task> action)
    {
        if (_disposed || _returnRequested) return;
        await _operations.WaitAsync();
        try { if (!_disposed && !_returnRequested) await action(); }
        catch (Exception ex) when (ex is not OutOfMemoryException) { if (!_disposed) Toast("Operation failed: " + ex.Message); }
        finally { _operations.Release(); }
    }

    private void WindowClosing(object? sender, WindowClosingEventArgs e)
    {
        if (_allowClose || _closingForOrion) return;
        e.Cancel = true;
        _ = ReturnAsync();
    }

    private async Task ReturnAsync()
    {
        if (_returnRequested || _disposed) return;
        _returnRequested = true;
        CompleteModal(null);
        await _operations.WaitAsync();
        try
        {
            await SnapshotAsync();
            _workspace.ActiveTabId = _activeTab.Id;
            SaveOptions();
            _returned = true;
            _returnToOrion(_workspace.CloneDetached());
            if (!_disposed) { _allowClose = true; Close(); }
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        { _returnRequested = false; _returned = false; Toast("Could not return to Orion: " + ex.Message); }
        finally { _operations.Release(); }
    }

    internal void CloseForOrion()
    {
        if (_disposed) return;
        _closingForOrion = true;
        _allowClose = true;
        Close();
    }

    private void WindowClosed(object? sender, EventArgs e)
    {
        if (_disposed) return;
        _disposed = true;
        _lifetime.Cancel();
        _editor.IsVisible = false;
        _editor.WebMessageReceived -= EditorMessageReceived;
        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.ClientsChanged -= BridgeClientsChanged;
        _bridge.LogReceived -= BridgeLogReceived;
        Opened -= WindowOpened; Closing -= WindowClosing; Closed -= WindowClosed; KeyDown -= WindowKeyDown;
        _modalCompletion?.TrySetResult(null);
        foreach (var completion in _snapshots.Values) completion.TrySetResult(false);
        _snapshots.Clear();
        _backgroundImage.Source = null;
        _backgroundBitmap?.Dispose();
        foreach (var image in _images.Values) image.Dispose();
        _images.Clear();
        SaveOptions();
        if (!_closingForOrion && !_returned)
        {
            _returned = true;
            _workspace.ActiveTabId = _activeTab.Id;
            _returnToOrion(_workspace.CloneDetached());
        }
    }

    private void WindowKeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_modal.IsVisible) CompleteModal(null);
            else ShowPage("editor");
            e.Handled = true; return;
        }
        if (_modal.IsVisible || e.Source is TextBox) return;
        var control = e.KeyModifiers.HasFlag(KeyModifiers.Control);
        if (e.Key == Key.F5 || control && e.Key == Key.Enter) Run(ExecuteAsync);
        else if (control && e.Key == Key.S) Run(SaveActiveAsync);
        else if (control && e.Key == Key.O) Run(OpenPickerAsync);
        else if (control && e.Key == Key.T) Run(() => AddTabAsync());
        else if (control && e.Key == Key.W) Run(() => CloseTabAsync(_activeTab));
        else if (control && e.Key == Key.B) { _options.ExplorerVisible = !_options.ExplorerVisible; ApplyPanels(); SaveOptions(); }
        else return;
        e.Handled = true;
    }

    private void SaveOptions()
    {
        if (!_options.Save() && !_disposed) AppendLog("warn", "Velocity preferences could not be saved.");
    }

    private async void Toast(string message)
    {
        if (_disposed) return;
        _toastText.Text = message;
        ToolTip.SetTip(_toast, message);
        var version = ++_toastVersion;
        _toast.Opacity = 1;
        try
        {
            await Task.Delay(3200, _lifetime.Token);
            if (version == _toastVersion) _toast.Opacity = 0;
        }
        catch (OperationCanceledException) { }
    }
}
