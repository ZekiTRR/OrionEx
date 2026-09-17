using Avalonia;
using Avalonia.Controls;
using Avalonia.Markup.Xaml;
using Avalonia.Threading;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace OrbitAvalonia;

// A local editor/UI host only. No execution, injection, client discovery or remote bridge.
public sealed partial class SynapseV3AltWindow : Window
{
    private const string UiOnly = "Execution is unavailable in this UI-only port. No injector or external client is connected.";
    private readonly string _scriptsDirectory;
    private readonly string _dataRoot;
    private readonly string _uiRoot;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly EditorWorkspaceService _workspaceService = new();
    private readonly HashSet<string> _dialogFiles = new(StringComparer.OrdinalIgnoreCase);
    private readonly List<object> _logs = [];
    private readonly NativeWebView _webView;
    private MonacoStaticServer? _server;
    private Window? _console;
    private NativeWebView? _consoleView;
    private bool _disposed, _closingForOrion, _finishingClose, _allowClose;
    private double _zoom = 1;

    internal SynapseV3AltWindow(string scriptsDirectory, EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _scriptsDirectory = Path.GetFullPath(scriptsDirectory).TrimEnd(Path.DirectorySeparatorChar);
        _dataRoot = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Orbit", "SynapseV3Alt");
        _uiRoot = Path.Combine(AppContext.BaseDirectory, "SynapseV3AltUI", "dist");
        _returnToOrion = returnToOrion ?? throw new ArgumentNullException(nameof(returnToOrion));
        _workspace = FromShared(initialWorkspace.CloneDetached());
        AvaloniaXamlLoader.Load(this);
        _webView = this.FindControl<NativeWebView>("UiWebView")!;
        Opened += OnOpened;
        Closing += OnClosing;
        Closed += OnClosed;
        PropertyChanged += (_, e) => { if (e.Property == WindowStateProperty) Emit("windowState", WindowInfo()); };
    }

    private async void OnOpened(object? sender, EventArgs e)
    {
        Opened -= OnOpened;
        try
        {
            EnsureNoLinks(_scriptsDirectory);
            Directory.CreateDirectory(_scriptsDirectory);
            _settings = ReadObject("settings.json");
            _storage = ReadObject("storage.json");
            _editorConfig = ReadObject("editor-config.json");
            RestoreTabMetadata();
            PersistWorkspace(); // Incoming Orion workspace is authoritative, never replaced by stale local tabs.
            EnsureNoLinks(_uiRoot);
            if (!File.Exists(Path.Combine(_uiRoot, "index.html")))
                throw new FileNotFoundException("SynapseV3AltUI/dist/index.html is missing. Build and deploy the UI assets first.");
            _server = new MonacoStaticServer(_uiRoot);
            ConnectView(_webView);
            _webView.Source = _server.Address;
            Log("info", "Local UI-only editor ready. External client: disconnected. Execution unavailable.");
        }
        catch (Exception error)
        {
            Title = "Synapse V3 Alt — unable to load UI";
            await ShowErrorAsync(error.Message);
            Close();
        }
    }

    private void ConnectView(NativeWebView view)
    {
        view.WebMessageReceived += OnMessage;
        view.NavigationStarted += OnNavigation;
        view.NewWindowRequested += OnNewWindow;
        view.NavigationCompleted += OnNavigationCompleted;
    }

    private void DisconnectView(NativeWebView view)
    {
        view.WebMessageReceived -= OnMessage;
        view.NavigationStarted -= OnNavigation;
        view.NewWindowRequested -= OnNewWindow;
        view.NavigationCompleted -= OnNavigationCompleted;
    }

    private bool IsLocalPage(Uri? uri) => _server is not null && uri is not null &&
        uri.Scheme == _server.Address.Scheme && uri.Host == _server.Address.Host && uri.Port == _server.Address.Port &&
        (uri.AbsolutePath == "/index.html" || uri.AbsolutePath == "/console/index.html");

    private void OnNavigation(object? sender, WebViewNavigationStartingEventArgs e)
    {
        if (!IsLocalPage(e.Request)) e.Cancel = true;
    }

    private void OnNewWindow(object? sender, WebViewNewWindowRequestedEventArgs e)
    {
        e.Handled = true;
        // External URLs are opened only through the allow-listed, explicit openExternal command.
    }

    private void OnNavigationCompleted(object? sender, WebViewNavigationCompletedEventArgs e)
    {
        Emit("windowState", WindowInfo());
        Emit("consoleSnapshot", _logs.ToArray());
    }

    private async void OnMessage(object? sender, WebMessageReceivedEventArgs e)
    {
        if (_disposed || sender is not NativeWebView view || string.IsNullOrWhiteSpace(e.Body) || e.Body.Length > 24_000_000) return;
        JsonNode? id = null;
        string method = "";
        try
        {
            var root = ParseUnwrapped(e.Body) as JsonObject;
            if (root?["synapseAlt"]?.ToJsonString() != "1") return;
            id = root["id"]?.DeepClone();
            if (id is not JsonValue || id.ToJsonString().Length > 160) return;
            method = root["method"]?.GetValue<string>() ?? "";
            var args = root["args"] as JsonArray ?? new JsonArray();
            var result = await DispatchAsync(view, method, args);
            await EvaluateSafeAsync(view, $"window.synapseAltResolve?.({id.ToJsonString()},{JsonSerializer.Serialize(result)},null);");
        }
        catch (Exception error)
        {
            Log("error", error.Message);
            if (id is not null)
                await EvaluateSafeAsync(view, $"window.synapseAltResolve?.({id.ToJsonString()},null,{JsonSerializer.Serialize(error.Message)});");
        }
    }

    private async Task<object?> DispatchAsync(NativeWebView source, string method, JsonArray args)
    {
        string Text(int index) => index < args.Count && args[index] is JsonValue value && value.TryGetValue<string>(out var s) ? s : "";
        JsonNode? Value(int index) => index < args.Count ? args[index] : null;
        bool console = source == _consoleView;
        if (_finishingClose && method is not ("saveWorkspace" or "saveStorage" or "close"))
            throw new InvalidOperationException("The editor is closing.");
        if (console && method is not ("getBootstrap" or "getSetting" or "listThemes" or "loadTheme" or "getConsoleLogs" or "flushConsoleLogs" or "clearConsole" or "close" or "minimize" or "maximize" or "startWindowDrag" or "openExternal"))
            throw new InvalidOperationException("This operation is not available in the local console.");
        var target = console ? _console! : this;
        switch (method)
        {
            case "getBootstrap": return new { settings = _settings, storage = _storage, workspace = _workspace,
                windowState = new { isMaximized = target.WindowState == WindowState.Maximized }, isMaximized = target.WindowState == WindowState.Maximized,
                externalClient = false, connected = false, clients = Array.Empty<object>(), uiOnly = true, logs = _logs.ToArray() };
            case "saveWorkspace": AcceptWorkspace(Value(0)); PersistWorkspace(); return true;
            case "saveStorage": _storage = RequireObject(Value(0)); PersistObject("storage.json", _storage); return true;
            case "getSetting": return _settings[Text(0)] ?? Value(1);
            case "setSetting": SetValue(_settings, Text(0), Value(1), "settings.json"); Emit("settingsChanged", new { key = Text(0), value = Value(1) }); return true;
            case "getEditorConfig": return _editorConfig[Text(0)] ?? new JsonObject();
            case "setEditorConfig": SetValue(_editorConfig, Text(0), Value(1), "editor-config.json"); return true;
            case "listSystemFonts": return Avalonia.Media.FontManager.Current.SystemFonts
                .Select(family => family.Name).Where(name => !string.IsNullOrWhiteSpace(name))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .OrderBy(name => name, StringComparer.CurrentCultureIgnoreCase).ToArray();
            case "listScripts": return ListScripts();
            case "listGists": return _workspaceService.ListGists().Select(g => new { name = g.DisplayName, path = g.FullPath });
            case "addGist":
                if (!await ConfirmAsync("Add GitHub Gist", $"Store this link in the “Github Gists” folder?\n\n{Text(0)}")) return false;
                return _workspaceService.StoreGistUrl(Text(0)) is { Length: > 0 } ? true : false;
            case "readGist":
            {
                var gist = _workspaceService.ListGists().FirstOrDefault(g => string.Equals(g.FullPath, Text(0), StringComparison.OrdinalIgnoreCase))
                    ?? throw new FileNotFoundException("Choose a saved entry from GitHub Gists.");
                var url = ReadText(gist.FullPath).Trim();
                return new { name = gist.DisplayName, content = await _workspaceService.FetchGistAsync(url, CancellationToken.None) };
            }
            case "readScript": { var path = ResolveScript(Text(0)); return new { name = Path.GetFileName(path), content = ReadText(path) }; }
            case "saveScript":
                try { var path = ResolveScript(Text(0)); await WriteScriptAsync(path, Text(1)); return new { ok = true, filePath = path, name = Path.GetFileName(path), error = (string?)null }; }
                catch (Exception error) { Log("error", error.Message); return new { ok = false, filePath = (string?)null, name = (string?)null, error = error.Message }; }
            case "openFileDialog": case "openFile": return await OpenFileAsync();
            case "saveFile": return await SaveFileAsync(Text(0), Text(1));
            case "deleteScript": return await DeleteScriptAsync(Text(0));
            case "listThemes": return ReadThemes();
            case "loadTheme": return ReadThemes().FirstOrDefault(t => t?["id"]?.GetValue<string>() == Text(0) || t?["folderName"]?.GetValue<string>() == Text(0))
                ?? throw new FileNotFoundException("The requested bundled theme does not exist.");
            case "openThemeFolder": OpenThemeFolder(); return true;
            case "openExternal": case "openBrowser": OpenExternal(Text(0)); return true;
            case "minimize": target.WindowState = WindowState.Minimized; return true;
            case "maximize": target.WindowState = target.WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized; return true;
            case "close": Dispatcher.UIThread.Post(target.Close); return true;
            case "startWindowDrag": StartNativeDrag(target); return true;
            case "setAlwaysOnTop": Topmost = Value(0)?.GetValue<bool>() ?? false; return true;
            case "setZoomFactor":
                _zoom = Value(0)?.GetValue<double>() ?? 1;
                if (!double.IsFinite(_zoom) || _zoom < .25 || _zoom > 1.5) throw new ArgumentException("Zoom must be between 0.25 and 1.5.");
                await _webView.InvokeScript($"window.hwAPI?.setZoomFactor({JsonSerializer.Serialize(_zoom)});"); return true;
            case "openConsole": OpenConsole(); return true;
            case "getConsoleLogs": return _logs.ToArray();
            case "flushConsoleLogs":
                foreach (var entry in _logs.ToArray())
                    await EvaluateSafeAsync(source, $"window.synapseAltEvent?.('consoleMessage',{JsonSerializer.Serialize(entry)});");
                return true;
            case "clearConsole": _logs.Clear(); Emit("consoleSnapshot", _logs.ToArray()); return true;
            case "getChangelog": return "SynapseV3Alt: local editor with local-file bookmarks and on-demand GitHub Gists. Execution, external clients and plugins are unavailable.";
            case "showItemInFolder": ShowItemInFolder(Text(0)); return true;
            case "execute": throw new InvalidOperationException(UiOnly);
            case "getClients": return Array.Empty<object>();
            case "isAttached": case "isConnected": return false;
            default: throw new NotSupportedException($"Unsupported UI-only operation: {method}");
        }
    }

    internal void CloseForOrion() { _closingForOrion = true; if (!_disposed) Close(); }

    private async void OnClosing(object? sender, WindowClosingEventArgs e)
    {
        if (_allowClose) return;
        e.Cancel = true;
        if (_finishingClose) return;
        _finishingClose = true;
        try
        {
            try
            {
                var snapshot = await _webView.InvokeScript("JSON.stringify(window.synapseAltSnapshot?.() ?? null)").WaitAsync(TimeSpan.FromSeconds(2));
                if (snapshot is not null && ParseUnwrapped(snapshot) is JsonObject state)
                {
                    if (state["workspace"] is JsonObject workspace) AcceptWorkspace(workspace);
                    if (state["storage"] is JsonObject storage) { _storage = (JsonObject)storage.DeepClone(); PersistObject("storage.json", _storage); }
                    if (state["settings"] is JsonObject settings) { _settings = (JsonObject)settings.DeepClone(); PersistObject("settings.json", _settings); }
                }
            }
            catch (Exception error) { Log("warning", "Final snapshot unavailable; retaining last saved host workspace. " + error.Message); }
            PersistWorkspace();
        }
        catch (Exception error) { await ShowErrorAsync("Unable to persist workspace: " + error.Message); }
        finally { _allowClose = true; Close(); }
    }

    private void OnClosed(object? sender, EventArgs e)
    {
        _disposed = true;
        _console?.Close();
        DisconnectView(_webView);
        Content = null; // Detaching NativeWebView destroys its native adapter; do not Hide/reparent it.
        _server?.Dispose();
        _server = null;
        _workspaceService.Dispose();
        if (!_closingForOrion) _returnToOrion(ToShared());
    }

    private void OpenConsole()
    {
        if (_console is not null) { _console.Activate(); return; }
        if (_server is null) throw new InvalidOperationException("Local UI server is unavailable.");
        var view = new NativeWebView();
        var window = new Window { Title = "Synapse V3 Alt — local console", Width = 760, Height = 420, MinWidth = 450, MinHeight = 250, Content = view };
        _console = window; _consoleView = view;
        ConnectView(view);
        window.PropertyChanged += (_, e) =>
        {
            if (e.Property == WindowStateProperty)
                _ = EvaluateSafeAsync(view, $"window.synapseAltEvent?.('windowState',{{isMaximized:{(window.WindowState == WindowState.Maximized ? "true" : "false")}}});");
        };
        window.Closed += (_, _) => { DisconnectView(view); window.Content = null; _console = null; _consoleView = null; };
        window.Show(this);
        view.Source = new Uri(_server.Address, "console/index.html");
    }

    private object WindowInfo() => new { isMaximized = WindowState == WindowState.Maximized };
    private void Log(string level, string message)
    {
        var entry = new { level, text = message, message, timestamp = DateTimeOffset.Now.ToString("O") };
        _logs.Add(entry); if (_logs.Count > 500) _logs.RemoveAt(0);
        Emit("consoleMessage", entry);
    }
    private void Emit(string name, object payload)
    {
        if (_disposed) return;
        var script = $"window.synapseAltEvent?.({JsonSerializer.Serialize(name)},{JsonSerializer.Serialize(payload)});";
        _ = EvaluateSafeAsync(_webView, script);
        if (_consoleView is not null) _ = EvaluateSafeAsync(_consoleView, script);
    }
    private async Task EvaluateSafeAsync(NativeWebView view, string script)
    {
        if (_disposed) return;
        try { await view.InvokeScript(script); } catch (Exception) { /* Page may not be ready, or has closed. */ }
    }
    private static JsonNode? ParseUnwrapped(string json)
    {
        var node = JsonNode.Parse(json);
        for (var i = 0; i < 3 && node is JsonValue value && value.TryGetValue<string>(out var inner); i++) node = JsonNode.Parse(inner);
        return node;
    }
    private static void OpenExternal(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme is not ("http" or "https"))
            throw new ArgumentException("Only HTTP and HTTPS browser links are allowed.");
        using var process = Process.Start(new ProcessStartInfo(uri.AbsoluteUri) { UseShellExecute = true });
        if (process is null) throw new InvalidOperationException("Unable to open the default browser.");
    }
    [DllImport("user32.dll")] private static extern bool ReleaseCapture();
    [DllImport("user32.dll")] private static extern IntPtr SendMessage(IntPtr window, uint message, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    private static void StartNativeDrag(Window window)
    {
        if (!OperatingSystem.IsWindows() || (GetAsyncKeyState(1) & 0x8000) == 0) return;
        var handle = window.TryGetPlatformHandle()?.Handle ?? IntPtr.Zero;
        if (handle == IntPtr.Zero) return;
        ReleaseCapture();
        SendMessage(handle, 0xA1, new IntPtr(2), IntPtr.Zero);
    }
}
