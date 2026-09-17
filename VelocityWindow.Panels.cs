using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Primitives;
using Avalonia.Input.Platform;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;

namespace OrbitAvalonia;

public sealed partial class VelocityWindow
{
    private sealed record ScriptEntry(string Path, string Relative);
    private List<ScriptEntry> _scriptEntries = [];
    private int _explorerGeneration;
    private readonly Queue<string> _logLines = new();
    private StackPanel? _clientList;

    private void BuildExplorer()
    {
        var layout = new Grid { RowDefinitions = new("38,*") };
        var searchRow = new Grid { ColumnDefinitions = new("*,36") };
        _search.TextChanged += (_, _) => RenderScripts();
        Put(searchRow, _search);
        Put(searchRow, MakeButton("", () => _ = RefreshScriptsAsync(), "Exp/FluentRefresh.png", "Refresh scripts"), column: 1);
        Put(layout, Box(searchRow, new(0, 0, 0, 1)));
        Put(layout, new ScrollViewer { Content = _scripts, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled }, 1);
        _explorer = Box(layout, new(0));
        Put(_workspaceView, _explorer);
        _explorerSplitter = new GridSplitter { Background = Line, ResizeDirection = GridResizeDirection.Columns, ResizeBehavior = GridResizeBehavior.PreviousAndNext, HorizontalAlignment = HorizontalAlignment.Stretch, VerticalAlignment = VerticalAlignment.Stretch };
        _explorerSplitter.DragCompleted += (_, _) => { _options.ExplorerWidth = Math.Clamp(_explorer.Bounds.Width, 160, 450); SaveOptions(); };
        Put(_workspaceView, _explorerSplitter, column: 1);
        _workspaceView.ColumnDefinitions[2].MinWidth = 300;
    }

    private async Task RefreshScriptsAsync()
    {
        var generation = ++_explorerGeneration;
        try
        {
            var entries = await Task.Run(() =>
            {
                if (!Directory.Exists(_scriptsDirectory)) return new List<ScriptEntry>();
                var enumeration = new EnumerationOptions { RecurseSubdirectories = false, IgnoreInaccessible = true, AttributesToSkip = FileAttributes.ReparsePoint };
                return Directory.EnumerateFiles(_scriptsDirectory, "*", enumeration)
                    .Where(p => new[] { ".lua", ".luau", ".txt" }.Contains(Path.GetExtension(p), StringComparer.OrdinalIgnoreCase))
                    .Take(3000).Select(p => new ScriptEntry(p, Path.GetRelativePath(_scriptsDirectory, p)))
                    .OrderBy(p => p.Relative, StringComparer.OrdinalIgnoreCase).ToList();
            });
            if (_disposed || generation != _explorerGeneration) return;
            _scriptEntries = entries; RenderScripts();
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException)
        { if (!_disposed) { AppendLog("error", "Explorer: " + ex.Message); Toast("Unable to read the scripts directory."); } }
    }

    private void RenderScripts()
    {
        if (_disposed) return;
        _scripts.Children.Clear();
        var search = _search.Text?.Trim() ?? "";
        var matches = _scriptEntries.Where(e => e.Relative.Contains(search, StringComparison.OrdinalIgnoreCase)).ToList();
        if (matches.Count == 0)
        {
            _scripts.Children.Add(new TextBlock { Text = search.Length > 0 ? "No matching scripts." : "No local scripts yet.\nOpen a file or save a new tab in your scripts folder.", TextWrapping = TextWrapping.Wrap, Foreground = Brush.Parse("#777777"), Margin = new(8, 16) });
            return;
        }
        foreach (var entry in matches.Take(600))
        {
            var row = MakeButton("", () => Run(() => OpenLocalScriptAsync(entry)), tip: entry.Path);
            row.HorizontalAlignment = HorizontalAlignment.Stretch;
            row.HorizontalContentAlignment = HorizontalAlignment.Stretch;
            row.Height = 29;
            var inner = new Grid { ColumnDefinitions = new("24,*") };
            Put(inner, Asset("Exp/Script-File.png", 16));
            Put(inner, new TextBlock { Text = Path.GetFileName(entry.Path), FontSize = 13, TextTrimming = TextTrimming.CharacterEllipsis, VerticalAlignment = VerticalAlignment.Center }, column: 1);
            row.Content = inner;
            var menu = new ContextMenu();
            var open = new MenuItem { Header = "Open in tab" }; open.Click += (_, _) => Run(() => OpenLocalScriptAsync(entry));
            var copy = new MenuItem { Header = "Copy path" }; copy.Click += async (_, _) => { if (Clipboard is { } clipboard) await clipboard.SetTextAsync(entry.Path); };
            menu.Items.Add(open); menu.Items.Add(copy); row.ContextMenu = menu;
            _scripts.Children.Add(row);
        }
        if (matches.Count > 600) _scripts.Children.Add(new TextBlock { Text = "Use search to narrow the list (first 600 shown).", TextWrapping = TextWrapping.Wrap });
        if (_scriptEntries.Count == 3000) _scripts.Children.Add(new TextBlock { Text = "Explorer is limited to 3,000 files.", Foreground = Brush.Parse("#777777"), TextWrapping = TextWrapping.Wrap });
    }

    private async Task OpenLocalScriptAsync(ScriptEntry entry)
    {
        var existing = _workspace.Tabs.FirstOrDefault(t => _filePaths.TryGetValue(t.Id, out var p) && string.Equals(p, entry.Path, StringComparison.OrdinalIgnoreCase));
        if (existing is not null) { await SelectTabAsync(existing); return; }
        if (new FileInfo(entry.Path).Length > 8_000_000) { Toast("File is too large (8 MB maximum)."); return; }
        var content = await File.ReadAllTextAsync(entry.Path);
        await AddTabAsync(content, Path.GetFileName(entry.Path), Path.GetExtension(entry.Path), entry.Path);
    }

    private void BuildTerminal()
    {
        var grid = new Grid { RowDefinitions = new("48,*,26") };
        var commands = new Grid { ColumnDefinitions = new("Auto,Auto,Auto,Auto"), VerticalAlignment = VerticalAlignment.Stretch };
        var execute = MakeButton("Execute", () => { }, "Bt/RunFileExe.png", "Unavailable: this port supports editor and local-file operations only.");
        execute.IsEnabled = false;
        Put(commands, execute, column: 0);
        Put(commands, MakeButton("Clear", () => Run(ClearEditorAsync), "Bt/Clear.png", "Clear active editor"), column: 1);
        Put(commands, MakeButton("Open", () => Run(OpenPickerAsync), "Bt/OpenFile.png", "Open script · Ctrl+O"), column: 2);
        Put(commands, MakeButton("Save", () => Run(SaveActiveAsync), "Bt/SaveFile.png", "Save script · Ctrl+S"), column: 3);
        var toolbar = new Grid { ColumnDefinitions = new("*,Auto"), Margin = new(5, 0) };
        Put(toolbar, new ScrollViewer { Content = commands, HorizontalScrollBarVisibility = ScrollBarVisibility.Auto, VerticalScrollBarVisibility = ScrollBarVisibility.Disabled });
        Put(toolbar, MakeButton("Connect", ConnectionControl, "Bt/Inject1.png", "Show existing Orion Bridge connections (does not inject)"), column: 1);
        Put(grid, Box(toolbar, new(0, 0, 0, 1)));
        var outputHeader = new Grid { ColumnDefinitions = new("*,Auto,Auto,Auto"), Margin = new(12, 0) };
        Put(outputHeader, MakeButton("", () => { _logLines.Clear(); _output.Text = ""; }, "Bt/Clear.png", "Clear terminal output"), column: 1);
        Put(outputHeader, MakeButton("", () => Run(async () => { if (Clipboard is { } clipboard) { await clipboard.SetTextAsync(string.Join(Environment.NewLine, _logLines)); Toast("Terminal copied."); } }), "Bt/Copy_Term.png", "Copy terminal output"), column: 2);
        Put(outputHeader, MakeButton("", () => Run(SaveTerminalAsync), "Bt/SaveFile.png", "Save terminal output"), column: 3);
        var outputPanel = new Grid { RowDefinitions = new("34,*") };
        Put(outputPanel, outputHeader);
        _outputScroll.Content = _output;
        Put(outputPanel, _outputScroll, 1);
        Put(grid, outputPanel, 1);
        var footer = new Grid { ColumnDefinitions = new("*,Auto"), Margin = new(10, 0), ColumnSpacing = 12 };
        Put(footer, _connection); Put(footer, _cursor, column: 1);
        Put(grid, Box(footer, new(0, 1, 0, 0)), 2);
        _terminal = Box(grid, new(0));
        Put(_codeArea, _terminal, 2);
        AppendLog("info", "Velocity UI ready. Execution uses Orion Bridge only; no injector is included.");
    }

    private async Task SaveTerminalAsync()
    {
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        { Title = "Velocity · Save terminal output", DefaultExtension = "txt", SuggestedFileName = "velocity-output" });
        var path = file?.TryGetLocalPath();
        if (path is null) return;
        await File.WriteAllTextAsync(path, string.Join(Environment.NewLine, _logLines));
        Toast("Terminal output saved to " + path);
    }

    private void ApplyPanels()
    {
        var availableWidth = Math.Max(498, (ClientSize.Width > 0 ? ClientSize.Width : Width) - 62);
        var availableHeight = Math.Max(323, (ClientSize.Height > 0 ? ClientSize.Height : Height) - 37);
        var explorerMax = Math.Min(450, availableWidth - 301);
        var terminalMax = Math.Min(400, availableHeight - 121);
        _explorer.IsVisible = _explorerSplitter.IsVisible = _options.ExplorerVisible;
        _workspaceView.ColumnDefinitions[0].MinWidth = _options.ExplorerVisible ? 160 : 0;
        _workspaceView.ColumnDefinitions[0].MaxWidth = _options.ExplorerVisible ? explorerMax : 0;
        _workspaceView.ColumnDefinitions[0].Width = new(_options.ExplorerVisible ? Math.Min(_options.ExplorerWidth, explorerMax) : 0);
        _workspaceView.ColumnDefinitions[1].Width = new(_options.ExplorerVisible ? 1 : 0);
        _terminal.IsVisible = _terminalSplitter.IsVisible = _options.TerminalVisible;
        _codeArea.RowDefinitions[2].MinHeight = _options.TerminalVisible ? 140 : 0;
        _codeArea.RowDefinitions[2].MaxHeight = _options.TerminalVisible ? terminalMax : 0;
        _codeArea.RowDefinitions[2].Height = new(_options.TerminalVisible ? Math.Clamp(_options.TerminalHeight, 140, terminalMax) : 0);
        _codeArea.RowDefinitions[1].Height = new(_options.TerminalVisible ? 1 : 0);
    }

    private void AppendLog(string level, string message)
    {
        if (_disposed) return;
        var text = message.Length > 4000 ? message[..4000] + "…" : message;
        _logLines.Enqueue($"[{DateTime.Now:HH:mm:ss}] [{level.ToUpperInvariant()}] {text}");
        while (_logLines.Count > 300) _logLines.Dequeue();
        _output.Text = string.Join(Environment.NewLine, _logLines);
        _outputScroll.ScrollToEnd();
    }

    private void BridgeLogReceived(string level, string message) => Dispatcher.UIThread.Post(() => AppendLog(level, message));
    private void BridgeConnectionChanged(bool connected) => Dispatcher.UIThread.Post(() => { if (!_disposed) RefreshClients(); });
    private void BridgeClientsChanged() => Dispatcher.UIThread.Post(() => { if (!_disposed) RefreshClients(); });

    private void RefreshClients()
    {
        if (_disposed) return;
        var clients = _bridge.GetConnectedClients();
        var live = clients.Select(c => c.Identifier).ToHashSet(StringComparer.OrdinalIgnoreCase);
        _selectedClients.RemoveWhere(id => !live.Contains(id));
        _knownClients.RemoveWhere(id => !live.Contains(id));
        foreach (var client in clients) if (_knownClients.Add(client.Identifier)) _selectedClients.Add(client.Identifier);
        _connection.Text = clients.Count == 0 ? "● Disconnected" : $"● {clients.Count} connected · {_selectedClients.Count} selected";
        _connection.Foreground = clients.Count == 0 ? Brush.Parse("#777777") : Accent;
        if (_currentPage == "clients") RenderClients();
    }

    private void ConnectionControl()
    {
        RefreshClients();
        ShowPage("clients");
        Toast(_bridge.GetConnectedClients().Count > 0 ? "Existing Orion Bridge clients refreshed." : "Waiting for a client running Orion Bridge. No injection is performed.");
    }

    private async Task ExecuteAsync()
    {
        await SnapshotAsync();
        QueueOnBridge(_activeTab.Content);
    }

    private void QueueOnBridge(string content)
    {
        // Deliberately never forwards Monaco execution requests to the bridge.
        Toast("Execute is unavailable in this frontend-only port.");
        AppendLog("info", "Execute is unavailable. Editor text was kept; nothing was sent to a client.");
    }

    private void RenderClients()
    {
        if (_clientList is null) return;
        _clientList.Children.Clear();
        var clients = _bridge.GetConnectedClients();
        if (clients.Count == 0)
        {
            _clientList.Children.Add(Card("No connected clients", "This list contains only clients currently reported by Orion Bridge. It does not scan processes, discover players, inject software, or create a connection on its own."));
            return;
        }
        foreach (var client in clients)
        {
            var selection = new CheckBox { Content = $"{client.Username}   ·   {client.Identifier}", IsChecked = _selectedClients.Contains(client.Identifier), Margin = new(8), HorizontalAlignment = HorizontalAlignment.Stretch };
            selection.IsCheckedChanged += (_, _) =>
            {
                if (selection.IsChecked == true) _selectedClients.Add(client.Identifier); else _selectedClients.Remove(client.Identifier);
                _connection.Text = $"● {clients.Count} connected · {_selectedClients.Count} selected";
            };
            _clientList.Children.Add(Box(selection));
        }
    }
}
