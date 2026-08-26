using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Threading;
using System.Diagnostics;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class AimWareV4Window : Window
{
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly EditorWorkspaceService _filesService = new();
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly HashSet<string> _selectedClients = new(StringComparer.OrdinalIgnoreCase);
    private bool _webViewDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;
    private List<string> _scriptFiles = [];

    private NativeWebView? _webView;
    private MonacoStaticServer? _uiServer;
    private StackPanel? _consoleOutput;
    private ScrollViewer? _consoleScroll;
    private ListBox? _scriptsList;
    private TextBlock? _scriptsFolderLabel;
    private Button? _navEditor;
    private Button? _navScripts;
    private Button? _navConsole;
    private Button? _navSettings;
    private Grid? _pageEditor;
    private Grid? _pageScripts;
    private Grid? _pageConsole;
    private StackPanel? _pageSettings;
    private CheckBox? _topMostCheck;

    public AimWareV4Window() : this(
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal AimWareV4Window(
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
        _consoleScroll = this.FindControl<ScrollViewer>("ConsoleScroll");
        _scriptsList = this.FindControl<ListBox>("ScriptsList");
        _scriptsFolderLabel = this.FindControl<TextBlock>("ScriptsFolderLabel");
        _navEditor = this.FindControl<Button>("NavEditor");
        _navScripts = this.FindControl<Button>("NavScripts");
        _navConsole = this.FindControl<Button>("NavConsole");
        _navSettings = this.FindControl<Button>("NavSettings");
        _pageEditor = this.FindControl<Grid>("PageEditor");
        _pageScripts = this.FindControl<Grid>("PageScripts");
        _pageConsole = this.FindControl<Grid>("PageConsole");
        _pageSettings = this.FindControl<StackPanel>("PageSettings");
        _topMostCheck = this.FindControl<CheckBox>("TopMostCheck");

        Topmost = OrbitPreferences.TopMostEnabled;
        if (_topMostCheck is not null) _topMostCheck.IsChecked = Topmost;

        _bridge.LogReceived += Bridge_LogReceived;
        _bridge.ConnectionChanged += Bridge_ConnectionChanged;
        Closed += AimWareV4Window_Closed;
        Opened += AimWareV4Window_Opened;
        KeyDown += AimWareV4Window_KeyDown;
    }

    private T? Find<T>(string name) where T : Control => this.FindControl<T>(name);

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = new EditorTabState { Title = "Script 1", Extension = ".lua" };
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    // ─────────────────────── navigation ───────────────────────

    private void NavEditor_Click(object? s, RoutedEventArgs e) => ShowPage("editor");
    private void NavScripts_Click(object? s, RoutedEventArgs e) => ShowPage("scripts");
    private void NavConsole_Click(object? s, RoutedEventArgs e) => ShowPage("console");
    private void NavSettings_Click(object? s, RoutedEventArgs e) => ShowPage("settings");

    private void ShowPage(string page)
    {
        if (_pageEditor is not null) _pageEditor.IsVisible = page == "editor";
        if (_pageScripts is not null) _pageScripts.IsVisible = page == "scripts";
        if (_pageConsole is not null) _pageConsole.IsVisible = page == "console";
        if (_pageSettings is not null) _pageSettings.IsVisible = page == "settings";

        var subBarVisible = page == "scripts";
        if (Find<Button>("SubWorkspace") is { } sw) sw.IsVisible = subBarVisible;
        if (Find<Button>("SubAutoExec") is { } sa) sa.IsVisible = subBarVisible;
        if (Find<Button>("SubScripts") is { } ss) ss.IsVisible = subBarVisible;

        SetClass(_navEditor?.Classes, "active", page == "editor");
        SetClass(_navScripts?.Classes, "active", page == "scripts");
        SetClass(_navConsole?.Classes, "active", page == "console");
        SetClass(_navSettings?.Classes, "active", page == "settings");

        if (page == "editor") RevealEditor();
    }

    private void TabMain_Click(object? sender, RoutedEventArgs e)
    {
        SetClass(TabMain?.Classes, "active", true);
        SetClass(TabWeapon?.Classes, "active", false);
    }

    private void TabWeapon_Click(object? sender, RoutedEventArgs e)
    {
        SetClass(TabMain?.Classes, "active", false);
        SetClass(TabWeapon?.Classes, "active", true);
    }

    private static void SetClass(Classes? classes, string name, bool on)
    {
        if (classes is null) return;
        if (on) classes.Add(name); else classes.Remove(name);
    }

    // ─────────────────────── editor ───────────────────────

    private bool _webViewReady;

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

    // ─────────────────────── scripts ───────────────────────

    private void RefreshScriptList()
    {
        if (_scriptsList is null) return;
        var folder = _scriptsDirectory;
        var files = new List<string>();
        try
        {
            Directory.CreateDirectory(folder);
            files.AddRange(Directory.EnumerateFiles(folder)
                .Where(f => new[] { ".lua", ".luau", ".txt" }.Contains(Path.GetExtension(f), StringComparer.OrdinalIgnoreCase))
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(Path.GetFileName));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
        _scriptsList.ItemsSource = files;
    }

    private async void ScriptsList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_scriptsList.SelectedItem is not string fileName) return;
        _scriptsList.SelectedItem = null;
        try
        {
            var path = System.IO.Path.Combine(_scriptsDirectory, fileName);
            var content = await File.ReadAllTextAsync(path);
            SetEditorContent(content);
            ShowPage("editor");
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { }
    }

    // ─────────────────────── console ───────────────────────

    private void Bridge_LogReceived(string level, string message) =>
        Dispatcher.UIThread.Post(() => AppendConsoleLine(level, message));

    private void AppendConsoleLine(string level, string message)
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
        var line = new TextBlock
        {
            Text = prefix + message,
            FontFamily = new FontFamily("Consolas"),
            FontSize = 11,
            Foreground = new SolidColorBrush(Color.Parse(color)),
            TextWrapping = TextWrapping.Wrap
        };
        _consoleOutput.Children.Add(line);
        while (_consoleOutput.Children.Count > 500)
            _consoleOutput.Children.RemoveAt(0);
        Dispatcher.UIThread.Post(line.BringIntoView, DispatcherPriority.Background);
    }

    private void ConsoleClear_Click(object? s, RoutedEventArgs e) => _consoleOutput?.Children.Clear();

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
        await writer.WriteAsync(await GetEditorContentAsync());
    }

    private void Clear_Click(object? s, RoutedEventArgs e) => SetEditorContent("");

    // ─────────────────────── settings ───────────────────────

    private void TopMost_Changed(object? s, RoutedEventArgs e)
    {
        Topmost = _topMostCheck?.IsChecked == true;
        OrbitPreferences.SetTopMost(Topmost);
    }

    private void Close_Click(object? s, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested) return;
        _returnRequested = true;
        _closingForOrion = true;
        _returnToOrion(_workspace.CloneDetached());
        Close();
    }

    // ─────────────────────── editor helpers ───────────────────────

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

    // ─────────────────────── lifecycle ───────────────────────

    private async void AimWareV4Window_Opened(object? sender, EventArgs e)
    {
        Opened -= AimWareV4Window_Opened;
        ShowPage("editor");
        RevealEditor();
    }

    private void AimWareV4Window_Closed(object? sender, EventArgs e)
    {
        _bridge.LogReceived -= Bridge_LogReceived;
        _bridge.ConnectionChanged -= Bridge_ConnectionChanged;
        _uiServer?.Dispose();
        _filesService.Dispose();

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _closingForOrion = true;
            _returnToOrion(_workspace.CloneDetached());
        }
    }

    private void Bridge_ConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(() =>
        {
            if (connected && _selectedClients.Count > 0)
            {
                AppendConsoleLine("info", "Bridge client connected");
            }
        });

    private void AimWareV4Window_KeyDown(object? sender, KeyEventArgs e)
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
