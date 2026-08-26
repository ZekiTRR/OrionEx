using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Threading;
using System.Diagnostics;
using System.Net.Http;
using System.Text.Json;

namespace OrbitAvalonia;

// SirHurt V5 Remake: hosts the reference web UI (SirHurtV5UI) and serves as
// its native bridge. The page talks to window.chrome.webview.hostObjects.bridge
// through an injected shim that forwards calls here as JSON messages.
public sealed partial class SirHurtV5RemakeWindow : Window
{
    private const string RscriptsApi = "https://rscripts.net/api/v2/scripts";

    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly EditorWorkspaceService _filesService = new();
    private readonly string _dataRoot;
    private readonly HttpClient _http = new()
    {
        Timeout = TimeSpan.FromSeconds(20)
    };

    private NativeWebView? _webView;
    private MonacoStaticServer? _uiServer;
    private bool _webViewDisposed;

    internal SirHurtV5RemakeWindow() : this(
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal SirHurtV5RemakeWindow(
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _scriptsDirectory = scriptsDirectory;
        _workspace = initialWorkspace.CloneDetached();
        _returnToOrion = returnToOrion;
        _dataRoot = System.IO.Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Orbit",
            "SirHurtV5");

        AvaloniaXamlLoader.Load(this);
        _webView = this.FindControl<NativeWebView>("UiWebView");

        Closed += SirHurtV5RemakeWindow_Closed;
        Opened += SirHurtV5RemakeWindow_Opened;
    }

    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "Script 1", Extension = ".lua" };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private async void SirHurtV5RemakeWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SirHurtV5RemakeWindow_Opened;

        try
        {
            System.IO.File.AppendAllText(
                System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-open.log"),
                DateTime.Now.ToString("HH:mm:ss") + " opening\n");
        }
        catch { }

        try
        {
            var uiRoot = System.IO.Path.Combine(AppContext.BaseDirectory, "SirHurtV5UI");
            _uiServer = new MonacoStaticServer(uiRoot);
            if (_webView is { } webView)
            {
                webView.WebMessageReceived += UiWebView_WebMessageReceived;
                webView.Source = _uiServer.Address;
                webView.NavigationCompleted += async (_, _) =>
                {
                    try
                    {
                        var probe = await webView.InvokeScript(
                            "(function(){ return typeof window.invokeCSharpAction + '|' + typeof window.chrome; })()");
                        System.IO.File.AppendAllText(
                            System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                            DateTime.Now.ToString("HH:mm:ss") + " probe: " + probe + "\n");
                    }
                    catch (Exception probeException)
                    {
                        System.IO.File.AppendAllText(
                            System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                            DateTime.Now.ToString("HH:mm:ss") + " probe failed: " + probeException.Message + "\n");
                    }
                };
            }

            StartEdgeWatcher();
        }
        catch (Exception exception)
        {
            try
            {
                System.IO.File.AppendAllText(
                    System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-open.log"),
                    DateTime.Now.ToString("HH:mm:ss") + " ERROR " + exception + "\n");
            }
            catch { }

            await Dispatcher.UIThread.InvokeAsync(() =>
                Title = "SirHurt V5 Remake \u2014 UI failed to load: " + exception.Message);
        }
    }

    private void SirHurtV5RemakeWindow_Closed(object? sender, EventArgs e)
    {
        _webViewDisposed = true;
        if (_webView is { } webView)
        {
            webView.WebMessageReceived -= UiWebView_WebMessageReceived;
        }

        _edgeTimer?.Stop();
        _uiServer?.Dispose();
        _filesService.Dispose();
        _http.Dispose();
    }

    // ─────────────────────────── bridge dispatch ───────────────────────────

    private async void UiWebView_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
    {
        if (_webViewDisposed || string.IsNullOrWhiteSpace(args.Body))
        {
            return;
        }

        try
        {
            System.IO.File.AppendAllText(
                System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                DateTime.Now.ToString("HH:mm:ss.fff") + " BODY: " + args.Body + "\n");
        }
        catch { }

        int id;
        string method;
        JsonElement[] args2;
        try
        {
            var payload = JsonDocument.Parse(args.Body);
            var root = payload.RootElement;

            // The WebView adapter converts string messages to WebMessageAsJson,
            // so a JSON.stringify payload arrives double-encoded as a quoted
            // string; unwrap until an object is reached.
            var unwrapCount = 0;
            while (root.ValueKind == JsonValueKind.String && unwrapCount++ < 3)
            {
                payload = JsonDocument.Parse(root.GetString() ?? "{}");
                root = payload.RootElement;
            }

            if (!root.TryGetProperty("__zb", out var idProperty))
            {
                return;
            }

            id = idProperty.GetInt32();
            method = root.TryGetProperty("method", out var m) ? m.GetString() ?? string.Empty : string.Empty;
            var arr = root.TryGetProperty("args", out var a) && a.ValueKind == JsonValueKind.Array
                ? a
                : default;
            args2 = arr.ValueKind == JsonValueKind.Array
                ? arr.EnumerateArray().ToArray()
                : [];
        }
        catch (JsonException)
        {
            return;
        }

        var result = await DispatchAsync(method, args2);
        try
        {
            System.IO.File.AppendAllText(
                System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                DateTime.Now.ToString("HH:mm:ss.fff") + " dispatched " + method + " -> " +
                (result is null ? "null" : result.GetType().Name) + "\n");
        }
        catch { }

        if (_webViewDisposed)
        {
            return;
        }

        try
        {
            var json = result is null ? "null" : JsonSerializer.Serialize(result);
            _webView?.InvokeScript($"window.__zbResolve({id}, {JsonSerializer.Serialize(json)});");
        }
        catch (InvalidOperationException)
        {
            // Page is gone; the pending promise times out on its own.
        }
    }

    private async Task<object?> DispatchAsync(string method, JsonElement[] args)
    {
        string Arg(int i) => i < args.Length && args[i].ValueKind == JsonValueKind.String
            ? args[i].GetString() ?? string.Empty
            : string.Empty;

        switch (method)
        {
            case "Execute":
            {
                var code = Arg(0);
                if (!string.IsNullOrWhiteSpace(code))
                {
                    _bridge.EnqueueExecute(code);
                }

                return "ok";
            }

            case "GetScripts":
                return GetScriptsEntries(Arg(0));

            case "ReadScript":
            case "ReadScriptRaw":
                return await ReadFileSafeAsync(ResolveFolder(Arg(0)), Arg(1));

            case "WriteScript":
                WriteFileSafe(ResolveFolder(Arg(0)), Arg(1), Arg(2));
                return "ok";

            case "DeleteScript":
                DeleteEntry(ResolveFolder(Arg(0)), Arg(1));
                return "ok";

            case "RenameScript":
                RenameEntry(ResolveFolder(Arg(0)), Arg(1), Arg(2));
                return "ok";

            case "FetchUrlContent":
                try
                {
                    return await _http.GetStringAsync(Arg(0));
                }
                catch (Exception exception) when (
                    exception is HttpRequestException or InvalidOperationException or TaskCanceledException)
                {
                    return null;
                }

            case "FetchRScripts":
                try
                {
                    var page = 1;
                    if (args.Length > 0 && args[0].TryGetInt32(out var parsed))
                    {
                        page = parsed;
                    }

                    var url = $"{RscriptsApi}?page={page}";
                    var query = Arg(1);
                    if (query.Length > 0)
                    {
                        url += "&q=" + Uri.EscapeDataString(query);
                    }

                    using (var request = new HttpRequestMessage(HttpMethod.Get, url))
                    {
                        request.Headers.UserAgent.ParseAdd("OrionEx/1.0");
                        request.Headers.Referrer = new Uri("https://rscripts.net/");
                        using var response = await _http.SendAsync(request);
                        response.EnsureSuccessStatusCode();
                        return await response.Content.ReadAsStringAsync();
                    }
                }
                catch (Exception exception) when (
                    exception is HttpRequestException or InvalidOperationException or TaskCanceledException)
                {
                    return "{\"scripts\":[]}";
                }

            case "OpenBrowser":
                OpenUrl(Arg(0));
                return "ok";

            case "Minimize":
                Dispatcher.UIThread.Post(() => WindowState = WindowState.Minimized);
                return "ok";

            case "Maximize":
                Dispatcher.UIThread.Post(() =>
                    WindowState = WindowState == WindowState.Maximized
                        ? WindowState.Normal
                        : WindowState.Maximized);
                return "ok";

            case "Close":
                Dispatcher.UIThread.Post(() =>
                {
                    _returnToOrion(_workspace.CloneDetached());
                    Close();
                });
                return "ok";

            case "SetTopMost":
                Dispatcher.UIThread.Post(() => Topmost = args.Length > 0 && args[0].GetBoolean());
                return "ok";

            case "SetUISize":
                Dispatcher.UIThread.Post(() =>
                {
                    try
                    {
                        Width = args.Length > 0 && args[0].TryGetDouble(out var w) ? w : Width;
                        Height = args.Length > 1 && args[1].TryGetDouble(out var h) ? h : Height;
                    }
                    catch (InvalidOperationException) { }
                });
                return "ok";

            case "GetSavedSettings":
                try
                {
                    var settingsPath = System.IO.Path.Combine(_dataRoot, "ui-settings.json");
                    return File.Exists(settingsPath)
                        ? File.ReadAllText(settingsPath)
                        : null;
                }
                catch (IOException)
                {
                    return null;
                }

            case "SaveSettings":
                try
                {
                    Directory.CreateDirectory(_dataRoot);
                    File.WriteAllText(
                        System.IO.Path.Combine(_dataRoot, "ui-settings.json"),
                        Arg(0));
                }
                catch (IOException) { }
                catch (UnauthorizedAccessException) { }

                return "ok";

            case "KillAllRoblox":
                try
                {
                    foreach (var process in Process.GetProcessesByName("RobloxPlayerBeta"))
                    {
                        try { process.Kill(true); }
                        finally { process.Dispose(); }
                    }
                }
                catch (InvalidOperationException) { }

                return "ok";

            case "CopyToClipboard":
                try
                {
                    System.Windows.Forms.Clipboard.SetText(Arg(0));
                }
                catch (System.Runtime.InteropServices.ExternalException) { }
                return "ok";

            case "OpenFolder":
            case "OpenRobloxFolder":
                try
                {
                    var folder = method == "OpenFolder" ? _scriptsDirectory : _filesService.AutoExecuteDirectory;
                    Directory.CreateDirectory(folder);
                    using (Process.Start(new ProcessStartInfo
                    {
                        FileName = folder,
                        UseShellExecute = true
                    })) { }
                }
                catch (InvalidOperationException) { }

                return "ok";

            case "OpenFile":
                OpenFileViaPicker();
                return "ok";

            case "SaveFile":
                SaveFileViaPicker(Arg(0));
                return "ok";

            case "StartCustomDrag":
                StartNativeDrag();
                return "ok";

            case "UIReady":
            case "WatchFolder":
            case "Attach":
            case "SetAutoInject":
            case "UnloadToLoader":
            case "StartDragging":
                StartNativeDrag();
                return "ok";
            case "EndCustomDrag":
            case "UpdateCustomDrag":
                return "ok";

            default:
                return null;
        }
    }

    // ─────────────────────────── file helpers ───────────────────────────

    private string ResolveFolder(string folder)
    {
        if (string.IsNullOrWhiteSpace(folder) || folder.Contains(':') || folder.Contains('\\'))
        {
            return folder;
        }

        var name = folder.TrimEnd('/').Split('/').Last().ToLowerInvariant();
        return name switch
        {
            "scripts" => _scriptsDirectory,
            "autoexe" or "autoexecute" => _filesService.AutoExecuteDirectory,
            _ => System.IO.Path.Combine(_dataRoot, folder.TrimEnd('/'))
        };
    }

    private IReadOnlyList<string> GetScriptsEntries(string folder)
    {
        var entries = new List<string>();
        try
        {
            Directory.CreateDirectory(folder);
            foreach (var directory in Directory.EnumerateDirectories(folder))
            {
                entries.Add(Path.GetFileName(directory) + "/");
            }

            foreach (var file in Directory.EnumerateFiles(folder))
            {
                var extension = Path.GetExtension(file);
                if (extension.Equals(".lua", StringComparison.OrdinalIgnoreCase) ||
                    extension.Equals(".luau", StringComparison.OrdinalIgnoreCase) ||
                    extension.Equals(".txt", StringComparison.OrdinalIgnoreCase) ||
                    extension.Equals(".json", StringComparison.OrdinalIgnoreCase))
                {
                    entries.Add(Path.GetFileName(file));
                }
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // An unreadable folder simply renders as an empty list.
        }

        return entries;
    }

    private static async Task<string> ReadFileSafeAsync(string folder, string name)
    {
        try
        {
            var path = SafeCombine(folder, name);
            return File.Exists(path) ? await File.ReadAllTextAsync(path) : string.Empty;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            return string.Empty;
        }
    }

    private static void WriteFileSafe(string folder, string name, string content)
    {
        try
        {
            var path = SafeCombine(folder, name);
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            File.WriteAllText(path, content ?? string.Empty);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
        }
    }

    private static void DeleteEntry(string folder, string name)
    {
        try
        {
            var path = SafeCombine(folder, name);
            if (name.EndsWith("/"))
            {
                if (Directory.Exists(path))
                {
                    Directory.Delete(path, true);
                }
            }
            else if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
        }
    }

    private static void RenameEntry(string folder, string oldName, string newName)
    {
        try
        {
            var oldPath = SafeCombine(folder, oldName);
            var newPath = SafeCombine(folder, newName);
            if (File.Exists(oldPath))
            {
                File.Move(oldPath, newPath, overwrite: false);
            }
            else if (Directory.Exists(oldPath) && !Directory.Exists(newPath))
            {
                Directory.Move(oldPath, newPath);
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
        }
    }

    private static string SafeCombine(string folder, string name)
    {
        var clean = (name ?? string.Empty).TrimEnd('/').Replace('/', Path.DirectorySeparatorChar);
        return Path.Combine(folder, clean);
    }

    // ─────────────────────────── file pickers ───────────────────────────

    private TaskCompletionSource<string[]?>? _openFileCompletion;
    private TaskCompletionSource<string?>? _saveFileCompletion;

    private void OpenFileViaPicker()
    {
        var completion = _openFileCompletion = new TaskCompletionSource<string[]?>(TaskCreationOptions.RunContinuationsAsynchronously);
        Dispatcher.UIThread.Post(async () =>
        {
            try
            {
                var files = await StorageProvider.OpenFilePickerAsync(new Avalonia.Platform.Storage.FilePickerOpenOptions
                {
                    Title = "Open script",
                    AllowMultiple = false,
                    FileTypeFilter =
                    [
                        new Avalonia.Platform.Storage.FilePickerFileType("Script files")
                        {
                            Patterns = ["*.lua", "*.luau", "*.txt"]
                        }
                    ]
                });

                var file = files.FirstOrDefault();
                if (file is null)
                {
                    completion.SetResult(null);
                    return;
                }

                await using var stream = await file.OpenReadAsync();
                using var reader = new StreamReader(stream);
                var content = await reader.ReadToEndAsync();
                completion.TrySetResult(new[] { file.Name, content });
            }
            catch (Exception exception)
            {
                try
                {
                    System.IO.File.AppendAllText(
                        System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                        DateTime.Now.ToString("HH:mm:ss") + " OpenFile error: " + exception + "\n");
                }
                catch { }

                completion.TrySetResult(null);
            }
        });
    }

    private void SaveFileViaPicker(string content)
    {
        var completion = _saveFileCompletion = new TaskCompletionSource<string?>(TaskCreationOptions.RunContinuationsAsynchronously);
        Dispatcher.UIThread.Post(async () =>
        {
            try
            {
                var file = await StorageProvider.SaveFilePickerAsync(new Avalonia.Platform.Storage.FilePickerSaveOptions
                {
                    Title = "Save script",
                    DefaultExtension = "lua",
                    FileTypeChoices =
                    [
                        new Avalonia.Platform.Storage.FilePickerFileType("Lua script") { Patterns = ["*.lua"] },
                        new Avalonia.Platform.Storage.FilePickerFileType("Text file") { Patterns = ["*.txt"] }
                    ]
                });

                if (file is null)
                {
                    completion.SetResult(null);
                    return;
                }

                await using var stream = await file.OpenWriteAsync();
                stream.SetLength(0);
                await using var writer = new StreamWriter(stream);
                await writer.WriteAsync(content ?? string.Empty);
                completion.TrySetResult(file.Name);
            }
            catch (Exception exception)
            {
                try
                {
                    System.IO.File.AppendAllText(
                        System.IO.Path.Combine(System.IO.Path.GetTempPath(), "v5-bridge.log"),
                        DateTime.Now.ToString("HH:mm:ss") + " SaveFile error: " + exception + "\n");
                }
                catch { }

                completion.TrySetResult(null);
            }
        });
    }

    // ───────────────── native drag & edge resize ─────────────────

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool GetCursorPos(out NativePoint p);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr LoadCursor(IntPtr hInstance, IntPtr lpCursorName);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr SetCursor(IntPtr hCursor);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr hWnd, out NativeRect r);

    [System.Runtime.InteropServices.DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct NativePoint { public int X, Y; }

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct NativeRect { public int Left, Top, Right, Bottom; }

    private const int VkLbutton = 0x01;
    private const uint SwpNozorder = 0x0004;
    private const uint SwpNosize = 0x0001;
    private const int EdgeGrip = 8;

    private static readonly IntPtr CursorArrow = LoadCursor(IntPtr.Zero, new IntPtr(32512));
    private static readonly IntPtr CursorWe = LoadCursor(IntPtr.Zero, new IntPtr(32644));
    private static readonly IntPtr CursorNs = LoadCursor(IntPtr.Zero, new IntPtr(32645));
    private static readonly IntPtr CursorNwse = LoadCursor(IntPtr.Zero, new IntPtr(32642));
    private static readonly IntPtr CursorNesw = LoadCursor(IntPtr.Zero, new IntPtr(32643));

    private DispatcherTimer? _edgeTimer;
    private bool _nativeResizing;

    private IntPtr NativeHandle => TryGetPlatformHandle()?.Handle ?? IntPtr.Zero;

    // Called by the web UI title bar through bridge.StartDragging().
    private void StartNativeDrag()
    {
        var handle = NativeHandle;
        if (handle == IntPtr.Zero || WindowState != WindowState.Normal)
        {
            return;
        }

        var thread = new System.Threading.Thread(() =>
        {
            try
            {
                GetCursorPos(out var startCursor);
                GetWindowRect(handle, out var startRect);
                while ((GetAsyncKeyState(VkLbutton) & 0x8000) != 0)
                {
                    GetCursorPos(out var cursor);
                    SetWindowPos(
                        handle,
                        IntPtr.Zero,
                        startRect.Left + (cursor.X - startCursor.X),
                        startRect.Top + (cursor.Y - startCursor.Y),
                        0,
                        0,
                        SwpNosize | SwpNozorder);
                    System.Threading.Thread.Sleep(10);
                }
            }
            catch { }
        })
        {
            IsBackground = true
        };
        thread.Start();
    }

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
            SetCursor(CursorArrow);
            return;
        }

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
            const int minHeight = 380;

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

    private static void OpenUrl(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) ||
            (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp))
        {
            return;
        }

        try
        {
            using var _ = Process.Start(new ProcessStartInfo
            {
                FileName = uri.AbsoluteUri,
                UseShellExecute = true
            });
        }
        catch (InvalidOperationException) { }
        catch (System.ComponentModel.Win32Exception) { }
    }
}
