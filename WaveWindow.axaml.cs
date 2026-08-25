using Avalonia;
using Avalonia.Animation;
using Avalonia.Controls;
using Avalonia.Controls.Documents;
using Avalonia.Controls.Primitives;
using AvaloniaPath = Avalonia.Controls.Shapes.Path;
using Avalonia.Controls.Templates;
using Avalonia.Data;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Diagnostics;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class WaveWindow : Window
{
    private enum WavePage { Editor, Cloud, Console }
    private enum SettingsSection { General, Editor }

    private sealed record WaveScriptItem(string Name, string Path);

    private sealed record WaveOutputLine(string Timestamp, string Message, IBrush Foreground);

    private sealed record ExplorerSection(string Id, string Title, string IconKey);

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly string _cloudDirectory = Path.Combine(
        AppContext.BaseDirectory,
        "Github Gists");
    private readonly string _baseDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly WaveEditorOptions _editorOptions;
    private readonly List<WaveOutputLine> _outputLines = [];
    private readonly ScriptHubService _hubService = new();
    private readonly List<ScriptHubCardModel> _hubCards = [];
    private readonly HashSet<string> _hubCardKeys = new(StringComparer.Ordinal);
    private int _hubPage = 1;
    private bool _hubHasMore;
    private bool _hubLoading;
    private int _hubLoadVersion;
    private CancellationTokenSource? _hubLoadCancellation;
    private readonly DispatcherTimer _hubSearchTimer;
    private readonly HashSet<string> _selectedClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _knownClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<WavePage, Button> _railByPage = [];
    private readonly HashSet<string> _favouriteScripts = new(StringComparer.OrdinalIgnoreCase);
    private string? _openSectionId;
    private readonly List<ExplorerSection> _explorerSections = [];
    private readonly Dictionary<string, List<WaveScriptItem>> _sectionFiles = [];
    private readonly Dictionary<string, StackPanel> _sectionChildren = [];

    private readonly Border _chrome;
    private readonly NativeWebView _editor;
    private readonly StackPanel _tabStrip;
    private readonly Grid _railHost;
    private readonly Border _railIndicator;
    private readonly TranslateTransform _railIndicatorTransform;
    private readonly Grid _pageEditor;
    private readonly Grid _pageCloud;
    private readonly Grid _pageConsole;
    private readonly Border _explorerSidebar;
    private readonly StackPanel _explorerTree;
    private readonly ListBox _cloudList;
    private readonly TextBox _cloudSearch;
    private readonly TextBlock _cloudEmpty;
    private readonly ScrollViewer _consoleScroll;
    private readonly SelectableTextBlock _consoleText;
    private readonly Button _executeButton;
    private readonly Border _toastPill;
    private readonly TextBlock _toastText;
    private readonly Panel _settingsOverlay;
    private readonly Border _settingsDialog;
    private readonly Button _settingsNavGeneral;
    private readonly Button _settingsNavEditor;
    private readonly StackPanel _settingsGeneralPage;
    private readonly StackPanel _settingsEditorPage;
    private readonly ToggleButton _topMostCheck;
    private readonly ToggleButton _minimapCheck;
    private readonly ToggleButton _inlayHintsCheck;
    private readonly ToggleButton _smoothCursorCheck;
    private readonly ToggleButton _smoothScrollCheck;

    private EditorTabState _activeTab;
    private WavePage _currentPage = WavePage.Editor;
    private SettingsSection _settingsSection = SettingsSection.General;
    private bool _editorReady;
    private bool _editorSourceAssigned;
    private bool _editorDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;
    private bool _settingsOpen;
    private bool _consoleLoaded;
    private bool _suppressToggleEvents;
    private bool _explorerSidebarOpen;
    private string _scriptsFolderSetting = string.Empty;
    private string _workspaceFolderSetting = string.Empty;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;
    private CancellationTokenSource? _fx;
    private CancellationTokenSource? _railFx;

    public WaveWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal WaveWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _baseDirectory = Path.GetDirectoryName(scriptsDirectory.TrimEnd(Path.DirectorySeparatorChar))
            ?? AppContext.BaseDirectory;
        _workspace = initialWorkspace.CloneDetached();
        if (_workspace.Tabs.Count == 0)
        {
            var firstTab = NewTabState();
            _workspace.Tabs.Add(firstTab);
            _workspace.ActiveTabId = firstTab.Id;
        }
        _activeTab = _workspace.Tabs.FirstOrDefault(tab => tab.Id == _workspace.ActiveTabId)
            ?? _workspace.Tabs[0];
        _returnToOrion = returnToOrion;
        _editorOptions = WaveEditorOptionsStore.Load();
        _scriptsFolderSetting = string.IsNullOrWhiteSpace(_editorOptions.ScriptsFolder)
            ? _scriptsDirectory
            : _editorOptions.ScriptsFolder;
        _workspaceFolderSetting = string.IsNullOrWhiteSpace(_editorOptions.WorkspaceFolder)
            ? Path.Combine(_baseDirectory, "Workspace")
            : _editorOptions.WorkspaceFolder;

        AvaloniaXamlLoader.Load(this);

        _hubSearchTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(450) };
        _hubSearchTimer.Tick += HubSearchTimer_Tick;

        _chrome = Required<Border>("WaveChrome");
        _editor = Required<NativeWebView>("EditorWebView");
        _tabStrip = Required<StackPanel>("TabStrip");
        _railHost = Required<Grid>("RailHost");
        _railIndicator = Required<Border>("RailIndicator");
        _railIndicatorTransform = _railIndicator.RenderTransform as TranslateTransform ?? new TranslateTransform();
        _railIndicator.RenderTransform = _railIndicatorTransform;
        _pageEditor = Required<Grid>("PageEditor");
        _pageCloud = Required<Grid>("PageCloud");
        _pageConsole = Required<Grid>("PageConsole");
        _explorerSidebar = Required<Border>("ExplorerSidebar");
        _explorerTree = Required<StackPanel>("ExplorerTree");
        _cloudList = Required<ListBox>("CloudList");
        _cloudSearch = Required<TextBox>("CloudSearch");
        _cloudEmpty = Required<TextBlock>("CloudEmpty");
        _consoleScroll = Required<ScrollViewer>("ConsoleScroll");
        _consoleText = Required<SelectableTextBlock>("ConsoleText");
        _executeButton = Required<Button>("ExecuteButton");
        _toastPill = Required<Border>("ToastPill");
        _toastText = Required<TextBlock>("ToastText");
        _settingsOverlay = Required<Panel>("SettingsOverlay");
        _settingsDialog = Required<Border>("SettingsDialog");
        _settingsNavGeneral = Required<Button>("SettingsNavGeneral");
        _settingsNavEditor = Required<Button>("SettingsNavEditor");
        _settingsGeneralPage = Required<StackPanel>("SettingsGeneralPage");
        _settingsEditorPage = Required<StackPanel>("SettingsEditorPage");
        _topMostCheck = Required<ToggleButton>("TopMostCheck");
        _minimapCheck = Required<ToggleButton>("MinimapCheck");
        _inlayHintsCheck = Required<ToggleButton>("InlayHintsCheck");
        _smoothCursorCheck = Required<ToggleButton>("SmoothCursorCheck");
        _smoothScrollCheck = Required<ToggleButton>("SmoothScrollCheck");

        _railByPage[WavePage.Editor] = Required<Button>("RailEditor");
        _railByPage[WavePage.Cloud] = Required<Button>("RailCloud");
        _railByPage[WavePage.Console] = Required<Button>("RailConsole");

        _editor.WebMessageReceived += Editor_WebMessageReceived;

        Topmost = OrbitPreferences.TopMostEnabled;
        CanResize = true;

        _cloudList.ItemTemplate = new FuncDataTemplate<ScriptHubCardModel>(
            (item, _) => BuildHubCardVisual(item), true);

        InitializeExplorerSections();
        _favouriteScripts.UnionWith(WaveFavouritesStore.Load());
        RefreshExplorer();
        InitializeToggleStates();
        UpdateRailVisuals();
        UpdateSettingsFolderLabels();
        RenderTabs();
        UpdateBridgeVisuals();

        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.LogReceived += BridgeLogReceived;
        _bridge.ClientsChanged += BridgeClientsChanged;
        RefreshClientTargets();

        Opened += WaveWindow_Opened;
        Closed += WaveWindow_Closed;
        PropertyChanged += WaveWindow_PropertyChanged;
        KeyDown += WaveWindow_KeyDown;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"Wave control '{name}' was not created.");

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = NewTabState();
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private static EditorTabState NewTabState() => new()
    {
        Title = "Untitled Tab",
        Content = string.Empty,
        Extension = ".lua"
    };

    // ─────────────────────────── lifecycle ───────────────────────────

    private async void WaveWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= WaveWindow_Opened;

        _chrome.Opacity = 0;
        var scale = new ScaleTransform(0.965, 0.965);
        _chrome.RenderTransform = scale;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(380),
                progress =>
                {
                    _chrome.Opacity = progress;
                    var value = 0.965 + (0.035 * progress);
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
            // Window closed during the entrance animation.
        }

        _chrome.Opacity = 1;
        _chrome.RenderTransform = null;
        PositionRailIndicator(_currentPage, animate: false);
        RevealEditor();
    }

    private void WaveWindow_Closed(object? sender, EventArgs e)
    {
        _editorDisposed = true;
        _editor.IsVisible = false;
        _pendingEditorSnapshot?.TrySetCanceled();
        _editor.WebMessageReceived -= Editor_WebMessageReceived;
        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.LogReceived -= BridgeLogReceived;
        _bridge.ClientsChanged -= BridgeClientsChanged;
        _hubSearchTimer.Stop();
        _hubLoadCancellation?.Cancel();
        _hubLoadCancellation?.Dispose();
        _hubService.Dispose();

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(CaptureWorkspace());
        }
    }

    private void WaveWindow_PropertyChanged(object? sender, AvaloniaPropertyChangedEventArgs e)
    {
        if (e.Property != WindowStateProperty)
        {
            return;
        }

        var maximized = WindowState == WindowState.Maximized;
        _chrome.CornerRadius = maximized ? new CornerRadius(0) : new CornerRadius(10);
        _chrome.BorderThickness = maximized ? new Thickness(0) : new Thickness(1);
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        Close();
    }

    private void WaveWindow_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_settingsOpen)
            {
                _ = CloseSettingsOverlayAsync();
                e.Handled = true;
            }
            else if (_explorerSidebarOpen)
            {
                _ = ToggleExplorerSidebarAsync();
                e.Handled = true;
            }
            return;
        }

        if (e.Source is TextBox)
        {
            return;
        }

        if (e.Key == Key.F5 ||
            ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.Enter))
        {
            _ = ExecuteCurrentScriptAsync();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.S)
        {
            _ = SaveCurrentFileAsync();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.O)
        {
            Open_Click(this, new RoutedEventArgs());
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.T)
        {
            AddTab();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.W)
        {
            CloseTab(_activeTab);
            e.Handled = true;
        }
    }

    // ─────────────────────────── title bar ───────────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed)
        {
            return;
        }

        if (e.Source is Visual visual &&
            (visual is Button || visual.GetVisualAncestors().OfType<Button>().Any()))
        {
            return;
        }

        if (e.ClickCount == 2 && CanResize)
        {
            WindowState = WindowState == WindowState.Maximized
                ? WindowState.Normal
                : WindowState.Maximized;
            return;
        }

        if (WindowState != WindowState.Maximized)
        {
            BeginMoveDrag(e);
        }
    }

    private void Minimize_Click(object? sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Maximize_Click(object? sender, RoutedEventArgs e)
    {
        if (CanResize)
        {
            WindowState = WindowState == WindowState.Maximized
                ? WindowState.Normal
                : WindowState.Maximized;
        }
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    // ─────────────────────────── rail & pages ───────────────────────────

    private void RailExplorer_Click(object? sender, RoutedEventArgs e) => _ = ToggleExplorerSidebarAsync();

    private void RailEditor_Click(object? sender, RoutedEventArgs e) => _ = SwitchPageAsync(WavePage.Editor);

    private void RailCloud_Click(object? sender, RoutedEventArgs e) => _ = SwitchPageAsync(WavePage.Cloud);

    private void RailConsole_Click(object? sender, RoutedEventArgs e) => _ = SwitchPageAsync(WavePage.Console);

    private Control ControlForPage(WavePage page) => page switch
    {
        WavePage.Editor => _pageEditor,
        WavePage.Cloud => _pageCloud,
        WavePage.Console => _pageConsole,
        _ => _pageEditor
    };

    private async Task ToggleExplorerSidebarAsync()
    {
        _explorerSidebarOpen = !_explorerSidebarOpen;
        if (_explorerSidebarOpen)
        {
            RefreshExplorer();
        }

        UpdateRailVisuals();

        const double targetWidth = 248d;
        var from = _explorerSidebar.Width;
        var to = _explorerSidebarOpen ? targetWidth : 0d;
        if (double.IsNaN(from))
        {
            from = 0d;
        }

        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(220),
                progress => _explorerSidebar.Width = Lerp(from, to, progress),
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _explorerSidebar.Width = to;

        if (_currentPage == WavePage.Editor && _editorReady && !_settingsOpen)
        {
            try
            {
                await _editor.InvokeScript("window.orionLayout && window.orionLayout();");
            }
            catch (InvalidOperationException)
            {
                _editorReady = false;
            }
        }
    }

    private async Task SwitchPageAsync(WavePage target)
    {
        if (target == _currentPage)
        {
            return;
        }

        var incoming = ControlForPage(target);
        var outgoing = ControlForPage(_currentPage);
        _currentPage = target;
        UpdateRailVisuals();
        PositionRailIndicator(target, animate: true);

        outgoing.IsVisible = false;
        outgoing.IsHitTestVisible = false;
        incoming.IsVisible = true;
        incoming.IsHitTestVisible = true;

        if (target == WavePage.Editor)
        {
            RevealEditor();
            if (_editorReady)
            {
                try
                {
                    await _editor.InvokeScript("window.orionLayout && window.orionLayout();");
                }
                catch (InvalidOperationException)
                {
                    _editorReady = false;
                }
            }
        }
        else
        {
            _editor.IsVisible = false;
            if (target == WavePage.Cloud) EnsureCloudLoaded();
            if (target == WavePage.Console) EnsureConsoleLoaded();
        }

        var token = RestartFx();
        incoming.Opacity = 0;
        var slide = new TranslateTransform { Y = 14 };
        incoming.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(210),
                progress =>
                {
                    incoming.Opacity = progress;
                    slide.Y = 14 * (1 - progress);
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        incoming.Opacity = 1;
        incoming.RenderTransform = null;
    }

    private void UpdateRailVisuals()
    {
        foreach (var (page, button) in _railByPage)
        {
            if (page == _currentPage)
            {
                button.Classes.Add("active");
            }
            else
            {
                button.Classes.Remove("active");
            }
        }

        var folderButton = this.FindControl<Button>("RailExplorer");
        if (folderButton is not null)
        {
            if (_explorerSidebarOpen)
            {
                folderButton.Classes.Add("active");
            }
            else
            {
                folderButton.Classes.Remove("active");
            }
        }
    }

    private void PositionRailIndicator(WavePage page, bool animate)
    {
        if (!_railByPage.TryGetValue(page, out var button))
        {
            return;
        }

        var topLeft = button.TranslatePoint(new Point(0, 0), _railHost);
        if (topLeft is null)
        {
            return;
        }

        var indicatorY = topLeft.Value.Y +
            Math.Max(0, (button.Bounds.Height - _railIndicator.Height) / 2);

        if (!animate)
        {
            _railIndicatorTransform.Y = indicatorY;
            return;
        }

        var fromIndicator = _railIndicatorTransform.Y;
        _railFx?.Cancel();
        _railFx?.Dispose();
        _railFx = new CancellationTokenSource();
        var token = _railFx.Token;
        _ = AnimateAsync(
            TimeSpan.FromMilliseconds(230),
            progress =>
            {
                _railIndicatorTransform.Y = Lerp(fromIndicator, indicatorY, progress);
            },
            CubicEaseOut,
            token);
    }

    // ─────────────────────────── tabs ───────────────────────────

    private void RenderTabs(Guid? entranceTabId = null)
    {
        _tabStrip.Children.Clear();
        foreach (var tab in _workspace.Tabs)
        {
            var visual = CreateTabVisual(tab);
            _tabStrip.Children.Add(visual);
            if (entranceTabId.HasValue && tab.Id == entranceTabId.Value)
            {
                AnimateTabEntrance(visual);
            }
        }

        var add = new Button
        {
            Width = 26,
            Height = 26,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(7),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = new AvaloniaPath
            {
                Data = (Geometry?)Resources["WavePlusIcon"],
                Width = 12,
                Height = 12,
                Stretch = Stretch.Uniform,
                Stroke = new SolidColorBrush(Color.Parse("#7E93B4")),
                StrokeThickness = 1.8,
                StrokeLineCap = PenLineCap.Round,
                StrokeJoin = PenLineJoin.Round
            }
        };
        ToolTip.SetTip(add, "New tab (Ctrl+T)");
        add.PointerEntered += (_, _) => add.Background = new SolidColorBrush(Color.Parse("#1E304F"));
        add.PointerExited += (_, _) => add.Background = Brushes.Transparent;
        add.Click += (_, _) => AddTab();
        _tabStrip.Children.Add(add);
    }

    private Border CreateTabVisual(EditorTabState tab)
    {
        var active = tab.Id == _activeTab.Id;
        var border = new Border
        {
            Height = 26,
            Padding = new Thickness(10, 0, 6, 0),
            CornerRadius = new CornerRadius(7),
            Background = new SolidColorBrush(Color.Parse(active ? "#1D2E4C" : "#00000000")),
            BorderBrush = new SolidColorBrush(Color.Parse(active ? "#203354" : "#00000000")),
            BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        border.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(150) },
            new BrushTransition { Property = Border.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(150) }
        };

        var grid = new Grid { ColumnDefinitions = new ColumnDefinitions("*,18") };

        var title = new TextBlock
        {
            Text = tab.Title,
            FontSize = 11.5,
            FontWeight = FontWeight.Medium,
            Foreground = new SolidColorBrush(Color.Parse(active ? "#EEEFF0" : "#93A5C4")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 6, 0)
        };
        title.Transitions = new Transitions
        {
            new BrushTransition { Property = TextBlock.ForegroundProperty, Duration = TimeSpan.FromMilliseconds(150) }
        };
        title.DoubleTapped += (_, e) =>
        {
            e.Handled = true;
            BeginTabRename(tab, grid, title);
        };
        Grid.SetColumn(title, 0);

        var close = new Button
        {
            Width = 16,
            Height = 16,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(4),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Content = new AvaloniaPath
            {
                Data = (Geometry?)Resources["WaveCloseIcon"],
                Width = 7,
                Height = 7,
                Stretch = Stretch.Uniform,
                Stroke = new SolidColorBrush(Color.Parse(active ? "#9FB2D2" : "#5E7295")),
                StrokeThickness = 2,
                StrokeLineCap = PenLineCap.Round,
                StrokeJoin = PenLineJoin.Round
            }
        };
        close.PointerEntered += (_, _) =>
        {
            close.Background = new SolidColorBrush(Color.Parse("#2A3C5F"));
            if (close.Content is AvaloniaPath enteredIcon)
            {
                enteredIcon.Stroke = new SolidColorBrush(Color.Parse("#FFFFFF"));
            }
        };
        close.PointerExited += (_, _) =>
        {
            close.Background = Brushes.Transparent;
            if (close.Content is AvaloniaPath exitedIcon)
            {
                exitedIcon.Stroke = new SolidColorBrush(Color.Parse(active ? "#9FB2D2" : "#5E7295"));
            }
        };
        close.Click += (_, e) =>
        {
            e.Handled = true;
            CloseTab(tab);
        };
        Grid.SetColumn(close, 1);

        grid.Children.Add(title);
        grid.Children.Add(close);
        border.Child = grid;

        border.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(border).Properties.IsLeftButtonPressed)
            {
                SelectTab(tab);
                e.Handled = true;
            }
        };
        border.PointerEntered += (_, _) =>
        {
            if (tab.Id != _activeTab.Id)
            {
                border.Background = new SolidColorBrush(Color.Parse("#14203A"));
                border.BorderBrush = new SolidColorBrush(Color.Parse("#22345A"));
            }
        };
        border.PointerExited += (_, _) =>
        {
            if (tab.Id != _activeTab.Id)
            {
                border.Background = new SolidColorBrush(Color.Parse("#00000000"));
                border.BorderBrush = new SolidColorBrush(Color.Parse("#00000000"));
            }
        };

        border.MinWidth = 110;
        border.MaxWidth = 190;
        return border;
    }

    private async void AnimateTabEntrance(Border visual)
    {
        visual.Opacity = 0;
        var slide = new TranslateTransform { X = -10 };
        visual.RenderTransform = slide;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(190),
                progress =>
                {
                    visual.Opacity = progress;
                    slide.X = -10 * (1 - progress);
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }
        visual.Opacity = 1;
        visual.RenderTransform = null;
    }

    private void BeginTabRename(EditorTabState tab, Grid grid, TextBlock title)
    {
        var input = new TextBox
        {
            Text = tab.Title,
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Padding = new Thickness(0),
            Foreground = new SolidColorBrush(Color.Parse("#EAF2FF")),
            CaretBrush = new SolidColorBrush(Color.Parse("#9CC0F5")),
            FontSize = 11.5,
            VerticalContentAlignment = VerticalAlignment.Center
        };
        Grid.SetColumn(input, 0);
        grid.Children.Remove(title);
        grid.Children.Add(input);

        var committed = false;
        void Commit()
        {
            if (committed)
            {
                return;
            }

            committed = true;
            var name = (input.Text ?? string.Empty).Trim();
            tab.Title = name.Length == 0 ? "Untitled Tab" : name;
            RenderTabs();
        }

        input.LostFocus += (_, _) => Commit();
        input.KeyDown += (_, e) =>
        {
            if (e.Key == Key.Enter)
            {
                Commit();
                e.Handled = true;
            }
            else if (e.Key == Key.Escape)
            {
                committed = true;
                RenderTabs();
                e.Handled = true;
            }
        };
        input.Focus();
        input.SelectAll();
    }

    private void AddTab()
    {
        var tab = NewTabState();
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs(tab.Id);
        PushActiveTabToEditor();
    }

    private void SelectTab(EditorTabState tab)
    {
        if (_activeTab.Id == tab.Id)
        {
            return;
        }

        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        PushActiveTabToEditor();
    }

    private void CloseTab(EditorTabState tab)
    {
        if (_workspace.Tabs.Count == 1)
        {
            _ = ShowToastAsync("Cannot close the last tab");
            return;
        }

        var index = _workspace.Tabs.IndexOf(tab);
        _workspace.Tabs.Remove(tab);
        if (_activeTab.Id == tab.Id)
        {
            _activeTab = _workspace.Tabs[Math.Clamp(index - 1, 0, _workspace.Tabs.Count - 1)];
            _workspace.ActiveTabId = _activeTab.Id;
            RenderTabs();
            PushActiveTabToEditor();
        }
        else
        {
            RenderTabs();
        }
    }

    // ─────────────────────────── editor bridge ───────────────────────────

    private void RevealEditor()
    {
        if (_editorDisposed || _settingsOpen || _currentPage != WavePage.Editor)
        {
            return;
        }

        _editor.IsVisible = true;
        if (_editorSourceAssigned)
        {
            return;
        }

        _editorSourceAssigned = true;
        _editor.Source = new UriBuilder(_monacoAddress)
        {
            Query = "transparent=1"
        }.Uri;
    }

    private async void Editor_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
    {
        if (string.IsNullOrWhiteSpace(args.Body))
        {
            return;
        }

        try
        {
            using var payload = JsonDocument.Parse(args.Body);
            var root = payload.RootElement;
            if (!root.TryGetProperty("type", out var typeProperty))
            {
                return;
            }

            switch (typeProperty.GetString())
            {
                case "ready":
                    Dispatcher.UIThread.Post(() =>
                    {
                        _editorReady = true;
                        ApplyEditorOptionsToWebView();
                        PushActiveTabToEditor();
                    });
                    break;

                case "contentChangedDelta" when root.TryGetProperty("changes", out var changesProperty):
                {
                    var changes = changesProperty.Clone();
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        if (EditorContentDelta.TryApply(changes, targetTab.Content, out var content))
                        {
                            targetTab.Content = content;
                        }
                    });
                    break;
                }

                case "contentSnapshot" when root.TryGetProperty("content", out var snapshotProperty):
                {
                    var content = snapshotProperty.GetString() ?? string.Empty;
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        targetTab.Content = content;
                        _pendingEditorSnapshot?.TrySetResult(content);
                    });
                    break;
                }

                case "executeRequested" when root.TryGetProperty("content", out var executeProperty):
                {
                    var content = executeProperty.GetString() ?? string.Empty;
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        targetTab.Content = content;
                        ExecuteOnBridge(content);
                    });
                    break;
                }

                case "cursorPosition":
                    // The original Wave shell has no caret status strip.
                    break;
            }
        }
        catch (JsonException)
        {
            // Ignore messages that are not part of the shared Monaco bridge.
        }
    }

    private void PushActiveTabToEditor()
    {
        if (!_editorReady || _activeTab is null)
        {
            return;
        }

        var content = JsonSerializer.Serialize(_activeTab.Content);
        var language = JsonSerializer.Serialize(LanguageForExtension(_activeTab.Extension));
        try
        {
            _editor.InvokeScript(
                $"window.orbitSetContent && window.orbitSetContent({content}, {language});");
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
        }
    }

    private async Task<string> RequestEditorContentAsync()
    {
        if (!_editorReady)
        {
            return _activeTab.Content;
        }

        _pendingEditorSnapshot?.TrySetCanceled();
        var completion = new TaskCompletionSource<string>(
            TaskCreationOptions.RunContinuationsAsynchronously);
        _pendingEditorSnapshot = completion;
        try
        {
            await _editor.InvokeScript(
                "window.orionRequestSnapshot && window.orionRequestSnapshot();");
            var completed = await Task.WhenAny(completion.Task, Task.Delay(700));
            return completed == completion.Task
                ? await completion.Task
                : _activeTab.Content;
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
            return _activeTab.Content;
        }
        finally
        {
            if (ReferenceEquals(_pendingEditorSnapshot, completion))
            {
                _pendingEditorSnapshot = null;
            }
        }
    }

    private static string LanguageForExtension(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".md" or ".markdown" => "markdown",
            ".json" => "json",
            ".js" or ".ts" => "javascript",
            ".txt" => "plaintext",
            _ => "lua"
        };

    // ─────────────────────────── editor options ───────────────────────────

    private void InitializeToggleStates()
    {
        _suppressToggleEvents = true;
        _topMostCheck.IsChecked = OrbitPreferences.TopMostEnabled;
        _minimapCheck.IsChecked = _editorOptions.Minimap;
        _inlayHintsCheck.IsChecked = _editorOptions.InlayHints;
        _smoothCursorCheck.IsChecked = _editorOptions.SmoothCursor;
        _smoothScrollCheck.IsChecked = _editorOptions.SmoothScroll;
        _suppressToggleEvents = false;

        _topMostCheck.IsCheckedChanged += TopMostCheck_IsCheckedChanged;
        _minimapCheck.IsCheckedChanged += EditorOptionCheck_IsCheckedChanged;
        _inlayHintsCheck.IsCheckedChanged += EditorOptionCheck_IsCheckedChanged;
        _smoothCursorCheck.IsCheckedChanged += EditorOptionCheck_IsCheckedChanged;
        _smoothScrollCheck.IsCheckedChanged += EditorOptionCheck_IsCheckedChanged;
    }

    private void TopMostCheck_IsCheckedChanged(object? sender, RoutedEventArgs e)
    {
        if (_suppressToggleEvents)
        {
            return;
        }

        var enabled = _topMostCheck.IsChecked == true;
        Topmost = enabled;
        OrbitPreferences.SetTopMost(enabled);
        _ = ShowToastAsync(enabled ? "Always on top enabled" : "Always on top disabled");
    }

    private void EditorOptionCheck_IsCheckedChanged(object? sender, RoutedEventArgs e)
    {
        if (_suppressToggleEvents)
        {
            return;
        }

        _editorOptions.Minimap = _minimapCheck.IsChecked == true;
        _editorOptions.InlayHints = _inlayHintsCheck.IsChecked == true;
        _editorOptions.SmoothCursor = _smoothCursorCheck.IsChecked == true;
        _editorOptions.SmoothScroll = _smoothScrollCheck.IsChecked == true;
        WaveEditorOptionsStore.Save(_editorOptions);
        ApplyEditorOptionsToWebView();
    }

    private void ApplyEditorOptionsToWebView()
    {
        if (!_editorReady || _editorDisposed)
        {
            return;
        }

        var payload = JsonSerializer.Serialize(new Dictionary<string, object?>(StringComparer.Ordinal)
        {
            ["minimap"] = new Dictionary<string, object?> { ["enabled"] = _editorOptions.Minimap },
            ["inlayHints"] = new Dictionary<string, object?>
            {
                ["enabled"] = _editorOptions.InlayHints ? "on" : "off"
            },
            ["cursorSmoothCaretAnimation"] = _editorOptions.SmoothCursor ? "on" : "off",
            ["smoothScrolling"] = _editorOptions.SmoothScroll
        });

        try
        {
            _editor.InvokeScript(
                $"window.orbitUpdateEditorOptions && window.orbitUpdateEditorOptions({payload});");
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
        }
    }

    // ─────────────────────────── settings overlay ───────────────────────────

    private void Settings_Click(object? sender, RoutedEventArgs e)
    {
        if (_settingsOpen)
        {
            _ = CloseSettingsOverlayAsync();
        }
        else
        {
            _ = OpenSettingsOverlayAsync();
        }
    }

    private async Task OpenSettingsOverlayAsync()
    {
        if (_settingsOpen)
        {
            return;
        }

        _settingsOpen = true;
        _editor.IsVisible = false;
        _settingsOverlay.IsVisible = true;

        var token = RestartFx();
        _settingsOverlay.Opacity = 0;
        var scale = new ScaleTransform(0.94, 0.94);
        _settingsDialog.RenderTransform = scale;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(210),
                progress =>
                {
                    _settingsOverlay.Opacity = progress;
                    var value = 0.94 + (0.06 * progress);
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _settingsOverlay.Opacity = 1;
        _settingsDialog.RenderTransform = null;
    }

    private async Task CloseSettingsOverlayAsync()
    {
        if (!_settingsOpen)
        {
            return;
        }

        _settingsOpen = false;
        var token = RestartFx();
        var scale = new ScaleTransform(1, 1);
        _settingsDialog.RenderTransform = scale;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(150),
                progress =>
                {
                    _settingsOverlay.Opacity = 1 - progress;
                    var value = 1 - (0.05 * progress);
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _settingsOverlay.IsVisible = false;
        _settingsDialog.RenderTransform = null;
        RevealEditor();
    }

    private void SettingsNavGeneral_Click(object? sender, RoutedEventArgs e) =>
        SwitchSettingsSection(SettingsSection.General);

    private void SettingsNavEditor_Click(object? sender, RoutedEventArgs e) =>
        SwitchSettingsSection(SettingsSection.Editor);

    private async void SwitchSettingsSection(SettingsSection section)
    {
        if (section == _settingsSection)
        {
            return;
        }

        _settingsSection = section;
        if (section == SettingsSection.General)
        {
            _settingsNavGeneral.Classes.Add("active");
            _settingsNavEditor.Classes.Remove("active");
        }
        else
        {
            _settingsNavGeneral.Classes.Remove("active");
            _settingsNavEditor.Classes.Add("active");
        }

        var incoming = section == SettingsSection.General ? _settingsGeneralPage : _settingsEditorPage;
        var outgoing = section == SettingsSection.General ? _settingsEditorPage : _settingsGeneralPage;
        outgoing.IsVisible = false;
        incoming.IsVisible = true;

        var token = RestartFx();
        incoming.Opacity = 0;
        var slide = new TranslateTransform { Y = 10 };
        incoming.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(180),
                progress =>
                {
                    incoming.Opacity = progress;
                    slide.Y = 10 * (1 - progress);
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        incoming.Opacity = 1;
        incoming.RenderTransform = null;
    }

    private void ReturnToOrion_Click(object? sender, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    private void UpdateSettingsFolderLabels()
    {
        if (this.FindControl<TextBlock>("ScriptsFolderLabel") is { } scriptsLabel)
        {
            scriptsLabel.Text = _scriptsFolderSetting;
        }

        if (this.FindControl<TextBlock>("WorkspaceFolderLabel") is { } workspaceLabel)
        {
            workspaceLabel.Text = _workspaceFolderSetting;
        }
    }

    private async void ScriptsFolderBrowse_Click(object? sender, RoutedEventArgs e) =>
        await BrowseFolderAsync("Scripts Folder", path =>
        {
            _scriptsFolderSetting = path;
            _editorOptions.ScriptsFolder = path;
        });

    private async void WorkspaceFolderBrowse_Click(object? sender, RoutedEventArgs e) =>
        await BrowseFolderAsync("Workspace Folder", path =>
        {
            _workspaceFolderSetting = path;
            _editorOptions.WorkspaceFolder = path;
        });

    private async Task BrowseFolderAsync(string title, Action<string> apply)
    {
        var folders = await StorageProvider.OpenFolderPickerAsync(new FolderPickerOpenOptions
        {
            Title = $"Select {title}",
            AllowMultiple = false
        });

        var folder = folders.FirstOrDefault();
        if (folder is null || string.IsNullOrEmpty(folder.Path.LocalPath))
        {
            return;
        }

        apply(folder.Path.LocalPath);
        WaveEditorOptionsStore.Save(_editorOptions);
        UpdateSettingsFolderLabels();
        RefreshExplorer();
        _ = ShowToastAsync($"{title}: {folder.Name}");
    }

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested)
        {
            return;
        }

        _returnRequested = true;
        _activeTab.Content = await RequestEditorContentAsync();
        _returnToOrion(CaptureWorkspace());
    }

    private EditorWorkspaceState CaptureWorkspace() => new()
    {
        Tabs = _workspace.Tabs.Select(tab => tab.CloneDetached()).ToList(),
        ActiveTabId = _activeTab.Id
    };

    // ─────────────────────────── actions ───────────────────────────

    private async void Execute_Click(object? sender, RoutedEventArgs e) => await ExecuteCurrentScriptAsync();

    private async Task ExecuteCurrentScriptAsync()
    {
        var source = await RequestEditorContentAsync();
        _activeTab.Content = source;
        if (string.IsNullOrWhiteSpace(source))
        {
            _ = ShowToastAsync("Nothing to execute");
            return;
        }

        ExecuteOnBridge(source);
    }

    private void ExecuteOnBridge(string source)
    {
        if (!_bridge.IsConnected)
        {
            _ = ShowToastAsync("Bridge offline — run Scripts/Orion Bridge.lua first");
            return;
        }

        _bridge.EnqueueExecute(source);
        _ = ShowToastAsync("Script executed");
        _ = PulseExecuteAsync();
    }

    private async Task PulseExecuteAsync()
    {
        _executeButton.RenderTransformOrigin = new RelativePoint(0.5, 0.5, RelativeUnit.Relative);
        var scale = new ScaleTransform(1, 1);
        _executeButton.RenderTransform = scale;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(260),
                progress =>
                {
                    var value = 1 - (0.07 * Math.Sin(progress * Math.PI));
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                progress => progress,
                token);
        }
        catch (OperationCanceledException)
        {
        }
        _executeButton.RenderTransform = null;
    }

    private async void Clear_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = await RequestEditorContentAsync();
        _activeTab.Content = string.Empty;
        PushActiveTabToEditor();
        _ = ShowToastAsync("Editor cleared");
    }

    private async void Open_Click(object? sender, RoutedEventArgs e)
    {
        var picked = await PickScriptAsync();
        if (picked is null)
        {
            return;
        }

        OpenFileInTab(picked.Value.File.Name, picked.Value.Content);
        _ = ShowToastAsync($"Opened {picked.Value.File.Name}");
    }

    private async Task<(IStorageFile File, string Content)?> PickScriptAsync()
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            Title = "Open script",
            AllowMultiple = false,
            FileTypeFilter =
            [
                new FilePickerFileType("Script files")
                {
                    Patterns = ["*.lua", "*.luau", "*.txt"]
                }
            ]
        });
        var file = files.FirstOrDefault();
        if (file is null)
        {
            return null;
        }

        await using var stream = await file.OpenReadAsync();
        using var reader = new StreamReader(stream);
        return (file, await reader.ReadToEndAsync());
    }

    private void OpenFileInTab(string fileName, string content)
    {
        var tab = new EditorTabState
        {
            Title = Path.GetFileNameWithoutExtension(fileName),
            Extension = Path.GetExtension(fileName) is { Length: > 0 } extension
                ? extension
                : ".lua",
            Content = content
        };
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs(tab.Id);
        if (_currentPage != WavePage.Editor)
        {
            _ = SwitchPageAsync(WavePage.Editor);
        }
        else
        {
            RevealEditor();
        }
        PushActiveTabToEditor();
    }

    private async void Save_Click(object? sender, RoutedEventArgs e) => await SaveCurrentFileAsync();

    private async Task SaveCurrentFileAsync()
    {
        _activeTab.Content = await RequestEditorContentAsync();
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            SuggestedFileName = SanitizeFileName(_activeTab.Title) + _activeTab.Extension,
            DefaultExtension = "lua",
            FileTypeChoices =
            [
                new FilePickerFileType("Lua script") { Patterns = ["*.lua"] },
                new FilePickerFileType("Luau script") { Patterns = ["*.luau"] },
                new FilePickerFileType("Text file") { Patterns = ["*.txt"] }
            ]
        });
        if (file is null)
        {
            return;
        }

        await using var stream = await file.OpenWriteAsync();
        stream.SetLength(0);
        await using var writer = new StreamWriter(stream);
        await writer.WriteAsync(_activeTab.Content);
        _activeTab.Title = Path.GetFileNameWithoutExtension(file.Name);
        _activeTab.Extension = Path.GetExtension(file.Name) is { Length: > 0 } extension
            ? extension
            : ".lua";
        RenderTabs();
        _ = ShowToastAsync($"Saved {file.Name}");
    }

    private static string SanitizeFileName(string value)
    {
        var invalid = Path.GetInvalidFileNameChars();
        var result = new string(value.Where(character => !invalid.Contains(character)).ToArray()).Trim();
        return result.Length == 0 ? "script" : result;
    }

    // ─────────────────────────── explorer & cloud ───────────────────────────

    private Control BuildScriptItemVisual(WaveScriptItem? item, bool showOrigin)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 9,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(10, 0)
        };
        panel.Children.Add(new AvaloniaPath
        {
            Data = (Geometry?)Resources[showOrigin ? "WaveCloudIcon" : "WaveScriptIcon"],
            Width = 15,
            Height = 15,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(Color.Parse("#7E93B4")),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
            StrokeJoin = PenLineJoin.Round,
            VerticalAlignment = VerticalAlignment.Center
        });
        panel.Children.Add(new TextBlock
        {
            Text = item?.Name ?? string.Empty,
            FontSize = 11.5,
            Foreground = new SolidColorBrush(Color.Parse("#C6D4EA")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });
        return panel;
    }

    private void InitializeExplorerSections()
    {
        _explorerSections.Add(new ExplorerSection(
            "Favourites", "Favourites", "WaveStarIcon"));
        _explorerSections.Add(new ExplorerSection(
            "Workspace", "Workspace", "WaveFolderIcon"));
        _explorerSections.Add(new ExplorerSection(
            "Scripts", "Scripts", "WaveTargetIcon"));
    }

    private string? DirectoryForSection(ExplorerSection section) => section.Id switch
    {
        "Workspace" => _workspaceFolderSetting,
        "Scripts" => _scriptsFolderSetting,
        _ => null
    };

    private static List<WaveScriptItem> ListScriptFiles(string directory)
    {
        var files = new List<WaveScriptItem>();
        try
        {
            Directory.CreateDirectory(directory);
            files.AddRange(Directory.EnumerateFiles(directory)
                .Where(path => new[] { ".lua", ".luau", ".txt" }
                    .Contains(Path.GetExtension(path), StringComparer.OrdinalIgnoreCase))
                .OrderBy(path => Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
                .Select(path => new WaveScriptItem(Path.GetFileName(path), path)));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // An unreadable folder simply renders as an empty section.
        }

        return files;
    }

    private void RefreshExplorer()
    {
        _sectionFiles.Clear();
        foreach (var section in _explorerSections)
        {
            if (section.Id == "Favourites")
            {
                _favouriteScripts.RemoveWhere(path => !File.Exists(path));
                WaveFavouritesStore.Save(_favouriteScripts);
                _sectionFiles[section.Id] = _favouriteScripts
                    .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                    .Select(path => new WaveScriptItem(Path.GetFileName(path), path))
                    .ToList();
            }
            else
            {
                var directory = DirectoryForSection(section);
                _sectionFiles[section.Id] = directory is null
                    ? []
                    : ListScriptFiles(directory);
            }
        }

        RebuildExplorerTree();
    }

    private void RebuildExplorerTree()
    {
        _explorerTree.Children.Clear();
        _sectionChildren.Clear();
        foreach (var section in _explorerSections)
        {
            var expanded = _openSectionId == section.Id;
            _explorerTree.Children.Add(BuildSectionHeader(section, expanded));

            var children = new StackPanel { Spacing = 2, Margin = new Thickness(18, 3, 0, 5), IsVisible = expanded };
            var files = _sectionFiles.TryGetValue(section.Id, out var value2) ? value2 : [];
            if (files.Count == 0)
            {
                children.Children.Add(new TextBlock
                {
                    Text = section.Id == "Favourites" ? "Star a script to pin it here" : "Empty",
                    FontSize = 10.5,
                    Foreground = new SolidColorBrush(Color.Parse("#55688A")),
                    Margin = new Thickness(13, 4, 0, 5)
                });
            }
            else
            {
                foreach (var file in files)
                {
                    children.Children.Add(BuildFileRow(section, file));
                }
            }

            _explorerTree.Children.Add(children);
            _sectionChildren[section.Id] = children;
        }
    }

    private async void AnimateSectionReveal(StackPanel children)
    {
        children.Opacity = 0;
        var slide = new TranslateTransform { X = -12 };
        children.RenderTransform = slide;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(210),
                progress =>
                {
                    children.Opacity = progress;
                    slide.X = -12 * (1 - progress);
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        children.Opacity = 1;
        children.RenderTransform = null;
    }

    private Control BuildSectionHeader(ExplorerSection section, bool expanded)
    {
        var header = new Button
        {
            Height = 31,
            Padding = new Thickness(11, 0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Left,
            VerticalContentAlignment = VerticalAlignment.Center,
            CornerRadius = new CornerRadius(8),
            Background = new SolidColorBrush(Color.Parse(expanded ? "#1F3358" : "#182742")),
            BorderBrush = new SolidColorBrush(Color.Parse(expanded ? "#31476F" : "#263A61")),
            BorderThickness = new Thickness(1),
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        header.Transitions = new Transitions
        {
            new BrushTransition { Property = Button.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(140) },
            new BrushTransition { Property = Button.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(140) }
        };
        var content = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 9,
            VerticalAlignment = VerticalAlignment.Center
        };
        content.Children.Add(new AvaloniaPath
        {
            Data = (Geometry?)Resources[section.IconKey],
            Width = 13,
            Height = 13,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(Color.Parse(expanded ? "#C7D8F2" : "#8CA3C4")),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
            StrokeJoin = PenLineJoin.Round,
            VerticalAlignment = VerticalAlignment.Center
        });
        content.Children.Add(new TextBlock
        {
            Text = section.Title,
            FontSize = 11.5,
            FontWeight = FontWeight.Medium,
            Foreground = new SolidColorBrush(Color.Parse(expanded ? "#EAF2FF" : "#C6D4EA")),
            VerticalAlignment = VerticalAlignment.Center
        });
        header.Content = content;
        header.PointerEntered += (_, _) =>
        {
            header.Background = new SolidColorBrush(Color.Parse("#223658"));
            header.BorderBrush = new SolidColorBrush(Color.Parse("#35507E"));
        };
        header.PointerExited += (_, _) =>
        {
            header.Background = new SolidColorBrush(Color.Parse(expanded ? "#1F3358" : "#182742"));
            header.BorderBrush = new SolidColorBrush(Color.Parse(expanded ? "#31476F" : "#263A61"));
        };
        header.Click += (_, _) => ToggleExplorerSection(section.Id);
        return header;
    }

    private Control BuildFileRow(ExplorerSection section, WaveScriptItem file)
    {
        var row = new Grid { ColumnDefinitions = new ColumnDefinitions("*,22") };
        var label = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 7,
            VerticalAlignment = VerticalAlignment.Center
        };
        label.Children.Add(new AvaloniaPath
        {
            Data = (Geometry?)Resources["WaveScriptIcon"],
            Width = 12,
            Height = 12,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(Color.Parse("#7E93B4")),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
            StrokeJoin = PenLineJoin.Round,
            VerticalAlignment = VerticalAlignment.Center
        });
        label.Children.Add(new TextBlock
        {
            Text = file.Name,
            FontSize = 11,
            Foreground = new SolidColorBrush(Color.Parse("#B9C8E2")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });
        row.Children.Add(label);

        var star = new Button
        {
            Width = 20,
            Height = 20,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(5),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = new AvaloniaPath
            {
                Data = (Geometry?)Resources["WaveStarIcon"],
                Width = 11,
                Height = 11,
                Stretch = Stretch.Uniform,
                Fill = _favouriteScripts.Contains(file.Path)
                    ? new SolidColorBrush(Color.Parse("#E8B84B"))
                    : Brushes.Transparent,
                Stroke = new SolidColorBrush(Color.Parse(_favouriteScripts.Contains(file.Path) ? "#E8B84B" : "#5E7295")),
                StrokeThickness = 1.5,
                StrokeLineCap = PenLineCap.Round,
                StrokeJoin = PenLineJoin.Round,
                VerticalAlignment = VerticalAlignment.Center
            }
        };
        ToolTip.SetTip(star, _favouriteScripts.Contains(file.Path) ? "Remove from favourites" : "Add to favourites");
        star.Click += (_, e) =>
        {
            e.Handled = true;
            if (!_favouriteScripts.Remove(file.Path))
            {
                _favouriteScripts.Add(file.Path);
            }

            WaveFavouritesStore.Save(_favouriteScripts);
            RefreshExplorer();
        };
        Grid.SetColumn(star, 1);
        row.Children.Add(star);

        var button = new Button
        {
            Height = 30,
            Padding = new Thickness(11, 0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
            VerticalContentAlignment = VerticalAlignment.Center,
            CornerRadius = new CornerRadius(7),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = row
        };
        button.PointerEntered += (_, _) =>
        {
            button.Background = new SolidColorBrush(Color.Parse("#16243E"));
            if (star.Content is AvaloniaPath starPath && !_favouriteScripts.Contains(file.Path))
            {
                starPath.Stroke = new SolidColorBrush(Color.Parse("#9DB2D4"));
            }
        };
        button.PointerExited += (_, _) =>
        {
            button.Background = Brushes.Transparent;
            if (star.Content is AvaloniaPath starPath && !_favouriteScripts.Contains(file.Path))
            {
                starPath.Stroke = new SolidColorBrush(Color.Parse("#5E7295"));
            }
        };
        button.Click += (_, _) => _ = OpenScriptFileAsync(file);
        return button;
    }

    private void ToggleExplorerSection(string sectionId)
    {
        var opening = _openSectionId != sectionId;
        _openSectionId = opening ? sectionId : null;
        RebuildExplorerTree();
        if (opening && _sectionChildren.TryGetValue(sectionId, out var children))
        {
            AnimateSectionReveal(children);
        }
    }

    private void EnsureCloudLoaded()
    {
        if (_hubCards.Count == 0 && !_hubLoading)
        {
            LoadHubCards(append: false);
        }
    }

    private Control BuildHubCardVisual(ScriptHubCardModel? card)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 10,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 6)
        };

        var thumbnail = new Image
        {
            Width = 52,
            Height = 34,
            Stretch = Stretch.UniformToFill
        };
        thumbnail.Bind(Image.SourceProperty, new Binding(nameof(ScriptHubCardModel.Thumbnail)));
        panel.Children.Add(new Border
        {
            Width = 52,
            Height = 34,
            CornerRadius = new CornerRadius(5),
            ClipToBounds = true,
            Child = thumbnail
        });

        var text = new StackPanel { Spacing = 2, VerticalAlignment = VerticalAlignment.Center };
        text.Children.Add(new TextBlock
        {
            Text = card?.Title ?? string.Empty,
            FontSize = 12,
            FontWeight = FontWeight.Medium,
            Foreground = new SolidColorBrush(Color.Parse("#EAF2FF")),
            TextTrimming = TextTrimming.CharacterEllipsis
        });
        text.Children.Add(new TextBlock
        {
            Text = card?.Subtitle ?? string.Empty,
            FontSize = 10.5,
            Foreground = new SolidColorBrush(Color.Parse("#8CA0BA")),
            TextTrimming = TextTrimming.CharacterEllipsis
        });
        panel.Children.Add(text);
        return panel;
    }

    private void LoadHubCards(bool append)
    {
        if (_hubLoading)
        {
            return;
        }

        if (!append)
        {
            _hubLoadCancellation?.Cancel();
            _hubLoadCancellation?.Dispose();
            _hubLoadCancellation = new CancellationTokenSource();
            _hubCards.Clear();
            _hubCardKeys.Clear();
            _hubPage = 1;
            _cloudEmpty.IsVisible = false;
            _cloudList.ItemsSource = null;
        }

        var cancellation = _hubLoadCancellation ??= new CancellationTokenSource();
        var version = ++_hubLoadVersion;
        _hubLoading = true;
        _cloudEmpty.Text = "Searching scripts…";
        _cloudEmpty.IsVisible = !append;

        _ = LoadHubCardsCore(append, version, cancellation.Token);
    }

    private async Task LoadHubCardsCore(bool append, int version, CancellationToken cancellation)
    {
        try
        {
            var query = (_cloudSearch.Text ?? string.Empty).Trim();
            var result = await _hubService.FetchAsync(
                ScriptHubProvider.RobloxScripts,
                query,
                append ? _hubPage + 1 : 1,
                cancellation);
            await _hubService.LoadThumbnailsAsync(result.Cards, cancellation);
            if (version != _hubLoadVersion || cancellation.IsCancellationRequested)
            {
                return;
            }

            var added = result.Cards.Where(card => _hubCardKeys.Add(card.Key)).ToArray();
            _hubCards.AddRange(added);
            _hubPage = append ? _hubPage + 1 : 1;
            _hubHasMore = result.HasMore && added.Length > 0;
            _cloudList.ItemsSource = _hubCards.ToList();

            if (_hubCards.Count == 0)
            {
                _cloudEmpty.Text = query.Length == 0
                    ? "No scripts are available right now"
                    : $"No scripts matching \"{query}\"";
                _cloudEmpty.IsVisible = true;
            }
            else
            {
                _cloudEmpty.IsVisible = false;
            }
        }
        catch (OperationCanceledException)
        {
            // A newer search replaced this request.
        }
        catch (Exception exception) when (exception is HttpRequestException or JsonException or InvalidDataException or TaskCanceledException)
        {
            if (version == _hubLoadVersion)
            {
                _cloudEmpty.Text = "Couldn't load scripts — the hub is unavailable right now";
                _cloudEmpty.IsVisible = true;
            }
        }
        finally
        {
            if (version == _hubLoadVersion)
            {
                _hubLoading = false;
            }
        }
    }

    private void HubSearchTimer_Tick(object? sender, EventArgs e)
    {
        _hubSearchTimer.Stop();
        LoadHubCards(append: false);
    }

    private void CloudSearch_TextChanged(object? sender, TextChangedEventArgs e)
    {
        _hubSearchTimer.Stop();
        _hubSearchTimer.Start();
    }

    private void CloudRefresh_Click(object? sender, RoutedEventArgs e) => LoadHubCards(append: false);

    private async void CloudList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_cloudList.SelectedItem is not ScriptHubCardModel card)
        {
            return;
        }

        _cloudList.SelectedItem = null;
        var content = card.ScriptBody;
        if (string.IsNullOrWhiteSpace(content))
        {
            _ = ShowToastAsync("Script source is empty");
            return;
        }

        var tab = new EditorTabState
        {
            Title = card.Title.EndsWith(".lua", StringComparison.OrdinalIgnoreCase)
                ? card.Title
                : card.Title + ".lua",
            Extension = ".lua",
            Content = content
        };
        _workspace.Tabs.Add(tab);
        SelectTab(tab);
        _ = SwitchPageAsync(WavePage.Editor);
        await Task.CompletedTask;
    }

    private async Task OpenScriptFileAsync(WaveScriptItem item)
    {
        try
        {
            OpenFileInTab(item.Name, await File.ReadAllTextAsync(item.Path));
            _ = ShowToastAsync($"Opened {item.Name}");
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            _ = ShowToastAsync($"Read error: {ex.Message}");
        }
    }

    // ─────────────────────────── clients ───────────────────────────

    private void BridgeClientsChanged() =>
        Dispatcher.UIThread.Post(RefreshClientTargets);

    private void BridgeConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(() => UpdateBridgeVisuals());

    private void BridgeLogReceived(string level, string message) =>
        Dispatcher.UIThread.Post(() => AppendOutput(message, level));

    private void RefreshClientTargets()
    {
        var clients = _bridge.GetConnectedClients();
        var liveIdentifiers = new HashSet<string>(
            clients.Select(client => client.Identifier),
            StringComparer.OrdinalIgnoreCase);

        _selectedClientIdentifiers.RemoveWhere(identifier => !liveIdentifiers.Contains(identifier));
        _knownClientIdentifiers.RemoveWhere(identifier => !liveIdentifiers.Contains(identifier));
        foreach (var client in clients)
        {
            if (_knownClientIdentifiers.Add(client.Identifier))
            {
                _selectedClientIdentifiers.Add(client.Identifier);
            }
        }

        UpdateBridgeVisuals();
    }


    private void UpdateBridgeVisuals()
    {
        var connected = _bridge.IsConnected && _bridge.GetConnectedClients().Count > 0;
        _executeButton.IsEnabled = connected;
        _executeButton.Opacity = connected ? 1 : 0.5;
        ToolTip.SetTip(
            _executeButton,
            connected
                ? "Execute (Ctrl+Enter)"
                : "Bridge offline — run Scripts/Orion Bridge.lua first");
    }

    // ─────────────────────────── console ───────────────────────────

    private void EnsureConsoleLoaded()
    {
        if (_consoleLoaded)
        {
            return;
        }

        _consoleLoaded = true;
        foreach (var entry in _bridge.GetLogSnapshot())
        {
            AppendOutput(entry.Message, entry.Level, quiet: true);
        }
        RebuildOutput();
    }

    private void ConsoleClear_Click(object? sender, RoutedEventArgs e)
    {
        _outputLines.Clear();
        _consoleText.Inlines?.Clear();
    }

    private void AppendOutput(string message, string level, bool quiet = false)
    {
        var foreground = level.ToLowerInvariant() switch
        {
            "warn" or "warning" => new SolidColorBrush(Color.Parse("#E5C07B")),
            "error" => new SolidColorBrush(Color.Parse("#E06C75")),
            "info" => new SolidColorBrush(Color.Parse("#61AFEF")),
            _ => new SolidColorBrush(Color.Parse("#C6D4EA"))
        };
        _outputLines.Add(new WaveOutputLine(
            DateTime.Now.ToString("HH:mm:ss"),
            message,
            foreground));

        if (_outputLines.Count > 500)
        {
            _outputLines.RemoveAt(0);
            RebuildOutput();
        }
        else if (!quiet)
        {
            AppendOutputLine(_outputLines[^1], _outputLines.Count > 1);
        }

        if (quiet)
        {
            return;
        }

        Dispatcher.UIThread.Post(
            () => _consoleScroll.Offset = new Vector(0, _consoleScroll.Extent.Height),
            DispatcherPriority.Background);
    }

    private void RebuildOutput()
    {
        _consoleText.Inlines?.Clear();
        for (var index = 0; index < _outputLines.Count; index++)
        {
            AppendOutputLine(_outputLines[index], index > 0);
        }
    }

    private void AppendOutputLine(WaveOutputLine line, bool prependLineBreak)
    {
        var inlines = _consoleText.Inlines;
        if (inlines is null)
        {
            return;
        }

        if (prependLineBreak)
        {
            inlines.Add(new LineBreak());
        }
        inlines.Add(new Run
        {
            Text = line.Timestamp + "  ",
            Foreground = new SolidColorBrush(Color.Parse("#4E6280"))
        });
        inlines.Add(new Run
        {
            Text = line.Message,
            Foreground = line.Foreground
        });
    }

    // ─────────────────────────── toast ───────────────────────────

    private async Task ShowToastAsync(string message)
    {
        _toastText.Text = message;
        var token = RestartFx();
        _toastPill.Opacity = 0;
        var slide = new TranslateTransform { Y = 8 };
        _toastPill.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(170),
                progress =>
                {
                    _toastPill.Opacity = progress;
                    slide.Y = 8 * (1 - progress);
                },
                CubicEaseOut,
                token);

            await Task.Delay(2100, token);

            await AnimateAsync(
                TimeSpan.FromMilliseconds(230),
                progress => _toastPill.Opacity = 1 - progress,
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        if (_fx is { IsCancellationRequested: false })
        {
            _toastPill.Opacity = 0;
            _toastPill.RenderTransform = null;
        }
    }

    // ─────────────────────────── animation helpers ───────────────────────────

    private CancellationToken RestartFx()
    {
        _fx?.Cancel();
        _fx?.Dispose();
        _fx = new CancellationTokenSource();
        return _fx.Token;
    }

    private static async Task AnimateAsync(
        TimeSpan duration,
        Action<double> update,
        Func<double, double> easing,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        while (stopwatch.Elapsed < duration)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var progress = Math.Clamp(
                stopwatch.Elapsed.TotalMilliseconds / duration.TotalMilliseconds,
                0d,
                1d);
            update(easing(progress));
            await Task.Delay(8, cancellationToken);
        }

        update(1d);
    }

    private static double CubicEaseOut(double progress) => 1d - Math.Pow(1d - progress, 3d);

    private static double Lerp(double start, double end, double progress) =>
        start + ((end - start) * progress);
}












