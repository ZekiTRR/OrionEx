using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Threading;
using Avalonia.VisualTree;

namespace OrbitAvalonia;

public sealed partial class SentinelWindow : Window
{
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly EditorWorkspaceService _filesService = new();
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private NativeWebView? _webView;
    private MonacoStaticServer? _uiServer;
    private bool _webViewReady;
    private bool _webViewDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;

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

        Topmost = OrbitPreferences.TopMostEnabled;
        Closed += SentinelWindow_Closed;
        Opened += SentinelWindow_Opened;
        KeyDown += SentinelWindow_KeyDown;
    }

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "Script 1", Extension = ".lua", Content = "print(\"Tutorial\")" };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private async void SentinelWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SentinelWindow_Opened;
        RevealEditor();
    }

    private void SentinelWindow_Closed(object? sender, EventArgs e)
    {
        _webViewDisposed = true;
        _uiServer?.Dispose();
        _filesService.Dispose();

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
        }
        catch { }
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
        // Attach is automatic in Orion bridge; no action needed.
    }

    // ─────────────────────── title bar ───────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Avalonia.Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        if (WindowState != WindowState.Maximized) BeginMoveDrag(e);
    }

    private void Minimize_Click(object? s, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Close_Click(object? s, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested) return;
        _returnRequested = true;
        _closingForOrion = true;
        _returnToOrion(_workspace.CloneDetached());
        Close();
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
