using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Data;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using System.Text.Json;

namespace OrbitAvalonia;

/// <summary>
/// Bunni.lol menu preserved as a native Orion shell. Execute, attachment and
/// console output route through the shared native Orion Bridge; the editor is
/// the shared Monaco surface, so workspace tabs round-trip with every other
/// Orion menu.
/// </summary>
public sealed partial class BunniWindow : Window
{
    private const int MaximumConsoleLines = 500;

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspaceState;
    private readonly Action<EditorWorkspaceState> _returnToOrbit;
    private readonly UnifiedBridgeServer _bridgeServer = UnifiedBridgeServer.Shared;
    private readonly List<(string Text, IBrush Brush)> _consoleLines = new();
    private static IBrush BrushFrom(string color) => new SolidColorBrush(Color.Parse(color));
    private readonly IBrush _consoleDefaultBrush = BrushFrom("#A8A6AC");
    private readonly IBrush _consoleErrorBrush = BrushFrom("#D99A9A");
    private readonly IBrush _consoleDimBrush = BrushFrom("#6E6C73");

    private NativeWebView _editorWebView = null!;
    private Button _executeButton = null!;
    private Button _attachButton = null!;
    private StackPanel _tabStripPanel = null!;
    private Button _addTabButton = null!;
    private Grid _editorView = null!;
    private Grid _scriptsView = null!;
    private ScrollViewer _settingsView = null!;
    private ScrollViewer _profileView = null!;
    private Border _consolePanel = null!;
    private Button _consoleBar = null!;
    private ScrollViewer _consoleScroll = null!;
    private StackPanel _consoleLogList = null!;
    private RotateTransform _consoleChevronRotate = null!;
    private TextBlock _scriptsCountText = null!;
    private TextBox _scriptsSearchBox = null!;
    private UniformGrid _scriptsHubPanel = null!;
    private TextBlock _scriptsHubStatus = null!;
    private ScrollViewer _scriptsHubScroll = null!;
    private Button _providerScriptBloxChip = null!;
    private Button _providerRscriptsChip = null!;
    private ComboBox _editorFontBox = null!;
    private NumericUpDown _editorFontSizeBox = null!;
    private readonly ScriptHubService _scriptHub = new();
    private ScriptHubProvider _currentScriptProvider = ScriptHubProvider.ScriptBlox;
    private int _scriptHubPage = 1;
    private bool _scriptHubHasMore;
    private bool _isLoadingScripts;
    private readonly List<ScriptHubCardModel> _scriptHubCards = new();
    private ToggleButton _topMostToggle = null!;
    private TextBlock _profileStatusText = null!;
    private StackPanel _profileClientsList = null!;
    private TextBlock _profileNoClientsText = null!;
    private Button _navEditorChip = null!;
    private Button _navScriptsChip = null!;
    private Button _navSettingsChip = null!;
    private Button _navProfileChip = null!;
    private Border _bunniChrome = null!;

    private bool _fontControlsReady;
    internal static readonly string[] EditorFontChoices =
    [
        "Consolas",
        "Cascadia Mono",
        "Courier New",
        "JetBrains Mono",
        "Fira Code",
        "Segoe UI"
    ];

    private static string EditorFontPath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "bunni-editor-font.txt");
    private static string EditorFontSizePath => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "bunni-editor-size.txt");

    private static (string Family, double Size) LoadEditorFontPreference()
    {
        try
        {
            var family = File.Exists(EditorFontPath) ? File.ReadAllText(EditorFontPath).Trim() : "Consolas";
            var size = 15.0;
            if (File.Exists(EditorFontSizePath) &&
                double.TryParse(File.ReadAllText(EditorFontSizePath).Trim(), out var parsed))
            {
                size = Math.Clamp(parsed, 8, 28);
            }

            return (string.IsNullOrWhiteSpace(family) ? "Consolas" : family, size);
        }
        catch (IOException)
        {
            return ("Consolas", 15.0);
        }
        catch (UnauthorizedAccessException)
        {
            return ("Consolas", 15.0);
        }
    }

    private static void SaveEditorFontPreference(string family, double size)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(EditorFontPath)!);
            File.WriteAllText(EditorFontPath, family);
            File.WriteAllText(EditorFontSizePath, size.ToString("0.#"));
        }
        catch (IOException)
        {
        }
        catch (UnauthorizedAccessException)
        {
        }
    }

    private bool _editorLoaded;
    private bool _editorReady;
    private bool _closingForOrbit;
    private bool _consoleOpen;
    private string _editorContent;

    // Avalonia's compiled XAML loader requires a public parameterless
    // constructor even though Orbit uses the address-aware overload below.
    public BunniWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal BunniWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrbit)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _workspaceState = initialWorkspace.CloneDetached();
        if (_workspaceState.Tabs.Count == 0)
        {
            var firstTab = new EditorTabState { Title = "untitled1", Extension = ".lua" };
            _workspaceState.Tabs.Add(firstTab);
            _workspaceState.ActiveTabId = firstTab.Id;
        }
        _editorContent = ActiveWorkspaceTab().Content;
        _returnToOrbit = returnToOrbit;

        AvaloniaXamlLoader.Load(this);
        Topmost = OrbitPreferences.TopMostEnabled;
        CanResize = true;

        _editorWebView = this.FindControl<NativeWebView>("EditorWebView")
            ?? throw new InvalidOperationException("The Bunni editor was not created.");
        _executeButton = this.FindControl<Button>("ExecuteButton")
            ?? throw new InvalidOperationException("The Bunni execute button was not created.");
        _attachButton = this.FindControl<Button>("AttachButton")
            ?? throw new InvalidOperationException("The Bunni attach button was not created.");
        _tabStripPanel = this.FindControl<StackPanel>("TabStripPanel")
            ?? throw new InvalidOperationException("The Bunni tab strip was not created.");
        _addTabButton = this.FindControl<Button>("AddTabButton")
            ?? throw new InvalidOperationException("The Bunni add-tab button was not created.");
        _editorView = this.FindControl<Grid>("EditorView")
            ?? throw new InvalidOperationException("The Bunni editor view was not created.");
        _scriptsView = this.FindControl<Grid>("ScriptsView")
            ?? throw new InvalidOperationException("The Bunni scripts view was not created.");
        _settingsView = this.FindControl<ScrollViewer>("SettingsView")
            ?? throw new InvalidOperationException("The Bunni settings view was not created.");
        _profileView = this.FindControl<ScrollViewer>("ProfileView")
            ?? throw new InvalidOperationException("The Bunni profile view was not created.");
        _consolePanel = this.FindControl<Border>("ConsolePanel")
            ?? throw new InvalidOperationException("The Bunni console panel was not created.");
        _consoleBar = this.FindControl<Button>("ConsoleBar")
            ?? throw new InvalidOperationException("The Bunni console bar was not created.");
        _consoleScroll = this.FindControl<ScrollViewer>("ConsoleScroll")
            ?? throw new InvalidOperationException("The Bunni console scroll was not created.");
        _consoleLogList = this.FindControl<StackPanel>("ConsoleLogList")
            ?? throw new InvalidOperationException("The Bunni console list was not created.");
        _consoleChevronRotate = (this.FindControl<Viewbox>("ConsoleChevron")?.RenderTransform as RotateTransform)
            ?? throw new InvalidOperationException("The Bunni console chevron was not created.");
        _scriptsSearchBox = this.FindControl<TextBox>("ScriptsSearchBox")
            ?? throw new InvalidOperationException("The Bunni scripts search box was not created.");
        _scriptsHubPanel = this.FindControl<UniformGrid>("ScriptsHubPanel")
            ?? throw new InvalidOperationException("The Bunni scripts hub panel was not created.");
        _scriptsHubStatus = this.FindControl<TextBlock>("ScriptsHubStatus")
            ?? throw new InvalidOperationException("The Bunni scripts status was not created.");
        _scriptsHubScroll = this.FindControl<ScrollViewer>("ScriptsHubScroll")
            ?? throw new InvalidOperationException("The Bunni scripts scroll was not created.");
        _scriptsHubScroll.SizeChanged += (_, _) => UpdateScriptHubColumns();
        _providerScriptBloxChip = this.FindControl<Button>("ProviderScriptBloxChip")
            ?? throw new InvalidOperationException("The Bunni ScriptBlox chip was not created.");
        _providerRscriptsChip = this.FindControl<Button>("ProviderRscriptsChip")
            ?? throw new InvalidOperationException("The Bunni RScripts chip was not created.");
        _editorFontBox = this.FindControl<ComboBox>("EditorFontBox")
            ?? throw new InvalidOperationException("The Bunni font box was not created.");
        _editorFontSizeBox = this.FindControl<NumericUpDown>("EditorFontSizeBox")
            ?? throw new InvalidOperationException("The Bunni font size box was not created.");
        _scriptsCountText = this.FindControl<TextBlock>("ScriptsCountText")
            ?? throw new InvalidOperationException("The Bunni scripts count was not created.");
        _topMostToggle = this.FindControl<ToggleButton>("TopMostToggle")
            ?? throw new InvalidOperationException("The Bunni topmost toggle was not created.");
        _profileStatusText = this.FindControl<TextBlock>("ProfileStatusText")
            ?? throw new InvalidOperationException("The Bunni profile status was not created.");
        _profileClientsList = this.FindControl<StackPanel>("ProfileClientsList")
            ?? throw new InvalidOperationException("The Bunni clients list was not created.");
        _profileNoClientsText = this.FindControl<TextBlock>("ProfileNoClientsText")
            ?? throw new InvalidOperationException("The Bunni empty clients text was not created.");
        _navEditorChip = this.FindControl<Button>("NavEditorChip")
            ?? throw new InvalidOperationException("The Bunni editor chip was not created.");
        _navScriptsChip = this.FindControl<Button>("NavScriptsChip")
            ?? throw new InvalidOperationException("The Bunni scripts chip was not created.");
        _navSettingsChip = this.FindControl<Button>("NavSettingsChip")
            ?? throw new InvalidOperationException("The Bunni settings chip was not created.");
        _navProfileChip = this.FindControl<Button>("NavProfileChip")
            ?? throw new InvalidOperationException("The Bunni profile chip was not created.");
        _bunniChrome = this.FindControl<Border>("BunniChrome")
            ?? throw new InvalidOperationException("The Bunni chrome was not created.");

        _editorWebView.WebMessageReceived += (_, args) => HandleEditorMessage(args.Body);
        _bridgeServer.ConnectionChanged += BridgeConnectionChanged;
        _bridgeServer.ClientsChanged += BridgeClientsChanged;
        _bridgeServer.LogReceived += BridgeLogReceived;

        _topMostToggle.IsChecked = OrbitPreferences.TopMostEnabled;
        _editorFontBox.ItemsSource = EditorFontChoices;
        var (savedFamily, savedSize) = LoadEditorFontPreference();
        _editorFontBox.SelectedItem = EditorFontChoices.Contains(savedFamily)
            ? savedFamily
            : EditorFontChoices[0];
        _editorFontSizeBox.Value = (decimal)savedSize;
        _fontControlsReady = true;

        RebuildTabs();
        RefreshBridgeState();
        foreach (var entry in _bridgeServer.GetLogSnapshot())
        {
            RecordConsoleLine($"[{entry.TimestampUtc.ToLocalTime():HH:mm:ss}] {entry.Message}", _consoleDefaultBrush);
        }

        Opened += BunniWindow_Opened;
        Closed += BunniWindow_Closed;
        PropertyChanged += BunniWindow_PropertyChanged;
    }

    private void BunniWindow_Opened(object? sender, EventArgs e)
    {
        if (_editorLoaded)
        {
            return;
        }

        _editorLoaded = true;
        var editorUri = new UriBuilder(_monacoAddress)
        {
            Query = "theme=bunni&bg=%23151517"
        };
        _editorWebView.Source = editorUri.Uri;
    }

    private void BunniWindow_Closed(object? sender, EventArgs e)
    {
        _bridgeServer.ConnectionChanged -= BridgeConnectionChanged;
        _bridgeServer.ClientsChanged -= BridgeClientsChanged;
        _bridgeServer.LogReceived -= BridgeLogReceived;
        _scriptHub.Dispose();

        if (!_closingForOrbit)
        {
            ReturnWorkspaceToOrbit();
        }
    }

    private void BunniWindow_PropertyChanged(object? sender, AvaloniaPropertyChangedEventArgs e)
    {
        if (e.Property == WindowStateProperty)
        {
            var maximized = WindowState == WindowState.Maximized;
            _bunniChrome.CornerRadius = maximized ? new CornerRadius(0) : new CornerRadius(10);
        }
    }

    internal void CloseForOrbit()
    {
        _closingForOrbit = true;
        Close();
    }

    // ============================ Window chrome ============================

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (e.GetCurrentPoint(this).Properties.IsLeftButtonPressed && WindowState != WindowState.Maximized)
        {
            BeginMoveDrag(e);
        }
    }

    private void Minimize_Click(object? sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Maximize_Click(object? sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => ReturnWorkspaceToOrbit();

    // ============================ Navigation ============================

    private void NavEditor_Click(object? sender, RoutedEventArgs e) => SwitchView(BunniView.Editor);
    private void NavScripts_Click(object? sender, RoutedEventArgs e)
    {
        SwitchView(BunniView.Scripts);
        if (_scriptHubCards.Count == 0)
        {
            _ = RunScriptSearchAsync(reset: true);
        }
    }
    private void NavSettings_Click(object? sender, RoutedEventArgs e) => SwitchView(BunniView.Settings);
    private void NavProfile_Click(object? sender, RoutedEventArgs e)
    {
        RefreshProfile();
        SwitchView(BunniView.Profile);
    }

    private enum BunniView
    {
        Editor,
        Scripts,
        Settings,
        Profile
    }

    private void SwitchView(BunniView view)
    {
        // NativeWebView is a child HWND: keep it out of the airspace of the
        // Avalonia-only views.
        _editorWebView.IsVisible = view == BunniView.Editor;

        FadeView(_editorView, view == BunniView.Editor);
        FadeView(_scriptsView, view == BunniView.Scripts);
        FadeView(_settingsView, view == BunniView.Settings);
        FadeView(_profileView, view == BunniView.Profile);

        SetChipActive(_navEditorChip, view == BunniView.Editor);
        SetChipActive(_navScriptsChip, view == BunniView.Scripts);
        SetChipActive(_navSettingsChip, view == BunniView.Settings);
        SetChipActive(_navProfileChip, view == BunniView.Profile);
    }

    private void FadeView(Control view, bool visible)
    {
        view.IsVisible = visible;
        if (visible)
        {
            view.Opacity = 0;
            Dispatcher.UIThread.Post(() => view.Opacity = 1);
        }
        else
        {
            view.Opacity = 0;
        }
    }

    private static async Task AnimateValueAsync(
        TimeSpan duration,
        Action<double> apply,
        double from,
        double to)
    {
        var stopwatch = System.Diagnostics.Stopwatch.StartNew();
        while (stopwatch.Elapsed < duration)
        {
            var progress = stopwatch.Elapsed.TotalMilliseconds / duration.TotalMilliseconds;
            var eased = 1 - Math.Pow(1 - progress, 3);
            apply(from + (to - from) * eased);
            await Task.Delay(16);
        }

        apply(to);
    }

    private static void SetChipActive(Button chip, bool active)
    {
        if (active)
        {
            chip.Classes.Add("active");
        }
        else
        {
            chip.Classes.Remove("active");
        }
    }

    // ============================ Tabs ============================

    private EditorTabState ActiveWorkspaceTab()
    {
        var activeTab = _workspaceState.Tabs.FirstOrDefault(tab => tab.Id == _workspaceState.ActiveTabId)
            ?? _workspaceState.Tabs[0];
        _workspaceState.ActiveTabId = activeTab.Id;
        return activeTab;
    }

    private static string DisplayName(EditorTabState tab) =>
        string.IsNullOrWhiteSpace(Path.GetExtension(tab.Title)) ? tab.Title + tab.Extension : tab.Title;

    private void RebuildTabs()
    {
        _tabStripPanel.Children.Clear();
        foreach (var tab in _workspaceState.Tabs)
        {
            _tabStripPanel.Children.Add(CreateTabButton(tab));
        }

    }

    private Button CreateTabButton(EditorTabState tab)
    {
        var button = new Button { Classes = { "bunni-tab" }, Tag = tab.Id };
        if (tab.Id == _workspaceState.ActiveTabId)
        {
            button.Classes.Add("active");
        }

        var isActive = tab.Id == _workspaceState.ActiveTabId;
        var iconBrush = isActive ? BrushFrom("#E3BA7C") : BrushFrom("#A4A2A7");
        var icon = new Viewbox
        {
            Width = 17,
            Height = 17,
            Child = new Canvas
            {
                Width = 24,
                Height = 24,
                Children =
                {
                    new Avalonia.Controls.Shapes.Path
                    {
                        Data = StreamGeometry.Parse("M4 6L20 6M4 12L20 12M4 18L13 18"),
                        Stroke = iconBrush,
                        StrokeThickness = 2.3,
                        StrokeLineCap = PenLineCap.Round
                    }
                }
            }
        };

        var title = new TextBlock
        {
            Text = DisplayName(tab),
            FontSize = 16,
            FontWeight = FontWeight.SemiBold,
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis
        };

        var closeIcon = new Viewbox
        {
            Width = 11,
            Height = 11,
            Child = new Canvas
            {
                Width = 24,
                Height = 24,
                Children =
                {
                    new Avalonia.Controls.Shapes.Path
                    {
                        Data = StreamGeometry.Parse("M5 5L19 19M19 5L5 19"),
                        Stroke = BrushFrom("#6D6B72"),
                        StrokeThickness = 2.4,
                        StrokeLineCap = PenLineCap.Round
                    }
                }
            }
        };

        var closeButton = new Button { Classes = { "bunni-tab-close" }, Content = closeIcon };
        closeButton.Click += (_, _) => CloseTab(tab);

        var grid = new Grid
        {
            ColumnDefinitions = new ColumnDefinitions("Auto,*,Auto"),
            ColumnSpacing = 12
        };
        Grid.SetColumn(icon, 0);
        Grid.SetColumn(title, 1);
        Grid.SetColumn(closeButton, 2);
        grid.Children.Add(icon);
        grid.Children.Add(title);
        grid.Children.Add(closeButton);
        button.Content = grid;
        button.Click += (_, _) => SwitchTab(tab);
        return button;
    }

    private void SwitchTab(EditorTabState tab)
    {
        if (_workspaceState.ActiveTabId == tab.Id)
        {
            return;
        }

        ActiveWorkspaceTab().Content = _editorContent;
        _workspaceState.ActiveTabId = tab.Id;
        _editorContent = tab.Content;
        RebuildTabs();
        SetEditorContent(_editorContent);
    }

    private void CloseTab(EditorTabState tab)
    {
        var wasActive = _workspaceState.ActiveTabId == tab.Id;
        _workspaceState.Tabs.Remove(tab);
        if (_workspaceState.Tabs.Count == 0)
        {
            var fresh = new EditorTabState { Title = NextUntitledTitle(), Extension = ".lua" };
            _workspaceState.Tabs.Add(fresh);
            _workspaceState.ActiveTabId = fresh.Id;
        }
        else if (wasActive)
        {
            _workspaceState.ActiveTabId = _workspaceState.Tabs[^1].Id;
        }

        if (wasActive)
        {
            _editorContent = ActiveWorkspaceTab().Content;
            SetEditorContent(_editorContent);
        }

        RebuildTabs();
    }

    private void AddTab_Click(object? sender, RoutedEventArgs e)
    {
        ActiveWorkspaceTab().Content = _editorContent;
        var tab = new EditorTabState { Title = NextUntitledTitle(), Extension = ".lua" };
        _workspaceState.Tabs.Add(tab);
        _workspaceState.ActiveTabId = tab.Id;
        _editorContent = string.Empty;
        RebuildTabs();
        SetEditorContent(_editorContent);
    }

    private string NextUntitledTitle()
    {
        var highest = 0;
        foreach (var tab in _workspaceState.Tabs)
        {
            var title = tab.Title;
            if (title.StartsWith("untitled", StringComparison.OrdinalIgnoreCase) &&
                int.TryParse(title["untitled".Length..], out var number))
            {
                highest = Math.Max(highest, number);
            }
        }

        return $"untitled{highest + 1}";
    }

    // ============================ Toolbar ============================

    private void Execute_Click(object? sender, RoutedEventArgs e)
    {
        if (!HasLiveBridgeConnection)
        {
            return;
        }

        if (_editorReady)
        {
            try
            {
                _editorWebView.InvokeScript("window.orbitRequestExecute && window.orbitRequestExecute();");
                return;
            }
            catch (InvalidOperationException)
            {
                _editorReady = false;
            }
        }

        _bridgeServer.EnqueueExecute(_editorContent);
    }

    private void Clear_Click(object? sender, RoutedEventArgs e) => SetEditorContent(string.Empty);

    private async void Open_Click(object? sender, RoutedEventArgs e)
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            AllowMultiple = false,
            Title = "Open script",
            FileTypeFilter =
            [
                new FilePickerFileType("Script files")
                {
                    Patterns = ["*.lua", "*.luau", "*.txt"]
                }
            ]
        });

        if (files.Count == 0)
        {
            return;
        }

        try
        {
            var filePath = files[0].Path.LocalPath;
            var content = await File.ReadAllTextAsync(filePath);
            var activeTab = ActiveWorkspaceTab();
            activeTab.Title = Path.GetFileNameWithoutExtension(filePath);
            activeTab.Extension = Path.GetExtension(filePath) is { Length: > 0 } extension
                ? extension
                : ".lua";
            SetEditorContent(content);
            RebuildTabs();
        }
        catch (IOException)
        {
            // This shell keeps file errors non-modal.
        }
    }

    private async void Save_Click(object? sender, RoutedEventArgs e)
    {
        var activeTab = ActiveWorkspaceTab();
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            SuggestedFileName = activeTab.Title + activeTab.Extension,
            FileTypeChoices =
            [
                new FilePickerFileType("Lua script") { Patterns = ["*.lua"] },
                new FilePickerFileType("Text file") { Patterns = ["*.txt"] }
            ]
        });

        if (file is null)
        {
            return;
        }

        try
        {
            await File.WriteAllTextAsync(file.Path.LocalPath, _editorContent);
        }
        catch (IOException)
        {
            // This shell keeps file errors non-modal.
        }
    }

    private void Attach_Click(object? sender, RoutedEventArgs e)
    {
        if (HasLiveBridgeConnection)
        {
            var clients = _bridgeServer.GetConnectedClients();
            RecordConsoleLine(
                $"[{DateTime.Now:HH:mm:ss}] Attached to {clients.Count} client(s): " +
                string.Join(", ", clients.Select(client => client.Username)),
                _consoleDefaultBrush);
        }
        else
        {
            RecordConsoleLine(
                $"[{DateTime.Now:HH:mm:ss}] Not attached — run Scripts/Orion Bridge.lua inside the game.",
                _consoleDimBrush);
        }

        ShowConsole();
    }

    // ============================ Console ============================

    private void ConsoleToggle_Click(object? sender, RoutedEventArgs e)
    {
        if (_consoleOpen)
        {
            HideConsole();
        }
        else
        {
            ShowConsole();
        }
    }

    private bool _consoleResizing;
    private double _consoleResizeStartY;
    private double _consoleResizeStartHeight;

    private void ConsoleResize_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (!_consolePanel.IsVisible)
        {
            return;
        }

        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed)
        {
            return;
        }

        _consoleResizing = true;
        _consoleResizeStartY = point.Position.Y;
        _consoleResizeStartHeight = _consolePanel.Height;
        // Live dragging must not fight the expand/collapse transition.
        _consolePanel.Transitions.Clear();
        e.Pointer.Capture(sender as IInputElement);
        e.Handled = true;
    }

    private void ConsoleResize_PointerMoved(object? sender, PointerEventArgs e)
    {
        if (!_consoleResizing)
        {
            return;
        }

        var y = e.GetCurrentPoint(this).Position.Y;
        _consolePanel.Height = Math.Clamp(
            _consoleResizeStartHeight - (y - _consoleResizeStartY),
            100,
            460);
    }

    private void ConsoleResize_PointerReleased(object? sender, PointerReleasedEventArgs e)
    {
        if (!_consoleResizing)
        {
            return;
        }

        _consoleResizing = false;
        _consolePreferredHeight = _consolePanel.Height;
        _consolePanel.Transitions.Add(new Avalonia.Animation.DoubleTransition
        {
            Property = Avalonia.Layout.Layoutable.HeightProperty,
            Duration = TimeSpan.FromMilliseconds(240),
            Easing = new Avalonia.Animation.Easings.CubicEaseOut()
        });
        e.Pointer.Capture(null);
        e.Handled = true;
    }

    private void ClearConsole_Click(object? sender, RoutedEventArgs e)
    {
        _consoleLines.Clear();
        _consoleLogList.Children.Clear();
    }

    private const double ConsoleDefaultHeight = 216;
    private double _consolePreferredHeight = ConsoleDefaultHeight;

    private void ShowConsole()
    {
        _consoleOpen = true;
        _consolePanel.IsVisible = true;
        RebuildConsoleLines();
        // The Height DoubleTransition turns these two assignments into a
        // smooth expand from zero.
        _consolePanel.Height = 0;
        Dispatcher.UIThread.Post(() => _consolePanel.Height = _consolePreferredHeight);
        _ = AnimateValueAsync(
            TimeSpan.FromMilliseconds(240),
            value => _consoleChevronRotate.Angle = value,
            _consoleChevronRotate.Angle,
            180);
    }

    private void HideConsole()
    {
        _consoleOpen = false;
        if (_consolePanel.Height > 0)
        {
            _consolePreferredHeight = _consolePanel.Height;
        }

        _consolePanel.Height = 0;
        _ = AnimateValueAsync(
            TimeSpan.FromMilliseconds(240),
            value => _consoleChevronRotate.Angle = value,
            _consoleChevronRotate.Angle,
            0);
        _ = Task.Run(async () =>
        {
            await Task.Delay(280);
            Dispatcher.UIThread.Post(() =>
            {
                if (!_consoleOpen)
                {
                    _consolePanel.IsVisible = false;
                }
            });
        });
    }

    private void BridgeLogReceived(string level, string message)
    {
        var brush = string.Equals(level, "error", StringComparison.OrdinalIgnoreCase)
            ? _consoleErrorBrush
            : _consoleDefaultBrush;
        Dispatcher.UIThread.Post(() =>
        {
            RecordConsoleLine($"[{DateTime.Now:HH:mm:ss}] {message}", brush);
            if (_consoleOpen)
            {
                RebuildConsoleLines();
                _consoleScroll.ScrollToEnd();
            }
        });
    }

    private void RecordConsoleLine(string text, IBrush brush)
    {
        _consoleLines.Add((text, brush));
        if (_consoleLines.Count > MaximumConsoleLines)
        {
            _consoleLines.RemoveRange(0, _consoleLines.Count - MaximumConsoleLines);
        }
    }

    private void RebuildConsoleLines()
    {
        _consoleLogList.Children.Clear();
        foreach (var (text, brush) in _consoleLines)
        {
            _consoleLogList.Children.Add(new TextBlock
            {
                Text = text,
                FontSize = 12.5,
                FontFamily = new FontFamily("Consolas"),
                Foreground = brush,
                TextWrapping = TextWrapping.NoWrap
            });
        }
    }

    // ============================ Bridge state ============================

    private void BridgeConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(() => RefreshBridgeState());

    private void BridgeClientsChanged() =>
        Dispatcher.UIThread.Post(() => RefreshBridgeState());

    private bool HasLiveBridgeConnection =>
        _bridgeServer.IsConnected && _bridgeServer.GetConnectedClients().Count > 0;

    private void RefreshBridgeState()
    {
        var attached = HasLiveBridgeConnection;
        if (attached)
        {
            _executeButton.Classes.Remove("dim");
        }
        else
        {
            _executeButton.Classes.Add("dim");
        }
        if (attached)
        {
            _attachButton.Classes.Add("attached");
        }
        else
        {
            _attachButton.Classes.Remove("attached");
        }

        ToolTip.SetTip(
            _executeButton,
            attached ? "Execute" : "Execute (run Scripts/Orion Bridge.lua first)");
        ToolTip.SetTip(
            _attachButton,
            attached
                ? $"Attached to {_bridgeServer.GetConnectedClients().Count} client(s)"
                : "Not attached — run Scripts/Orion Bridge.lua first");

        _profileStatusText.Text = _bridgeServer.IsConnected
            ? (attached
                ? $"Bridge connected — {_bridgeServer.GetConnectedClients().Count} client(s)"
                : "Bridge connected — no clients attached")
            : "Bridge offline — run Scripts/Orion Bridge.lua";
    }

    // ============================ Scripts view ============================

    // ============================ Script hub (Scripts view) ============================

    private void ProviderScriptBlox_Click(object? sender, RoutedEventArgs e) =>
        SwitchScriptProvider(ScriptHubProvider.ScriptBlox);

    private void ProviderRscripts_Click(object? sender, RoutedEventArgs e) =>
        SwitchScriptProvider(ScriptHubProvider.Rscripts);

    private void SwitchScriptProvider(ScriptHubProvider provider)
    {
        if (_currentScriptProvider == provider)
        {
            return;
        }

        _currentScriptProvider = provider;
        SetChipActive(_providerScriptBloxChip, provider == ScriptHubProvider.ScriptBlox);
        SetChipActive(_providerRscriptsChip, provider == ScriptHubProvider.Rscripts);
        _ = RunScriptSearchAsync(reset: true);
    }

    private void SearchScripts_Click(object? sender, RoutedEventArgs e) =>
        _ = RunScriptSearchAsync(reset: true);

    private void ScriptsHubScroll_ScrollChanged(object? sender, ScrollChangedEventArgs e)
    {
        if (!_scriptHubHasMore || _isLoadingScripts)
        {
            return;
        }

        var viewer = (ScrollViewer)sender!;
        if (viewer.Extent.Height <= 0)
        {
            return;
        }

        // Keep fetching while the user reaches the tail of the list (or the
        // list does not yet fill the viewport).
        if (viewer.Offset.Y + viewer.Viewport.Height >= viewer.Extent.Height - 240)
        {
            _ = RunScriptSearchAsync(reset: false);
        }
    }

    private void ScriptsSearch_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            _ = RunScriptSearchAsync(reset: true);
        }
    }

    private async Task RunScriptSearchAsync(bool reset)
    {
        if (_isLoadingScripts)
        {
            return;
        }

        _isLoadingScripts = true;
        if (reset)
        {
            _scriptHubPage = 1;
            _scriptHubCards.Clear();
            _scriptsHubPanel.Children.Clear();
        }
        else
        {
            _scriptHubPage++;
        }

        var query = _scriptsSearchBox.Text ?? string.Empty;
        _scriptsHubStatus.Text = string.IsNullOrWhiteSpace(query)
            ? $"Loading latest scripts from {ProviderName(_currentScriptProvider)}..."
            : $"Searching {ProviderName(_currentScriptProvider)} for \"{query.Trim()}\"...";
        _scriptsHubStatus.IsVisible = true;

        try
        {
            var result = await _scriptHub.FetchAsync(_currentScriptProvider, query, _scriptHubPage, CancellationToken.None);
            var fresh = result.Cards.Where(card =>
                !_scriptHubCards.Any(existing => existing.Key == card.Key)).ToList();
            _scriptHubCards.AddRange(fresh);

            foreach (var card in fresh)
            {
                _scriptsHubPanel.Children.Add(CreateScriptCard(card));
            }

            await _scriptHub.LoadThumbnailsAsync(fresh, CancellationToken.None);
            UpdateScriptHubColumns();

            _scriptHubHasMore = result.HasMore && fresh.Count > 0;
            _scriptsHubStatus.IsVisible = _scriptHubCards.Count == 0;
            _scriptsHubStatus.Text = _scriptHubCards.Count == 0
                ? "No scripts found. Try another query."
                : string.Empty;
            _scriptsCountText.Text = _scriptHubCards.Count == 0
                ? "Search community scripts"
                : $"{_scriptHubCards.Count} script(s) from {ProviderName(_currentScriptProvider)}";
        }
        catch (Exception searchException) when (
            searchException is IOException ||
            searchException is InvalidOperationException ||
            searchException is InvalidDataException ||
            searchException is System.Net.Http.HttpRequestException ||
            searchException is TaskCanceledException ||
            searchException is UriFormatException)
        {
            _scriptHubHasMore = false;
            _scriptsHubStatus.IsVisible = true;
            _scriptsHubStatus.Text = _scriptHubCards.Count == 0
                ? $"Could not reach {ProviderName(_currentScriptProvider)}. Check the connection and try again."
                : string.Empty;
        }
        finally
        {
            _isLoadingScripts = false;
        }
    }

    private void UpdateScriptHubColumns()
    {
        var width = _scriptsHubScroll.Viewport.Width;
        if (width <= 0)
        {
            width = _scriptsHubScroll.Bounds.Width;
        }

        var columns = Math.Max(2, (int)(width / 226));
        if (_scriptsHubPanel.Columns != columns)
        {
            _scriptsHubPanel.Columns = columns;
        }
    }

    private static string ProviderName(ScriptHubProvider provider) => provider switch
    {
        ScriptHubProvider.Rscripts => "RScripts",
        ScriptHubProvider.ScriptBlox => "ScriptBlox",
        _ => provider.ToString()
    };

    private Button CreateScriptCard(ScriptHubCardModel card)
    {
        var thumbnail = new Image
        {
            Height = 100,
            Stretch = Stretch.UniformToFill,
            HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Stretch
        };
        // The card model raises PropertyChanged for Thumbnail once loaded;
        // bind against it explicitly (the button has no DataContext flow here).
        thumbnail.Bind(Image.SourceProperty, new Binding("Thumbnail") { Source = card });
        var thumbnailClip = new Border
        {
            Height = 100,
            CornerRadius = new CornerRadius(9, 9, 0, 0),
            ClipToBounds = true,
            Child = thumbnail,
            Background = BrushFrom("#232327")
        };

        var title = new TextBlock
        {
            Text = card.Title,
            FontSize = 13,
            FontWeight = FontWeight.SemiBold,
            Margin = new Thickness(10, 8, 10, 0),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap
        };
        var subtitle = new TextBlock
        {
            Text = card.Subtitle,
            FontSize = 11.5,
            Foreground = _consoleDimBrush,
            Margin = new Thickness(10, 2, 10, 0),
            TextTrimming = TextTrimming.CharacterEllipsis,
            TextWrapping = TextWrapping.NoWrap
        };
        var meta = new TextBlock
        {
            Text = card.Views > 0 ? $"{FormatCount(card.Views)} views" : string.Empty,
            FontSize = 11,
            Foreground = _consoleDimBrush,
            Margin = new Thickness(10, 2, 10, 9),
            TextTrimming = TextTrimming.CharacterEllipsis
        };

        var content = new StackPanel { Children = { thumbnailClip, title, subtitle, meta } };
        var cardButton = new Button
        {
            Classes = { "bunni-script-card" },
            Content = content,
            Tag = card,
            HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Stretch,
            Margin = new Thickness(0, 0, 10, 10)
        };
        ToolTip.SetTip(cardButton, card.Description);
        cardButton.Click += (_, _) => OpenScriptInEditor(card);
        return cardButton;
    }

    private static string FormatCount(long count) => count switch
    {
        >= 1_000_000 => $"{count / 1_000_000.0:0.#}M",
        >= 1_000 => $"{count / 1_000.0:0.#}K",
        _ => count.ToString("0")
    };

    private void OpenScriptInEditor(ScriptHubCardModel card)
    {
        var body = card.ScriptBody;
        if (string.IsNullOrWhiteSpace(body))
        {
            body = $"-- {card.Title}\n-- {card.Description}\n-- Open for the full script: {card.ExternalUrl}\n";
        }

        ActiveWorkspaceTab().Content = _editorContent;
        var tab = new EditorTabState
        {
            Title = SanitizeTabTitle(card.Title),
            Extension = ".lua",
            Content = body
        };
        _workspaceState.Tabs.Add(tab);
        _workspaceState.ActiveTabId = tab.Id;
        _editorContent = body;
        RebuildTabs();
        SwitchView(BunniView.Editor);
        SetEditorContent(body);
    }

    private static string SanitizeTabTitle(string title)
    {
        var invalid = Path.GetInvalidFileNameChars();
        var clean = new string(title.Where(character => !invalid.Contains(character)).ToArray()).Trim();
        if (clean.Length > 60)
        {
            clean = clean[..60].Trim();
        }

        return string.IsNullOrWhiteSpace(clean) ? "script" : clean;
    }

    // ============================ Settings view ============================

    private void TopMostToggle_Click(object? sender, RoutedEventArgs e)
    {
        var enabled = _topMostToggle.IsChecked == true;
        Topmost = enabled;
        OrbitPreferences.SetTopMost(enabled);
    }

    private void EditorFont_SelectionChanged(object? sender, SelectionChangedEventArgs e) =>
        ApplyEditorFontPreference(save: true);

    private void EditorFontSize_ValueChanged(object? sender, NumericUpDownValueChangedEventArgs e) =>
        ApplyEditorFontPreference(save: true);

    private void ApplyEditorFontPreference(bool save)
    {
        if (!_fontControlsReady)
        {
            return;
        }

        var family = _editorFontBox.SelectedItem as string ?? "Consolas";
        var size = _editorFontSizeBox.Value is decimal chosen ? (double)chosen : 15.0;
        size = Math.Clamp(size, 8, 28);
        if (save)
        {
            SaveEditorFontPreference(family, size);
        }

        if (!_editorReady)
        {
            return;
        }

        try
        {
            var familyJson = JsonSerializer.Serialize(family);
            _editorWebView.InvokeScript(
                $"window.orbitSetEditorFont && window.orbitSetEditorFont({familyJson}, {size.ToString("0.#")});");
        }
        catch (InvalidOperationException)
        {
            // Monaco may still be loading; the preference applies on ready.
        }
    }

    private void ReturnToOrion_Click(object? sender, RoutedEventArgs e) => ReturnWorkspaceToOrbit();

    // ============================ Profile view ============================

    private void RefreshProfile()
    {
        RefreshBridgeState();
        _profileClientsList.Children.Clear();
        var clients = _bridgeServer.GetConnectedClients();
        _profileNoClientsText.IsVisible = clients.Count == 0;
        foreach (var client in clients)
        {
            _profileClientsList.Children.Add(new TextBlock
            {
                Margin = new Thickness(10, 6, 10, 6),
                FontSize = 13.5,
                Foreground = _consoleDefaultBrush,
                Text = $"{client.Username}  ({client.Identifier})"
            });
        }
    }

    // ============================ Editor plumbing ============================

    private void SetEditorContent(string content)
    {
        _editorContent = content;
        ActiveWorkspaceTab().Content = content;
        var serialized = JsonSerializer.Serialize(content);
        try
        {
            _editorWebView.InvokeScript($"window.orbitSetContent && window.orbitSetContent({serialized}, 'lua');");
        }
        catch (InvalidOperationException)
        {
            // Monaco may still be loading; the action can safely be retried.
        }
    }

    private void HandleEditorMessage(string? message)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            return;
        }

        try
        {
            using var payload = JsonDocument.Parse(message);
            var root = payload.RootElement;
            if (!root.TryGetProperty("type", out var type))
            {
                return;
            }

            if (type.GetString() == "ready")
            {
                _editorReady = true;
                SetEditorContent(_editorContent);
                ApplyEditorFontPreference(save: false);
            }
            else if (type.GetString() == "contentChanged" &&
                root.TryGetProperty("content", out var content))
            {
                _editorContent = content.GetString() ?? string.Empty;
                ActiveWorkspaceTab().Content = _editorContent;
            }
            else if (type.GetString() == "contentChangedDelta" &&
                root.TryGetProperty("changes", out var changes) &&
                EditorContentDelta.TryApply(changes, _editorContent, out var updatedContent))
            {
                _editorContent = updatedContent;
                ActiveWorkspaceTab().Content = _editorContent;
            }
            else if (type.GetString() == "executeRequested" &&
                root.TryGetProperty("content", out var executeContent))
            {
                _editorContent = executeContent.GetString() ?? string.Empty;
                ActiveWorkspaceTab().Content = _editorContent;
                if (HasLiveBridgeConnection)
                {
                    _bridgeServer.EnqueueExecute(_editorContent);
                }
            }
        }
        catch (JsonException)
        {
            // Ignore unrelated browser messages.
        }
    }

    private void ReturnWorkspaceToOrbit()
    {
        ActiveWorkspaceTab().Content = _editorContent;
        _returnToOrbit(_workspaceState.CloneDetached());
    }

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var firstTab = new EditorTabState
        {
            Title = "untitled1",
            Extension = ".lua",
            Content = "-- wyv.gg and peyton are my GOATs!\nprint('peytondev on youtube!')\n"
        };
        return new EditorWorkspaceState
        {
            Tabs = [firstTab],
            ActiveTabId = firstTab.Id
        };
    }
}
