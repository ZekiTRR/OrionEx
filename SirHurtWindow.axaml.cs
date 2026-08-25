using Avalonia;
using Avalonia.Animation;
using Avalonia.Controls;
using Avalonia.Controls.Documents;
using Avalonia.Controls.Shapes;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.Templates;
using AvaloniaPath = Avalonia.Controls.Shapes.Path;
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

public sealed partial class SirHurtWindow : Window
{

    private sealed record SirHurtScriptItem(string Name, string Path);

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly SirHurtOptions _options;
    private List<SirHurtScriptItem> _workspaceScripts = [];
    private readonly HashSet<string> _selectedClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _knownClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);

    private readonly Border _chrome;
    private readonly NativeWebView _editor;
    private readonly StackPanel _tabStrip;
    private readonly Panel _confirmOverlay;
    private readonly Border _confirmDialog;
    private readonly TextBlock _confirmMessage;
    private readonly Button _confirmAccept;
    private readonly Border _toastPill;
    private readonly TextBlock _toastText;
    private readonly TextBlock _statusText;
    private readonly Ellipse _statusDot;
    private readonly Grid _editorMode;
    private readonly Grid _consoleMode;
    private readonly Grid _settingsMode;
    private readonly StackPanel _scriptsPanel;
    private readonly StackPanel _creditsPanel;
    private readonly TextBox _scriptSearch;
    private readonly ListBox _scriptList;
    private readonly TextBlock _scriptsEmpty;
    private readonly StackPanel _settingsList;
    private readonly StackPanel _consoleOutput;
    private readonly ScrollViewer _consoleScroll;
    private readonly ScrollViewer _tabScroll;
    private bool _consoleOpen;
    private bool _consoleReplayed;
    private readonly Button _railCode;
    private readonly Button _railConsole;
    private readonly Button _railSettings;
    private readonly Button _topMostToggle;
    private readonly Button _closeTabConfirmToggle;

    private EditorTabState _activeTab;
    private EditorTabState? _pendingCloseTab;
    private bool _editorReady;
    private bool _editorSourceAssigned;
    private bool _editorDisposed;
    private bool _settingsOpen;
    private bool _suppressToggleEvents;
    private bool _closingForOrion;
    private bool _returnRequested;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;
    private CancellationTokenSource? _fx;

    public SirHurtWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal SirHurtWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
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
        _options = SirHurtOptionsStore.Load();

        AvaloniaXamlLoader.Load(this);

        _chrome = Required<Border>("ShChrome");
        _editor = Required<NativeWebView>("EditorWebView");
        _tabStrip = Required<StackPanel>("TabStrip");
        _confirmOverlay = Required<Panel>("ConfirmOverlay");
        _confirmDialog = Required<Border>("ConfirmDialog");
        _confirmMessage = Required<TextBlock>("ConfirmMessage");
        _confirmAccept = Required<Button>("ConfirmAccept");
        _toastPill = Required<Border>("ToastPill");
        _toastText = Required<TextBlock>("ToastText");
        _statusText = Required<TextBlock>("StatusText");
        _statusDot = Required<Ellipse>("StatusDot");
        _editorMode = Required<Grid>("EditorMode");
        _consoleMode = Required<Grid>("ConsoleMode");
        _settingsMode = Required<Grid>("SettingsMode");
        _scriptsPanel = Required<StackPanel>("ScriptsPanel");
        _creditsPanel = Required<StackPanel>("CreditsPanel");
        _scriptSearch = Required<TextBox>("ScriptSearch");
        _scriptList = Required<ListBox>("ScriptList");
        _scriptsEmpty = Required<TextBlock>("ScriptsEmpty");
        _settingsList = Required<StackPanel>("SettingsList");
        _consoleOutput = Required<StackPanel>("ConsoleOutput");
        _consoleScroll = Required<ScrollViewer>("ConsoleScroll");
        _tabScroll = Required<ScrollViewer>("TabScroll");
        _railCode = Required<Button>("RailCode");
        _railConsole = Required<Button>("RailConsole");
        _railSettings = Required<Button>("RailSettings");
        _topMostToggle = new Button { Classes = { "sh-toggle" } };
        _closeTabConfirmToggle = new Button { Classes = { "sh-toggle" } };

        _editor.WebMessageReceived += Editor_WebMessageReceived;

        Topmost = OrbitPreferences.TopMostEnabled;
        CanResize = true;

        _scriptList.ItemTemplate = new FuncDataTemplate<SirHurtScriptItem>(
            (item, _) => BuildScriptItemVisual(item), true);

        InitializeSettingsRows();
        InitializeToggleStates();
        RenderTabs();
        UpdateBridgeVisuals();
        RefreshScripts();

        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.ClientsChanged += BridgeClientsChanged;
        _bridge.LogReceived += BridgeConsole_LogReceived;
        RefreshClientTargets();

        _tabScroll.PointerWheelChanged += TabScroll_PointerWheelChanged;

        Opened += SirHurtWindow_Opened;
        Closed += SirHurtWindow_Closed;
        PropertyChanged += SirHurtWindow_PropertyChanged;
        KeyDown += SirHurtWindow_KeyDown;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"SirHurt control '{name}' was not created.");

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

    private async void SirHurtWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SirHurtWindow_Opened;

        _chrome.Opacity = 0;
        var scale = new ScaleTransform(0.97, 0.97);
        _chrome.RenderTransform = scale;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(340),
                progress =>
                {
                    _chrome.Opacity = progress;
                    var value = 0.97 + (0.03 * progress);
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _chrome.Opacity = 1;
        _chrome.RenderTransform = null;
        RevealEditor();
    }

    private void SirHurtWindow_Closed(object? sender, EventArgs e)
    {
        _editorDisposed = true;
        _editor.IsVisible = false;
        _pendingEditorSnapshot?.TrySetCanceled();
        _editor.WebMessageReceived -= Editor_WebMessageReceived;
        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.ClientsChanged -= BridgeClientsChanged;
        _bridge.LogReceived -= BridgeConsole_LogReceived;

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(CaptureWorkspace());
        }
    }

    private void SirHurtWindow_PropertyChanged(object? sender, AvaloniaPropertyChangedEventArgs e)
    {
        if (e.Property != WindowStateProperty)
        {
            return;
        }

        var maximized = WindowState == WindowState.Maximized;
        _chrome.CornerRadius = maximized ? new CornerRadius(0) : new CornerRadius(8);
        _chrome.BorderThickness = maximized ? new Thickness(0) : new Thickness(1);
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        Close();
    }

    private void SirHurtWindow_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_confirmOverlay.IsVisible)
            {
                HideConfirmOverlay();
                e.Handled = true;
            }
            else if (_settingsOpen || _consoleOpen)
            {
                ShowEditorMode();
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
            RequestCloseTab(_activeTab);
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
        WindowState = WindowState == WindowState.Maximized
            ? WindowState.Normal
            : WindowState.Maximized;
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    // ─────────────────────────── rail ───────────────────────────

    private void RailCode_Click(object? sender, RoutedEventArgs e)
    {
        if (_settingsOpen || _consoleOpen)
        {
            ShowEditorMode();
        }
    }



    private void RailSettings_Click(object? sender, RoutedEventArgs e)
    {
        if (_settingsOpen)
        {
            ShowEditorMode();
        }
        else
        {
            ShowSettingsMode();
        }
    }

    private void ShowEditorMode()
    {
        _settingsOpen = false;
        _consoleOpen = false;
        _consoleMode.IsVisible = false;
        _settingsMode.IsVisible = false;
        _editorMode.IsVisible = true;
        _creditsPanel.IsVisible = false;
        _scriptsPanel.IsVisible = true;
        UpdateRailVisuals();
        RevealEditor();
        _ = AnimateModeInAsync(_editorMode);
    }

    private void RailConsole_Click(object? sender, RoutedEventArgs e)
    {
        if (_consoleOpen)
        {
            ShowEditorMode();
            return;
        }

        _settingsOpen = false;
        _consoleOpen = true;
        _editor.IsVisible = false;
        _editorMode.IsVisible = false;
        _settingsMode.IsVisible = false;
        _scriptsPanel.IsVisible = false;
        _creditsPanel.IsVisible = false;
        _consoleMode.IsVisible = true;
        UpdateRailVisuals();

        if (!_consoleReplayed)
        {
            _consoleReplayed = true;
            foreach (var entry in _bridge.GetLogSnapshot())
            {
                AppendConsoleLine(entry.Level, entry.Message);
            }
        }

        _ = AnimateModeInAsync(_consoleMode);
    }

    private void ShowSettingsMode()
    {
        if (_settingsOpen)
        {
            return;
        }

        _settingsOpen = true;
        _consoleOpen = false;
        _editor.IsVisible = false;
        _editorMode.IsVisible = false;
        _consoleMode.IsVisible = false;
        _scriptsPanel.IsVisible = false;
        _creditsPanel.IsVisible = true;
        UpdateRailVisuals();
        _ = AnimateModeInAsync(_settingsMode);
    }

    private void UpdateRailVisuals()
    {
        SetClass(_railSettings.Classes, "active", _settingsOpen);
        SetClass(_railConsole.Classes, "active", _consoleOpen);
        SetClass(_railCode.Classes, "active", !_settingsOpen && !_consoleOpen);
    }

    private void BridgeConsole_LogReceived(string level, string message) =>
        Dispatcher.UIThread.Post(() =>
        {
            if (_consoleOpen)
            {
                AppendConsoleLine(level, message);
            }
        });

    private void AppendConsoleLine(string level, string message)
    {
        if (_editorDisposed || _consoleOutput is null)
        {
            return;
        }

        var normalized = string.IsNullOrWhiteSpace(level) ? "info" : level.ToLowerInvariant();
        var prefix = normalized switch
        {
            "warn" or "warning" => "[warn]   ",
            "error" => "[error]  ",
            "print" or "output" => "[print]  ",
            _ => "[info]   "
        };
        var color = normalized switch
        {
            "warn" or "warning" => "#C8A25A",
            "error" => "#D06B6B",
            "print" or "output" => "#9CCB6B",
            _ => "#B8B8BA"
        };

        var line = new TextBlock
        {
            Text = prefix + message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 10,
            Foreground = new SolidColorBrush(Color.Parse(color)),
            TextWrapping = TextWrapping.Wrap
        };
        _consoleOutput.Children.Add(line);
        while (_consoleOutput.Children.Count > 500)
        {
            _consoleOutput.Children.RemoveAt(0);
        }

        Dispatcher.UIThread.Post(line.BringIntoView, DispatcherPriority.Background);
    }

    private void ConsoleClear_Click(object? sender, RoutedEventArgs e)
    {
        _consoleOutput.Children.Clear();
    }

    private void TabScroll_PointerWheelChanged(object? sender, PointerWheelEventArgs e)
    {
        var offset = _tabScroll.Offset;
        _tabScroll.Offset = new Avalonia.Vector(offset.X - e.Delta.Y * 48, offset.Y);
        e.Handled = true;
    }

    private async Task AnimateModeInAsync(Control incoming)
    {
        var token = RestartFx();
        incoming.Opacity = 0;
        var slide = new TranslateTransform { Y = 10 };
        incoming.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(190),
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

    // ─────────────────────────── tabs ───────────────────────────

    private void RenderTabs(Guid? entranceTabId = null)
    {
        _tabStrip.Children.Clear();
        Border? activeVisual = null;
        foreach (var tab in _workspace.Tabs)
        {
            var visual = CreateTabVisual(tab);
            _tabStrip.Children.Add(visual);
            if (tab.Id == _activeTab.Id)
            {
                activeVisual = visual;
            }
            if (entranceTabId.HasValue && tab.Id == entranceTabId.Value)
            {
                AnimateTabEntrance(visual);
            }
        }
        Dispatcher.UIThread.Post(() => activeVisual?.BringIntoView(), DispatcherPriority.Background);

        var add = new Button
        {
            Width = 24,
            Height = 24,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(4),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = new TextBlock
            {
                Text = "+",
                FontSize = 14,
                Foreground = new SolidColorBrush(Color.Parse("#8A8A8A"))
            }
        };
        ToolTip.SetTip(add, "New tab (Ctrl+T)");
        add.PointerEntered += (_, _) => add.Background = new SolidColorBrush(Color.Parse("#222222"));
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
            Background = new SolidColorBrush(Color.Parse(active ? "#32373A" : "#2B2E32")),
            BorderBrush = new SolidColorBrush(Color.Parse(active ? "#32526F" : "#00000000")),
            BorderThickness = new Thickness(0, 0, 0, 2),
            VerticalAlignment = VerticalAlignment.Stretch,
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        border.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(130) },
            new BrushTransition { Property = Border.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(130) }
        };

        var grid = new Grid { ColumnDefinitions = new ColumnDefinitions("*,16") };

        var title = new TextBlock
        {
            Text = tab.Title,
            FontSize = 11,
            FontWeight = FontWeight.Medium,
            Foreground = new SolidColorBrush(Color.Parse(active ? "#FFFFFF" : "#8A8A8A")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 5, 0)
        };
        title.Transitions = new Transitions
        {
            new BrushTransition { Property = TextBlock.ForegroundProperty, Duration = TimeSpan.FromMilliseconds(130) }
        };
        title.DoubleTapped += (_, e) =>
        {
            e.Handled = true;
            BeginTabRename(tab, grid, title);
        };
        Grid.SetColumn(title, 0);

        var close = new Button
        {
            Width = 14,
            Height = 14,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Content = new TextBlock
            {
                Text = "×",
                FontSize = 10,
                Foreground = new SolidColorBrush(Color.Parse(active ? "#9A9A9A" : "#6A6A6A"))
            }
        };
        close.PointerEntered += (_, _) =>
        {
            close.Background = new SolidColorBrush(Color.Parse("#2E2E2E"));
            if (close.Content is TextBlock enteredLabel)
            {
                enteredLabel.Foreground = new SolidColorBrush(Color.Parse("#FFFFFF"));
            }
        };
        close.PointerExited += (_, _) =>
        {
            close.Background = Brushes.Transparent;
            if (close.Content is TextBlock exitedLabel)
            {
                exitedLabel.Foreground = new SolidColorBrush(
                    Color.Parse(active ? "#9A9A9A" : "#6A6A6A"));
            }
        };
        close.Click += (_, e) =>
        {
            e.Handled = true;
            RequestCloseTab(tab);
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
                title.Foreground = new SolidColorBrush(Color.Parse("#C9C9C9"));
            }
        };
        border.PointerExited += (_, _) =>
        {
            if (tab.Id != _activeTab.Id)
            {
                title.Foreground = new SolidColorBrush(Color.Parse("#8A8A8A"));
            }
        };

        border.MinWidth = 96;
        border.MaxWidth = 180;
        return border;
    }

    private async void AnimateTabEntrance(Border visual)
    {
        visual.Opacity = 0;
        var slide = new TranslateTransform { X = -8 };
        visual.RenderTransform = slide;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(170),
                progress =>
                {
                    visual.Opacity = progress;
                    slide.X = -8 * (1 - progress);
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
            Foreground = new SolidColorBrush(Color.Parse("#E8E8E8")),
            CaretBrush = new SolidColorBrush(Color.Parse("#9C9C9C")),
            FontSize = 11,
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

    private void RequestCloseTab(EditorTabState tab)
    {
        if (_workspace.Tabs.Count == 1)
        {
            _ = ShowToastAsync("Cannot close the last tab");
            return;
        }

        if (_options.CloseTabConfirmation)
        {
            ShowConfirmOverlay(tab);
            return;
        }

        CloseTab(tab);
    }

    private void CloseTab(EditorTabState tab)
    {
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

    // ─────────────────────────── tab-close confirmation ───────────────────────────

    private async void ShowConfirmOverlay(EditorTabState tab)
    {
        _pendingCloseTab = tab;
        _confirmMessage.Text = $"Are you sure you want to close \"{tab.Title}\"?";
        _editor.IsVisible = false;
        _confirmOverlay.IsVisible = true;

        var token = RestartFx();
        _confirmOverlay.Opacity = 0;
        var scale = new ScaleTransform(0.95, 0.95);
        _confirmDialog.RenderTransform = scale;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(160),
                progress =>
                {
                    _confirmOverlay.Opacity = progress;
                    var value = 0.95 + (0.05 * progress);
                    scale.ScaleX = value;
                    scale.ScaleY = value;
                },
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _confirmOverlay.Opacity = 1;
        _confirmDialog.RenderTransform = null;
    }

    private async void HideConfirmOverlay()
    {
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(120),
                progress => _confirmOverlay.Opacity = 1 - progress,
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _confirmOverlay.IsVisible = false;
        _pendingCloseTab = null;
        RevealEditor();
    }

    private void ConfirmAccept_Click(object? sender, RoutedEventArgs e)
    {
        var tab = _pendingCloseTab;
        HideConfirmOverlay();
        if (tab is not null)
        {
            CloseTab(tab);
        }
    }

    private void ConfirmCancel_Click(object? sender, RoutedEventArgs e) => HideConfirmOverlay();

    // ─────────────────────────── editor bridge ───────────────────────────

    private void RevealEditor()
    {
        if (_editorDisposed || _settingsOpen || _consoleOpen)
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

    // ─────────────────────────── settings ───────────────────────────

    private void InitializeSettingsRows()
    {
        _settingsList.Children.Add(BuildSettingsRow(
            "Return to Orion UI",
            "Closes SirHurt and restores the main Orion workspace with all tabs.",
            BuildReturnButton()));

        _settingsList.Children.Add(BuildDivider());

        var topMostRow = BuildSettingsRow(
            "Top Most",
            "Keeps SirHurt on top of all other windows.",
            _topMostToggle);
        _settingsList.Children.Add(topMostRow);
        _settingsList.Children.Add(BuildDivider());

        var confirmRow = BuildSettingsRow(
            "Close Tab Confirmation",
            "Shows a confirmation popup when closing a tab.",
            _closeTabConfirmToggle);
        _settingsList.Children.Add(confirmRow);
    }

    private Control BuildReturnButton()
    {
        var button = new Button
        {
            Classes = { "sh-mini" },
            Height = 24,
            Content = "Return"
        };
        button.Click += (_, _) => _ = ReturnToOrionAsync();
        return button;
    }

    private static Control BuildDivider() => new Border
    {
        Height = 1,
        Background = new SolidColorBrush(Color.Parse("#262626")),
        Margin = new Thickness(0, 2)
    };

    private static Control BuildSettingsRow(string title, string description, Control right)
    {
        var grid = new Grid
        {
            ColumnDefinitions = new ColumnDefinitions("*,Auto"),
            ColumnSpacing = 14,
            MinHeight = 52,
            VerticalAlignment = VerticalAlignment.Top
        };

        var text = new StackPanel
        {
            Spacing = 3,
            VerticalAlignment = VerticalAlignment.Center
        };
        text.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 13,
            FontWeight = FontWeight.SemiBold,
            Foreground = new SolidColorBrush(Color.Parse("#E8E8E8"))
        });
        text.Children.Add(new TextBlock
        {
            Text = description,
            FontSize = 10.5,
            Foreground = new SolidColorBrush(Color.Parse("#8A8A8A")),
            TextWrapping = TextWrapping.Wrap
        });
        Grid.SetColumn(text, 0);
        grid.Children.Add(text);

        Grid.SetColumn(right, 1);
        grid.Children.Add(right);

        return grid;
    }

    private void InitializeToggleStates()
    {
        _suppressToggleEvents = true;
        SetToggleVisual(_topMostToggle, OrbitPreferences.TopMostEnabled);
        SetToggleVisual(_closeTabConfirmToggle, _options.CloseTabConfirmation);
        _suppressToggleEvents = false;

        _topMostToggle.Click += TopMostToggle_Click;
        _closeTabConfirmToggle.Click += CloseTabConfirmToggle_Click;
    }

    private static void SetToggleVisual(Button toggle, bool enabled)
    {
        SetClass(toggle.Classes, "checked", enabled);
        toggle.Content = enabled ? "ENABLED" : "DISABLED";
    }

    private void TopMostToggle_Click(object? sender, RoutedEventArgs e)
    {
        if (_suppressToggleEvents)
        {
            return;
        }

        var enabled = !_topMostToggle.Classes.Contains("checked");
        SetToggleVisual(_topMostToggle, enabled);
        Topmost = enabled;
        OrbitPreferences.SetTopMost(enabled);
        _ = ShowToastAsync(enabled ? "Top Most enabled" : "Top Most disabled");
    }

    private void CloseTabConfirmToggle_Click(object? sender, RoutedEventArgs e)
    {
        if (_suppressToggleEvents)
        {
            return;
        }

        var enabled = !_closeTabConfirmToggle.Classes.Contains("checked");
        SetToggleVisual(_closeTabConfirmToggle, enabled);
        _options.CloseTabConfirmation = enabled;
        SirHurtOptionsStore.Save(_options);
        _ = ShowToastAsync(enabled ? "Close Tab Confirmation enabled" : "Close Tab Confirmation disabled");
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
            _ = ShowToastAsync("Not injected — run Scripts/Orion Bridge.lua first");
            return;
        }

        _bridge.EnqueueExecute(source);
        _ = ShowToastAsync("Script executed");
    }

    private void Initialize_Click(object? sender, RoutedEventArgs e)
    {
        RefreshClientTargets();
        if (_bridge.IsConnected && _selectedClientIdentifiers.Count > 0)
        {
            _ = ShowToastAsync("Injected — bridge connected");
        }
        else
        {
            _ = ShowToastAsync("Not injected — run Scripts/Orion Bridge.lua first");
        }
    }

    private async void Clear_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = await RequestEditorContentAsync();
        _activeTab.Content = string.Empty;
        PushActiveTabToEditor();
        _ = ShowToastAsync("Text cleared");
    }

    private async void ExecuteFile_Click(object? sender, RoutedEventArgs e)
    {
        var picked = await PickScriptAsync();
        if (picked is null)
        {
            return;
        }

        OpenFileInTab(picked.Value.File.Name, picked.Value.Content);
        if (string.IsNullOrWhiteSpace(picked.Value.Content))
        {
            _ = ShowToastAsync("File is empty");
            return;
        }

        ExecuteOnBridge(picked.Value.Content);
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
            Title = System.IO.Path.GetFileNameWithoutExtension(fileName),
            Extension = System.IO.Path.GetExtension(fileName) is { Length: > 0 } extension
                ? extension
                : ".lua",
            Content = content
        };
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs(tab.Id);
        if (_settingsOpen)
        {
            ShowEditorMode();
        }
        RevealEditor();
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
        _activeTab.Title = System.IO.Path.GetFileNameWithoutExtension(file.Name);
        _activeTab.Extension = System.IO.Path.GetExtension(file.Name) is { Length: > 0 } extension
            ? extension
            : ".lua";
        RenderTabs();
        _ = ShowToastAsync($"Saved {file.Name}");
    }

    private static string SanitizeFileName(string value)
    {
        var invalid = System.IO.Path.GetInvalidFileNameChars();
        var result = new string(value.Where(character => !invalid.Contains(character)).ToArray()).Trim();
        return result.Length == 0 ? "script" : result;
    }

    // ─────────────────────────── scripts panel ───────────────────────────

    private Control BuildScriptItemVisual(SirHurtScriptItem? item)
    {
        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 7,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(7, 0)
        };
        panel.Children.Add(new AvaloniaPath
        {
            Data = (Geometry?)Resources["ShFileIcon"],
            Width = 12,
            Height = 12,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(Color.Parse("#8A8A8A")),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
            StrokeJoin = PenLineJoin.Round,
            VerticalAlignment = VerticalAlignment.Center
        });
        panel.Children.Add(new TextBlock
        {
            Text = item?.Name ?? string.Empty,
            FontSize = 10.5,
            Foreground = new SolidColorBrush(Color.Parse("#C9C9C9")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });
        return panel;
    }

    private void RefreshScripts()
    {
        _workspaceScripts = ListScriptFiles(_scriptsDirectory);
        ApplyScriptFilter(_scriptSearch.Text ?? string.Empty);
    }

    private static List<SirHurtScriptItem> ListScriptFiles(string directory)
    {
        var files = new List<SirHurtScriptItem>();
        try
        {
            Directory.CreateDirectory(directory);
            files.AddRange(Directory.EnumerateFiles(directory)
                .Where(path => new[] { ".lua", ".luau", ".txt" }
                    .Contains(System.IO.Path.GetExtension(path), StringComparer.OrdinalIgnoreCase))
                .OrderBy(path => System.IO.Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
                .Select(path => new SirHurtScriptItem(System.IO.Path.GetFileName(path), path)));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // An unreadable folder simply renders as an empty list.
        }

        return files;
    }

    private void ScriptSearch_TextChanged(object? sender, TextChangedEventArgs e) =>
        ApplyScriptFilter(_scriptSearch.Text ?? string.Empty);

    private void ApplyScriptFilter(string query)
    {
        var filtered = _workspaceScripts
            .Where(item => query.Length == 0 ||
                item.Name.Contains(query, StringComparison.OrdinalIgnoreCase))
            .ToList();
        _scriptList.ItemsSource = filtered;
        _scriptsEmpty.IsVisible = filtered.Count == 0;
    }

    private async void ScriptList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_scriptList.SelectedItem is not SirHurtScriptItem item)
        {
            return;
        }

        _scriptList.SelectedItem = null;
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

    // ─────────────────────────── bridge ───────────────────────────

    private void BridgeClientsChanged() =>
        Dispatcher.UIThread.Post(RefreshClientTargets);

    private void BridgeConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(() => UpdateBridgeVisuals());

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
        _statusText.Text = connected ? "Status: Injected" : "Status: Not Injected";
        _statusDot.Fill = new SolidColorBrush(Color.Parse(connected ? "#7CE38B" : "#C7386C"));
    }

    // ─────────────────────────── toast ───────────────────────────

    private async Task ShowToastAsync(string message)
    {
        _toastText.Text = message;
        var token = RestartFx();
        _toastPill.Opacity = 0;
        var slide = new TranslateTransform { Y = 6 };
        _toastPill.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(160),
                progress =>
                {
                    _toastPill.Opacity = progress;
                    slide.Y = 6 * (1 - progress);
                },
                CubicEaseOut,
                token);

            await Task.Delay(2100, token);

            await AnimateAsync(
                TimeSpan.FromMilliseconds(220),
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

    private static void SetClass(Classes classes, string className, bool enabled)
    {
        if (enabled)
        {
            classes.Add(className);
        }
        else
        {
            classes.Remove(className);
        }
    }

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














