using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class VelocityWindow
{
    private void EditorMessageReceived(object? sender, WebMessageReceivedEventArgs args)
    {
        if (_disposed || string.IsNullOrWhiteSpace(args.Body)) return;
        var body = args.Body;
        if (Dispatcher.UIThread.CheckAccess()) HandleEditorMessage(body);
        else Dispatcher.UIThread.Post(() => HandleEditorMessage(body));
    }

    private void HandleEditorMessage(string body)
    {
        if (_disposed) return;
        try
        {
            using var json = JsonDocument.Parse(body);
            var root = json.RootElement;
            if (!root.TryGetProperty("type", out var type)) return;
            if (type.GetString() == "ready") { _ = InitializeEditorAsync(); return; }
            // Untagged/delayed messages must never be attributed to whichever tab happens to be selected now.
            if (!root.TryGetProperty("velocityTab", out var tabProperty) ||
                !Guid.TryParse(tabProperty.GetString(), out var id)) return;
            var tab = _workspace.Tabs.FirstOrDefault(t => t.Id == id);
            if (tab is null) return;
            var serial = root.TryGetProperty("velocitySerial", out var seq) && seq.TryGetInt64(out var number) ? number : 0;
            var previous = _messageSerials.GetValueOrDefault(id);
            var fresh = serial > previous;
            if (fresh) _messageSerials[id] = serial;
            switch (type.GetString())
            {
                case "contentChangedDelta" when fresh && root.TryGetProperty("changes", out var changes):
                    if (EditorContentDelta.TryApply(changes, tab.Content, out var content)) tab.Content = content;
                    else if (tab == _activeTab) _ = SnapshotAsync();
                    UpdateDirtyTitle(tab);
                    break;
                case "contentSnapshot":
                case "contentChanged":
                    if (fresh && root.TryGetProperty("content", out var text)) tab.Content = text.GetString() ?? "";
                    UpdateDirtyTitle(tab);
                    if (root.TryGetProperty("velocityRequest", out var request) && request.GetString() is { } key && _snapshots.TryGetValue(key, out var completion))
                        completion.TrySetResult(true);
                    break;
                case "executeRequested":
                    if (fresh && root.TryGetProperty("content", out var execute)) tab.Content = execute.GetString() ?? "";
                    UpdateDirtyTitle(tab);
                    if (!_returnRequested && !_modal.IsVisible) QueueOnBridge(tab.Content);
                    break;
                case "cursorPosition" when tab == _activeTab:
                    if (root.TryGetProperty("line", out var line) && root.TryGetProperty("column", out var column))
                        _cursor.Text = $"Ln {line}, Col {column}";
                    break;
            }
        }
        catch (JsonException) { }
    }

    private async Task InitializeEditorAsync()
    {
        if (_disposed) return;
        try
        {
            // The shared page uses one Monaco model. Stamp messages at their JS source, not on arrival.
            await _editor.InvokeScript("""
                (() => {
                  if (!window.velocitySendInstalled && typeof window.invokeCSharpAction === 'function') {
                    const send = window.invokeCSharpAction;
                    window.velocitySerial = 0;
                    window.invokeCSharpAction = function (message) {
                      try {
                        const value = JSON.parse(message);
                        value.velocityTab = window.velocityTab;
                        value.velocitySerial = ++window.velocitySerial;
                        message = JSON.stringify(value);
                      } catch (_) {}
                      return send(message);
                    };
                    window.velocitySendInstalled = true;
                  }
                })();
                """);
            _messageSerials.Clear();
            _editorReady = true;
            await PushTabAsync(_activeTab);
            await ApplyEditorOptionsAsync();
            RevealEditor();
        }
        catch (Exception ex) when (ex is not OutOfMemoryException)
        { _editorReady = false; AppendLog("error", "Monaco initialization failed: " + ex.Message); }
    }

    private async Task SnapshotAsync()
    {
        if (!_editorReady || _disposed) return;
        var request = Guid.NewGuid().ToString("N");
        var completion = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
        _snapshots[request] = completion;
        try
        {
            await _editor.InvokeScript($$"""
                (() => {
                  if (window.orionEditorContent && window.invokeCSharpAction)
                    window.invokeCSharpAction(JSON.stringify({type:'contentSnapshot',content:window.orionEditorContent(),velocityRequest:{{JsonSerializer.Serialize(request)}}}));
                })();
                """);
            if (await Task.WhenAny(completion.Task, Task.Delay(1800)) != completion.Task)
                throw new InvalidOperationException("Editor did not respond. Your tabs were kept; retry when Monaco is ready.");
            // The message handler is the only writer. Assigning a captured snapshot here would overwrite later keystrokes.
            await completion.Task;
        }
        finally { _snapshots.Remove(request); }
    }

    private async Task PushTabAsync(EditorTabState tab)
    {
        if (!_editorReady || _disposed) return;
        var language = tab.Extension.ToLowerInvariant() switch
        { ".json" => "json", ".js" or ".ts" => "javascript", ".md" => "markdown", ".txt" => "plaintext", _ => "lua" };
        await _editor.InvokeScript($"window.velocityTab={JsonSerializer.Serialize(tab.Id.ToString())}; window.orbitSetContent && window.orbitSetContent({JsonSerializer.Serialize(tab.Content)}, {JsonSerializer.Serialize(language)});");
    }

    private async Task ApplyEditorOptionsAsync()
    {
        if (!_editorReady || _disposed) return;
        var size = _options.FontSize.ToString(System.Globalization.CultureInfo.InvariantCulture);
        var minimap = _options.Minimap ? "true" : "false";
        await _editor.InvokeScript($$"""
            window.orbitSetEditorFont && window.orbitSetEditorFont({{JsonSerializer.Serialize(_options.FontFamily)}}, {{size}});
            if (window.orbitSetMinimap) window.orbitSetMinimap({{minimap}});
            else if (window.monaco && monaco.editor.getEditors) monaco.editor.getEditors().forEach(function (e) { e.updateOptions({ minimap: { enabled: {{minimap}}} }); });
            if (window.velocityApplyTheme) window.velocityApplyTheme({{JsonSerializer.Serialize(_options.Background)}}, {{JsonSerializer.Serialize(_options.Accent)}}, {{JsonSerializer.Serialize(_backgroundDataUrl)}});
            """);
        _editor.Background = Brush.Parse(_options.Background);
    }

    private async Task ReloadEditorAsync()
    {
        if (_editorReady) await SnapshotAsync();
        _editorReady = false;
        _editor.Source = new UriBuilder(_monacoAddress) { Query = "theme=velocity&bg=%23080808&reload=" + DateTime.UtcNow.Ticks }.Uri;
    }

    private readonly Dictionary<Guid, TextBlock> _tabLabels = new();

    private bool IsDirty(EditorTabState tab) => !_cleanContent.TryGetValue(tab.Id, out var clean) || tab.Content != clean;
    private void UpdateDirtyTitle(EditorTabState tab)
    {
        if (_tabLabels.TryGetValue(tab.Id, out var title)) title.Text = tab.Title + (IsDirty(tab) ? " •" : "");
    }

    private void RenderTabs()
    {
        _tabs.Children.Clear(); _tabLabels.Clear();
        foreach (var tab in _workspace.Tabs)
        {
            var active = tab.Id == _activeTab.Id;
            var label = new TextBlock { Text = tab.Title + (IsDirty(tab) ? " •" : ""), FontSize = 13, MaxWidth = 180, TextTrimming = TextTrimming.CharacterEllipsis, VerticalAlignment = VerticalAlignment.Center, Opacity = .8 };
            _tabLabels[tab.Id] = label;
            var caption = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 7 };
            caption.Children.Add(Asset("Tabs/Icons/Script-File_Alt.png", 16));
            caption.Children.Add(label);
            var select = MakeButton("", () => Run(() => SelectTabAsync(tab)));
            select.Content = caption; select.Height = 38; select.Padding = new(10, 0, 10, 0);
            select.Background = Brushes.Transparent;
            select.HorizontalContentAlignment = HorizontalAlignment.Left;
            select.MinWidth = 100;
            var close = MakeButton("", () => Run(() => CloseTabAsync(tab)), tip: "Close " + tab.Title);
            close.Content = new Avalonia.Controls.Shapes.Path { Data = Geometry.Parse("M 1,1 L 9,9 M 9,1 L 1,9"), Stroke = Brush.Parse("#B9BBBE"), StrokeThickness = 1, Width = 10, Height = 10 };
            close.Width = 22; close.Height = 24; close.Padding = new(0); close.Margin = new(0, 0, 8, 0);
            close.VerticalAlignment = VerticalAlignment.Center;
            close.Opacity = active ? 1 : 0;
            var row = new StackPanel { Orientation = Orientation.Horizontal };
            row.Children.Add(select); row.Children.Add(close);
            var surface = new Border { Child = row, Background = active ? Brush.Parse("#0A0A0A") : Brushes.Transparent, BorderBrush = Line, BorderThickness = new(0, 0, 1, 0) };
            var host = new Border { Child = surface, Height = 40, BorderBrush = active ? Accent : Brushes.Transparent, BorderThickness = new(0, 2, 0, 0) };
            host.PointerEntered += (_, _) => { surface.Background = Brush.Parse("#0A0A0A"); close.Opacity = active ? 1 : .6; };
            host.PointerExited += (_, _) => { surface.Background = active ? Brush.Parse("#0A0A0A") : Brushes.Transparent; close.Opacity = active ? 1 : 0; };
            ToolTip.SetTip(host, tab.Title);
            var menu = new ContextMenu();
            void Item(string title, Func<Task> action, bool enabled = true)
            {
                var item = new MenuItem { Header = title, IsEnabled = enabled };
                item.Click += (_, _) => Run(action); menu.Items.Add(item);
            }
            Item("Rename...", () => RenameTabAsync(tab));
            Item("Duplicate", async () => { await SnapshotAsync(); await AddTabAsync(tab.Content, tab.Title + " copy", tab.Extension); });
            Item("Move left", () => MoveTabAsync(tab, -1), _workspace.Tabs.IndexOf(tab) > 0);
            Item("Move right", () => MoveTabAsync(tab, 1), _workspace.Tabs.IndexOf(tab) < _workspace.Tabs.Count - 1);
            menu.Items.Add(new Separator());
            Item("Save as...", async () => { await SelectTabAsync(tab); await SaveActiveAsync(); });
            Item("Close", () => CloseTabAsync(tab));
            Item("Close other tabs...", () => CloseOtherTabsAsync(tab), _workspace.Tabs.Count > 1);
            host.ContextMenu = menu;
            _tabs.Children.Add(host);
        }
    }

    private async Task SelectTabAsync(EditorTabState tab)
    {
        if (!_workspace.Tabs.Contains(tab)) return;
        if (_activeTab != tab)
        {
            await SnapshotAsync();
            _activeTab = tab; _workspace.ActiveTabId = tab.Id;
            await PushTabAsync(tab);
            RenderTabs();
        }
        ShowPage("editor");
    }

    private async Task AddTabAsync(string content = "", string? title = null, string extension = ".lua", string? path = null)
    {
        await SnapshotAsync();
        var index = 1;
        while (_workspace.Tabs.Any(t => t.Title == $"Script {index}.lua")) index++;
        var tab = new EditorTabState { Title = title ?? $"Script {index}.lua", Content = content, Extension = extension };
        _workspace.Tabs.Add(tab); _activeTab = tab; _workspace.ActiveTabId = tab.Id;
        _cleanContent[tab.Id] = content;
        if (path is not null) _filePaths[tab.Id] = path;
        RenderTabs(); ShowPage("editor"); await PushTabAsync(tab);
    }

    private async Task RenameTabAsync(EditorTabState tab)
    {
        var name = await PromptAsync("Rename tab", "This changes the tab label, not the file on disk.", "Rename", tab.Title);
        if (string.IsNullOrWhiteSpace(name) || !_workspace.Tabs.Contains(tab)) return;
        tab.Title = name.Trim()[..Math.Min(name.Trim().Length, 100)];
        var extension = Path.GetExtension(tab.Title);
        if (!string.IsNullOrEmpty(extension)) tab.Extension = extension;
        RenderTabs();
        if (tab == _activeTab) { await SnapshotAsync(); await PushTabAsync(tab); }
    }

    private Task MoveTabAsync(EditorTabState tab, int offset)
    {
        var current = _workspace.Tabs.IndexOf(tab);
        if (current < 0) return Task.CompletedTask;
        var next = Math.Clamp(current + offset, 0, _workspace.Tabs.Count - 1);
        _workspace.Tabs.RemoveAt(current); _workspace.Tabs.Insert(next, tab); RenderTabs();
        return Task.CompletedTask;
    }

    private async Task CloseTabAsync(EditorTabState tab)
    {
        if (!_workspace.Tabs.Contains(tab)) return;
        await SnapshotAsync();
        if ((_options.ConfirmClose || IsDirty(tab)) && await PromptAsync("Close tab?", $"Close \"{tab.Title}\"?" + (IsDirty(tab) ? " Unsaved changes will be discarded." : " The file on disk is not deleted."), "Close tab") is null) return;
        var index = _workspace.Tabs.IndexOf(tab);
        _workspace.Tabs.Remove(tab); _cleanContent.Remove(tab.Id); _filePaths.Remove(tab.Id); _messageSerials.Remove(tab.Id);
        if (_workspace.Tabs.Count == 0)
        {
            var empty = new EditorTabState { Title = "Script 1.lua" }; _workspace.Tabs.Add(empty); _cleanContent[empty.Id] = "";
        }
        if (_activeTab == tab)
        {
            _activeTab = _workspace.Tabs[Math.Clamp(index - 1, 0, _workspace.Tabs.Count - 1)];
            _workspace.ActiveTabId = _activeTab.Id; await PushTabAsync(_activeTab);
        }
        RenderTabs();
    }

    private async Task CloseOtherTabsAsync(EditorTabState tab)
    {
        await SnapshotAsync();
        if (await PromptAsync("Close other tabs?", "Unsaved changes in the other tabs will be discarded. Files on disk are not deleted.", "Close others") is null) return;
        _workspace.Tabs.RemoveAll(t => t != tab);
        foreach (var id in _cleanContent.Keys.Where(id => id != tab.Id).ToArray()) { _cleanContent.Remove(id); _filePaths.Remove(id); _messageSerials.Remove(id); }
        _activeTab = tab; _workspace.ActiveTabId = tab.Id; RenderTabs(); await PushTabAsync(tab);
    }

    private async Task ClearEditorAsync()
    {
        await SnapshotAsync();
        if (_activeTab.Content.Length > 0 && await PromptAsync("Clear editor?", "This clears the active tab. The file on disk is unchanged.", "Clear") is null) return;
        _activeTab.Content = ""; await PushTabAsync(_activeTab); UpdateDirtyTitle(_activeTab);
    }

    private async Task OpenPickerAsync()
    {
        _nativeDialogDepth++; RevealEditor();
        try
        {
            var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            { Title = "Velocity · Open script", AllowMultiple = true, FileTypeFilter = [new("Scripts") { Patterns = ["*.lua", "*.luau", "*.txt", "*.json", "*.js", "*.md"] }, FilePickerFileTypes.All] });
            foreach (var file in files)
            {
                if (_disposed || _returnRequested) break;
                await using var stream = await file.OpenReadAsync();
                if (stream.CanSeek && stream.Length > 8_000_000) { Toast("File is too large (8 MB maximum)."); continue; }
                using var reader = new StreamReader(stream);
                var content = await reader.ReadToEndAsync();
                await AddTabAsync(content, file.Name, Path.GetExtension(file.Name), file.TryGetLocalPath());
            }
        }
        finally { _nativeDialogDepth--; RevealEditor(); }
    }

    private async Task SaveActiveAsync()
    {
        await SnapshotAsync();
        var tab = _activeTab;
        _nativeDialogDepth++; RevealEditor();
        try
        {
            var invalid = Path.GetInvalidFileNameChars();
            var suggested = new string(tab.Title.Where(c => !invalid.Contains(c)).ToArray());
            var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
            { Title = "Velocity · Save script", SuggestedFileName = string.IsNullOrWhiteSpace(suggested) ? "script.lua" : suggested, DefaultExtension = "lua", FileTypeChoices = [new("Lua / Luau") { Patterns = ["*.lua", "*.luau"] }, FilePickerFileTypes.TextPlain, FilePickerFileTypes.All] });
            if (file is null || _disposed) return;
            // Capture again after the picker; no stale pre-dialog text is assigned back to the workspace.
            await SnapshotAsync();
            var saved = tab.Content;
            await using (var stream = await file.OpenWriteAsync())
            {
                stream.SetLength(0);
                await using var writer = new StreamWriter(stream);
                await writer.WriteAsync(saved);
            }
            _cleanContent[tab.Id] = saved;
            tab.Title = file.Name; tab.Extension = Path.GetExtension(file.Name);
            if (file.TryGetLocalPath() is { } local) _filePaths[tab.Id] = local;
            RenderTabs(); Toast("Saved " + file.Name); await RefreshScriptsAsync();
        }
        finally { _nativeDialogDepth--; RevealEditor(); }
    }
}
