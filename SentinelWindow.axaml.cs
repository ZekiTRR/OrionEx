using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class SentinelWindow : Window
{
    private const int MaximumTabs = 8;

    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly List<EditorTabState> _tabs = [];
    private readonly SentinelOptions _options;

    private EditorTabState _activeTab = null!;
    private NativeWebView? _webView;
    private MonacoStaticServer? _uiServer;
    private bool _webViewReady;
    private bool _webViewNavigationStarted;
    private bool _webViewDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;
    private bool _showingOutput;
    private bool _unlockFpsSent;
    private TaskCompletionSource<string>? _pendingSnapshot;
    private ListBox? _scriptsList;
    private StackPanel? _tabStrip;
    private ScrollViewer? _tabScroll;
    private StackPanel? _consoleOutput;
    private ScrollViewer? _consoleScroll;
    private Border? _consolePanel;
    private SentinelSettingsWindow? _settingsWindow;
    private SentinelScriptHubWindow? _hubWindow;

    public SentinelWindow() : this(
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal SentinelWindow(
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _scriptsDirectory = scriptsDirectory;
        _workspace = initialWorkspace.CloneDetached();
        _returnToOrion = returnToOrion;
        _options = SentinelOptionsStore.Load();

        AvaloniaXamlLoader.Load(this);
        _webView = this.FindControl<NativeWebView>("EditorWebView");
        _scriptsList = this.FindControl<ListBox>("ScriptsList");
        _tabStrip = this.FindControl<StackPanel>("TabStrip");
        _tabScroll = this.FindControl<ScrollViewer>("TabScroll");
        _consoleOutput = this.FindControl<StackPanel>("ConsoleOutput");
        _consoleScroll = this.FindControl<ScrollViewer>("ConsoleScroll");
        _consolePanel = this.FindControl<Border>("ConsolePanel");

        _tabs.AddRange(_workspace.Tabs);
        if (_tabs.Count == 0)
        {
            _tabs.Add(new EditorTabState { Title = "New Tab", Extension = ".lua" });
        }
        _activeTab = _tabs.FirstOrDefault(tab => tab.Id == _workspace.ActiveTabId) ?? _tabs[0];

        Topmost = _options.TopMost;
        RebuildTabs();

        if (_webView is not null)
        {
            _webView.WebMessageReceived += EditorWebView_WebMessageReceived;
        }
        _bridge.LogReceived += Bridge_LogReceived;
        _bridge.ConnectionChanged += Bridge_ConnectionChanged;
        Closed += SentinelWindow_Closed;
        Opened += SentinelWindow_Opened;
        KeyDown += SentinelWindow_KeyDown;
    }

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "New Tab", Extension = ".lua", Content = "print(\"I love life\")" };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private void SentinelWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SentinelWindow_Opened;
        RefreshScriptList();
        RevealEditor();
        SeedConsoleFromBridge();
        StartEdgeWatcher();
    }

    private void SentinelWindow_Closed(object? sender, EventArgs e)
    {
        WriteTrace($"Closed: closingForOrion={_closingForOrion} returnRequested={_returnRequested}");
        _webViewDisposed = true;
        _edgeTimer?.Stop();
        if (_webView is not null)
        {
            _webView.WebMessageReceived -= EditorWebView_WebMessageReceived;
        }
        _bridge.LogReceived -= Bridge_LogReceived;
        _bridge.ConnectionChanged -= Bridge_ConnectionChanged;
        _pendingSnapshot?.TrySetCanceled();
        _uiServer?.Dispose();

        _settingsWindow?.Close();
        _hubWindow?.Close();

        SentinelOptionsStore.Save(_options);
    }

    private static void WriteTrace(string message)
    {
        try
        {
            System.IO.File.AppendAllText(
                System.IO.Path.Combine(System.IO.Path.GetTempPath(), "orion-handoff.log"),
                $"{DateTime.Now:HH:mm:ss.fff} [Sentinel] {message}\n");
        }
        catch { }
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        Close();
    }

    internal async Task RequestReturnToOrionAsync()
    {
        if (_returnRequested)
        {
            return;
        }

        _returnRequested = true;
        _closingForOrion = true;
        WriteTrace("RequestReturnToOrionAsync start");
        try
        {
            _activeTab.Content = await RequestEditorContentAsync();
        }
        catch
        {
        }

        try
        {
            PersistWorkspace();
        }
        catch
        {
        }

        try
        {
            _returnToOrion(_workspace.CloneDetached());
            WriteTrace("RequestReturnToOrionAsync: _returnToOrion returned");
        }
        catch (Exception ex)
        {
            WriteTrace("RequestReturnToOrionAsync failed: " + ex);
        }
    }

    private void PersistWorkspace()
    {
        _workspace.Tabs.Clear();
        _workspace.Tabs.AddRange(_tabs);
        _workspace.ActiveTabId = _activeTab.Id;
    }

    // ─────────────────────── title bar & edge resize ───────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Avalonia.Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        if (WindowState != WindowState.Maximized) BeginMoveDrag(e);
    }

    private void EditorMinimize_Click(object? s, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void EditorClose_Click(object? s, RoutedEventArgs e) => _ = RequestReturnToOrionAsync();

    [DllImport("user32.dll")]
    private static extern bool GetCursorPos(out NativePoint p);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern IntPtr LoadCursor(IntPtr hInstance, IntPtr lpCursorName);

    [DllImport("user32.dll")]
    private static extern IntPtr SetCursor(IntPtr hCursor);

    [DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out NativeRect r);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [StructLayout(LayoutKind.Sequential)]
    private struct NativePoint { public int X, Y; }

    [StructLayout(LayoutKind.Sequential)]
    private struct NativeRect { public int Left, Top, Right, Bottom; }

    private const int VkLbutton = 0x01;
    private const uint SwpNozorder = 0x0004;
    private const int EdgeGrip = 8;

    private static readonly IntPtr CursorArrow = LoadCursor(IntPtr.Zero, new IntPtr(32512));
    private static readonly IntPtr CursorWe = LoadCursor(IntPtr.Zero, new IntPtr(32644));
    private static readonly IntPtr CursorNs = LoadCursor(IntPtr.Zero, new IntPtr(32645));
    private static readonly IntPtr CursorNwse = LoadCursor(IntPtr.Zero, new IntPtr(32642));
    private static readonly IntPtr CursorNesw = LoadCursor(IntPtr.Zero, new IntPtr(32643));

    private DispatcherTimer? _edgeTimer;
    private string? _lastEdgeZone;
    private bool _nativeResizing;

    private IntPtr NativeHandle => TryGetPlatformHandle()?.Handle ?? IntPtr.Zero;

    private void StartEdgeWatcher()
    {
        _edgeTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        _edgeTimer.Tick += (_, _) => UpdateEdgeCursor();
        _edgeTimer.Start();
    }

    private void UpdateEdgeCursor()
    {
        if (_nativeResizing)
        {
            return;
        }

        var handle = NativeHandle;
        if (handle == IntPtr.Zero || WindowState != WindowState.Normal ||
            GetForegroundWindow() != handle)
        {
            return;
        }

        GetWindowRect(handle, out var rect);
        GetCursorPos(out var cursor);

        var width = rect.Right - rect.Left;
        var height = rect.Bottom - rect.Top;
        var relX = cursor.X - rect.Left;
        var relY = cursor.Y - rect.Top;

        if (relX < 0 || relY < 0 || relX > width || relY > height)
        {
            return;
        }

        var zone = string.Empty;
        if (relY <= EdgeGrip && relX <= EdgeGrip) zone = "LT";
        else if (relY <= EdgeGrip && relX >= width - EdgeGrip) zone = "RT";
        else if (relY >= height - EdgeGrip && relX <= EdgeGrip) zone = "LB";
        else if (relY >= height - EdgeGrip && relX >= width - EdgeGrip) zone = "RB";
        else if (relX <= EdgeGrip) zone = "L";
        else if (relX >= width - EdgeGrip) zone = "R";
        else if (relY <= EdgeGrip) zone = "T";
        else if (relY >= height - EdgeGrip) zone = "B";

        if (zone.Length == 0)
        {
            // Reset the resize cursor once after leaving an edge zone. Forcing
            // it every tick fights the I-beam/hand cursors of the WebView and
            // buttons and makes the cursor flicker all over the window.
            if (_lastEdgeZone is not null)
            {
                _lastEdgeZone = null;
                SetCursor(CursorArrow);
            }

            return;
        }

        _lastEdgeZone = zone;
        SetCursor(zone is "LT" or "RB" ? CursorNwse : zone is "RT" or "LB" ? CursorNesw : zone is "L" or "R" ? CursorWe : CursorNs);

        if ((GetAsyncKeyState(VkLbutton) & 0x8000) != 0)
        {
            _nativeResizing = true;
            var startCursor = cursor;
            var startRect = rect;
            var thread = new System.Threading.Thread(() => ResizeLoop(handle, startRect, startCursor, zone))
            {
                IsBackground = true
            };
            thread.Start();
        }
    }

    private void ResizeLoop(IntPtr handle, NativeRect start, NativePoint startCursor, string zone)
    {
        try
        {
            const int minWidth = 600;
            const int minHeight = 340;

            while ((GetAsyncKeyState(VkLbutton) & 0x8000) != 0)
            {
                GetCursorPos(out var cursor);
                var dx = cursor.X - startCursor.X;
                var dy = cursor.Y - startCursor.Y;

                var left = start.Left;
                var top = start.Top;
                var right = start.Right;
                var bottom = start.Bottom;

                if (zone.Contains('L'))
                {
                    left += dx;
                    if (right - left < minWidth) left = right - minWidth;
                }

                if (zone.Contains('R'))
                {
                    right += dx;
                    if (right - left < minWidth) right = left + minWidth;
                }

                if (zone.Contains('T'))
                {
                    top += dy;
                    if (bottom - top < minHeight) top = bottom - minHeight;
                }

                if (zone.Contains('B'))
                {
                    bottom += dy;
                    if (bottom - top < minHeight) bottom = top + minHeight;
                }

                SetWindowPos(handle, IntPtr.Zero, left, top, right - left, bottom - top, SwpNozorder);
                System.Threading.Thread.Sleep(10);
            }
        }
        catch { }
        finally
        {
            _nativeResizing = false;
        }
    }

    // ─────────────────────── Monaco bridge ───────────────────────

    private void RevealEditor()
    {
        if (_webViewDisposed || _webView is null) return;
        _webView.IsVisible = !_showingOutput;
        if (_webViewNavigationStarted) return;
        _webViewNavigationStarted = true;
        try
        {
            var uiRoot = System.IO.Path.Combine(AppContext.BaseDirectory, "MonacoPreview");
            _uiServer = new MonacoStaticServer(uiRoot);
            var address = new UriBuilder(_uiServer.Address) { Query = "bg=%23181818" };
            _webView.Source = address.Uri;
        }
        catch (Exception ex)
        {
            AppendConsoleLine("error", "Editor failed to start: " + ex.Message);
        }
    }

    private void EditorWebView_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
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
                        _webViewReady = true;
                        PushActiveTabToEditor();
                    });
                    break;

                case "contentChanged" when root.TryGetProperty("content", out var contentProperty):
                {
                    var content = contentProperty.GetString() ?? string.Empty;
                    Dispatcher.UIThread.Post(() => _activeTab.Content = content);
                    break;
                }

                case "contentChangedDelta" when root.TryGetProperty("changes", out var changesProperty):
                {
                    var changes = changesProperty.Clone();
                    Dispatcher.UIThread.Post(() =>
                    {
                        if (EditorContentDelta.TryApply(changes, _activeTab.Content, out var content))
                        {
                            _activeTab.Content = content;
                        }
                    });
                    break;
                }

                case "contentSnapshot" when root.TryGetProperty("content", out var snapshotProperty):
                {
                    var content = snapshotProperty.GetString() ?? string.Empty;
                    Dispatcher.UIThread.Post(() =>
                    {
                        _activeTab.Content = content;
                        _pendingSnapshot?.TrySetResult(content);
                    });
                    break;
                }

                case "executeRequested" when root.TryGetProperty("content", out var executeProperty):
                {
                    var content = executeProperty.GetString() ?? string.Empty;
                    Dispatcher.UIThread.Post(() =>
                    {
                        _activeTab.Content = content;
                        _bridge.EnqueueExecute(content);
                    });
                    break;
                }
            }
        }
        catch (JsonException)
        {
            // Ignore browser messages that are not emitted by the editor bridge.
        }
    }

    private void PushActiveTabToEditor()
    {
        if (!_webViewReady || _webView is null)
        {
            return;
        }

        var content = JsonSerializer.Serialize(_activeTab.Content);
        var language = JsonSerializer.Serialize(LanguageForExtension(_activeTab.Extension));
        try
        {
            _webView.InvokeScript(
                $"window.orbitSetContent && window.orbitSetContent({content}, {language});");
        }
        catch (InvalidOperationException)
        {
            _webViewReady = false;
        }
    }

    private async Task<string> RequestEditorContentAsync()
    {
        if (!_webViewReady || _webView is null || _showingOutput)
        {
            return _activeTab.Content;
        }

        _pendingSnapshot?.TrySetCanceled();
        var completion = new TaskCompletionSource<string>(
            TaskCreationOptions.RunContinuationsAsynchronously);
        _pendingSnapshot = completion;

        try
        {
            await _webView.InvokeScript(
                "window.orionRequestSnapshot && window.orionRequestSnapshot();");
        }
        catch
        {
            _webViewReady = false;
            _pendingSnapshot = null;
            return _activeTab.Content;
        }

        try
        {
            var completed = await Task.WhenAny(completion.Task, Task.Delay(700));
            return completed == completion.Task
                ? await completion.Task
                : _activeTab.Content;
        }
        catch
        {
            return _activeTab.Content;
        }
        finally
        {
            if (ReferenceEquals(_pendingSnapshot, completion))
            {
                _pendingSnapshot = null;
            }
        }
    }

    private static string LanguageForExtension(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".json" => "json",
            ".js" or ".ts" => "javascript",
            ".txt" => "plaintext",
            _ => "lua"
        };

    // ─────────────────────── tabs ───────────────────────

    private void RebuildTabs()
    {
        if (_tabStrip is null)
        {
            return;
        }

        _tabStrip.Children.Clear();
        _tabStrip.Children.Add(BuildOutputTab());

        Border? activeVisual = null;
        foreach (var tab in _tabs)
        {
            var visual = BuildScriptTab(tab);
            _tabStrip.Children.Add(visual);
            if (!_showingOutput && tab.Id == _activeTab.Id)
            {
                activeVisual = visual;
            }
        }

        _tabStrip.Children.Add(BuildAddTabButton());
        activeVisual?.BringIntoView();
    }

    private void TabScroll_PointerWheelChanged(object? sender, PointerWheelEventArgs e)
    {
        if (_tabScroll is not { } scroll || scroll.Extent.Width <= scroll.Viewport.Width)
        {
            return;
        }

        var delta = e.Delta.Y != 0 ? e.Delta.Y : e.Delta.X;
        var maxOffset = scroll.Extent.Width - scroll.Viewport.Width;
        scroll.Offset = scroll.Offset.WithX(Math.Clamp(scroll.Offset.X - delta * 48, 0, maxOffset));
        e.Handled = true;
    }

    private Border BuildOutputTab()
    {
        var isActive = _showingOutput;
        var border = new Border
        {
            Height = 23,
            Padding = new Thickness(7, 0),
            MinWidth = 69,
            Background = isActive
                ? new SolidColorBrush(Color.Parse("#565656"))
                : Brushes.Transparent,
            Cursor = new Cursor(StandardCursorType.Hand),
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Stretch
        };
        border.Child = new TextBlock
        {
            Text = "Output",
            FontSize = 12,
            Foreground = new SolidColorBrush(Color.Parse("#F4F4F4")),
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
        };
        border.PointerPressed += (_, eventArgs) =>
        {
            if (!eventArgs.GetCurrentPoint(this).Properties.IsLeftButtonPressed) return;
            eventArgs.Handled = true;
            ShowOutput();
        };
        return border;
    }

    private Border BuildScriptTab(EditorTabState tab)
    {
        var isActive = !_showingOutput && tab.Id == _activeTab.Id;
        var foreground = Color.Parse(isActive ? "#F4F4F4" : "#B7B7B7");
        var border = new Border
        {
            Height = 23,
            MinWidth = 69,
            Padding = new Thickness(7, 0),
            Background = new SolidColorBrush(Color.Parse(isActive ? "#565656" : "#202020")),
            Cursor = new Cursor(StandardCursorType.Hand),
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Stretch,
            Margin = new Thickness(0, 0, 0, 0)
        };

        var grid = new Grid { ColumnDefinitions = new ColumnDefinitions("*,14"), Margin = new Thickness(0, 0, 0, 0) };
        grid.Children.Add(new TextBlock
        {
            Text = tab.Title,
            FontSize = 12,
            Foreground = new SolidColorBrush(foreground),
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis
        });

        var close = new TextBlock
        {
            Text = "×",
            FontSize = 14,
            Foreground = new SolidColorBrush(foreground),
            HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Right,
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
        };
        close.PointerPressed += (_, eventArgs) =>
        {
            if (!eventArgs.GetCurrentPoint(this).Properties.IsLeftButtonPressed) return;
            eventArgs.Handled = true;
            CloseTab(tab);
        };
        Grid.SetColumn(close, 1);
        grid.Children.Add(close);

        border.Child = grid;
        border.PointerPressed += (_, eventArgs) =>
        {
            if (!eventArgs.GetCurrentPoint(this).Properties.IsLeftButtonPressed) return;
            eventArgs.Handled = true;
            if (tab.Id != _activeTab.Id || _showingOutput)
            {
                ShowTab(tab);
            }
        };
        return border;
    }

    private Border BuildAddTabButton()
    {
        var border = new Border
        {
            Width = 25,
            Height = 23,
            Background = Brushes.Transparent,
            Cursor = new Cursor(StandardCursorType.Hand),
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Stretch
        };
        border.Child = new TextBlock
        {
            Text = "+",
            FontSize = 17,
            Foreground = new SolidColorBrush(Color.Parse("#B7B7B7")),
            HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Center,
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
        };
        border.PointerPressed += (_, eventArgs) =>
        {
            if (!eventArgs.GetCurrentPoint(this).Properties.IsLeftButtonPressed) return;
            eventArgs.Handled = true;
            AddTab();
        };
        ToolTip.SetTip(border, "New tab");
        return border;
    }

    private void ShowTab(EditorTabState tab)
    {
        _showingOutput = false;
        _activeTab = tab;
        if (_consolePanel is { } console) console.IsVisible = false;
        if (_webView is { } webView && !_webViewDisposed) webView.IsVisible = true;
        PushActiveTabToEditor();
        RebuildTabs();
    }

    private void ShowOutput()
    {
        _showingOutput = true;
        if (_webView is { } webView) webView.IsVisible = false;
        if (_consolePanel is { } console) console.IsVisible = true;
        RebuildTabs();
    }

    private void AddTab()
    {
        if (_tabs.Count >= MaximumTabs)
        {
            AppendConsoleLine("warn", "Maximum tabs reached");
            return;
        }

        var number = 1;
        string title;
        do
        {
            title = number == 1 ? "New Tab" : $"New Tab {number}";
            number++;
        }
        while (_tabs.Any(tab => tab.Title.Equals(title, StringComparison.OrdinalIgnoreCase)));

        var tab = new EditorTabState { Title = title, Extension = ".lua" };
        _tabs.Add(tab);
        ShowTab(tab);
    }

    private void CloseTab(EditorTabState tab)
    {
        var index = _tabs.IndexOf(tab);
        if (index < 0)
        {
            return;
        }

        var wasActive = tab.Id == _activeTab.Id && !_showingOutput;
        _tabs.Remove(tab);
        if (_tabs.Count == 0)
        {
            var replacement = new EditorTabState { Title = "New Tab", Extension = ".lua" };
            _tabs.Add(replacement);
            _activeTab = replacement;
        }
        else if (wasActive)
        {
            _activeTab = _tabs[Math.Clamp(index, 0, _tabs.Count - 1)];
        }

        if (_showingOutput)
        {
            RebuildTabs();
        }
        else
        {
            ShowTab(_activeTab);
        }
    }

    // ─────────────────────── console (Output tab) ───────────────────────

    private void SeedConsoleFromBridge()
    {
        foreach (var entry in _bridge.GetLogSnapshot())
        {
            AppendConsoleLine(
                string.IsNullOrWhiteSpace(entry.Level) ? "info" : entry.Level,
                entry.Message ?? string.Empty);
        }
    }

    internal void AppendConsoleLine(string level, string message)
    {
        if (_consoleOutput is null)
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
        _consoleOutput.Children.Add(new TextBlock
        {
            Text = prefix + message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 11,
            Foreground = new SolidColorBrush(Color.Parse(color)),
            TextWrapping = TextWrapping.Wrap
        });
        while (_consoleOutput.Children.Count > 500)
        {
            _consoleOutput.Children.RemoveAt(0);
        }
        _consoleScroll?.ScrollToEnd();
    }

    private void Bridge_LogReceived(string level, string message)
    {
        Dispatcher.UIThread.Post(() => AppendConsoleLine(level, message));
    }

    private void Bridge_ConnectionChanged(bool connected)
    {
        Dispatcher.UIThread.Post(() =>
        {
            if (connected)
            {
                ApplyUnlockFps(notify: true);
            }
        });
    }

    // ─────────────────────── actions ───────────────────────

    private async void Execute_Click(object? s, RoutedEventArgs e)
    {
        var code = await RequestEditorContentAsync();
        if (string.IsNullOrWhiteSpace(code))
        {
            AppendConsoleLine("warn", "Nothing to execute — the editor is empty");
            return;
        }
        _bridge.EnqueueExecute(code);
    }

    private async void Open_Click(object? s, RoutedEventArgs e)
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            Title = "Open script",
            AllowMultiple = false,
            FileTypeFilter =
            [
                new FilePickerFileType("Script files") { Patterns = ["*.lua", "*.luau", "*.txt"] }
            ]
        });
        var file = files.FirstOrDefault();
        if (file is null) return;
        await using var stream = await file.OpenReadAsync();
        using var reader = new StreamReader(stream);
        var content = await reader.ReadToEndAsync();

        var target = _tabs.FirstOrDefault(tab =>
            tab.Content.Length == 0 && tab.Title.StartsWith("New Tab", StringComparison.OrdinalIgnoreCase));
        if (target is null)
        {
            if (_tabs.Count >= MaximumTabs)
            {
                AppendConsoleLine("warn", "Maximum tabs reached");
                return;
            }
            target = new EditorTabState { Title = "New Tab", Extension = ".lua" };
            _tabs.Add(target);
        }

        target.Title = System.IO.Path.GetFileNameWithoutExtension(file.Name);
        target.Extension = System.IO.Path.GetExtension(file.Name);
        target.Content = content;
        ShowTab(target);
    }

    private async void Save_Click(object? s, RoutedEventArgs e)
    {
        var content = await RequestEditorContentAsync();
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            DefaultExtension = "lua",
            FileTypeChoices =
            [
                new FilePickerFileType("Lua script") { Patterns = ["*.lua"] },
                new FilePickerFileType("Text file") { Patterns = ["*.txt"] }
            ]
        });
        if (file is null) return;
        await using var stream = await file.OpenWriteAsync();
        stream.SetLength(0);
        await using var writer = new StreamWriter(stream);
        await writer.WriteAsync(content);

        _activeTab.Title = System.IO.Path.GetFileNameWithoutExtension(file.Name);
        _activeTab.Extension = System.IO.Path.GetExtension(file.Name);
        RebuildTabs();
    }

    private void Clear_Click(object? s, RoutedEventArgs e)
    {
        _activeTab.Content = string.Empty;
        PushActiveTabToEditor();
    }

    private void Attach_Click(object? s, RoutedEventArgs e)
    {
        if (_bridge.IsConnected)
        {
            AppendConsoleLine("info", "Attached to Roblox.");
        }
        else
        {
            AppendConsoleLine("warn", "Not attached — start Roblox, the bridge attaches automatically.");
        }
    }

    private void ScriptHub_Click(object? s, RoutedEventArgs e)
    {
        if (_hubWindow is { } existing)
        {
            existing.Close();
            return;
        }

        _hubWindow = new SentinelScriptHubWindow(this, _scriptsDirectory);
        _hubWindow.Closed += (_, _) => _hubWindow = null;
        _hubWindow.Show(this);
    }

    private void Settings_Click(object? s, RoutedEventArgs e)
    {
        if (_settingsWindow is { } existing)
        {
            existing.Close();
            return;
        }

        _settingsWindow = new SentinelSettingsWindow(this, _options);
        _settingsWindow.OptionsChanged += ApplyOptions;
        _settingsWindow.Closed += (_, _) => _settingsWindow = null;
        _settingsWindow.Show(this);
    }

    private void ApplyOptions()
    {
        Topmost = _options.TopMost;
        ApplyUnlockFps(notify: true);
    }

    private void ApplyUnlockFps(bool notify)
    {
        if (!_options.UnlockFps)
        {
            _unlockFpsSent = false;
            return;
        }

        if (!_bridge.IsConnected || _unlockFpsSent)
        {
            return;
        }

        _bridge.EnqueueExecute("setfpscap(240)");
        _unlockFpsSent = true;
        if (notify)
        {
            AppendConsoleLine("info", "Unlock FPS: setfpscap(240) sent to Roblox.");
        }
    }

    // ─────────────────────── script list ───────────────────────

    private void RefreshScriptList()
    {
        if (_scriptsList is null) return;
        var files = new List<string>();
        try
        {
            Directory.CreateDirectory(_scriptsDirectory);
            files.AddRange(Directory.EnumerateFiles(_scriptsDirectory)
                .Where(f => new[] { ".lua", ".luau", ".txt" }
                    .Contains(Path.GetExtension(f), StringComparer.OrdinalIgnoreCase))
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(f => Path.GetFileName(f) ?? f));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        _scriptsList.ItemsSource = files;
    }

    private async void ScriptsList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_scriptsList?.SelectedItem is not string fileName) return;
        _scriptsList.SelectedItem = null;
        try
        {
            var path = System.IO.Path.Combine(_scriptsDirectory, fileName);
            var content = await File.ReadAllTextAsync(path);
            _activeTab.Title = System.IO.Path.GetFileNameWithoutExtension(fileName);
            _activeTab.Extension = Path.GetExtension(fileName);
            _activeTab.Content = content;
            ShowTab(_activeTab);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
    }

    // ─────────────────────── keyboard ───────────────────────

    private void SentinelWindow_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.F5 || ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.Enter))
        {
            Execute_Click(this, new RoutedEventArgs());
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.O)
        {
            Open_Click(this, new RoutedEventArgs());
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.S)
        {
            Save_Click(this, new RoutedEventArgs());
            e.Handled = true;
        }
    }
}