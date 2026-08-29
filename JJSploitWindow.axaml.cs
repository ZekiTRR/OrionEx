using System;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using Avalonia.VisualTree;

namespace OrbitAvalonia;

// JJSploit UI — 1:1 native port of the JJSploit Electron menu
// (D:\Cheats\Orion\JJSploit-UI-Source-main\app_.asar\build\). 500x300 frameless
// window, dark #131418 top bar, dark #333333 body, General view only.
public sealed partial class JJSploitWindow : Window
{
    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;

    private JJSploitGeneralView? _generalView;
    private NativeWebView? _luaWebView;
    private Button? _topMostBtn;
    private TextBlock? _siteLinkText;

    private bool _topMostOn;
    private bool _closingForOrion;
    private bool _returnRequested;
    private bool _editorReady;
    private bool _luaSourceAssigned;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;

    public JJSploitWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        new EditorWorkspaceState(),
        static _ => { })
    {
    }

    internal JJSploitWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _workspace = initialWorkspace.CloneDetached();
        _returnToOrion = returnToOrion;

        AvaloniaXamlLoader.Load(this);

        _generalView = this.FindControl<JJSploitGeneralView>("GeneralView");
        _topMostBtn = this.FindControl<Button>("TopMostBtn");
        _siteLinkText = this.FindControl<TextBlock>("SiteLinkText");

        if (_generalView is not null)
        {
            // Subscribe to Monaco WebView messages BEFORE Source is set, so the
            // first `ready` event from Monaco is not lost.
            _luaWebView = _generalView.FindControl<NativeWebView>("LuaWebView");
            if (_luaWebView is not null)
            {
                _luaWebView.WebMessageReceived += LuaWebView_WebMessageReceived;
            }

            _generalView.QuickCommandRequested += (_, cmd) => HandleQuickCommand(cmd);
            _generalView.LuaExecuteRequested += (_, _) => _ = RequestLuaExecuteAsync();
            _generalView.LuaOpenFileRequested += (_, _) => _ = OpenLuaFileAsync();
            _generalView.WalkSpeedExecuteRequested += (_, value) => ExecuteWithPlaceholder("inline/walkspeed.lua", "value", value);
            _generalView.JumpPowerExecuteRequested += (_, value) => ExecuteWithPlaceholder("inline/jumppower.lua", "value", value);
            _generalView.TeleportExecuteRequested += (_, xyz) => ExecuteTeleport(xyz);
        }

        Closed += JJSploitWindow_Closed;
        Opened += JJSploitWindow_Opened;
    }

    private void JJSploitWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= JJSploitWindow_Opened;
        if (_generalView is null || _luaWebView is null) return;

        // The General view's constructor already calls SelectTab("Lua"), so the
        // Lua tab and its WebView are visible. Just make sure the WebView is
        // shown and assign the Source once.
        _luaWebView.IsVisible = true;
        if (_luaSourceAssigned) return;
        _luaSourceAssigned = true;
        try
        {
            _luaWebView.Source = new UriBuilder(_monacoAddress) { Query = "transparent=1" }.Uri;
        }
        catch { }
    }

    private void JJSploitWindow_Closed(object? sender, EventArgs e)
    {
        if (_luaWebView is not null)
        {
            _luaWebView.WebMessageReceived -= LuaWebView_WebMessageReceived;
        }

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _closingForOrion = true;
            _returnToOrion(_workspace.CloneDetached());
        }
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        _returnRequested = true;
        Close();
    }

    // ─────────────────────────── top bar ───────────────────────────

    private void TopBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Visual v &&
            (v is Button || v.GetVisualAncestors().OfType<Button>().Any()))
        {
            return;
        }
        if (WindowState != WindowState.Maximized)
        {
            BeginMoveDrag(e);
        }
    }

    private void TopBar_Site_Click(object? sender, RoutedEventArgs e)
    {
        OpenUrl("https://wearedevs.net/");
        if (_siteLinkText is not null)
        {
            _siteLinkText.Foreground = new SolidColorBrush(Color.Parse("#3498DB"));
        }
    }

    private void TopBar_FixRoblox_Click(object? sender, RoutedEventArgs e)
    {
        try
        {
            foreach (var p in Process.GetProcessesByName("RobloxPlayerBeta"))
            {
                try { p.Kill(entireProcessTree: true); }
                catch { }
                finally { p.Dispose(); }
            }
        }
        catch { }
    }

    private void TopBar_TopMost_Click(object? sender, RoutedEventArgs e)
    {
        _topMostOn = !_topMostOn;
        Topmost = _topMostOn;
        if (_topMostBtn is null) return;
        if (_topMostBtn.Classes.Contains("topmost-on"))
        {
            _topMostBtn.Classes.Remove("topmost-on");
        }
        else
        {
            _topMostBtn.Classes.Add("topmost-on");
        }
    }

    private void TopBar_Exit_Click(object? sender, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    // ─────────────────────────── toast (TODO marker) ───────────────────────────

    private async void ShowToast(string text)
    {
        var pill = new Border
        {
            Background = new SolidColorBrush(Color.Parse("#1F1F1F")),
            BorderBrush = new SolidColorBrush(Color.Parse("#3A3A3A")),
            BorderThickness = new Thickness(1),
            CornerRadius = new CornerRadius(6),
            Padding = new Thickness(10, 6),
            Opacity = 0,
            IsHitTestVisible = false,
            HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Center,
            VerticalAlignment = Avalonia.Layout.VerticalAlignment.Bottom,
            Margin = new Thickness(0, 0, 0, 20)
        };
        var tb = new TextBlock { FontSize = 11, Foreground = new SolidColorBrush(Color.Parse("#ECECEC")), Text = text };
        pill.Child = tb;
        if (_generalView is { } view)
        {
            // Place toast inside the general view so it stays within the window
            var host = view.Parent as Panel;
            if (host is null)
            {
                // Fallback: add to a top-level Grid
                if (Content is Panel p) p.Children.Add(pill);
            }
            else
            {
                host.Children.Add(pill);
            }
        }
        try
        {
            for (int i = 0; i < 10; i++) { pill.Opacity = i / 10.0; await Task.Delay(20); }
            await Task.Delay(1400);
            for (int i = 10; i >= 0; i--) { pill.Opacity = i / 10.0; await Task.Delay(20); }
        }
        catch { }
    }

    // ─────────────────────────── return to Orion ───────────────────────────

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested) return;
        _returnRequested = true;
        await Task.CompletedTask;
        _closingForOrion = true;
        _returnToOrion(_workspace.CloneDetached());
        Close();
    }

    // ─────────────────────────── lua executor (Monaco) ───────────────────────────

    private void LuaWebView_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
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
                    Dispatcher.UIThread.Post(() => _editorReady = true);
                    break;
                case "executeRequested" when root.TryGetProperty("content", out var content):
                    var text = content.GetString() ?? string.Empty;
                    Dispatcher.UIThread.Post(() => ExecuteOnBridge(text));
                    break;
                case "contentSnapshot" when root.TryGetProperty("content", out var snapshot):
                    var snap = snapshot.GetString() ?? string.Empty;
                    Dispatcher.UIThread.Post(() => _pendingEditorSnapshot?.TrySetResult(snap));
                    break;
            }
        }
        catch (JsonException) { }
    }

    private async Task RequestLuaExecuteAsync()
    {
        var source = await RequestLuaContentAsync();
        if (string.IsNullOrWhiteSpace(source))
        {
            ShowToast("Nothing to execute");
            return;
        }
        ExecuteOnBridge(source);
    }

    private void ExecuteOnBridge(string source)
    {
        if (!_bridge.IsConnected)
        {
            ShowToast("Not injected — run Orion Bridge.lua first");
            return;
        }
        _bridge.EnqueueExecute(source);
    }

    // ─────────────────────────── quick commands ───────────────────────────
    //
    // Buttons in the General view carry a `Tag` that follows one of two
    // conventions:
    //   - "script:<relative path>" — load Scripts/JJSploit/luascripts/<path>
    //     and send it to the bridge. Mirrors the original app.asar
    //     `storedluascript` action which reads the same files.
    //   - anything else — for now we just surface a TODO toast. The original
    //     app sends inline luascript payloads (loadstring via HttpGet, etc.);
    //     wiring those up requires either network access or a local copy of
    //     the upstream scripts, neither of which is in scope right now.
    private readonly Dictionary<string, string> _scriptCache = new(StringComparer.OrdinalIgnoreCase);

    private void HandleQuickCommand(string cmd)
    {
        if (string.IsNullOrWhiteSpace(cmd))
        {
            return;
        }

        if (cmd.StartsWith("script:", StringComparison.Ordinal))
        {
            // Format: script:<relative path>[?toggle=<Name>]
            // The optional ?toggle= is consumed here and not part of the file
            // name. inline/esp.lua is re-injected on every click and flips its
            // own persistent BoolValue, so each button just resubmits the same
            // script — the toggle parameter is informational.
            var raw = cmd.Substring("script:".Length);
            string relative;
            var queryIdx = raw.IndexOf('?');
            if (queryIdx >= 0)
            {
                relative = raw.Substring(0, queryIdx);
            }
            else
            {
                relative = raw;
            }
            relative = relative.Replace('/', System.IO.Path.DirectorySeparatorChar);
            var content = LoadScriptFromResources(relative);
            if (string.IsNullOrEmpty(content))
            {
                ShowToast("Script not found: " + relative);
                return;
            }
            ExecuteOnBridge(content);
            return;
        }

        if (cmd.StartsWith("Magnetize", StringComparison.Ordinal))
        {
            // Magnetize has a side-effect of also loading magnetizeto.lua. The
            // General view already sent the username as part of the cmd
            // string ("Magnetize to: <name>"), but the original JS bundled the
            // username into a luascript payload alongside the storedluascript
            // call. For now we just fire the storedluascript and let the user
            // run it.
            var content = LoadScriptFromResources("general" + System.IO.Path.DirectorySeparatorChar + "magnetizeto.lua");
            if (!string.IsNullOrEmpty(content))
            {
                ExecuteOnBridge(content);
            }
            else
            {
                ShowToast("TODO: " + cmd);
            }
            return;
        }

        if (cmd.StartsWith("vectorteleport", StringComparison.Ordinal))
        {
            // vectorteleport <x> <y> <z> — show a TODO toast; the General
            // view already has TpV3 inputs that build this string. A future
            // step is to convert the JJSploit click-command into a
            // CFrame.new(x, y, z) luascript.
            ShowToast("TODO: " + cmd);
            return;
        }

        ShowToast("TODO: " + cmd);
    }

    private string LoadScriptFromResources(string relative)
    {
        if (_scriptCache.TryGetValue(relative, out var cached))
        {
            return cached;
        }

        // Strip the optional "inline/" or "luascripts/" prefix from the
        // caller-supplied path, because the JJSploit tree on disk has two
        // sibling subfolders and we don't want to double up ("inline/inline/").
        var normalised = relative.Replace('\\', '/');
        string? tail = null;
        if (normalised.StartsWith("inline/", StringComparison.OrdinalIgnoreCase))
        {
            tail = normalised.Substring("inline/".Length);
        }
        else if (normalised.StartsWith("luascripts/", StringComparison.OrdinalIgnoreCase))
        {
            tail = normalised.Substring("luascripts/".Length);
        }
        tail ??= normalised;

        // Try the canonical JJSploit tree first, then a flat fallback.
        var candidates = new[]
        {
            System.IO.Path.Combine(_scriptsDirectory, "JJSploit", "inline", tail),
            System.IO.Path.Combine(_scriptsDirectory, "JJSploit", "luascripts", tail),
            System.IO.Path.Combine(_scriptsDirectory, "inline", tail),
            System.IO.Path.Combine(_scriptsDirectory, "luascripts", tail)
        };
        foreach (var path in candidates)
        {
            try
            {
                if (System.IO.File.Exists(path))
                {
                    var text = System.IO.File.ReadAllText(path);
                    _scriptCache[relative] = text;
                    return text;
                }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
        return string.Empty;
    }

    // Loads a script with a single {placeholder} substituted by the supplied
    // value. Used for inline/walkspeed.lua, inline/jumppower.lua where the
    // Lua body just sets a single Humanoid property.
    private void ExecuteWithPlaceholder(string relativePath, string placeholder, string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            ShowToast("Value is empty");
            return;
        }
        var template = LoadScriptFromResources(relativePath);
        if (string.IsNullOrEmpty(template))
        {
            ShowToast("Script not found: " + relativePath);
            return;
        }
        var content = template.Replace("{" + placeholder + "}", value);
        ExecuteOnBridge(content);
    }

    // Teleport: {x}, {y}, {z} placeholders.
    private void ExecuteTeleport(string xyz)
    {
        var parts = xyz.Split('|');
        if (parts.Length != 3)
        {
            ShowToast("Bad teleport args");
            return;
        }
        var template = LoadScriptFromResources("inline/teleport.lua");
        if (string.IsNullOrEmpty(template))
        {
            ShowToast("Script not found: inline/teleport.lua");
            return;
        }
        var content = template
            .Replace("{x}", parts[0].Trim())
            .Replace("{y}", parts[1].Trim())
            .Replace("{z}", parts[2].Trim());
        ExecuteOnBridge(content);
    }

    private async Task<string> RequestLuaContentAsync()
    {
        if (_generalView is null) return string.Empty;
        var webView = _generalView.FindControl<NativeWebView>("LuaWebView");
        if (webView is null || !_editorReady) return string.Empty;
        _pendingEditorSnapshot?.TrySetCanceled();
        var tcs = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
        _pendingEditorSnapshot = tcs;
        try
        {
            await webView.InvokeScript("window.orionRequestSnapshot && window.orionRequestSnapshot();");
            var done = await Task.WhenAny(tcs.Task, Task.Delay(700));
            return done == tcs.Task ? await tcs.Task : string.Empty;
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
            return string.Empty;
        }
        finally
        {
            if (ReferenceEquals(_pendingEditorSnapshot, tcs))
            {
                _pendingEditorSnapshot = null;
            }
        }
    }

    private async Task OpenLuaFileAsync()
    {
        try
        {
            var startFolder = _scriptsDirectory;
            try { Directory.CreateDirectory(startFolder); } catch { }

            var suggested = await StorageProvider.TryGetFolderFromPathAsync(new Uri(startFolder));
            var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            {
                Title = "Open script",
                AllowMultiple = false,
                SuggestedStartLocation = suggested,
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
            if (_generalView is null) return;
            var webView = _generalView.FindControl<NativeWebView>("LuaWebView");
            if (webView is null) return;
            try
            {
                await webView.InvokeScript(
                    $"window.orbitSetContent && window.orbitSetContent({JsonSerializer.Serialize(content)}, \"lua\");");
            }
            catch (InvalidOperationException)
            {
                _editorReady = false;
            }
        }
        catch { }
    }

    // ─────────────────────────── helpers ───────────────────────────

    private void OpenUrl(string url)
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
