using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Threading;

namespace OrbitAvalonia;

// Right-hand script list of the editor page: Bookmarks, Github Gists,
// Auto Execute Sync and Local Filesystem, matching the design mock.
public sealed partial class OrionWindow
{
    private sealed record OrionExplorerEntry(string Name, string Path, bool IsGist);

    private sealed class OrionSectionDefinition
    {
        public OrionSectionDefinition(string id, string title)
        {
            Id = id;
            Title = title;
        }

        public string Id { get; }
        public string Title { get; }
    }

    private static readonly OrionSectionDefinition[] OrionExplorerSections =
    [
        new("LocalFiles", "Local Filesystem"),
        new("AutoExecute", "Auto Execute Sync"),
        new("Gists", "Github Gists"),
        new("Bookmarks", "Bookmarks")
    ];

    private readonly EditorWorkspaceService _orionFilesService = new();
    private readonly HashSet<string> _orionBookmarks = new(StringComparer.OrdinalIgnoreCase);
    private readonly Dictionary<string, List<OrionExplorerEntry>> _orionExplorerEntries = new();
    private readonly Dictionary<string, TextBlock> _orionSectionLabels = new();

    private TextBlock? _orionExplorerSectionTitle;
    private Border? _orionExplorerOpenedHeader;
    private Border? _orionExplorerContent;
    private TextBlock? _orionExplorerEmpty;
    private Button? _orionExplorerAddButton;
    private StackPanel? _orionExplorerRows;
    private TextBox? _orionExplorerSearch;

    private string? _orionOpenSection;
    private string _orionExplorerQuery = string.Empty;
    private bool _orionExplorerReady;

    private void InitializeOrionExplorer()
    {
        _orionBookmarks.UnionWith(OrionBookmarksStore.Load());

        _orionSectionLabels["LocalFiles"] = OrionExplorerRequired<TextBlock>("OrionSectionLocalText");
        _orionSectionLabels["AutoExecute"] = OrionExplorerRequired<TextBlock>("OrionSectionAutoText");
        _orionSectionLabels["Gists"] = OrionExplorerRequired<TextBlock>("OrionSectionGistsText");
        _orionSectionLabels["Bookmarks"] = OrionExplorerRequired<TextBlock>("OrionSectionBookmarksText");
        _orionExplorerSectionTitle = OrionExplorerRequired<TextBlock>("OrionExplorerSectionTitle");
        _orionExplorerOpenedHeader = OrionExplorerRequired<Border>("OrionExplorerOpenedHeader");
        _orionExplorerContent = OrionExplorerRequired<Border>("OrionExplorerContent");
        _orionExplorerEmpty = OrionExplorerRequired<TextBlock>("OrionExplorerEmpty");
        _orionExplorerAddButton = OrionExplorerRequired<Button>("OrionExplorerAddButton");
        _orionExplorerRows = OrionExplorerRequired<StackPanel>("OrionExplorerRows");
        _orionExplorerSearch = OrionExplorerRequired<TextBox>("OrionExplorerSearch");

        _orionExplorerReady = true;
        RefreshOrionExplorer();
    }

    private T OrionExplorerRequired<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException("Orion explorer control '" + name + "' was not created.");

    private void DisposeOrionExplorer()
    {
        _orionExplorerReady = false;
        _orionFilesService.Dispose();
    }

    // ─────────────────────────── sections ───────────────────────────

    private void OrionExplorerSection_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string sectionId })
        {
            return;
        }

        _orionOpenSection = _orionOpenSection == sectionId ? null : sectionId;
        RefreshOrionExplorer();
    }

    private List<OrionExplorerEntry> CollectOrionSectionEntries(string sectionId)
    {
        var query = _orionExplorerQuery.Trim();
        IEnumerable<OrionExplorerEntry> entries = sectionId switch
        {
            "LocalFiles" => ListOrionDirectoryEntries(_orionWorkspace.ScriptsDirectory),
            "AutoExecute" => ListOrionDirectoryEntries(_orionFilesService.AutoExecuteDirectory),
            "Gists" => _orionFilesService.ListGists()
                .Select(gist => new OrionExplorerEntry(gist.DisplayName, gist.FullPath, true)),
            "Bookmarks" => _orionBookmarks
                .Where(File.Exists)
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(path => new OrionExplorerEntry(Path.GetFileName(path), path, false)),
            _ => []
        };

        return query.Length == 0
            ? entries.ToList()
            : entries.Where(entry => entry.Name.Contains(query, StringComparison.OrdinalIgnoreCase)).ToList();
    }

    private IEnumerable<OrionExplorerEntry> ListOrionDirectoryEntries(string directory)
    {
        try
        {
            Directory.CreateDirectory(directory);
            return Directory.EnumerateFiles(directory)
                .Where(path => new[] { ".lua", ".luau", ".txt" }
                    .Contains(Path.GetExtension(path), StringComparer.OrdinalIgnoreCase))
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(path => new OrionExplorerEntry(Path.GetFileName(path), path, false));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            return [];
        }
    }

    private void RefreshOrionExplorer()
    {
        if (!_orionExplorerReady)
        {
            return;
        }

        foreach (var pair in _orionSectionLabels)
        {
            var open = pair.Key == _orionOpenSection;
            pair.Value.Foreground = new SolidColorBrush(Color.Parse(open ? "#A9A9AB" : "#454747"));
        }

        var opened = OrionExplorerSections.FirstOrDefault(section => section.Id == _orionOpenSection);
        if (opened is null)
        {
            _orionExplorerOpenedHeader!.IsVisible = false;
            _orionExplorerContent!.IsVisible = false;
            _orionExplorerEmpty!.IsVisible = false;
            return;
        }

        var entries = CollectOrionSectionEntries(opened.Id);
        _orionExplorerEntries[opened.Id] = entries;

        _orionExplorerOpenedHeader!.IsVisible = true;
        _orionExplorerContent!.IsVisible = true;
        _orionExplorerSectionTitle!.Text = opened.Title;
        _orionExplorerAddButton!.IsVisible = opened.Id is "Gists" or "AutoExecute";
        _orionExplorerEmpty!.IsVisible = entries.Count == 0;
        _orionExplorerEmpty.Text = opened.Id switch
        {
            "Bookmarks" => "Bookmark a script to pin it here",
            "Gists" => "Add a raw GitHub link with +",
            _ => "Empty"
        };

        _orionExplorerRows!.Children.Clear();
        foreach (var entry in entries)
        {
            _orionExplorerRows.Children.Add(BuildOrionExplorerRow(opened.Id, entry));
        }
    }

    private Control BuildOrionExplorerRow(string sectionId, OrionExplorerEntry entry)
    {
        // Row metrics follow the design mock: 10-unit pitch, 6.667 text,
        // 5x5 bookmark and action glyphs on the right edge.
        var row = new Grid
        {
            Height = 10,
            Margin = new Thickness(0, 0, 2, 0),
            ColumnDefinitions = new ColumnDefinitions("*,16,12"),
            Cursor = new Cursor(StandardCursorType.Hand)
        };

        var label = new StackPanel
        {
            Orientation = Orientation.Horizontal,
            Spacing = 5.333,
            VerticalAlignment = VerticalAlignment.Center
        };
        label.Children.Add(new Image
        {
            Width = 6,
            Height = 6,
            Stretch = Stretch.Uniform,
            Source = LoadOrionBitmap("avares://Orion/Assets/Orion/Sharp/script-list-dot.png")
        });
        label.Children.Add(new TextBlock
        {
            Text = entry.Name,
            FontSize = 6.667,
            Foreground = new SolidColorBrush(Color.Parse("#7D7D80")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center
        });
        ToolTip.SetTip(row, entry.Name);
        row.Children.Add(label);

        var bookmarked = _orionBookmarks.Contains(entry.Path);
        var bookmark = new Button
        {
            Width = 10,
            Height = 10,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Tag = entry,
            Content = new Avalonia.Controls.Shapes.Path
            {
                Data = Geometry.Parse("M0,0 H7 V11 L3.5,8.2 L0,11 Z"),
                Width = 7,
                Height = 11,
                Stretch = Stretch.Fill,
                Fill = bookmarked
                    ? new SolidColorBrush(Color.Parse("#FFD54A"))
                    : Brushes.Transparent,
                Stroke = new SolidColorBrush(Color.Parse(bookmarked ? "#FFD54A" : "#7D7D80")),
                StrokeThickness = 1,
                StrokeLineCap = PenLineCap.Round,
                StrokeJoin = PenLineJoin.Round
            }
        };
        ToolTip.SetTip(bookmark, bookmarked ? "Remove bookmark" : "Bookmark");
        bookmark.Click += (_, _) =>
        {
            if (!_orionBookmarks.Remove(entry.Path))
            {
                _orionBookmarks.Add(entry.Path);
            }

            OrionBookmarksStore.Save(_orionBookmarks);
            RefreshOrionExplorer();
        };
        Grid.SetColumn(bookmark, 1);
        row.Children.Add(bookmark);

        var action = new Button
        {
            Width = 10,
            Height = 10,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Tag = entry,
            Content = new Image
            {
                Width = 5,
                Height = 5,
                Stretch = Stretch.Uniform,
                Source = LoadOrionBitmap("avares://Orion/Assets/Orion/Sharp/row-action-alt.png")
            }
        };
        ToolTip.SetTip(action, "Execute script");
        action.PointerEntered += (_, _) =>
        {
            if (action.Content is Image icon)
            {
                icon.Source = LoadOrionBitmap("avares://Orion/Assets/Orion/Sharp/row-action-hot.png");
            }
        };
        action.PointerExited += (_, _) =>
        {
            if (action.Content is Image icon)
            {
                icon.Source = LoadOrionBitmap("avares://Orion/Assets/Orion/Sharp/row-action-alt.png");
            }
        };
        action.Click += (_, _) => _ = ExecuteOrionExplorerEntryAsync(entry);
        Grid.SetColumn(action, 2);
        row.Children.Add(action);

        row.PointerPressed += async (_, eventArgs) =>
        {
            if (!eventArgs.GetCurrentPoint(row).Properties.IsLeftButtonPressed)
            {
                return;
            }

            eventArgs.Handled = true;
            await OpenOrionExplorerEntryAsync(entry);
        };

        return row;
    }

    private async Task OpenOrionExplorerEntryAsync(OrionExplorerEntry entry)
    {
        try
        {
            string content;
            if (entry.IsGist)
            {
                _ = Task.Run(() => Dispatcher.UIThread.Post(() =>
                    AppendOrionConsoleLine("info", $"Fetching {entry.Name}\u2026")));
                var url = (await File.ReadAllTextAsync(entry.Path)).Trim();
                content = await _orionFilesService.FetchGistAsync(url, CancellationToken.None);
            }
            else
            {
                content = await File.ReadAllTextAsync(entry.Path);
            }

            OpenOrionTab(entry.Name, content, Path.GetExtension(entry.Name) is { Length: > 0 } extension
                ? extension
                : ".lua");
        }
        catch (Exception exception) when (
            exception is IOException or HttpRequestException or InvalidOperationException or UnauthorizedAccessException)
        {
            AppendOrionConsoleLine("error", $"Couldn't open {entry.Name}: {exception.Message}");
        }
    }

    private async Task ExecuteOrionExplorerEntryAsync(OrionExplorerEntry entry)
    {
        if (!_orionBridge.IsConnected)
        {
            AppendOrionConsoleLine("warn", "Not attached \u2014 run Scripts/Orion Bridge.lua first");
            return;
        }

        try
        {
            var content = entry.IsGist
                ? await _orionFilesService.FetchGistAsync(
                    (await File.ReadAllTextAsync(entry.Path)).Trim(),
                    CancellationToken.None)
                : await File.ReadAllTextAsync(entry.Path);

            if (string.IsNullOrWhiteSpace(content))
            {
                AppendOrionConsoleLine("warn", $"{entry.Name} is empty");
                return;
            }

            _orionBridge.EnqueueExecute(content);
            AppendOrionConsoleLine("info", $"Executed {entry.Name}");
        }
        catch (Exception exception) when (
            exception is IOException or HttpRequestException or InvalidOperationException or UnauthorizedAccessException)
        {
            AppendOrionConsoleLine("error", $"Couldn't execute {entry.Name}: {exception.Message}");
        }
    }

    private void OrionExplorerSearch_TextChanged(object? sender, TextChangedEventArgs e)
    {
        _orionExplorerQuery = _orionExplorerSearch?.Text ?? string.Empty;
        RefreshOrionExplorer();
    }

    // ─────────────────────────── header action (+) ───────────────────────────

    private void OrionExplorerAdd_Click(object? sender, RoutedEventArgs e)
    {
        switch (_orionOpenSection)
        {
            case "Gists":
                ShowOrionGistDialog();
                break;
            case "AutoExecute":
                SyncOrionTabToAutoExecute();
                break;
        }
    }

    private void SyncOrionTabToAutoExecute()
    {
        var content = _orionActiveTab.Content;
        if (string.IsNullOrWhiteSpace(content))
        {
            AppendOrionConsoleLine("warn", "Current tab is empty \u2014 nothing to sync");
            return;
        }

        try
        {
            var path = EditorWorkspaceService.UniqueFilePath(
                _orionFilesService.AutoExecuteDirectory,
                Path.GetFileNameWithoutExtension(_orionActiveTab.Title),
                ".lua");
            File.WriteAllText(path, content);
            AppendOrionConsoleLine("info", $"Synced {Path.GetFileName(path)} to Auto Execute");
            RefreshOrionExplorer();
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            AppendOrionConsoleLine("error", $"Sync failed: {ex.Message}");
        }
    }

    // ─────────────────────────── gist dialog ───────────────────────────

    private Border? _orionGistDialog;
    private TextBox? _orionGistUrlBox;
    private TextBlock? _orionGistError;

    private void ShowOrionGistDialog()
    {
        _orionGistDialog ??= OrionExplorerRequired<Border>("OrionGistDialog");
        _orionGistUrlBox ??= OrionExplorerRequired<TextBox>("OrionGistUrlBox");
        _orionGistError ??= OrionExplorerRequired<TextBlock>("OrionGistError");

        _orionGistUrlBox.Text = string.Empty;
        _orionGistError.IsVisible = false;
        _orionGistDialog.IsVisible = true;
        _orionGistUrlBox.Focus();
    }

    private void OrionGistCancel_Click(object? sender, RoutedEventArgs e)
    {
        if (_orionGistDialog is { } dialog)
        {
            dialog.IsVisible = false;
        }
    }

    private void OrionGistAdd_Click(object? sender, RoutedEventArgs e)
    {
        if (_orionGistUrlBox is not { } box || _orionGistError is not { } error)
        {
            return;
        }

        try
        {
            var title = _orionFilesService.StoreGistUrl(box.Text ?? string.Empty);
            AppendOrionConsoleLine("info", $"Added gist {title}");
            error.IsVisible = false;
            if (_orionGistDialog is { } dialog)
            {
                dialog.IsVisible = false;
            }

            RefreshOrionExplorer();
        }
        catch (Exception exception) when (
            exception is InvalidOperationException or IOException)
        {
            error.Text = exception.Message;
            error.IsVisible = true;
        }
    }

    // ─────────────────────────── auto execute ───────────────────────────

    private void OrionAutoExecuteOnAttach()
    {
        try
        {
            var executed = 0;
            foreach (var path in Directory.EnumerateFiles(_orionFilesService.AutoExecuteDirectory)
                .Where(path => new[] { ".lua", ".luau", ".txt" }
                    .Contains(Path.GetExtension(path), StringComparer.OrdinalIgnoreCase))
                .OrderBy(path => Path.GetFileName(path), StringComparer.OrdinalIgnoreCase))
            {
                var source = File.ReadAllText(path);
                if (string.IsNullOrWhiteSpace(source))
                {
                    continue;
                }

                _orionBridge.EnqueueExecute(source);
                AppendOrionConsoleLine("info", $"Auto-executed {Path.GetFileName(path)}");
                executed++;
            }

            if (executed > 0)
            {
                AppendOrionConsoleLine("info", $"Auto Execute Sync ran {executed} script(s)");
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            AppendOrionConsoleLine("error", $"Auto Execute Sync failed: {ex.Message}");
        }
    }
}

internal static class OrionBookmarksStore
{
    private static readonly object Gate = new();
    private static readonly string StorePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "orion-bookmarks.json");

    public static HashSet<string> Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(StorePath)) return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var paths = System.Text.Json.JsonSerializer.Deserialize<List<string>>(File.ReadAllText(StorePath));
                return new HashSet<string>(paths ?? [], StringComparer.OrdinalIgnoreCase);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or System.Text.Json.JsonException)
            {
                return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            }
        }
    }

    public static void Save(HashSet<string> bookmarks)
    {
        lock (Gate)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(StorePath)!);
                File.WriteAllText(
                    StorePath,
                    System.Text.Json.JsonSerializer.Serialize(bookmarks.OrderBy(path => path).ToList()));
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
