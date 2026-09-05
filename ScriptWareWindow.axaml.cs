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
using Avalonia.Media.Imaging;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Diagnostics;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class ScriptWareWindow : Window
{
    private sealed record ScriptWareScriptItem(string Name, string Path);

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly ScriptWareOptions _options;
    private readonly HashSet<string> _selectedClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _knownClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, bool> _folderOpen = new(StringComparer.OrdinalIgnoreCase);

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
    private readonly Border _editorMode;
    private readonly Grid _settingsMode;
    private readonly Border _scriptsPanel;
    private readonly StackPanel _scriptsTree;
    private readonly StackPanel _settingsList;
    private readonly Button _railCode;
    private readonly Button _railTools;
    private readonly Button _railGear;
    private readonly Button _maximizeButton;
    private readonly ColumnDefinition _railColumn;
    private readonly ColumnDefinition _scriptsColumn;
    private EditorTabState _activeTab;
    private EditorTabState? _pendingCloseTab;
    private bool _editorReady;
    private bool _editorSourceAssigned;
    private bool _editorDisposed;
    private bool _settingsOpen;
    private bool _suppressToggleEvents;
    private bool _closingForOrion;
    private bool _returnRequested;
    private bool _railVisible = true;
    private bool _scriptsVisible = true;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;
    private CancellationTokenSource? _fx;

    public ScriptWareWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal ScriptWareWindow(
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
            var firstTab = NewTabState(1);
            _workspace.Tabs.Add(firstTab);
            _workspace.ActiveTabId = firstTab.Id;
        }
        _activeTab = _workspace.Tabs.FirstOrDefault(tab => tab.Id == _workspace.ActiveTabId)
            ?? _workspace.Tabs[0];
        _returnToOrion = returnToOrion;
        _options = ScriptWareOptionsStore.Load();
        RestoreSavedTabsIfFresh();

        AvaloniaXamlLoader.Load(this);

        _chrome = Required<Border>("SwChrome");
        _editor = Required<NativeWebView>("EditorWebView");
        _tabStrip = Required<StackPanel>("TabStrip");
        _confirmOverlay = Required<Panel>("ConfirmOverlay");
        _confirmDialog = Required<Border>("ConfirmDialog");
        _confirmMessage = Required<TextBlock>("ConfirmMessage");
        _confirmAccept = Required<Button>("ConfirmAccept");
        _toastPill = Required<Border>("ToastPill");
        _toastText = Required<TextBlock>("ToastText");
        _statusText = Required<TextBlock>("StatusText");
        _editorMode = Required<Border>("EditorMode");
        _settingsMode = Required<Grid>("SettingsMode");
        _scriptsPanel = Required<Border>("ScriptsPanel");
        _scriptsTree = Required<StackPanel>("ScriptsTree");
        _settingsList = Required<StackPanel>("SettingsList");
        _railCode = Required<Button>("RailCode");
        _railTools = Required<Button>("RailTools");
        _railGear = Required<Button>("RailGear");
        _maximizeButton = Required<Button>("MaximizeButton");
        _railColumn = Required<Grid>("BodyGrid").ColumnDefinitions[0];
        _scriptsColumn = Required<Grid>("MainAreaGrid").ColumnDefinitions[1];

        _editor.WebMessageReceived += Editor_WebMessageReceived;

        ApplyResizable(_options.Resizable, save: false);
        Topmost = OrbitPreferences.TopMostEnabled;

        InitializeSettingsRows();
        InitializeToggleStates();
        RenderTabs();
        UpdateBridgeVisuals();
        BuildScriptsTree();
        UpdateRailVisuals();

        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.ClientsChanged += BridgeClientsChanged;
        RefreshClientTargets();

        Opened += ScriptWareWindow_Opened;
        Closed += ScriptWareWindow_Closed;
        KeyDown += ScriptWareWindow_KeyDown;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"Script-Ware control '{name}' was not created.");

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = NewTabState(1);
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private static EditorTabState NewTabState(int index) => new()
    {
        Title = $"Script{index}.lua",
        Content = string.Empty,
        Extension = ".lua"
    };

    // ─────────────────────────── lifecycle ───────────────────────────

    private async void ScriptWareWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= ScriptWareWindow_Opened;

        _chrome.Opacity = 0;
        var scale = new ScaleTransform(0.97, 0.97);
        _chrome.RenderTransform = scale;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(280),
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

    private void ScriptWareWindow_Closed(object? sender, EventArgs e)
    {
        _editorDisposed = true;
        _editor.IsVisible = false;
        _pendingEditorSnapshot?.TrySetCanceled();
        _editor.WebMessageReceived -= Editor_WebMessageReceived;
        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.ClientsChanged -= BridgeClientsChanged;

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(CaptureWorkspace());
        }
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        Close();
    }

    private void ScriptWareWindow_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_confirmOverlay.IsVisible)
            {
                HideConfirmOverlay();
                e.Handled = true;
            }
            else if (_settingsOpen)
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

    private void Attach_Click(object? sender, RoutedEventArgs e)
    {
        RefreshClientTargets();
        var clients = _bridge.GetConnectedClients();
        if (_bridge.IsConnected && clients.Count > 0)
        {
            _statusText.Text = $" Attached to {clients.Count} client(s)";
            _ = ShowToastAsync($"Attached to {clients.Count} client(s)");
        }
        else
        {
            _statusText.Text = " Not Attached";
            _ = ShowToastAsync("Not attached — run Scripts/Orion Bridge.lua");
        }
    }

    private void RailCode_Click(object? sender, RoutedEventArgs e) => ShowEditorMode();

    private void RailSettings_Click(object? sender, RoutedEventArgs e) => ShowSettingsMode();

    private void ShowEditorMode()
    {
        if (_settingsOpen)
        {
            _settingsOpen = false;
            _settingsMode.IsVisible = false;
            _editorMode.IsVisible = true;
            UpdateRailVisuals();
            RevealEditor();
            _ = AnimateModeInAsync(_editorMode);
        }
        else
        {
            UpdateRailVisuals();
            RevealEditor();
        }
    }

    private void ShowSettingsMode()
    {
        if (_settingsOpen)
        {
            return;
        }

        _settingsOpen = true;
        _editor.IsVisible = false;
        _editorMode.IsVisible = false;
        _settingsMode.IsVisible = true;
        UpdateRailVisuals();
        _ = AnimateModeInAsync(_settingsMode);
    }

    private void UpdateRailVisuals()
    {
        // The original rail highlights the CURRENT page in blue; the rest stay light.
        SetClass(_railCode.Classes, "blue", !_settingsOpen);
        SetClass(_railCode.Classes, "light", _settingsOpen);
        SetClass(_railCode.Classes, "active", !_settingsOpen);
        SetClass(_railTools.Classes, "blue", _settingsOpen);
        SetClass(_railTools.Classes, "light", !_settingsOpen);
        SetClass(_railTools.Classes, "active", _settingsOpen);
        SetClass(_railGear.Classes, "blue", _settingsOpen);
        SetClass(_railGear.Classes, "light", !_settingsOpen);
        SetClass(_railGear.Classes, "active", _settingsOpen);
    }

    private async Task AnimateModeInAsync(Control incoming)
    {
        var token = RestartFx();
        incoming.Opacity = 0;
        var slide = new TranslateTransform { Y = 8 };
        incoming.RenderTransform = slide;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(170),
                progress =>
                {
                    incoming.Opacity = progress;
                    slide.Y = 8 * (1 - progress);
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
            Width = 30,
            Height = 30,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = new TextBlock
            {
                Text = "+",
                FontSize = 16,
                Foreground = new SolidColorBrush(Color.Parse("#C9C9C9"))
            }
        };
        ToolTip.SetTip(add, "New tab (Ctrl+T)");
        add.PointerEntered += (_, _) => add.Background = new SolidColorBrush(Color.Parse("#3A3A3A"));
        add.PointerExited += (_, _) => add.Background = Brushes.Transparent;
        add.Click += (_, _) => AddTab();
        _tabStrip.Children.Add(add);
    }

    private Border CreateTabVisual(EditorTabState tab)
    {
        var active = tab.Id == _activeTab.Id;
        var border = new Border
        {
            Height = 30,
            Padding = new Thickness(11, 0),
            MinWidth = 90,
            MaxWidth = 190,
            VerticalAlignment = VerticalAlignment.Stretch,
            Background = new SolidColorBrush(Color.Parse(active ? "#3A3A3A" : "#00000000")),
            BorderBrush = new SolidColorBrush(Color.Parse(active ? "#0A84FF" : "#00000000")),
            BorderThickness = new Thickness(0, 0, 0, 2),
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        border.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(120) },
            new BrushTransition { Property = Border.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(120) }
        };

        var panel = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };

        var title = new TextBlock
        {
            Text = tab.Title,
            FontSize = 12,
            Foreground = new SolidColorBrush(Color.Parse(active ? "#F0F0F0" : "#B0B0B0")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 8, 0)
        };
        title.Transitions = new Transitions
        {
            new BrushTransition { Property = TextBlock.ForegroundProperty, Duration = TimeSpan.FromMilliseconds(120) }
        };
        title.DoubleTapped += (_, e) =>
        {
            e.Handled = true;
            BeginTabRename(tab, panel, title);
        };
        panel.Children.Add(title);

        var close = new TextBlock
        {
            Text = "x",
            FontSize = 12,
            Foreground = new SolidColorBrush(Color.Parse("#9A9A9A")),
            VerticalAlignment = VerticalAlignment.Center
        };
        close.Transitions = new Transitions
        {
            new BrushTransition { Property = TextBlock.ForegroundProperty, Duration = TimeSpan.FromMilliseconds(120) }
        };
        close.PointerEntered += (_, _) => close.Foreground = new SolidColorBrush(Color.Parse("#FFFFFF"));
        close.PointerExited += (_, _) => close.Foreground = new SolidColorBrush(Color.Parse("#9A9A9A"));
        var closeHost = new Border
        {
            Background = Brushes.Transparent,
            Padding = new Thickness(3, 0)
        };
        closeHost.PointerPressed += (_, e) =>
        {
            e.Handled = true;
            RequestCloseTab(tab);
        };
        closeHost.Child = close;
        panel.Children.Add(closeHost);

        border.Child = panel;

        border.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(border).Properties.IsLeftButtonPressed)
            {
                SelectTab(tab);
                e.Handled = true;
            }
        };

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
                TimeSpan.FromMilliseconds(160),
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

    private void BeginTabRename(EditorTabState tab, StackPanel panel, TextBlock title)
    {
        var input = new TextBox
        {
            Text = tab.Title,
            Width = 120,
            Background = new SolidColorBrush(Color.Parse("#1F1F1F")),
            BorderThickness = new Thickness(0),
            CornerRadius = new CornerRadius(2),
            Padding = new Thickness(4, 1),
            Foreground = new SolidColorBrush(Color.Parse("#FFFFFF")),
            CaretBrush = new SolidColorBrush(Color.Parse("#9C9C9C")),
            FontSize = 11.5,
            VerticalContentAlignment = VerticalAlignment.Center
        };
        panel.Children.Remove(title);
        panel.Children.Insert(0, input);

        var committed = false;
        void Commit()
        {
            if (committed)
            {
                return;
            }

            committed = true;
            var name = (input.Text ?? string.Empty).Trim();
            tab.Title = name.Length == 0 ? tab.Title : name;
            if (System.IO.Path.GetExtension(tab.Title) is { Length: > 0 } extension)
            {
                tab.Extension = extension;
            }
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
        var index = _workspace.Tabs.Count + 1;
        var tab = NewTabState(index);
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs(tab.Id);
        if (_settingsOpen)
        {
            ShowEditorMode();
        }
        PushActiveTabToEditor();
    }

    private void SelectTab(EditorTabState tab)
    {
        if (_activeTab.Id == tab.Id)
        {
            if (_settingsOpen)
            {
                ShowEditorMode();
            }
            return;
        }

        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        if (_settingsOpen)
        {
            ShowEditorMode();
        }
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
        if (_editorDisposed || _settingsOpen)
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
                        ApplyEditorFontPreference(save: false);
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

    private static readonly string[] EditorFontChoices =
    [
        "Consolas",
        "Cascadia Mono",
        "Courier New",
        "JetBrains Mono",
        "Fira Code",
        "Segoe UI"
    ];

    private static string EditorFontPath => System.IO.Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orion",
        "scriptware-editor-font.txt");
    private static string EditorFontSizePath => System.IO.Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orion",
        "scriptware-editor-size.txt");

    private static (string Family, double Size) LoadEditorFontPreference()
    {
        try
        {
            var family = File.Exists(EditorFontPath) ? File.ReadAllText(EditorFontPath).Trim() : "Consolas";
            var size = 14.0;
            if (File.Exists(EditorFontSizePath) &&
                double.TryParse(File.ReadAllText(EditorFontSizePath).Trim(), out var parsed))
            {
                size = Math.Clamp(parsed, 8, 28);
            }

            return (string.IsNullOrWhiteSpace(family) ? "Consolas" : family, size);
        }
        catch (IOException)
        {
            return ("Consolas", 14.0);
        }
        catch (UnauthorizedAccessException)
        {
            return ("Consolas", 14.0);
        }
    }

    private static void SaveEditorFontPreference(string family, double size)
    {
        try
        {
            Directory.CreateDirectory(System.IO.Path.GetDirectoryName(EditorFontPath)!);
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

    private ComboBox? _editorFontBox;
    private NumericUpDown? _editorFontSizeBox;
    private bool _fontControlsReady;

    private void ApplyEditorFontPreference(bool save)
    {
        if (!_fontControlsReady ||
            _editorFontBox is not { } fontBox ||
            _editorFontSizeBox is not { } sizeBox)
        {
            return;
        }

        var family = fontBox.SelectedItem as string ?? "Consolas";
        var size = sizeBox.Value is decimal chosen ? (double)chosen : 14.0;
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
            var familyJson = System.Text.Json.JsonSerializer.Serialize(family);
            _editor.InvokeScript(
                $"window.orbitSetEditorFont && window.orbitSetEditorFont({familyJson}, {size.ToString("0.#")});");
        }
        catch (InvalidOperationException)
        {
            // Monaco may still be loading; the preference applies on ready.
        }
    }

    private void EditorFont_SelectionChanged(object? sender, SelectionChangedEventArgs e) =>
        ApplyEditorFontPreference(save: true);

    private void EditorFontSize_ValueChanged(object? sender, NumericUpDownValueChangedEventArgs e) =>
        ApplyEditorFontPreference(save: true);

    private void InitializeSettingsRows()
    {
        _settingsList.Children.Add(BuildSettingsRow(
            "Return to Orion UI",
            "Closes ScriptWare and restores the main Orion workspace with all tabs.",
            BuildReturnButton()));

        _settingsList.Children.Add(BuildDivider());

        var savedFont = LoadEditorFontPreference();
        _editorFontBox = new ComboBox
        {
            MinWidth = 150,
            Height = 26,
            FontSize = 11.5,
            ItemsSource = EditorFontChoices,
            SelectedItem = EditorFontChoices.Contains(savedFont.Family) ? savedFont.Family : EditorFontChoices[0]
        };
        _editorFontBox.SelectionChanged += EditorFont_SelectionChanged;
        _editorFontSizeBox = new NumericUpDown
        {
            MinWidth = 84,
            Height = 26,
            FontSize = 11.5,
            Minimum = 8,
            Maximum = 28,
            Increment = 1,
            Value = (decimal)savedFont.Size
        };
        _editorFontSizeBox.ValueChanged += EditorFontSize_ValueChanged;
        _fontControlsReady = true;

        _settingsList.Children.Add(BuildSettingsRow(
            "Editor Font",
            "Font family used inside the code editor.",
            _editorFontBox));
        _settingsList.Children.Add(BuildDivider());
        _settingsList.Children.Add(BuildSettingsRow(
            "Editor Font Size",
            "Font size for the code editor (8-28).",
            _editorFontSizeBox));
        _settingsList.Children.Add(BuildDivider());

        var topMostRow = BuildSettingsRow(
            "Top Most",
            "Keeps ScriptWare on top of all other windows.",
            _topMostToggle);
        _settingsList.Children.Add(topMostRow);
        _settingsList.Children.Add(BuildDivider());

        var confirmRow = BuildSettingsRow(
            "Close Tab Confirmation",
            "Shows a confirmation popup when closing a tab.",
            _closeTabConfirmToggle);
        _settingsList.Children.Add(confirmRow);
        _settingsList.Children.Add(BuildDivider());

        var resizableRow = BuildSettingsRow(
            "Resizable Window",
            "Lets the window be resized and maximized; the interface adapts to the new size.",
            _resizableToggle);
        _settingsList.Children.Add(resizableRow);
    }

    private readonly Button _topMostToggle = new() { Classes = { "sw-toggle" } };
    private readonly Button _closeTabConfirmToggle = new() { Classes = { "sw-toggle" } };
    private readonly Button _resizableToggle = new() { Classes = { "sw-toggle" } };

    private Control BuildReturnButton()
    {
        var button = new Button
        {
            Classes = { "sw-mini" },
            Height = 26,
            Content = "Return"
        };
        button.Click += (_, _) => _ = ReturnToOrionAsync();
        return button;
    }

    private static Control BuildDivider() => new Border
    {
        Height = 1,
        Background = new SolidColorBrush(Color.Parse("#333333")),
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
            Foreground = new SolidColorBrush(Color.Parse("#909090")),
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
        SetToggleVisual(_resizableToggle, _options.Resizable);
        _suppressToggleEvents = false;

        _topMostToggle.Click += TopMostToggle_Click;
        _closeTabConfirmToggle.Click += CloseTabConfirmToggle_Click;
        _resizableToggle.Click += ResizableToggle_Click;
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
        ScriptWareOptionsStore.Save(_options);
        _ = ShowToastAsync(enabled ? "Close Tab Confirmation enabled" : "Close Tab Confirmation disabled");
    }

    private void ResizableToggle_Click(object? sender, RoutedEventArgs e)
    {
        if (_suppressToggleEvents)
        {
            return;
        }

        var enabled = !_resizableToggle.Classes.Contains("checked");
        SetToggleVisual(_resizableToggle, enabled);
        _options.Resizable = enabled;
        ScriptWareOptionsStore.Save(_options);
        ApplyResizable(enabled, save: false);
        _ = ShowToastAsync(enabled ? "Resizable window enabled" : "Resizable window disabled");
    }

    private void ApplyResizable(bool enabled, bool save)
    {
        if (save)
        {
            OrbitPreferences.SetResizable(enabled);
        }

        if (!enabled)
        {
            WindowState = WindowState.Normal;
        }

        CanResize = enabled;
        _maximizeButton.IsVisible = enabled;
        _maximizeButton.IsEnabled = enabled;
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
            _ = ShowToastAsync("Not attached — run Scripts/Orion Bridge.lua first");
            return;
        }

        _bridge.EnqueueExecute(source);
        _ = ShowToastAsync("Script executed");
    }

    private async void Clear_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = await RequestEditorContentAsync();
        _activeTab.Content = string.Empty;
        PushActiveTabToEditor();
        _ = ShowToastAsync("Text cleared");
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
        var existing = _workspace.Tabs.FirstOrDefault(tab =>
            string.Equals(tab.Title, fileName, StringComparison.OrdinalIgnoreCase));
        if (existing is not null)
        {
            existing.Content = content;
            _activeTab = existing;
            _workspace.ActiveTabId = existing.Id;
            RenderTabs();
            if (_settingsOpen)
            {
                ShowEditorMode();
            }
            RevealEditor();
            PushActiveTabToEditor();
            return;
        }

        var tab = new EditorTabState
        {
            Title = fileName,
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
        var suggested = SanitizeFileName(_activeTab.Title);
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            SuggestedFileName = suggested,
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
        _activeTab.Title = System.IO.Path.GetFileName(file.Name);
        _activeTab.Extension = System.IO.Path.GetExtension(file.Name) is { Length: > 0 } extension
            ? extension
            : ".lua";
        RenderTabs();
        _ = ShowToastAsync($"Saved {file.Name}");
    }

    private async void CloseRoblox_Click(object? sender, RoutedEventArgs e)
    {
        try
        {
            var processes = Process.GetProcessesByName("RobloxPlayerBeta");
            if (processes.Length == 0)
            {
                _ = ShowToastAsync("Roblox is not running");
                return;
            }

            foreach (var process in processes)
            {
                try
                {
                    process.Kill(entireProcessTree: true);
                }
                finally
                {
                    process.Dispose();
                }
            }

            _ = ShowToastAsync($"Closed Roblox ({processes.Length})");
        }
        catch (Exception)
        {
            _ = ShowToastAsync("Failed to close Roblox");
        }
    }

    private async void SaveTabs_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = await RequestEditorContentAsync();
        ScriptWareSessionStore.Save(_workspace.Tabs.Select(tab => new ScriptWareSavedTab(
            tab.Title,
            tab.Extension,
            tab.Content)).ToList());
        _ = ShowToastAsync($"Saved {_workspace.Tabs.Count} script tabs");
    }

    private void RestoreSavedTabsIfFresh()
    {
        // Only a pristine handoff workspace (one empty tab) is replaced by the
        // saved session; real tabs coming from Orion always win.
        if (_workspace.Tabs.Count != 1 ||
            _workspace.Tabs[0].Content.Length != 0)
        {
            return;
        }

        var saved = ScriptWareSessionStore.Load();
        if (saved is null || saved.Count == 0)
        {
            return;
        }

        var tabs = saved.Select(entry => new EditorTabState
        {
            Title = string.IsNullOrWhiteSpace(entry.Title) ? "Script1.lua" : entry.Title,
            Extension = string.IsNullOrWhiteSpace(entry.Extension) ? ".lua" : entry.Extension,
            Content = entry.Content ?? string.Empty
        }).ToList();

        _workspace.Tabs.Clear();
        _workspace.Tabs.AddRange(tabs);
        _activeTab = _workspace.Tabs[0];
        _workspace.ActiveTabId = _activeTab.Id;
    }

    private void PanelToggle_Click(object? sender, RoutedEventArgs e)
    {
        _scriptsVisible = !_scriptsVisible;
        _scriptsColumn.Width = new GridLength(_scriptsVisible ? 152 : 0);
        _scriptsPanel.IsVisible = _scriptsVisible;
    }

    private void RailToggle_Click(object? sender, RoutedEventArgs e)
    {
        _railVisible = !_railVisible;
        _railColumn.Width = new GridLength(_railVisible ? 44 : 0);
    }

    private static string SanitizeFileName(string value)
    {
        var invalid = System.IO.Path.GetInvalidFileNameChars();
        var result = new string(value.Where(character => !invalid.Contains(character)).ToArray()).Trim();
        if (result.EndsWith(".lua", StringComparison.OrdinalIgnoreCase))
        {
            result = result[..^4];
        }
        return result.Length == 0 ? "script" : result;
    }

    // ─────────────────────────── scripts tree ───────────────────────────

    private void BuildScriptsTree()
    {
        _scriptsTree.Children.Clear();

        List<string> directories;
        List<string> rootFiles;
        try
        {
            Directory.CreateDirectory(_scriptsDirectory);
            directories = Directory.EnumerateDirectories(_scriptsDirectory)
                .OrderBy(path => System.IO.Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
                .ToList();
            rootFiles = ListLuaFiles(_scriptsDirectory);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // An unreadable folder simply renders as an empty tree.
            return;
        }

        foreach (var directory in directories)
        {
            var name = System.IO.Path.GetFileName(directory);
            var open = _folderOpen.TryGetValue(name, out var isOpen) ? isOpen : true;
            _scriptsTree.Children.Add(BuildFolderRow(name, directory, open));

            if (open)
            {
                foreach (var file in ListLuaFiles(directory))
                {
                    _scriptsTree.Children.Add(BuildFileRow(
                        System.IO.Path.GetFileName(file),
                        file,
                        indent: 26,
                        treeGuide: true));
                }
            }
        }

        foreach (var file in rootFiles)
        {
            _scriptsTree.Children.Add(BuildFileRow(
                System.IO.Path.GetFileName(file),
                file,
                indent: 8,
                treeGuide: false));
        }
    }

    private static List<string> ListLuaFiles(string directory)
    {
        try
        {
            return Directory.EnumerateFiles(directory)
                .Where(path => new[] { ".lua", ".luau", ".txt" }
                    .Contains(System.IO.Path.GetExtension(path), StringComparer.OrdinalIgnoreCase))
                .OrderBy(path => System.IO.Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            return [];
        }
    }

    private Control BuildFolderRow(string name, string path, bool open)
    {
        _folderOpen[name] = open;

        var row = new Border
        {
            Classes = { "sw-treerow" },
            Margin = new Thickness(2, 1, 0, 1),
            Cursor = new Cursor(StandardCursorType.Hand)
        };

        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 5,
            VerticalAlignment = VerticalAlignment.Center
        };

        var chevron = new AvaloniaPath
        {
            Data = (Geometry?)Resources[open ? "SwChevronDownIcon" : "SwChevronRightIcon"],
            Width = 9,
            Height = 9,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(Color.Parse("#8A8A8A")),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
            StrokeJoin = PenLineJoin.Round,
            VerticalAlignment = VerticalAlignment.Center
        };
        panel.Children.Add(chevron);

        panel.Children.Add(new AvaloniaPath
        {
            Data = (Geometry?)Resources["SwFolderIcon"],
            Width = 13,
            Height = 13,
            Stretch = Stretch.Uniform,
            Fill = new SolidColorBrush(Color.Parse("#D9B64A")),
            StrokeThickness = 0,
            VerticalAlignment = VerticalAlignment.Center
        });

        panel.Children.Add(new TextBlock
        {
            Text = name,
            FontSize = 11.5,
            Foreground = new SolidColorBrush(Color.Parse("#E4E4E4")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });

        row.Child = panel;
        row.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(row).Properties.IsLeftButtonPressed)
            {
                _folderOpen[name] = !open;
                BuildScriptsTree();
                e.Handled = true;
            }
        };
        return row;
    }

    private Control BuildFileRow(string name, string path, int indent, bool treeGuide)
    {
        var row = new Border
        {
            Classes = { "sw-treerow" },
            Margin = new Thickness(2, 0, 0, 0),
            Padding = new Thickness(indent, 0, 4, 0),
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        ToolTip.SetTip(row, path);

        var panel = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 5,
            VerticalAlignment = VerticalAlignment.Center
        };

        if (treeGuide)
        {
            panel.Children.Add(new Border
            {
                Width = 1,
                Height = 14,
                Margin = new Thickness(-14, 0, 8, 0),
                Background = new SolidColorBrush(Color.Parse("#3A3A3A")),
                VerticalAlignment = VerticalAlignment.Center
            });
        }

        // The .txt icon exactly as the asset Assets/ScriptWare/txt-icon.png.
        var fileIcon = new Image
        {
            Height = 12,
            Stretch = Stretch.Uniform,
            Source = new Bitmap(Avalonia.Platform.AssetLoader.Open(new Uri("avares://Orion/Assets/ScriptWare/txt-icon.png"))),
            VerticalAlignment = VerticalAlignment.Center
        };
        RenderOptions.SetBitmapInterpolationMode(fileIcon, BitmapInterpolationMode.HighQuality);
        panel.Children.Add(fileIcon);

        panel.Children.Add(new TextBlock
        {
            Text = name,
            FontSize = 11.5,
            Foreground = new SolidColorBrush(Color.Parse("#DCDCDC")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });

        row.Child = panel;
        row.DoubleTapped += async (_, e) =>
        {
            e.Handled = true;
            try
            {
                OpenFileInTab(name, await File.ReadAllTextAsync(path));
                _ = ShowToastAsync($"Opened {name}");
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
            {
                _ = ShowToastAsync($"Read error: {ex.Message}");
            }
        };
        return row;
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
        _statusText.Text = connected ? " Attached" : " Not Attached";
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
}
