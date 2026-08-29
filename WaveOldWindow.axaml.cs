using Avalonia;
using Avalonia.Animation;
using Avalonia.Animation.Easings;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.Shapes;
using Avalonia.Controls.Templates;
using Avalonia.Data;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using OrbitAvalonia.Controls;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace OrbitAvalonia;

public sealed partial class WaveOldWindow : Window
{
    private enum WaveOldPage { Editor, ScriptCloud, Settings }

    private sealed record WaveOldScriptItem(string Name, string FullPath);
    private sealed record WaveOldExplorerSection(string Id, string Title);

    private readonly WaveOldEditorOptions _options;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly EditorWorkspaceState _workspace;
    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;

    private readonly Border _chrome;
    private readonly Grid _editorPage;
    private readonly Grid _scriptCloudPage;
    private readonly Grid _settingsPage;
    private readonly Border _sidePanel;
    private readonly Border _editorPanel;
    private readonly ToggleButton _editorToggleButton;
    private readonly ToggleButton _scriptCloudToggleButton;
    private readonly ToggleButton _settingsToggleButton;
    private readonly WaveOldToastContainer _toastContainer;
    private readonly NativeWebView _editor;
    private readonly StackPanel _tabStrip;
    private readonly ListBox _hubList;
    private readonly TextBox _hubSearch;
    private readonly TextBlock _hubEmpty;
    private readonly ScriptHubService _hubService = new();
    private readonly List<ScriptHubCardModel> _hubCards = [];
    private readonly HashSet<string> _hubCardKeys = new(StringComparer.Ordinal);
    private ScriptHubProvider _hubProvider = ScriptHubProvider.ScriptBlox;
    private int _hubPage = 1;
    private bool _hubHasMore;
    private bool _hubLoading;
    private int _hubLoadVersion;
    private CancellationTokenSource? _hubLoadCancellation;
    private readonly DispatcherTimer _hubSearchTimer;
    private readonly Button _executeButton;

    private EditorTabState _activeTab = null!;
    private WaveOldPage _currentPage = WaveOldPage.Editor;
    private bool _sidePanelOpen;
    private readonly List<WaveOldExplorerSection> _explorerSections = [];
    private readonly Dictionary<string, List<WaveOldScriptItem>> _sectionFiles = [];
    private readonly Dictionary<string, StackPanel> _sectionChildren = [];
    private string? _openSectionId;
    private bool _explorerInitialized;
    private readonly string _workspaceDirectory;
    private bool _closingForOrion;
    private bool _returnRequested;
    private bool _editorReady;
    private bool _editorSourceAssigned;
    private bool _editorDisposed;
    private CancellationTokenSource? _fx;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;

    public WaveOldWindow() : this(new Uri("http://127.0.0.1:1/index.html"), string.Empty, CreateDefaultWorkspace(), _ => { })
    {
    }

    internal WaveOldWindow(
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
        _options = WaveOldOptionsStore.Load();

        AvaloniaXamlLoader.Load(this);

        _hubSearchTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(450) };
        _hubSearchTimer.Tick += HubSearchTimer_Tick;

        _chrome = this.FindControl<Border>("WaveOldChrome")!;
        _editorPage = this.FindControl<Grid>("EditorPage")!;
        _scriptCloudPage = this.FindControl<Grid>("ScriptCloudPage")!;
        _settingsPage = this.FindControl<Grid>("SettingsPage")!;
        _sidePanel = this.FindControl<Border>("SidePanel")!;
        _editorPanel = this.FindControl<Border>("EditorPanel")!;
        _editorToggleButton = this.FindControl<ToggleButton>("EditorToggleButton")!;
        _scriptCloudToggleButton = this.FindControl<ToggleButton>("ScriptCloudToggleButton")!;
        _settingsToggleButton = this.FindControl<ToggleButton>("SettingsToggleButton")!;
        _toastContainer = this.FindControl<WaveOldToastContainer>("ToastContainer")!;
        _editor = this.FindControl<NativeWebView>("EditorWebView")!;
        _tabStrip = this.FindControl<StackPanel>("TabStrip")!;
        _executeButton = this.FindControl<Button>("ExecuteButton")!;
        _hubList = this.FindControl<ListBox>("HubList")!;
        _hubSearch = this.FindControl<TextBox>("HubSearch")!;
        _hubEmpty = this.FindControl<TextBlock>("HubEmpty")!;
        _hubList.ItemTemplate = new FuncDataTemplate<ScriptHubCardModel>((item, _) => BuildHubCardVisual(item), true);

        _editor.WebMessageReceived += Editor_WebMessageReceived;

        Opened += WaveOldWindow_Opened;
        Closed += WaveOldWindow_Closed;
        KeyDown += WaveOldWindow_KeyDown;

        LoadOptions();
        RenderTabs();
        RevealEditor();
        LoadHubCards(append: false);

        _workspaceDirectory = global::System.IO.Path.Combine(
            string.IsNullOrEmpty(_scriptsDirectory) ? AppContext.BaseDirectory : global::System.IO.Path.GetDirectoryName(_scriptsDirectory.TrimEnd(global::System.IO.Path.DirectorySeparatorChar)) ?? AppContext.BaseDirectory,
            "Workspace");
        _explorerSections.Add(new WaveOldExplorerSection("Scripts", "Scripts"));
        _explorerSections.Add(new WaveOldExplorerSection("Workspace", "Workspace"));
    }

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

    private void LoadOptions()
    {
        try
        {
            if (this.FindControl<Border>("TopMostHit") is { } topMostHit)
            {
                SetCheck(topMostHit, _options.TopMost);
                Topmost = _options.TopMost;
            }
            if (this.FindControl<Border>("MinimapHit") is { } minimapHit) SetCheck(minimapHit, _options.Minimap);
            if (this.FindControl<Slider>("FontSizeSlider") is { } fontSlider) fontSlider.Value = _options.FontSize;
            if (this.FindControl<TextBlock>("FontSizeValue") is { } fontVal) fontVal.Text = ((int)_options.FontSize).ToString();
        }
        catch { }
    }

    private static void SetCheck(Border hit, bool isChecked)
    {
        if (hit.Child is TextBlock check) check.Opacity = isChecked ? 1 : 0;
    }

    private static bool GetCheck(Border hit) => hit.Child is TextBlock c && c.Opacity > 0.5;
    private static void ToggleCheck(Border hit) { if (hit.Child is TextBlock c) c.Opacity = c.Opacity > 0.5 ? 0 : 1; }

    private CancellationToken RestartFx()
    {
        _fx?.Cancel();
        _fx = new CancellationTokenSource();
        return _fx.Token;
    }

    private async void WaveOldWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= WaveOldWindow_Opened;
        _chrome.Opacity = 0;
        var token = RestartFx();
        try
        {
            await AnimateAsync(TimeSpan.FromMilliseconds(250),
                progress => _chrome.Opacity = progress,
                new QuarticEaseIn(), token);
        }
        catch (OperationCanceledException) { }
        _chrome.Opacity = 1;
    }

    private void WaveOldWindow_Closed(object? sender, EventArgs e)
    {
        _editorDisposed = true;
        _editor.IsVisible = false;
        _pendingEditorSnapshot?.TrySetCanceled();
        _editor.WebMessageReceived -= Editor_WebMessageReceived;
        _hubLoadCancellation?.Cancel();
        _hubLoadCancellation?.Dispose();
        _hubSearchTimer.Stop();
        _hubService.Dispose();

        if (!_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(_workspace);
        }
    }

    internal void CloseForOrion() { _closingForOrion = true; Close(); }

    private async void WaveOldWindow_KeyDown(object? sender, KeyEventArgs e)
    {
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
            OpenFileButton_Click(this, new RoutedEventArgs());
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

    // ─────────── title bar ───────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        if (e.ClickCount == 2)
        {
            WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
            return;
        }
        if (WindowState != WindowState.Maximized) BeginMoveDrag(e);
    }

    private void ExitButton_Click(object? sender, RoutedEventArgs e) => CloseForOrion();
    private void MaximizeButton_Click(object? sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
    }
    private void MinimizeButton_Click(object? sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    // ─────────── rail page switch ───────────

    private void EditorToggleButton_Click(object? sender, RoutedEventArgs e) => SwitchPage(WaveOldPage.Editor);
    private void ScriptCloudToggleButton_Click(object? sender, RoutedEventArgs e) => SwitchPage(WaveOldPage.ScriptCloud);
    private void SettingsToggleButton_Click(object? sender, RoutedEventArgs e) => SwitchPage(WaveOldPage.Settings);

    private void SwitchPage(WaveOldPage page)
    {
        if (_currentPage == page) return;
        _editorToggleButton.IsChecked = page == WaveOldPage.Editor;
        _scriptCloudToggleButton.IsChecked = page == WaveOldPage.ScriptCloud;
        _settingsToggleButton.IsChecked = page == WaveOldPage.Settings;

        var token = RestartFx();
        _ = FadeSwitchAsync(page, token);
        _currentPage = page;
    }

    private async Task FadeSwitchAsync(WaveOldPage page, CancellationToken token)
    {
        var incoming = page switch
        {
            WaveOldPage.Editor => _editorPage,
            WaveOldPage.ScriptCloud => _scriptCloudPage,
            WaveOldPage.Settings => _settingsPage,
            _ => _editorPage,
        };
        var outgoing = _currentPage switch
        {
            WaveOldPage.Editor => _editorPage,
            WaveOldPage.ScriptCloud => _scriptCloudPage,
            WaveOldPage.Settings => _settingsPage,
            _ => _editorPage,
        };

        if (outgoing != incoming)
        {
            try { await AnimateAsync(TimeSpan.FromMilliseconds(250), p => outgoing.Opacity = 1 - p, new QuarticEaseInOut(), token); }
            catch (OperationCanceledException) { return; }
            outgoing.Opacity = 0;
            outgoing.IsVisible = false;
        }

        incoming.Opacity = 0;
        incoming.IsVisible = true;
        try { await AnimateAsync(TimeSpan.FromMilliseconds(250), p => incoming.Opacity = p, new QuarticEaseInOut(), token); }
        catch (OperationCanceledException) { return; }
        incoming.Opacity = 1;
    }

    // ─────────── side panel toggle ───────────

    private bool _sidePanelAnimating;
    private async void SidePanelButton_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (_sidePanelAnimating) return;
        _sidePanelAnimating = true;
        _sidePanelOpen = !_sidePanelOpen;
        if (_sidePanelOpen) RefreshExplorerIfNeeded();
        double from = _sidePanel.Width;
        if (double.IsNaN(from)) from = 0;
        double to = _sidePanelOpen ? 230 : 0;
        var fromEditor = _editorPanel.Margin;
        var toEditor = new Thickness(_sidePanelOpen ? 230 : 0, 0, 0, 0);
        var token = RestartFx();
        try
        {
            await AnimateAsync(TimeSpan.FromMilliseconds(750),
                p =>
                {
                    _sidePanel.Width = Lerp(from, to, p);
                    _editorPanel.Margin = new Thickness(
                        Lerp(fromEditor.Left, toEditor.Left, p),
                        fromEditor.Top, fromEditor.Right, fromEditor.Bottom);
                },
                new QuarticEaseInOut(), token);
        }
        catch (OperationCanceledException) { }
        _sidePanel.Width = to;
        _editorPanel.Margin = toEditor;
        _sidePanelAnimating = false;
    }

    // ─────────── editor / tabs / monaco ───────────

    private void RevealEditor()
    {
        if (_editorDisposed || _currentPage != WaveOldPage.Editor) return;
        _editor.IsVisible = true;
        if (_editorSourceAssigned) return;
        _editorSourceAssigned = true;
        _editor.Source = new UriBuilder(_monacoAddress) { Query = "transparent=1" }.Uri;
    }

    private void RenderTabs()
    {
        _tabStrip.Children.Clear();
        foreach (var tab in _workspace.Tabs)
        {
            var visual = CreateTabVisual(tab);
            _tabStrip.Children.Add(visual);
        }
        var add = new Button
        {
            Width = 24,
            Height = 24,
            Padding = new Thickness(0),
            CornerRadius = new CornerRadius(6),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Cursor = new Cursor(StandardCursorType.Hand),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Margin = new Thickness(6, 0, 0, 0),
            Content = new Avalonia.Controls.Shapes.Path
            {
                Data = (Geometry?)Resources["WaveOldIconPlus"],
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
        add.Click += (_, _) => AddTab();
        _tabStrip.Children.Add(add);
    }

    private void AnimateTabEntrance(Border visual)
    {
        visual.Opacity = 0;
        var scaleTransform = new ScaleTransform(0.92, 0.92);
        visual.RenderTransformOrigin = new RelativePoint(0.5, 0.5, RelativeUnit.Relative);
        visual.RenderTransform = scaleTransform;
        _ = AnimateAsync(TimeSpan.FromMilliseconds(220),
            p =>
            {
                var eased = 1 - Math.Pow(1 - p, 3);
                visual.Opacity = eased;
                scaleTransform.ScaleX = 0.92 + 0.08 * eased;
                scaleTransform.ScaleY = 0.92 + 0.08 * eased;
            },
            null, _fx?.Token ?? CancellationToken.None);
    }

    private Border CreateTabVisual(EditorTabState tab)
    {
        var active = tab.Id == _activeTab.Id;
        var border = new Border
        {
            Height = 28,
            Padding = new Thickness(12, 0, 8, 0),
            CornerRadius = new CornerRadius(7),
            Background = new SolidColorBrush(active
                ? new Color(0xFF, 0x1D, 0x2E, 0x4C)
                : new Color(0x00, 0x16, 0x1C, 0x26)),
            BorderBrush = new SolidColorBrush(active
                ? new Color(0xFF, 0x20, 0x33, 0x54)
                : new Color(0x00, 0x22, 0x34, 0x52)),
            BorderThickness = new Thickness(1),
            VerticalAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Opacity = active ? 1.0 : 0.78,
        };
        border.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(180) },
            new BrushTransition { Property = Border.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(180) },
            new DoubleTransition { Property = Border.OpacityProperty, Duration = TimeSpan.FromMilliseconds(180) }
        };

        var grid = new Grid { ColumnDefinitions = new ColumnDefinitions("*,16") };

        var title = new TextBlock
        {
            Text = tab.Title,
            FontSize = 12,
            FontWeight = FontWeight.SemiBold,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            Foreground = new SolidColorBrush(active
                ? new Color(0xFF, 0xFF, 0xFF, 0xFF)
                : new Color(0xFF, 0xB9, 0xC6, 0xDC)),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 4, 0),
        };
        title.Transitions = new Transitions
        {
            new BrushTransition { Property = TextBlock.ForegroundProperty, Duration = TimeSpan.FromMilliseconds(180) }
        };
        title.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(border).Properties.IsLeftButtonPressed) SelectTab(tab);
        };
        Grid.SetColumn(title, 0);
        grid.Children.Add(title);

        var closeButton = new Button
        {
            Width = 16,
            Height = 16,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Cursor = new Cursor(StandardCursorType.Hand),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Opacity = active ? 1 : 0.5,
        };
        closeButton.Transitions = new Transitions
        {
            new DoubleTransition { Property = Button.OpacityProperty, Duration = TimeSpan.FromMilliseconds(120) }
        };
        var closePath = new Avalonia.Controls.Shapes.Path
        {
            Data = (Geometry?)Resources["WaveOldIconClose"],
            Width = 10,
            Height = 10,
            Stretch = Stretch.Uniform,
            Stroke = new SolidColorBrush(active
                ? new Color(0xFF, 0xFF, 0xFF, 0xFF)
                : new Color(0xFF, 0xB9, 0xC6, 0xDC)),
            StrokeThickness = 1.6,
            StrokeLineCap = PenLineCap.Round,
        };
        closeButton.Content = closePath;
        closeButton.PointerEntered += (_, _) => closeButton.Opacity = 1;
        closeButton.PointerExited += (_, _) => closeButton.Opacity = active ? 1 : 0.5;
        closeButton.Click += (_, _) => CloseTab(tab);
        Grid.SetColumn(closeButton, 1);
        grid.Children.Add(closeButton);

        title.DoubleTapped += (_, _) => BeginRenameTab(tab, title, border, closeButton);

        border.Child = grid;
        border.PointerPressed += (_, e) => { if (e.GetCurrentPoint(border).Properties.IsLeftButtonPressed) SelectTab(tab); };
        return border;
    }

    private void BeginRenameTab(EditorTabState tab, TextBlock title, Border border, Button closeButton)
    {
        if (!tab.Id.Equals(_activeTab.Id)) SelectTab(tab);
        if (tab.IsRenaming) return;

        tab.IsRenaming = true;
        var grid = (Grid)border.Child!;
        Grid.SetColumn(title, 0);
        grid.Children.Remove(title);
        var editor = new TextBox
        {
            Text = tab.Title,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            FontSize = 12,
            FontWeight = FontWeight.SemiBold,
            Foreground = new SolidColorBrush(Color.Parse("#FFFFFF")),
            Background = new SolidColorBrush(Color.Parse("#0A1424")),
            BorderBrush = new SolidColorBrush(Color.Parse("#267DE5")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(4),
            Padding = new Thickness(4, 0),
            MinHeight = 22,
            MinWidth = 60,
            VerticalAlignment = VerticalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(editor, 0);
        grid.Children.Insert(0, editor);
        editor.SelectAll();
        editor.Focus();

        var commit = new Action(() =>
        {
            if (!tab.IsRenaming) return;
            var newTitle = (editor.Text ?? string.Empty).Trim();
            if (!string.IsNullOrEmpty(newTitle)) tab.Title = newTitle;
            tab.IsRenaming = false;
            grid.Children.Remove(editor);
            grid.Children.Insert(0, title);
            title.Text = tab.Title;
            RenderTabs();
        });

        editor.KeyDown += (_, e) =>
        {
            if (e.Key == Key.Enter) { commit(); e.Handled = true; }
            else if (e.Key == Key.Escape)
            {
                tab.IsRenaming = false;
                grid.Children.Remove(editor);
                grid.Children.Insert(0, title);
                e.Handled = true;
            }
        };
        editor.LostFocus += (_, _) => commit();
    }

    private void AddTab()
    {
        var tab = NewTabState();
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        PushActiveTabToEditor();

        // Animate just the newly created tab (last Border before the + button).
        for (int i = _tabStrip.Children.Count - 1; i >= 0; i--)
        {
            if (_tabStrip.Children[i] is Border b)
            {
                AnimateTabEntrance(b);
                break;
            }
        }
    }

    private void SelectTab(EditorTabState tab)
    {
        if (_activeTab.Id == tab.Id) return;
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        PushActiveTabToEditor();
        _ = PulseActiveTabAsync();
    }

    private async Task PulseActiveTabAsync()
    {
        // Find the visual for the active tab and run a short "press" pulse.
        Border? visual = null;
        foreach (var child in _tabStrip.Children)
        {
            if (child is Border b && b.DataContext == _activeTab)
            {
                visual = b;
                break;
            }
        }
        if (visual is null)
        {
            // Fallback: pick the first border (active tab is the first by RenderTabs order).
            foreach (var child in _tabStrip.Children)
            {
                if (child is Border b) { visual = b; break; }
            }
        }
        if (visual is null) return;

        visual.RenderTransformOrigin = new RelativePoint(0.5, 0.5, RelativeUnit.Relative);
        var scale = visual.RenderTransform as ScaleTransform ?? new ScaleTransform(1, 1);
        visual.RenderTransform = scale;
        var token = RestartFx();
        try
        {
            await AnimateAsync(TimeSpan.FromMilliseconds(220),
                p =>
                {
                    var v = 1 - 0.06 * Math.Sin(p * Math.PI);
                    scale.ScaleX = v;
                    scale.ScaleY = v;
                },
                null, token);
        }
        catch (OperationCanceledException) { }
        scale.ScaleX = 1;
        scale.ScaleY = 1;
    }

    private void CloseTab(EditorTabState tab)
    {
        if (_workspace.Tabs.Count == 1)
        {
            return;
        }
        var index = _workspace.Tabs.IndexOf(tab);
        _workspace.Tabs.Remove(tab);
        if (_activeTab.Id == tab.Id)
        {
            _activeTab = _workspace.Tabs[Math.Max(0, index - 1)];
            _workspace.ActiveTabId = _activeTab.Id;
        }
        RenderTabs();
        PushActiveTabToEditor();
    }

    private void PushActiveTabToEditor()
    {
        if (!_editorReady || _activeTab is null) return;
        var content = JsonSerializer.Serialize(_activeTab.Content);
        var language = JsonSerializer.Serialize(LanguageForExtension(_activeTab.Extension));
        try
        {
            _editor.InvokeScript(
                $"window.orbitSetContent && window.orbitSetContent({content}, {language});");
        }
        catch (InvalidOperationException) { _editorReady = false; }
        ApplyEditorOptionsToMonaco();
    }

    private void ApplyEditorOptionsToMonaco()
    {
        if (!_editorReady) return;
        var options = new
        {
            minimap = new { enabled = _options.Minimap },
            fontSize = _options.FontSize
        };
        try
        {
            _editor.InvokeScript(
                $"window.orbitUpdateEditorOptions && window.orbitUpdateEditorOptions({JsonSerializer.Serialize(options)});");
        }
        catch (InvalidOperationException) { _editorReady = false; }
    }

    private static string LanguageForExtension(string ext) => ext.ToLowerInvariant() switch
    {
        ".luau" => "lua",
        ".lua" => "lua",
        ".txt" => "plaintext",
        ".json" => "json",
        ".js" => "javascript",
        ".ts" => "typescript",
        _ => "plaintext"
    };

    private async Task<string> RequestEditorContentAsync()
    {
        if (!_editorReady) return _activeTab?.Content ?? string.Empty;
        _pendingEditorSnapshot = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
        try
        {
            _editor.InvokeScript("window.orbitRequestContent && window.orbitRequestContent();");
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
            return _activeTab?.Content ?? string.Empty;
        }
        var timeout = Task.Delay(TimeSpan.FromSeconds(2));
        var finished = await Task.WhenAny(_pendingEditorSnapshot.Task, timeout);
        if (finished == timeout) return _activeTab?.Content ?? string.Empty;
        return await _pendingEditorSnapshot.Task;
    }

    private async void Editor_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
    {
        if (string.IsNullOrWhiteSpace(args.Body)) return;
        try
        {
            using var payload = JsonDocument.Parse(args.Body);
            var root = payload.RootElement;
            if (!root.TryGetProperty("type", out var typeProperty)) return;
            switch (typeProperty.GetString())
            {
                case "ready":
                    Dispatcher.UIThread.Post(() =>
                    {
                        _editorReady = true;
                        PushActiveTabToEditor();
                    });
                    break;

                case "contentSnapshot" when root.TryGetProperty("content", out var snapshotProperty):
                {
                    var content = snapshotProperty.GetString() ?? string.Empty;
                    var target = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        if (target is not null) target.Content = content;
                        _pendingEditorSnapshot?.TrySetResult(content);
                    });
                    break;
                }

                case "contentChanged" when root.TryGetProperty("content", out var changedProperty):
                {
                    // Monaco echoes the current document whenever it changes so the
                    // Save shortcut can flush without an extra round-trip.
                    var content = changedProperty.GetString() ?? string.Empty;
                    var target = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        if (target is not null) target.Content = content;
                    });
                    break;
                }
            }
        }
        catch (JsonException) { }
    }

    // ─────────── editor toolbar ───────────

    private async void OpenFileButton_Click(object? sender, RoutedEventArgs e)
    {
        try
        {
            var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            {
                Title = "Open script",
                AllowMultiple = false,
                FileTypeFilter = new[]
                {
                    new FilePickerFileType("Script files") { Patterns = new[] { "*.lua", "*.luau", "*.txt" } }
                }
            });
            var file = files.FirstOrDefault();
            if (file is null) return;
            await using var stream = await file.OpenReadAsync();
            using var reader = new StreamReader(stream);
            var content = await reader.ReadToEndAsync();
            OpenFileInTab(file.Name, content);
        }
        catch
        {
        }
    }

    private void OpenFileInTab(string fileName, string content)
    {
        var tab = new EditorTabState
        {
            Title = global::System.IO.Path.GetFileNameWithoutExtension(fileName),
            Extension = global::System.IO.Path.GetExtension(fileName) is { Length: > 0 } e ? e : ".lua",
            Content = content,
        };
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        if (_currentPage != WaveOldPage.Editor)
        {
            SwitchPage(WaveOldPage.Editor);
        }
        PushActiveTabToEditor();
    }

    private async void SaveFileButton_Click(object? sender, RoutedEventArgs e) => await SaveCurrentFileAsync();

    private async Task SaveCurrentFileAsync()
    {
        try
        {
            // Use the in-memory tab content (Monaco pushes deltas as the user types).
            // We do not request a snapshot from the webview here to keep Save instant.
            var currentContent = _activeTab?.Content ?? string.Empty;

            var suggested = SanitizeFileName(_activeTab?.Title ?? "script") + (_activeTab?.Extension ?? ".lua");
            var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
            {
                Title = "Save script",
                SuggestedFileName = suggested,
                DefaultExtension = "lua",
                ShowOverwritePrompt = true,
                FileTypeChoices = new[]
                {
                    new FilePickerFileType("Lua script") { Patterns = new[] { "*.lua" } },
                    new FilePickerFileType("Luau script") { Patterns = new[] { "*.luau" } },
                    new FilePickerFileType("Text file") { Patterns = new[] { "*.txt" } }
                }
            });
            if (file is null) return;

            await using (var stream = await file.OpenWriteAsync())
            {
                stream.SetLength(0);
                await using var writer = new StreamWriter(stream);
                await writer.WriteAsync(currentContent);
            }

            if (_activeTab is not null)
            {
                _activeTab.Title = global::System.IO.Path.GetFileNameWithoutExtension(file.Name);
                _activeTab.Extension = global::System.IO.Path.GetExtension(file.Name) is { Length: > 0 } ext ? ext : ".lua";
            }
            RenderTabs();
        }
        catch
        {
        }
    }

    private static string SanitizeFileName(string value)
    {
        var invalid = global::System.IO.Path.GetInvalidFileNameChars();
        var result = new string(value.Where(c => !invalid.Contains(c)).ToArray()).Trim();
        return string.IsNullOrEmpty(result) ? "script" : result;
    }

    private async void ClearButton_Click(object? sender, RoutedEventArgs e)
    {
        if (_activeTab is null) return;
        _activeTab.Content = string.Empty;
        try
        {
            _editor.InvokeScript("window.orbitSetContent && window.orbitSetContent(\"\", \"lua\");");
        }
        catch (InvalidOperationException) { _editorReady = false; }
        await Task.CompletedTask;
    }

    private async void ExecuteButton_Click(object? sender, RoutedEventArgs e) => await ExecuteCurrentScriptAsync();

    private async Task ExecuteCurrentScriptAsync()
    {
        if (_activeTab is null) return;
        var source = await RequestEditorContentAsync();
        _activeTab.Content = source;
        if (string.IsNullOrWhiteSpace(source)) return;
        ExecuteOnBridge(source);
    }

    private void ExecuteOnBridge(string source)
    {
        if (!_bridge.IsConnected) return;
        _bridge.EnqueueExecute(source);
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
            await AnimateAsync(TimeSpan.FromMilliseconds(260),
                p => { var v = 1 - 0.07 * Math.Sin(p * Math.PI); scale.ScaleX = v; scale.ScaleY = v; },
                null, token);
        }
        catch (OperationCanceledException) { }
        scale.ScaleX = 1;
        scale.ScaleY = 1;
    }

    private void Settings_Click(object? sender, RoutedEventArgs e) => SwitchPage(WaveOldPage.Settings);

    // ─────────── script cloud (script hub) ───────────

    private void LoadHubCards(bool append)
    {
        if (_hubLoading) return;
        if (!append)
        {
            _hubLoadCancellation?.Cancel();
            _hubLoadCancellation?.Dispose();
            _hubLoadCancellation = new CancellationTokenSource();
            _hubCards.Clear();
            _hubCardKeys.Clear();
            _hubPage = 1;
        }
        var cancellation = _hubLoadCancellation ??= new CancellationTokenSource();
        var version = ++_hubLoadVersion;
        _hubLoading = true;
        _hubEmpty.Text = "Searching scripts…";
        _hubEmpty.IsVisible = !append;
        _ = LoadHubCardsCore(append, version, cancellation.Token);
    }

    private async Task LoadHubCardsCore(bool append, int version, CancellationToken cancellation)
    {
        try
        {
            var query = (_hubSearch.Text ?? string.Empty).Trim();
            var result = await _hubService.FetchAsync(
                _hubProvider, query, append ? _hubPage + 1 : 1, cancellation);
            await _hubService.LoadThumbnailsAsync(result.Cards, cancellation);
            if (version != _hubLoadVersion || cancellation.IsCancellationRequested) return;

            var added = result.Cards.Where(card => _hubCardKeys.Add(card.Key)).ToArray();
            _hubCards.AddRange(added);
            _hubPage = append ? _hubPage + 1 : 1;
            _hubHasMore = result.HasMore && added.Length > 0;
            _hubList.ItemsSource = _hubCards.ToList();

            if (_hubCards.Count == 0)
            {
                _hubEmpty.Text = query.Length == 0
                    ? "No scripts are available right now"
                    : $"No scripts matching \"{query}\"";
                _hubEmpty.IsVisible = true;
            }
            else _hubEmpty.IsVisible = false;
        }
        catch (OperationCanceledException) { }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or InvalidDataException or TaskCanceledException)
        {
            if (version == _hubLoadVersion)
            {
                _hubEmpty.Text = "Couldn't load scripts — the hub is unavailable right now";
                _hubEmpty.IsVisible = true;
            }
        }
        finally
        {
            if (version == _hubLoadVersion) _hubLoading = false;
        }
    }

    private void HubSearchTimer_Tick(object? sender, EventArgs e)
    {
        _hubSearchTimer.Stop();
        LoadHubCards(append: false);
    }

    private void HubSearch_TextChanged(object? sender, TextChangedEventArgs e)
    {
        _hubSearchTimer.Stop();
        _hubSearchTimer.Start();
    }

    private void HubRefresh_Click(object? sender, RoutedEventArgs e) => LoadHubCards(append: false);

    private void HubProvider_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string tag }) return;
        if (!Enum.TryParse<ScriptHubProvider>(tag, out var provider)) return;
        _hubProvider = provider;
        UpdateProviderButtons();
        LoadHubCards(append: false);
    }

    private void UpdateProviderButtons()
    {
        var activeName = _hubProvider.ToString();
        foreach (var name in new[] { "ScriptBlox", "Rscripts", "RobloxScripts", "HaxHell" })
        {
            if (this.FindControl<Button>($"HubProvider{name}") is { } btn)
            {
                btn.Classes.Set("active", name == activeName);
            }
        }
    }

    private async void HubList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_hubList.SelectedItem is not ScriptHubCardModel card) return;
        _hubList.SelectedItem = null;
        if (string.IsNullOrWhiteSpace(card.ScriptBody)) return;
        var tab = new EditorTabState
        {
            Title = card.Title.EndsWith(".lua", StringComparison.OrdinalIgnoreCase)
                ? card.Title
                : card.Title + ".lua",
            Content = card.ScriptBody,
            Extension = ".lua"
        };
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        if (_currentPage != WaveOldPage.Editor) SwitchPage(WaveOldPage.Editor);
        PushActiveTabToEditor();
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
            Background = new SolidColorBrush(Color.Parse("#1D1D1E")),
            Child = thumbnail
        });
        var text = new StackPanel { Spacing = 2, VerticalAlignment = VerticalAlignment.Center, Width = 140 };
        text.Children.Add(new TextBlock
        {
            Text = card?.Title ?? string.Empty,
            FontSize = 12,
            FontWeight = FontWeight.Medium,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            Foreground = new SolidColorBrush(Color.Parse("#EAF2FF")),
            TextTrimming = TextTrimming.CharacterEllipsis
        });
        text.Children.Add(new TextBlock
        {
            Text = card?.Subtitle ?? string.Empty,
            FontSize = 10.5,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            Foreground = new SolidColorBrush(Color.Parse("#8CA0BA")),
            TextTrimming = TextTrimming.CharacterEllipsis
        });
        panel.Children.Add(text);

        var card1 = new Border
        {
            Width = 210,
            Height = 46,
            CornerRadius = new CornerRadius(6),
            Background = new SolidColorBrush(Color.Parse("#1D1D1E")),
            BorderBrush = new SolidColorBrush(Color.Parse("#2C2C2D")),
            BorderThickness = new Thickness(1),
            Child = panel,
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        card1.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(140) }
        };
        card1.PointerEntered += (_, _) => card1.Background = new SolidColorBrush(Color.Parse("#27272A"));
        card1.PointerExited += (_, _) => card1.Background = new SolidColorBrush(Color.Parse("#1D1D1E"));
        return card1;
    }

    // ─────────── settings ───────────

    private void SettingsExecutorToggleButton_Click(object? sender, RoutedEventArgs e)
    {
        if (this.FindControl<Grid>("SettingsExecutorSection") is { } s) s.BringIntoView();
    }
    private void SettingsEditorToggleButton_Click(object? sender, RoutedEventArgs e)
    {
        if (this.FindControl<Grid>("SettingsEditorSection") is { } s) s.BringIntoView();
    }
    private void SettingsAiToggleButton_Click(object? sender, RoutedEventArgs e)
    {
        if (this.FindControl<Grid>("SettingsAiSection") is { } s) s.BringIntoView();
    }

    private void TopMostHit_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (e.Handled) return;
        e.Handled = true;
        if (sender is not Border b) return;
        _options.TopMost = !_options.TopMost;
        SetCheck(b, _options.TopMost);
        Topmost = _options.TopMost;
        if (_options.TopMost) Activate();
        PersistOptions();
    }
    private void MinimapHit_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (sender is not Border b) return;
        ToggleCheck(b);
        _options.Minimap = GetCheck(b);
        PersistOptions();
        ApplyEditorOptionsToMonaco();
    }
    private void FontSizeSlider_ValueChanged(object? sender, Avalonia.Controls.Primitives.RangeBaseValueChangedEventArgs e)
    {
        if (sender is not Slider s) return;
        if (this.FindControl<TextBlock>("FontSizeValue") is { } v) v.Text = ((int)s.Value).ToString();
        _options.FontSize = (int)s.Value;
        PersistOptions();
        ApplyEditorOptionsToMonaco();
    }
    private void PersistOptions() => WaveOldOptionsStore.Save(_options);

    // ─────────── explorer ───────────

    private void RefreshExplorer()
    {
        _sectionFiles.Clear();
        foreach (var section in _explorerSections)
        {
            var directory = section.Id == "Scripts" ? _scriptsDirectory : _workspaceDirectory;
            _sectionFiles[section.Id] = string.IsNullOrEmpty(directory)
                ? []
                : ListScriptFiles(directory);
        }
        RebuildExplorerTree();
    }

    private void RebuildExplorerTree()
    {
        var tree = this.FindControl<StackPanel>("ExplorerTree");
        if (tree is null) return;
        tree.Children.Clear();
        _sectionChildren.Clear();
        foreach (var section in _explorerSections)
        {
            var expanded = _openSectionId == section.Id;
            tree.Children.Add(BuildSectionHeader(section, expanded));

            var children = new StackPanel { Spacing = 1, Margin = new Thickness(14, 2, 0, 6), IsVisible = expanded };
            var files = _sectionFiles.TryGetValue(section.Id, out var value) ? value : [];
            if (files.Count == 0)
            {
                children.Children.Add(new TextBlock
                {
                    Text = "Empty",
                    FontSize = 10.5,
                    Foreground = new SolidColorBrush(Color.Parse("#55688A")),
                    Margin = new Thickness(11, 4, 0, 5)
                });
            }
            else
            {
                foreach (var file in files)
                {
                    children.Children.Add(BuildFileRow(section, file));
                }
            }
            tree.Children.Add(children);
            _sectionChildren[section.Id] = children;
        }
    }

    private Control BuildSectionHeader(WaveOldExplorerSection section, bool expanded)
    {
        var header = new Button
        {
            Height = 30,
            Padding = new Thickness(11, 0),
            Margin = new Thickness(0, 2, 0, 2),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Left,
            VerticalContentAlignment = VerticalAlignment.Center,
            CornerRadius = new CornerRadius(7),
            Background = new SolidColorBrush(Color.Parse(expanded ? "#1F3358" : "#19243E")),
            BorderBrush = new SolidColorBrush(Color.Parse(expanded ? "#31476F" : "#26385E")),
            BorderThickness = new Thickness(1),
            Cursor = new Cursor(StandardCursorType.Hand),
        };
        header.Transitions = new Transitions
        {
            new BrushTransition { Property = Button.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(140) },
            new BrushTransition { Property = Button.BorderBrushProperty, Duration = TimeSpan.FromMilliseconds(140) }
        };

        var content = new Grid();
        content.ColumnDefinitions.Add(new ColumnDefinition(16, GridUnitType.Pixel));
        content.ColumnDefinitions.Add(new ColumnDefinition(1, GridUnitType.Star));
        content.ColumnDefinitions.Add(new ColumnDefinition(14, GridUnitType.Pixel));

        var folderIcon = new Avalonia.Controls.Shapes.Path
        {
            Data = (Geometry?)Resources["WaveOldIconFolder"],
            Width = 14,
            Height = 14,
            Stretch = Stretch.Uniform,
            Fill = new SolidColorBrush(Color.Parse("#B9C6DC")),
        };
        Grid.SetColumn(folderIcon, 0);
        content.Children.Add(folderIcon);

        var title = new TextBlock
        {
            Text = section.Title,
            FontSize = 12,
            FontWeight = FontWeight.SemiBold,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            Foreground = new SolidColorBrush(Color.Parse("#EAF2FF")),
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(8, 0, 0, 0),
        };
        Grid.SetColumn(title, 1);
        content.Children.Add(title);

        var chevron = new Avalonia.Controls.Shapes.Path
        {
            Data = (Geometry?)Resources["WaveOldIconChevronRight"],
            Width = 11,
            Height = 11,
            Stretch = Stretch.Uniform,
            Fill = new SolidColorBrush(Color.Parse("#7E93B4")),
        };
        chevron.RenderTransformOrigin = new RelativePoint(0.5, 0.5, RelativeUnit.Relative);
        chevron.RenderTransform = new RotateTransform(expanded ? 90 : 0);
        Grid.SetColumn(chevron, 2);
        content.Children.Add(chevron);

        header.Content = content;
        header.Click += (_, _) => ToggleExplorerSection(section.Id);
        return header;
    }

    private void ToggleExplorerSection(string id)
    {
        _openSectionId = _openSectionId == id ? null : id;
        RebuildExplorerTree();
    }

    private Control BuildFileRow(WaveOldExplorerSection section, WaveOldScriptItem file)
    {
        var row = new Button
        {
            Padding = new Thickness(8, 4),
            Margin = new Thickness(0, 1, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Left,
            VerticalContentAlignment = VerticalAlignment.Center,
            CornerRadius = new CornerRadius(5),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            Cursor = new Cursor(StandardCursorType.Hand),
        };
        row.Transitions = new Transitions
        {
            new BrushTransition { Property = Button.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(120) }
        };
        row.PointerEntered += (_, _) => row.Background = new SolidColorBrush(Color.Parse("#172846"));
        row.PointerExited += (_, _) => row.Background = Brushes.Transparent;

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition(12, GridUnitType.Pixel));
        grid.ColumnDefinitions.Add(new ColumnDefinition(1, GridUnitType.Star));

        var fileIcon = new Avalonia.Controls.Shapes.Path
        {
            Data = (Geometry?)Resources["WaveOldIconOpen"],
            Width = 11,
            Height = 11,
            Stretch = Stretch.Uniform,
            Fill = new SolidColorBrush(Color.Parse("#7E93B4")),
            VerticalAlignment = VerticalAlignment.Center,
        };
        Grid.SetColumn(fileIcon, 0);
        grid.Children.Add(fileIcon);

        var name = new TextBlock
        {
            Text = file.Name,
            FontSize = 11.5,
            FontFamily = new FontFamily("avares://Orion/Assets/WaveOld#Izmir"),
            Foreground = new SolidColorBrush(Color.Parse("#D8E0EC")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(6, 0, 0, 0),
        };
        Grid.SetColumn(name, 1);
        grid.Children.Add(name);

        row.Content = grid;
        row.Click += (_, _) =>
        {
            try
            {
                if (!File.Exists(file.FullPath)) return;
                var content = File.ReadAllText(file.FullPath);
                OpenFileInTab(file.Name, content);
            }
            catch { }
        };
        return row;
    }

    private static List<WaveOldScriptItem> ListScriptFiles(string directory)
    {
        var files = new List<WaveOldScriptItem>();
        try
        {
            if (!string.IsNullOrEmpty(directory)) Directory.CreateDirectory(directory);
            files.AddRange(Directory.EnumerateFiles(directory)
                .Where(p => new[] { ".lua", ".luau", ".txt" }
                    .Contains(global::System.IO.Path.GetExtension(p), StringComparer.OrdinalIgnoreCase))
                .OrderBy(p => global::System.IO.Path.GetFileName(p), StringComparer.OrdinalIgnoreCase)
                .Select(p => new WaveOldScriptItem(global::System.IO.Path.GetFileName(p), p)));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        return files;
    }

    private void RefreshExplorerIfNeeded()
    {
        if (_explorerInitialized) return;
        _explorerInitialized = true;
        RefreshExplorer();
        _openSectionId = "Scripts";
        RebuildExplorerTree();
    }

    // ─────────── helpers ───────────

    private static double Lerp(double a, double b, double t) => a + (b - a) * t;

    private static async Task AnimateAsync(TimeSpan duration, Action<double> apply, Easing? easing, CancellationToken token)
    {
        var start = DateTime.UtcNow;
        while (!token.IsCancellationRequested)
        {
            var elapsed = DateTime.UtcNow - start;
            if (elapsed >= duration) break;
            var t = elapsed.TotalMilliseconds / duration.TotalMilliseconds;
            try { apply(easing?.Ease(t) ?? t); } catch { }
            await Task.Delay(16, token);
        }
    }
}

internal static class VisualTreeHelpers
{
    public static IEnumerable<Visual> GetVisualAncestors(this Visual v)
    {
        var cur = v.Parent as Visual;
        while (cur != null) { yield return cur; cur = cur.Parent as Visual; }
    }
}
