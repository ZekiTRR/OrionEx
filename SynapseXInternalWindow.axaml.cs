using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using Avalonia.VisualTree;

namespace OrbitAvalonia;

/// <summary>
/// Imitation of the Synapse X internal (in-game) UI: three movable
/// ImGui-style windows (Executor, Console, Script Hub) over the game.
/// Nothing is injected — execution and console output travel through the
/// shared Orion bridge (local HTTP only); the surface itself is an ordinary
/// topmost window.
/// </summary>
public sealed partial class SynapseXInternalWindow : Window
{
    private const uint WmHotkey = 0x0312;
    private const uint WmQuit = 0x0012;
    private const uint ModNoRepeat = 0x4000;

    private static uint _hotkeyThreadId;
    private Thread? _hotkeyThread;
    private volatile bool _hotkeyStop;

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspaceState;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;

    private NativeWebView _editorWebView = null!;
    private StackPanel _consoleOutput = null!;
    private ScrollViewer _consolePane = null!;
    private StackPanel _executorScriptList = null!;
    private StackPanel _hubList = null!;
    private StackPanel _hubDetails = null!;
    private TextBlock _hubDetailsName = null!;
    private Border _editorScrollStrip = null!;
    private TextBox _consoleInput = null!;
    private Canvas _overlayCanvas = null!;
    private Border _executorPanel = null!;
    private Border _consolePanel = null!;
    private Border _hubPanel = null!;
    private List<(string Name, string Path)> _scriptFiles = [];
    private int _selectedScriptIndex = -1;

    private EditorTabState _activeTab => _workspaceState.Tabs.FirstOrDefault(t => t.Id == _workspaceState.ActiveTabId)
        ?? _workspaceState.Tabs[0];

    private bool _editorLoaded;
    private bool _editorReady;
    private bool _closingForOrbit;
    private bool _returnRequested;
    private bool _overlayWanted = true;
    private DispatcherTimer? _overlayTimer;

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int key);

    [DllImport("user32.dll")]
    private static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint modifiers, uint virtualKey);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll")]
    private static extern bool PeekMessageW(out Msg message, IntPtr window, uint min, uint max, uint remove);

    [DllImport("user32.dll")]
    private static extern bool PostThreadMessageW(uint threadId, uint msg, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    private delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT { public int Left, Top, Right, Bottom; }

    [StructLayout(LayoutKind.Sequential)]
    private struct Msg
    {
        public IntPtr Window;
        public uint Message;
        public IntPtr WParam;
        public IntPtr LParam;
        public uint Time;
        public int PointX;
        public int PointY;
    }

    public SynapseXInternalWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal SynapseXInternalWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _workspaceState = initialWorkspace.CloneDetached();
        if (_workspaceState.Tabs.Count == 0)
        {
            var tab = new EditorTabState { Title = "Script 1.lua", Extension = ".lua" };
            _workspaceState.Tabs.Add(tab);
            _workspaceState.ActiveTabId = tab.Id;
        }
        _returnToOrion = returnToOrion;

        AvaloniaXamlLoader.Load(this);

        _editorWebView = Required<NativeWebView>("EditorWebView");
        _consoleOutput = Required<StackPanel>("ConsoleOutput");
        _consolePane = Required<ScrollViewer>("ConsolePane");
        _executorScriptList = Required<StackPanel>("ExecutorScriptList");
        _hubList = Required<StackPanel>("HubList");
        _hubDetails = Required<StackPanel>("HubDetails");
        _hubDetailsName = Required<TextBlock>("HubDetailsName");
        _editorScrollStrip = Required<Border>("EditorScrollStrip");
        _overlayCanvas = Required<Canvas>("OverlayCanvas");
        _consoleInput = Required<TextBox>("ConsoleInput");
        _executorPanel = Required<Border>("ExecutorWindow");
        _consolePanel = Required<Border>("ConsoleWindow");
        _hubPanel = Required<Border>("HubWindow");

        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.ClientsChanged += BridgeClientsChanged;
        _bridge.LogReceived += BridgeLogReceived;

        // Monaco announces itself with a "ready" web message once the editor
        // JS is up; only after that can it receive content (Clear, Open File,
        // initial tab text).
        _editorWebView.WebMessageReceived += (_, args) => HandleEditorMessage(args.Body);

        PointerMoved += OverlayCanvas_PointerMoved;
        PointerReleased += OverlayCanvas_PointerReleased;

        // Show the logs the bridge already collected (e.g. prints executed
        // before this window was opened), then the banner line.
        foreach (var entry in _bridge.GetLogSnapshot())
        {
            AppendConsoleLine(entry.Level, entry.Message);
        }

        LogSystem("Synapse X successfully (re)loaded.");
        RefreshBridgeState();
        _ = LoadScriptsListAsync();

        _editorLoaded = true;
        var editorUri = new UriBuilder(_monacoAddress)
        {
            Query = "bg=%231E1E1E"
        };
        _editorWebView.Source = editorUri.Uri;

        // Rule timer: visible only while Roblox is a focused window.
        _overlayTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(60) };
        _overlayTimer.Tick += OverlayTimer_Tick;
        _overlayTimer.Start();

        StartHotkeyListener();

        Closed += SynapseXInternalWindow_Closed;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"Synapse X internal control '{name}' was not created.");

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "Script 1.lua", Extension = ".lua", Content = string.Empty };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private void SynapseXInternalWindow_Closed(object? sender, EventArgs e)
    {
        _overlayTimer?.Stop();
        _hotkeyStop = true;
        for (var index = 0; index < ToggleHotkeys.Length; index++)
        {
            UnregisterHotKey(IntPtr.Zero, HotkeyIdBase + index);
        }

        if (_hotkeyThreadId != 0)
        {
            PostThreadMessageW(_hotkeyThreadId, WmQuit, IntPtr.Zero, IntPtr.Zero);
        }

        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.ClientsChanged -= BridgeClientsChanged;
        _bridge.LogReceived -= BridgeLogReceived;

        if (!_closingForOrbit && !_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(_workspaceState.CloneDetached());
        }
    }

    internal void CloseForOrbit()
    {
        _closingForOrbit = true;
        Close();
    }

    // ─────────────────────────── overlay behaviour ───────────────────────────

    private static void LogSxi(string message) =>
        File.AppendAllText(
            Path.Combine(Path.GetTempPath(), "orion-handoff.log"),
            $"{DateTime.Now:HH:mm:ss.fff} [SXI] {message}\n");

    private bool _dragging;
    private readonly Stopwatch _gameScanClock = new();
    private (IntPtr Handle, int X, int Y, int Width, int Height)? _cachedGame;

    private void OverlayTimer_Tick(object? sender, EventArgs e)
    {
        // Dragging panels must stay perfectly smooth: skip all scan/layout
        // work until the pointer is released.
        if (_dragging)
        {
            return;
        }

        var game = FindGameWindowCached();
        var gameOk = game is not null && !IsIconic(game.Value.Handle);

        var foregroundOk = false;
        if (gameOk)
        {
            var foreground = GetForegroundWindow();
            var ownHandle = this.TryGetPlatformHandle()?.Handle ?? IntPtr.Zero;
            foregroundOk = ownHandle != IntPtr.Zero && foreground == ownHandle;
            if (!foregroundOk)
            {
                GetWindowThreadProcessId(foreground, out var foregroundPid);
                foregroundOk = foregroundPid != 0 && _robloxProcessIds.Contains(foregroundPid);
            }
        }

        var shouldShow = _overlayWanted && gameOk && foregroundOk;

        if (shouldShow && !IsVisible)
        {
            PositionOverGame(force: false);
            Show();
            LogSxi("overlay shown");
        }
        else if (!shouldShow && IsVisible)
        {
            Hide();
            LogSxi("overlay hidden");
        }

        if (IsVisible)
        {
            PositionOverGame(force: false);
        }
    }

    private HashSet<uint> _robloxProcessIds = [];

    private static List<uint> GetRobloxProcessIds()
    {
        var ids = new List<uint>();
        foreach (var processName in new[] { "RobloxPlayerBeta", "Roblox", "Windows10Universal" })
        {
            foreach (var process in Process.GetProcessesByName(processName))
            {
                ids.Add((uint)process.Id);
            }
        }

        return ids;
    }

    // The full process/window scan is far too heavy to run every 60 ms —
    // it stalls the UI thread and makes panel dragging stutter. Cache it.
    private (IntPtr Handle, int X, int Y, int Width, int Height)? FindGameWindowCached()
    {
        if (_cachedGame is { } cached && _gameScanClock.ElapsedMilliseconds < 400)
        {
            return cached;
        }

        _gameScanClock.Restart();
        return _cachedGame = FindGameWindow();
    }

    private (IntPtr Handle, int X, int Y, int Width, int Height)? FindGameWindow()
    {
        // Locate Roblox by process id across ALL of its top-level windows —
        // MainWindowHandle does not always match the window the user plays in.
        _robloxProcessIds = [.. GetRobloxProcessIds()];
        if (_robloxProcessIds.Count == 0)
        {
            return null;
        }

        var candidates = new List<(IntPtr Handle, int X, int Y, int Width, int Height)>();
        EnumWindows((hWnd, _) =>
        {
            if (!IsWindowVisible(hWnd) || !GetWindowRect(hWnd, out var rect))
            {
                return true;
            }

            GetWindowThreadProcessId(hWnd, out var pid);
            if (!_robloxProcessIds.Contains(pid))
            {
                return true;
            }

            var width = rect.Right - rect.Left;
            var height = rect.Bottom - rect.Top;
            if (width < 200 || height < 150)
            {
                return true;
            }

            candidates.Add((hWnd, rect.Left, rect.Top, width, height));
            return true;
        }, IntPtr.Zero);

        if (candidates.Count == 0)
        {
            return null;
        }

        // Prefer the Roblox window the user is actually looking at.
        var foreground = GetForegroundWindow();
        GetWindowThreadProcessId(foreground, out var foregroundPid);
        if (foregroundPid != 0 && _robloxProcessIds.Contains(foregroundPid))
        {
            var match = candidates.FirstOrDefault(candidate => candidate.Handle == foreground);
            if (match.Handle != IntPtr.Zero)
            {
                return match;
            }
        }

        return candidates.OrderByDescending(candidate => (long)candidate.Width * candidate.Height).First();
    }

    private bool _panelLayoutDone;

    private void PositionOverGame(bool force)
    {
        var game = FindGameWindowCached();
        if (game is null)
        {
            return;
        }

        var (_, x, y, width, height) = game.Value;

        // The Canvas must cover the entire game surface: size the window to the
        // Roblox window, converting physical pixels to DIPs.
        var dipWidth = width / RenderScaling;
        var dipHeight = height / RenderScaling;
        if (Math.Abs(Width - dipWidth) > 0.5)
        {
            Width = dipWidth;
        }

        if (Math.Abs(Height - dipHeight) > 0.5)
        {
            Height = dipHeight;
        }

        if (!_panelLayoutDone)
        {
            LayoutPanelsCascade(dipWidth, dipHeight);
            _panelLayoutDone = true;
        }

        var target = new PixelPoint(x, y);
        if (force || Position != target)
        {
            Position = target;
        }
    }

    // First show: cascade the panels inside the Roblox area
    // (Executor top-left, Console top-right, Script Hub bottom-left).
    private void LayoutPanelsCascade(double gameWidth, double gameHeight)
    {
        const double margin = 12;
        PlacePanel(_executorPanel, margin, margin, gameWidth, gameHeight);
        PlacePanel(_consolePanel, gameWidth - _consolePanel.Width - margin, margin, gameWidth, gameHeight);
        PlacePanel(_hubPanel, margin, gameHeight - _hubPanel.Height - margin, gameWidth, gameHeight);
    }

    private static void PlacePanel(Border panel, double left, double top, double gameWidth, double gameHeight)
    {
        Canvas.SetLeft(panel, Math.Clamp(left, 0, Math.Max(0, gameWidth - panel.Width)));
        Canvas.SetTop(panel, Math.Clamp(top, 0, Math.Max(0, gameHeight - panel.Height)));
    }

    // ─────────────────────────── window dragging ───────────────────────────

    private Border? _dragWindow;
    private Point _dragOrigin;

    private void WindowTitle_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (sender is Border { Tag: string windowName } title &&
            this.FindControl<Border>(windowName) is { } window &&
            e.GetCurrentPoint(this).Properties.IsLeftButtonPressed)
        {
            _dragWindow = window;
            _dragOrigin = e.GetPosition(_overlayCanvas);
            _dragging = true;
            ActivateWindow(window);
            e.Pointer.Capture(title);
            e.Handled = true;
        }
    }

    private void OverlayCanvas_PointerMoved(object? sender, PointerEventArgs e)
    {
        if (_dragWindow is null)
        {
            return;
        }

        // Layout-based movement (Canvas.Left/Top): Monaco's WebView2 is a
        // native HWND and only follows real layout changes — render transforms
        // would leave it behind until release.
        var position = e.GetPosition(_overlayCanvas);
        var delta = position - _dragOrigin;
        _dragOrigin = position;

        var left = Canvas.GetLeft(_dragWindow) + delta.X;
        var top = Canvas.GetTop(_dragWindow) + delta.Y;
        Canvas.SetLeft(_dragWindow, Math.Clamp(left, 0, Math.Max(0, _overlayCanvas.Bounds.Width - _dragWindow.Width)));
        Canvas.SetTop(_dragWindow, Math.Clamp(top, 0, Math.Max(0, _overlayCanvas.Bounds.Height - _dragWindow.Height)));
    }

    private void OverlayCanvas_PointerReleased(object? sender, PointerEventArgs e)
    {
        _dragWindow = null;
        _dragging = false;
    }

    // ─────────────────────────── window resizing ───────────────────────────

    private Border? _resizeWindow;
    private Point _resizeOrigin;
    private Size _resizeStartSize;

    private void WindowResize_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        if (sender is Border { Tag: string windowName } grip &&
            this.FindControl<Border>(windowName) is { } window &&
            e.GetCurrentPoint(this).Properties.IsLeftButtonPressed)
        {
            _resizeWindow = window;
            _resizeOrigin = e.GetPosition(_overlayCanvas);
            _resizeStartSize = new Size(window.Width, window.Height);
            ActivateWindow(window);
            e.Pointer.Capture(grip);
            e.Handled = true;
        }
    }

    private void WindowResize_PointerMoved(object? sender, PointerEventArgs e)
    {
        if (_resizeWindow is null)
        {
            return;
        }

        var (minWidth, minHeight) = ReferenceEquals(_resizeWindow, _hubPanel) ? (380, 180)
            : ReferenceEquals(_resizeWindow, _executorPanel) ? (320, 200) : (320, 160);
        var position = e.GetPosition(_overlayCanvas);
        var maxWidth = Math.Max(minWidth, _overlayCanvas.Bounds.Width - Canvas.GetLeft(_resizeWindow));
        var maxHeight = Math.Max(minHeight, _overlayCanvas.Bounds.Height - Canvas.GetTop(_resizeWindow));

        _resizeWindow.Width = Math.Clamp(_resizeStartSize.Width + position.X - _resizeOrigin.X, minWidth, maxWidth);
        _resizeWindow.Height = Math.Clamp(_resizeStartSize.Height + position.Y - _resizeOrigin.Y, minHeight, maxHeight);
        e.Handled = true;
    }

    private void WindowResize_PointerReleased(object? sender, PointerReleasedEventArgs e)
    {
        _resizeWindow = null;
    }

    private int _topZIndex = 10;

    private void ActivateWindow(Border window)
    {
        _topZIndex++;
        window.ZIndex = _topZIndex;
    }

    private static void SetClass(Control control, string className, bool enabled)
    {
        if (enabled)
        {
            control.Classes.Add(className);
        }
        else
        {
            control.Classes.Remove(className);
        }
    }

    private void CloseOverlay_Click(object? sender, RoutedEventArgs e)
    {
        // The X closes the whole overlay; Orion stays open the entire time.
        CloseForReal();
    }

    private void CloseForReal()
    {
        _closingForOrbit = true;
        _returnRequested = true;
        _returnToOrion(_workspaceState.CloneDetached());
        Close();
    }

    // ─────────────────────────── editor ───────────────────────────

    private async void Execute_Click(object? sender, RoutedEventArgs e)
    {
        if (!HasLiveBridge)
        {
            SetEditorStatus("Not attached — run Scripts/Orion Bridge.lua");
            return;
        }

        _activeTab.Content = await RequestEditorContentAsync();
        _bridge.EnqueueExecute(_activeTab.Content);
        SetEditorStatus($"Executed {_activeTab.Title}");
    }

    private void Clear_Click(object? sender, RoutedEventArgs e) => PushEditorContent(string.Empty);

    private void SetEditorStatus(string message) => LogSystem(message);

    private void LogSystem(string message)
    {
        var line = new TextBlock
        {
            Text = message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 12.5,
            Foreground = new SolidColorBrush(Color.Parse("#5F6A7F")),
            TextWrapping = TextWrapping.Wrap
        };
        _consoleOutput.Children.Add(line);
        TrimConsole();
        Dispatcher.UIThread.Post(line.BringIntoView, DispatcherPriority.Background);
    }

    private bool HasLiveBridge => _bridge.IsConnected && _bridge.GetConnectedClients().Count > 0;

    private void PushEditorContent(string content)
    {
        _activeTab.Content = content;
        // The decorative horizontal scrollbar strip only makes sense for long scripts.
        _editorScrollStrip.IsVisible = IsLongScript(content);
        if (!_editorReady)
        {
            return;
        }

        try
        {
            var serialized = JsonSerializer.Serialize(content);
            _editorWebView.InvokeScript($"window.orbitSetContent && window.orbitSetContent({serialized}, 'lua');");
        }
        catch (InvalidOperationException)
        {
            // Monaco may still be loading.
        }
    }

    private static bool IsLongScript(string content) =>
        content.Length > 2000 || content.Split('\n').Any(line => line.Length > 150);

    private TaskCompletionSource<string>? _editorSnapshot;

    private async Task<string> RequestEditorContentAsync()
    {
        if (!_editorReady)
        {
            return _activeTab.Content;
        }

        // NativeWebView cannot hand back a script's return value: the editor
        // answers through a "contentSnapshot" web message instead — the same
        // pattern the Orion UI uses. The InvokeScript result itself is
        // JSON-encoded and must never be executed as Lua.
        _editorSnapshot?.TrySetCanceled();
        var completion = new TaskCompletionSource<string>(
            TaskCreationOptions.RunContinuationsAsynchronously);
        _editorSnapshot = completion;

        try
        {
            await _editorWebView.InvokeScript("window.orionRequestSnapshot && window.orionRequestSnapshot();");
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
    }

    private async void OpenFile_Click(object? sender, RoutedEventArgs e)
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            AllowMultiple = false,
            Title = "Open script",
            FileTypeFilter =
            [
                new FilePickerFileType("Script files") { Patterns = ["*.lua", "*.txt"] }
            ]
        });

        if (files.Count == 0)
        {
            return;
        }

        try
        {
            var content = await File.ReadAllTextAsync(files[0].Path.LocalPath);
            _activeTab.Content = content;
            _activeTab.Title = Path.GetFileName(files[0].Path.LocalPath);
            PushEditorContent(content);
        }
        catch (IOException)
        {
        }
    }

    private async void ExecuteFile_Click(object? sender, RoutedEventArgs e)
    {
        if (_selectedScriptIndex < 0 || _selectedScriptIndex >= _scriptFiles.Count)
        {
            SetEditorStatus("Select a script in the list first");
            return;
        }

        if (!HasLiveBridge)
        {
            SetEditorStatus("Not attached — run Scripts/Orion Bridge.lua");
            return;
        }

        try
        {
            var content = await File.ReadAllTextAsync(_scriptFiles[_selectedScriptIndex].Path);
            _bridge.EnqueueExecute(content);
            SetEditorStatus($"Executed {_scriptFiles[_selectedScriptIndex].Name}");
        }
        catch (IOException)
        {
        }
    }

    private async void SaveFile_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = await RequestEditorContentAsync();
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            SuggestedFileName = _activeTab.Title,
            DefaultExtension = "lua",
            FileTypeChoices = [new FilePickerFileType("Script files") { Patterns = ["*.lua"] }]
        });

        if (file is null)
        {
            return;
        }

        try
        {
            await File.WriteAllTextAsync(file.Path.LocalPath, _activeTab.Content);
            _ = LoadScriptsListAsync();
        }
        catch (IOException)
        {
        }
    }

    // ─────────────────────────── console ───────────────────────────

    private void HandleEditorMessage(string? body)
    {
        try
        {
            using var payload = JsonDocument.Parse(body ?? string.Empty);
            var type = payload.RootElement.TryGetProperty("type", out var typeProperty)
                ? typeProperty.GetString()
                : null;
            switch (type)
            {
                case "ready":
                    Dispatcher.UIThread.Post(() =>
                    {
                        _editorReady = true;
                        PushEditorContent(_activeTab.Content);
                    });
                    break;

                case "contentSnapshot" when payload.RootElement.TryGetProperty("content", out var content):
                    _editorSnapshot?.TrySetResult(content.GetString() ?? string.Empty);
                    break;
            }
        }
        catch (JsonException)
        {
            // Not a message we care about.
        }
    }

    // Console behaves exactly like the Orion UI console: every bridge log is
    // shown unconditionally, with a level prefix, muted colors, wrapped
    // Consolas lines and a 250-line cap.
    private void AppendConsoleLine(string level, string message)
    {
        var normalized = string.IsNullOrWhiteSpace(level) ? "info" : level.ToLowerInvariant();
        var prefix = normalized switch
        {
            "warn" or "warning" => "[warn]   ",
            "error" => "[error]  ",
            "print" or "output" => "[print]  ",
            _ => "[info]   "
        };
        var line = new TextBlock
        {
            Text = prefix + message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 12.5,
            Foreground = new SolidColorBrush(Color.Parse(normalized switch
            {
                "warn" or "warning" => "#C8A25A",
                "error" => "#D06B6B",
                _ => "#B8B8BA"
            })),
            TextWrapping = TextWrapping.Wrap
        };
        _consoleOutput.Children.Add(line);
        TrimConsole();
        Dispatcher.UIThread.Post(line.BringIntoView, DispatcherPriority.Background);
    }

    private void TrimConsole()
    {
        while (_consoleOutput.Children.Count > 250)
        {
            _consoleOutput.Children.RemoveAt(0);
        }
    }

    private void BridgeLogReceived(string level, string message) =>
        Dispatcher.UIThread.Post(() => AppendConsoleLine(level, message));

    private void ConsoleClear_Click(object? sender, RoutedEventArgs e)
    {
        _consoleOutput.Children.Clear();
    }

    private void ConsoleInput_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key != Key.Enter)
        {
            return;
        }

        var text = _consoleInput.Text?.Trim();
        if (string.IsNullOrEmpty(text))
        {
            return;
        }

        if (!HasLiveBridge)
        {
            LogSystem("Not attached — run Scripts/Orion Bridge.lua.");
            return;
        }

        _bridge.EnqueueExecute(text);
        _consoleInput.Clear();
    }

    private void BridgeConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(RefreshBridgeState);

    private void BridgeClientsChanged() =>
        Dispatcher.UIThread.Post(RefreshBridgeState);

    private bool _lastAttached;

    private void RefreshBridgeState()
    {
        var clients = _bridge.GetConnectedClients();
        var attached = _bridge.IsConnected && clients.Count > 0;
        if (attached != _lastAttached)
        {
            _lastAttached = attached;
            LogSystem(attached
                ? $"Attached — {clients.Count} client(s)."
                : "Not attached — run Scripts/Orion Bridge.lua.");
        }
    }

    // ─────────────────────────── script lists ───────────────────────────

    private async Task LoadScriptsListAsync()
    {
        _scriptFiles.Clear();
        _selectedScriptIndex = -1;

        try
        {
            _scriptFiles = Directory.EnumerateFiles(_scriptsDirectory)
                .Where(path => !Path.GetFileName(path).StartsWith('.'))
                .OrderBy(path => Path.GetFileName(path), StringComparer.OrdinalIgnoreCase)
                .Select(path => (Path.GetFileName(path), path))
                .ToList();
        }
        catch (IOException)
        {
        }

        RebuildExecutorScriptList();
        RebuildHubList();
        await Task.CompletedTask;
    }

    private void RebuildExecutorScriptList()
    {
        _executorScriptList.Children.Clear();
        for (var index = 0; index < _scriptFiles.Count; index++)
        {
            var (name, path) = _scriptFiles[index];
            var capturedIndex = index;
            var row = new Button
            {
                Classes = { "sxi-listitem" },
                Content = new TextBlock
                {
                    Text = name,
                    FontSize = 11.5,
                    TextTrimming = TextTrimming.CharacterEllipsis
                }
            };
            if (index == _selectedScriptIndex)
            {
                row.Classes.Add("selected");
            }

            ToolTip.SetTip(row, path);
            row.Click += (_, _) => SelectScript(capturedIndex, row);
            _executorScriptList.Children.Add(row);
        }

        if (_scriptFiles.Count == 0)
        {
            _executorScriptList.Children.Add(new TextBlock
            {
                Text = "(no scripts)",
                FontSize = 11,
                Foreground = new SolidColorBrush(Color.Parse("#7A7A7A")),
                Margin = new Thickness(2, 2, 0, 0)
            });
        }
    }

    // Fixed Script Hub entries, mirroring the original Synapse X hub.
    private static readonly (string Name, string Script)[] HubScripts =
    [
        ("Dark Dex",
            "loadstring(game:HttpGet(\"https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua\", true))()"),
        ("Remote Spy",
            "loadstring(game:HttpGet(\"https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua\"))()"),
        ("InfYield",
            "loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()")
    ];

    private void RebuildHubList()
    {
        _hubList.Children.Clear();
        for (var index = 0; index < HubScripts.Length; index++)
        {
            var capturedIndex = index;
            var row = new Button
            {
                Classes = { "sxi-listitem" },
                Content = new TextBlock { Text = HubScripts[index].Name }
            };
            row.Click += (_, _) => SelectHubScript(capturedIndex, row);
            _hubList.Children.Add(row);
        }
    }

    private int _selectedHubIndex = -1;

    private void SelectHubScript(int index, Button row)
    {
        _selectedHubIndex = index;
        foreach (var child in _hubList.Children.OfType<Button>())
        {
            SetClass(child, "selected", false);
        }

        SetClass(row, "selected", true);
        _hubDetailsName.Text = HubScripts[index].Name;
        _hubDetails.IsVisible = true;
    }

    private void HubExecute_Click(object? sender, RoutedEventArgs e)
    {
        if (_selectedHubIndex < 0 || _selectedHubIndex >= HubScripts.Length)
        {
            return;
        }

        if (!HasLiveBridge)
        {
            LogSystem("Not attached — run Scripts/Orion Bridge.lua.");
            return;
        }

        var (name, script) = HubScripts[_selectedHubIndex];
        _bridge.EnqueueExecute(script);
        LogSystem($"Executed {name}.");
    }

    private async void SelectScript(int index, Button row)
    {
        _selectedScriptIndex = index;
        foreach (var child in _executorScriptList.Children.OfType<Button>())
        {
            SetClass(child, "selected", false);
        }

        SetClass(row, "selected", true);

        // Clicking a script loads it into the editor tab.
        try
        {
            var content = await File.ReadAllTextAsync(_scriptFiles[index].Path);
            _activeTab.Content = content;
            _activeTab.Title = _scriptFiles[index].Name;
            PushEditorContent(content);
            LogSystem($"Loaded {_scriptFiles[index].Name}.");
        }
        catch (IOException)
        {
            LogSystem($"Failed to read {_scriptFiles[index].Name}.");
        }
    }

    // ─────────────────────────── hotkey configuration ───────────────────────────
    //
    // Every entry in ToggleHotkeys registers ONE global hotkey that toggles the
    // internal UI. To add or remove hotkeys, simply edit this list — nothing
    // else needs to change.
    //
    //   (Modifier, VirtualKey, Label)
    //
    //   Modifier   Win32 modifier flags (combine with | when needed):
    //                0x0000 = none, 0x0001 = ALT, 0x0002 = CTRL, 0x0004 = SHIFT
    //   VirtualKey Win32 virtual-key code ("Virtual-Key Codes" on MSDN):
    //                0x24 = Home, 0x70 = F1, 0x71 = F2, 0x72 = F3, 0x73 = F4 ...
    //   Label      Human-readable name, used in the handoff log only.
    //
    // NOTE: while Roblox is focused its protection filters bare menu keys
    // (Insert/Home), so keys like Home need a modifier. F-keys work alone.
    private static readonly (uint Modifier, uint VirtualKey, string Label)[] ToggleHotkeys =
    [
        (0x0002, 0x24, "Ctrl+Home"), // Control + Home
        (0x0000, 0x72, "F3"),        // F3
    ];

    private const int HotkeyIdBase = 0x5358; // "SX" — one id per hotkey: Base + index

    private void StartHotkeyListener()
    {
        _hotkeyThread = new Thread(() =>
        {
            try
            {
                _hotkeyThreadId = GetCurrentThreadId();

                // Register each hotkey on this dedicated thread: WM_HOTKEY is
                // posted to the thread's own message queue (no window needed)
                // and the OS delivers it regardless of keyboard focus.
                var registered = new bool[ToggleHotkeys.Length];
                for (var index = 0; index < ToggleHotkeys.Length; index++)
                {
                    var hotkey = ToggleHotkeys[index];
                    registered[index] = RegisterHotKey(
                        IntPtr.Zero, HotkeyIdBase + index,
                        hotkey.Modifier | ModNoRepeat, hotkey.VirtualKey);
                }

                var registeredLabels = ToggleHotkeys
                    .Where((_, index) => registered[index])
                    .Select(hotkey => hotkey.Label)
                    .DefaultIfEmpty("none")
                    .ToArray();
                LogSxi($"hotkeys registered -> {string.Join(", ", registeredLabels)}");

                // Polling state for hotkeys another process owns (rare): they
                // are still supported through GetAsyncKeyState below.
                var pollWasDown = new bool[ToggleHotkeys.Length];

                while (!_hotkeyStop)
                {
                    // Drain the message queue (PM_REMOVE = 1).
                    while (PeekMessageW(out var message, IntPtr.Zero, 0, 0, 1))
                    {
                        if (message.Message == WmQuit)
                        {
                            return;
                        }

                        if (message.Message == WmHotkey)
                        {
                            var index = message.WParam.ToInt32() - HotkeyIdBase;
                            if (index >= 0 && index < ToggleHotkeys.Length)
                            {
                                Dispatcher.UIThread.Post(OnHomePressed);
                            }
                        }
                    }

                    // Fallback poll for any hotkey that could not be registered.
                    for (var index = 0; index < ToggleHotkeys.Length; index++)
                    {
                        if (registered[index])
                        {
                            continue;
                        }

                        var down = IsHotkeyDown(ToggleHotkeys[index]);
                        if (down && !pollWasDown[index])
                        {
                            Dispatcher.UIThread.Post(OnHomePressed);
                        }

                        pollWasDown[index] = down;
                    }

                    Thread.Sleep(40);
                }
            }
            catch
            {
                // Without the hotkeys the overlay still shows while Roblox is focused.
            }
        })
        {
            IsBackground = true,
            Name = "OrionSxiHotkey"
        };
        _hotkeyThread.Start();
    }

    private static bool IsKeyDown(uint virtualKey) =>
        (GetAsyncKeyState((int)virtualKey) & 0x8000) != 0;

    private static bool IsHotkeyDown((uint Modifier, uint VirtualKey, string Label) hotkey)
    {
        if (!IsKeyDown(hotkey.VirtualKey))
        {
            return false;
        }

        const uint modAlt = 0x0001, modControl = 0x0002, modShift = 0x0004;
        if ((hotkey.Modifier & modControl) != 0 && !IsKeyDown(0x11)) return false; // VK_CONTROL
        if ((hotkey.Modifier & modAlt) != 0 && !IsKeyDown(0x12)) return false;     // VK_MENU
        if ((hotkey.Modifier & modShift) != 0 && !IsKeyDown(0x10)) return false;   // VK_SHIFT
        return true;
    }

    private void OnHomePressed()
    {
        LogSxi($"home -> wanted={_overlayWanted} visible={IsVisible}");
        if (IsVisible)
        {
            // User dismissed: do not auto-show until Home is pressed again.
            _overlayWanted = false;
            Hide();
        }
        else
        {
            _overlayWanted = true;
            PositionOverGame(force: true);
            Show();
        }
    }
}
