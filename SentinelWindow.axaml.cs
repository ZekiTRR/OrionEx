using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.VisualTree;
using Avalonia.Threading;
using System.Diagnostics;

namespace OrbitAvalonia;

public sealed partial class SentinelWindow : Window
{
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private NativeWebView? _webView;
    private MonacoStaticServer? _uiServer;
    private bool _webViewReady;
    private bool _webViewDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;
    private StackPanel? _consoleOutput;
    private ListBox? _scriptsList;
    private List<string> _scriptFiles = [];
    private StackPanel? _tabStrip;

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

        AvaloniaXamlLoader.Load(this);
        _webView = this.FindControl<NativeWebView>("EditorWebView");
        _consoleOutput = this.FindControl<StackPanel>("ConsoleOutput");
        _scriptsList = this.FindControl<ListBox>("ScriptsList");
        _tabStrip = this.FindControl<StackPanel>("EditorTabStrip");

        Topmost = OrbitPreferences.TopMostEnabled;
        if (this.FindControl<CheckBox>("OptTopMost") is { } optTop)
            optTop.IsChecked = Topmost;

        _bridge.LogReceived += Bridge_LogReceived;
        _bridge.ConnectionChanged += Bridge_ConnectionChanged;
        Closed += SentinelWindow_Closed;
        Opened += SentinelWindow_Opened;
        KeyDown += SentinelWindow_KeyDown;
    }

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "Script 1", Extension = ".lua", Content = "print(\"I love life\")" };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private async void SentinelWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SentinelWindow_Opened;
        RefreshScriptList();
        RevealEditor();
    }

    private void SentinelWindow_Closed(object? sender, EventArgs e)
    {
        _webViewDisposed = true;
        _bridge.LogReceived -= Bridge_LogReceived;
        _bridge.ConnectionChanged -= Bridge_ConnectionChanged;
        _uiServer?.Dispose();

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

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested) return;
        _returnRequested = true;
        _closingForOrion = true;
        _returnToOrion(_workspace.CloneDetached());
        Close();
    }

    // ─────────────────────── title bar ───────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Avalonia.Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        if (WindowState != WindowState.Maximized) BeginMoveDrag(e);
    }

    private void EditorMinimize_Click(object? s, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void EditorClose_Click(object? s, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    private void OptionsClose_Click(object? s, RoutedEventArgs e)
    {
        if (this.FindControl<Border>("OptionsPanel") is { } panel)
            panel.IsVisible = !panel.IsVisible;
    }

    private void HubClose_Click(object? s, RoutedEventArgs e)
    {
        if (this.FindControl<Border>("HubPanel") is { } panel)
            panel.IsVisible = !panel.IsVisible;
    }

    // ─────────────────────── editor ───────────────────────

    private void RevealEditor()
    {
        if (_webViewDisposed || _webView is null) return;
        _webView.IsVisible = true;
        if (_webView.Source is not null) return;
        try
        {
            var uiRoot = System.IO.Path.Combine(AppContext.BaseDirectory, "MonacoPreview");
            _uiServer = new MonacoStaticServer(uiRoot);
            _webView.Source = _uiServer.Address;
            _webView.NavigationCompleted += async (_, _) =>
            {
                _webViewReady = true;
                PushConsoleSnapshot();
                await SetEditorContentFromWorkspace();
            };
        }
        catch { }
    }

    private async Task SetEditorContentFromWorkspace()
    {
        var content = _workspace.Tabs.FirstOrDefault()?.Content ?? "";
        if (string.IsNullOrEmpty(content)) return;
        try
        {
            var json = System.Text.Json.JsonSerializer.Serialize(content);
            _webView?.InvokeScript($"window.orbitSetContent && window.orbitSetContent({json}, 'lua');");
        }
        catch (InvalidOperationException) { }
    }

    private async Task<string> GetEditorContentAsync()
    {
        if (!_webViewReady || _webView is null) return string.Empty;
        try
        {
            var result = await _webView.InvokeScript(
                "window.orionRequestSnapshot && window.orionRequestSnapshot()");
            return result ?? string.Empty;
        }
        catch (InvalidOperationException)
        {
            return string.Empty;
        }
    }

    private void SetEditorContent(string content)
    {
        if (_webView is null || !_webViewReady) return;
        try
        {
            var json = System.Text.Json.JsonSerializer.Serialize(content);
            _webView.InvokeScript($"window.orbitSetContent && window.orbitSetContent({json}, 'lua');");
        }
        catch (InvalidOperationException) { }
    }

    // ─────────────────────── actions ───────────────────────

    private async void Execute_Click(object? s, RoutedEventArgs e)
    {
        var code = await GetEditorContentAsync();
        if (string.IsNullOrWhiteSpace(code)) return;
        _bridge.EnqueueExecute(code);
    }

    private async void Open_Click(object? s, RoutedEventArgs e)
    {
        var files = await StorageProvider.OpenFilePickerAsync(new Avalonia.Platform.Storage.FilePickerOpenOptions
        {
            Title = "Open script",
            AllowMultiple = false,
            FileTypeFilter =
            [
                new Avalonia.Platform.Storage.FilePickerFileType("Script files") { Patterns = ["*.lua", "*.luau", "*.txt"] }
            ]
        });
        var file = files.FirstOrDefault();
        if (file is null) return;
        await using var stream = await file.OpenReadAsync();
        using var reader = new StreamReader(stream);
        SetEditorContent(await reader.ReadToEndAsync());
    }

    private async void Save_Click(object? s, RoutedEventArgs e)
    {
        var content = await GetEditorContentAsync();
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
        if (file is null) return;
        await using var stream = await file.OpenWriteAsync();
        stream.SetLength(0);
        await using var writer = new StreamWriter(stream);
        await writer.WriteAsync(content);
    }

    private void Clear_Click(object? s, RoutedEventArgs e) => SetEditorContent("");

    private void Attach_Click(object? s, RoutedEventArgs e)
    {
        // Attach is automatic in Orion bridge.
    }

    private void ScriptHub_Click(object? s, RoutedEventArgs e)
    {
        if (this.FindControl<Border>("HubPanel") is { } hub)
            hub.IsVisible = !hub.IsVisible;
    }

    private void Settings_Click(object? s, RoutedEventArgs e)
    {
        if (this.FindControl<Border>("OptionsPanel") is { } options)
            options.IsVisible = !options.IsVisible;
    }

    private async void KillRoblox_Click(object? s, RoutedEventArgs e)
    {
        try
        {
            foreach (var process in Process.GetProcessesByName("RobloxPlayerBeta"))
            {
                try { process.Kill(true); }
                finally { process.Dispose(); }
            }
        }
        catch { }
    }

    private void HubExecute_Click(object? s, RoutedEventArgs e) => Execute_Click(s, e);

    private void HubItem_Click(object? s, RoutedEventArgs e)
    {
        if (s is not Button { Tag: string tag }) return;
        try
        {
            var path = System.IO.Path.Combine(_scriptsDirectory, tag + ".lua");
            if (File.Exists(path)) SetEditorContent(File.ReadAllText(path));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
    }

    private void OptTopMost_Changed(object? s, RoutedEventArgs e)
    {
        if (this.FindControl<CheckBox>("OptTopMost") is { } toggle)
        {
            Topmost = toggle.IsChecked == true;
            OrbitPreferences.SetTopMost(Topmost);
        }
    }

    // ─────────────────────── console ───────────────────────

    private void Bridge_ConnectionChanged(bool connected)
    {
        // Orion bridge is always available; no action needed.
    }

    private void PushConsoleSnapshot()
    {
        if (_webViewDisposed || _webView is null || !_webViewReady) return;
        try
        {
            var lines = new List<string>();
            foreach (var entry in _bridge.GetLogSnapshot())
            {
                var normalized = string.IsNullOrWhiteSpace(entry.Level) ? "info" : entry.Level.ToLowerInvariant();
                var prefix = normalized switch
                {
                    "warn" or "warning" => "[warn]   ",
                    "error" => "[error]  ",
                    "print" or "output" => "[print]  ",
                    _ => "[info]   "
                };
                lines.Add(System.Text.Json.JsonSerializer.Serialize(prefix + (entry.Message ?? "")));
            }

            if (lines.Count == 0) return;
            var array = "[" + string.Join(",", lines) + "]";
            _webView.InvokeScript($"window.addConsoleLines && window.addConsoleLines({array});");
        }
        catch (InvalidOperationException) { }
    }

    private void Bridge_LogReceived(string level, string message)
    {
        Dispatcher.UIThread.Post(() =>
        {
            if (_consoleOutput is null) return;
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
                _consoleOutput.Children.RemoveAt(0);
        });
    }

    private void ConsoleClear_Click(object? s, RoutedEventArgs e) => _consoleOutput?.Children.Clear();

    // ─────────────────────── keyboard ───────────────────────

    private void RefreshScriptList()
    {
        if (_scriptsList is null) return;
        _scriptFiles.Clear();
        try
        {
            Directory.CreateDirectory(_scriptsDirectory);
            _scriptFiles.AddRange(Directory.EnumerateFiles(_scriptsDirectory)
                .Where(f => new[] { ".lua", ".luau", ".txt" }
                    .Contains(Path.GetExtension(f), StringComparer.OrdinalIgnoreCase))
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(Path.GetFileName));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        _scriptsList.ItemsSource = _scriptFiles;
    }

    private async void ScriptsList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_scriptsList?.SelectedItem is not string fileName) return;
        _scriptsList.SelectedItem = null;
        try
        {
            var path = System.IO.Path.Combine(_scriptsDirectory, fileName);
            var content = await File.ReadAllTextAsync(path);
            SetEditorContent(content);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
    }

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
