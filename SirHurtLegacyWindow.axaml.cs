using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.Documents;
using Avalonia.Controls.Primitives;
using Avalonia.Controls.Templates;
using Avalonia.Animation;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Layout;
using Avalonia.Markup.Xaml;
using Avalonia.Media;
using Avalonia.Platform.Storage;
using Avalonia.Threading;
using Avalonia.VisualTree;
using System.Diagnostics;
using System.Text.Json;

namespace OrbitAvalonia;

public sealed partial class SirHurtLegacyWindow : Window
{
    private sealed record SirHurtLegacyScriptItem(string Name, string Path);

    private readonly Uri _monacoAddress;
    private readonly string _scriptsDirectory;
    private readonly EditorWorkspaceState _workspace;
    private readonly Action<EditorWorkspaceState> _returnToOrion;
    private readonly UnifiedBridgeServer _bridge = UnifiedBridgeServer.Shared;
    private readonly HashSet<string> _selectedClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private readonly HashSet<string> _knownClientIdentifiers = new(StringComparer.OrdinalIgnoreCase);
    private MonacoStaticServer? _legacyMonacoServer;
    private List<SirHurtLegacyScriptItem> _scripts = [];

    private readonly Border _chrome;
    private readonly NativeWebView _editor;
    private readonly StackPanel _tabStrip;
    private readonly ListBox _scriptList;
    private readonly ListBox _dropdownList;
    private readonly Popup _scriptDropdown;
    private readonly TextBlock _scriptCaptionText;
    private readonly Panel _settingsOverlay;
    private readonly CheckBox _topMostCheck;
    private readonly Border _toastTip;
    private readonly TextBlock _toastText;
    private readonly TextBlock _telemetryDll;

    private EditorTabState _activeTab;
    private bool _editorReady;
    private bool _editorSourceAssigned;
    private bool _editorDisposed;
    private bool _closingForOrion;
    private bool _returnRequested;
    private TaskCompletionSource<string>? _pendingEditorSnapshot;
    private CancellationTokenSource? _fx;

    public SirHurtLegacyWindow() : this(
        new Uri("http://127.0.0.1:1/index.html"),
        System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"),
        CreateDefaultWorkspace(),
        static _ => { })
    {
    }

    internal SirHurtLegacyWindow(
        Uri monacoAddress,
        string scriptsDirectory,
        EditorWorkspaceState initialWorkspace,
        Action<EditorWorkspaceState> returnToOrion)
    {
        _monacoAddress = monacoAddress;
        _scriptsDirectory = scriptsDirectory;
        _workspace = initialWorkspace.CloneDetached();
        if (_workspace.Tabs.Count == 0)
        {
            var tab = NewTabState(1);
            _workspace.Tabs.Add(tab);
            _workspace.ActiveTabId = tab.Id;
        }
        _activeTab = _workspace.Tabs.FirstOrDefault(tab => tab.Id == _workspace.ActiveTabId)
            ?? _workspace.Tabs[0];

        // A pristine handoff workspace gets the classic default script name.
        if (_workspace.Tabs.Count == 1 && _activeTab.Content.Length == 0)
        {
            _activeTab.Title = "Script1.lua";
            _activeTab.Extension = ".lua";
        }

        _returnToOrion = returnToOrion;

        AvaloniaXamlLoader.Load(this);

        _chrome = Required<Border>("HlChrome");
        _editor = Required<NativeWebView>("EditorWebView");
        _tabStrip = Required<StackPanel>("TabStrip");
        _scriptList = Required<ListBox>("ScriptList");
        _dropdownList = Required<ListBox>("DropdownList");
        _scriptDropdown = Required<Popup>("ScriptDropdown");
        _scriptCaptionText = Required<TextBlock>("ScriptCaptionText");
        _settingsOverlay = Required<Panel>("SettingsOverlay");
        _topMostCheck = Required<CheckBox>("TopMostCheck");
        _toastTip = Required<Border>("ToastTip");
        _toastText = Required<TextBlock>("ToastText");
        _telemetryDll = Required<TextBlock>("TelemetryDll");

        _editor.WebMessageReceived += Editor_WebMessageReceived;

        CanResize = true;
        Topmost = OrbitPreferences.TopMostEnabled;
        _topMostCheck.IsChecked = Topmost;

        _scriptList.ItemTemplate = new FuncDataTemplate<SirHurtLegacyScriptItem>(
            (item, _) => BuildScriptItemVisual(item), true);
        _dropdownList.ItemTemplate = _scriptList.ItemTemplate;

        RenderTabs();
        RefreshScripts();
        UpdateCaption();
        UpdateBridgeVisuals();

        _bridge.ConnectionChanged += BridgeConnectionChanged;
        _bridge.ClientsChanged += BridgeClientsChanged;
        RefreshClientTargets();

        Opened += SirHurtLegacyWindow_Opened;
        Closed += SirHurtLegacyWindow_Closed;
        KeyDown += SirHurtLegacyWindow_KeyDown;
    }

    private T Required<T>(string name) where T : Control
        => this.FindControl<T>(name)
           ?? throw new InvalidOperationException($"SirHurt legacy control '{name}' was not created.");

    private static EditorWorkspaceState CreateDefaultWorkspace()
    {
        var tab = NewTabState(1);
        return new EditorWorkspaceState { Tabs = [tab], ActiveTabId = tab.Id };
    }

    private static EditorTabState NewTabState(int index) => new()
    {
        Title = $"Script{index}.lua",
        Content = string.Empty,
        Extension = ".lua"
    };

    // ─────────────────────────── lifecycle ───────────────────────────

    private async void SirHurtLegacyWindow_Opened(object? sender, EventArgs e)
    {
        Opened -= SirHurtLegacyWindow_Opened;

        _chrome.Opacity = 0;
        var token = RestartFx();
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(220),
                progress => _chrome.Opacity = progress,
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        _chrome.Opacity = 1;
        RevealEditor();
    }

    private void SirHurtLegacyWindow_Closed(object? sender, EventArgs e)
    {
        _editorDisposed = true;
        _editor.IsVisible = false;
        _pendingEditorSnapshot?.TrySetCanceled();
        _editor.WebMessageReceived -= Editor_WebMessageReceived;
        _bridge.ConnectionChanged -= BridgeConnectionChanged;
        _bridge.ClientsChanged -= BridgeClientsChanged;

        // Detach the server reference but do NOT dispose it here. Disposing the
        // Kestrel-backed MonacoStaticServer synchronously from Window.Closed
        // deadlocks / throws while Avalonia is tearing down the WebView2 host,
        // and the resulting exception tears the closure handler apart before
        // _returnToOrion runs. The server is allowed to live until the Orion
        // process exits (the same way the shared _orionMonacoServer does).
        _legacyMonacoServer = null;

        if (!_closingForOrion && !_returnRequested)
        {
            _returnRequested = true;
            _returnToOrion(CaptureWorkspace());
        }
    }

    internal void CloseForOrion()
    {
        _closingForOrion = true;
        Close();
    }

    private void SirHurtLegacyWindow_KeyDown(object? sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            if (_settingsOverlay.IsVisible)
            {
                _settingsOverlay.IsVisible = false;
                e.Handled = true;
            }
            else if (_scriptDropdown.IsOpen)
            {
                _scriptDropdown.Close();
                e.Handled = true;
            }
            return;
        }

        if (e.Key == Key.F5 ||
            ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.Enter))
        {
            _ = ExecuteCurrentScriptAsync();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.O)
        {
            Open_Click(this, new RoutedEventArgs());
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.S)
        {
            _ = SaveCurrentFileAsync();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.T)
        {
            AddTab();
            e.Handled = true;
        }
        else if ((e.KeyModifiers & KeyModifiers.Control) != 0 && e.Key == Key.W)
        {
            RequestCloseTab(_activeTab);
            e.Handled = true;
        }
    }

    private async Task ReturnToOrionAsync()
    {
        if (_returnRequested)
        {
            return;
        }

        _returnRequested = true;
        _activeTab.Content = await RequestEditorContentAsync();
        _returnToOrion(CaptureWorkspace());
    }

    private EditorWorkspaceState CaptureWorkspace() => new()
    {
        Tabs = _workspace.Tabs.Select(tab => tab.CloneDetached()).ToList(),
        ActiveTabId = _activeTab.Id
    };

    // ─────────────────────────── title bar ───────────────────────────

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed)
        {
            return;
        }

        if (e.Source is Avalonia.Visual visual &&
            (visual is Button || visual.GetVisualAncestors().OfType<Button>().Any()))
        {
            return;
        }

        if (e.ClickCount == 2 && CanResize)
        {
            WindowState = WindowState == WindowState.Maximized
                ? WindowState.Normal
                : WindowState.Maximized;
            return;
        }

        if (WindowState != WindowState.Maximized)
        {
            BeginMoveDrag(e);
        }
    }

    private void Minimize_Click(object? sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Maximize_Click(object? sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized
            ? WindowState.Normal
            : WindowState.Maximized;
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => _ = ReturnToOrionAsync();

    // ─────────────────────────── editor bridge ───────────────────────────

    private void RevealEditor()
    {
        if (_editorDisposed)
        {
            return;
        }

        _editor.IsVisible = true;
        if (_editorSourceAssigned)
        {
            return;
        }

        _editorSourceAssigned = true;

        // SirHurt Legacy uses a dedicated Monaco drop under MonacoPreviewLegacy,
        // so its colour palette and copy can evolve independently of the
        // shared MonacoPreview folder used by the rest of Orion.
        var legacyRoot = System.IO.Path.Combine(
            AppContext.BaseDirectory, "MonacoPreviewLegacy");
        _legacyMonacoServer = new MonacoStaticServer(legacyRoot);
        var builder = new UriBuilder(_legacyMonacoServer.Address);
        // White classic surface with dark ink, matching the original utility.
        var query = "bg=%23FFFFFF&fg=231C30";
        if (!string.IsNullOrWhiteSpace(builder.Query) && builder.Query != "?")
        {
            query = builder.Query.TrimStart('?') + "&" + query;
        }
        builder.Query = query;
        _editor.Source = builder.Uri;
    }

    private async void Editor_WebMessageReceived(object? sender, WebMessageReceivedEventArgs args)
    {
        if (string.IsNullOrWhiteSpace(args.Body))
        {
            return;
        }

        try
        {
            using var payload = JsonDocument.Parse(args.Body);
            var root = payload.RootElement;
            if (!root.TryGetProperty("type", out var typeProperty))
            {
                return;
            }

            switch (typeProperty.GetString())
            {
                case "ready":
                    Dispatcher.UIThread.Post(() =>
                    {
                        _editorReady = true;
                        PushActiveTabToEditor();
                    });
                    break;

                case "contentChangedDelta" when root.TryGetProperty("changes", out var changesProperty):
                {
                    var changes = changesProperty.Clone();
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        if (EditorContentDelta.TryApply(changes, targetTab.Content, out var content))
                        {
                            targetTab.Content = content;
                        }
                    });
                    break;
                }

                case "contentSnapshot" when root.TryGetProperty("content", out var snapshotProperty):
                {
                    var content = snapshotProperty.GetString() ?? string.Empty;
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        targetTab.Content = content;
                        _pendingEditorSnapshot?.TrySetResult(content);
                    });
                    break;
                }

                case "executeRequested" when root.TryGetProperty("content", out var executeProperty):
                {
                    var content = executeProperty.GetString() ?? string.Empty;
                    var targetTab = _activeTab;
                    Dispatcher.UIThread.Post(() =>
                    {
                        targetTab.Content = content;
                        ExecuteOnBridge(content);
                    });
                    break;
                }
            }
        }
        catch (JsonException)
        {
            // Ignore messages that are not part of the shared Monaco bridge.
        }
    }

    private void PushActiveTabToEditor()
    {
        if (!_editorReady || _activeTab is null)
        {
            return;
        }

        var content = JsonSerializer.Serialize(_activeTab.Content);
        var language = JsonSerializer.Serialize(LanguageForExtension(_activeTab.Extension));
        try
        {
            _editor.InvokeScript(
                $"window.orbitSetContent && window.orbitSetContent({content}, {language});");
        }
        catch (InvalidOperationException)
        {
            _editorReady = false;
        }
    }

    private async Task<string> RequestEditorContentAsync()
    {
        if (!_editorReady)
        {
            return _activeTab.Content;
        }

        _pendingEditorSnapshot?.TrySetCanceled();
        var completion = new TaskCompletionSource<string>(
            TaskCreationOptions.RunContinuationsAsynchronously);
        _pendingEditorSnapshot = completion;
        try
        {
            await _editor.InvokeScript(
                "window.orionRequestSnapshot && window.orionRequestSnapshot();");
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
        finally
        {
            if (ReferenceEquals(_pendingEditorSnapshot, completion))
            {
                _pendingEditorSnapshot = null;
            }
        }
    }

    private static string LanguageForExtension(string extension) =>
        extension.ToLowerInvariant() switch
        {
            ".md" or ".markdown" => "markdown",
            ".json" => "json",
            ".js" or ".ts" => "javascript",
            ".txt" => "plaintext",
            _ => "lua"
        };

    // ─────────────────────────── tabs ───────────────────────────

    private void RenderTabs()
    {
        _tabStrip.Children.Clear();
        foreach (var tab in _workspace.Tabs)
        {
            _tabStrip.Children.Add(CreateTabVisual(tab));
        }

        var add = new Button
        {
            Width = 30,
            Height = 30,
            Padding = new Thickness(0),
            Background = Brushes.Transparent,
            BorderThickness = new Thickness(0),
            HorizontalContentAlignment = HorizontalAlignment.Center,
            VerticalContentAlignment = VerticalAlignment.Center,
            Cursor = new Cursor(StandardCursorType.Hand),
            Content = new TextBlock
            {
                Text = "+",
                FontSize = 15,
                Foreground = new SolidColorBrush(Color.Parse("#555555"))
            }
        };
        ToolTip.SetTip(add, "New tab (Ctrl+T)");
        add.PointerEntered += (_, _) => add.Background = new SolidColorBrush(Color.Parse("#E0E0E0"));
        add.PointerExited += (_, _) => add.Background = Brushes.Transparent;
        add.Click += (_, _) => AddTab();
        _tabStrip.Children.Add(add);
    }

    private Border CreateTabVisual(EditorTabState tab)
    {
        var active = tab.Id == _activeTab.Id;
        var border = new Border
        {
            Height = 30,
            Padding = new Thickness(9, 0),
            MinWidth = 80,
            MaxWidth = 170,
            VerticalAlignment = VerticalAlignment.Stretch,
            Background = new SolidColorBrush(Color.Parse(active ? "#FFFFFF" : "#E8E8E8")),
            BorderBrush = new SolidColorBrush(Color.Parse(active ? "#A8A8A8" : "#C0C0C0")),
            BorderThickness = new Thickness(1, 1, 1, active ? 0 : 1),
            Margin = new Thickness(0, active ? 0 : 2, 1, 0),
            Cursor = new Cursor(StandardCursorType.Hand)
        };
        border.Transitions = new Transitions
        {
            new BrushTransition { Property = Border.BackgroundProperty, Duration = TimeSpan.FromMilliseconds(100) }
        };

        var panel = new StackPanel { Orientation = Orientation.Horizontal, VerticalAlignment = VerticalAlignment.Center };

        var title = new TextBlock
        {
            Text = tab.Title,
            FontSize = 13,
            Foreground = new SolidColorBrush(Color.Parse(active ? "#1F1F1F" : "#666666")),
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(0, 0, 7, 0)
        };
        panel.Children.Add(title);

        var close = new TextBlock
        {
            Text = "×",
            FontSize = 13,
            Foreground = new SolidColorBrush(Color.Parse("#999999")),
            VerticalAlignment = VerticalAlignment.Center
        };
        close.PointerEntered += (_, _) => close.Foreground = new SolidColorBrush(Color.Parse("#D82323"));
        close.PointerExited += (_, _) => close.Foreground = new SolidColorBrush(Color.Parse("#999999"));
        var closeHost = new Border
        {
            Background = Brushes.Transparent,
            Padding = new Thickness(3, 0)
        };
        closeHost.PointerPressed += (_, e) =>
        {
            e.Handled = true;
            RequestCloseTab(tab);
        };
        closeHost.Child = close;
        panel.Children.Add(closeHost);

        border.Child = panel;
        border.PointerPressed += (_, e) =>
        {
            if (e.GetCurrentPoint(border).Properties.IsLeftButtonPressed)
            {
                SelectTab(tab);
                e.Handled = true;
            }
        };

        return border;
    }

    private void AddTabButton_Click(object? sender, RoutedEventArgs e) => AddTab();

    private void AddTab()
    {
        var tab = NewTabState(_workspace.Tabs.Count + 1);
        _workspace.Tabs.Add(tab);
        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        UpdateCaption();
        PushActiveTabToEditor();
    }

    private void SelectTab(EditorTabState tab)
    {
        if (_activeTab.Id == tab.Id)
        {
            return;
        }

        _activeTab = tab;
        _workspace.ActiveTabId = tab.Id;
        RenderTabs();
        UpdateCaption();
        PushActiveTabToEditor();
    }

    private void RequestCloseTab(EditorTabState tab)
    {
        if (_workspace.Tabs.Count == 1)
        {
            _ = ShowToastAsync("Cannot close the last tab");
            return;
        }

        _ = CloseTabAsync(tab);
    }

    private async Task CloseTabAsync(EditorTabState tab)
    {
        var index = _workspace.Tabs.IndexOf(tab);
        if (_activeTab.Id == tab.Id)
        {
            _activeTab.Content = await RequestEditorContentAsync();
            _workspace.Tabs.Remove(tab);
            _activeTab = _workspace.Tabs[Math.Clamp(index - 1, 0, _workspace.Tabs.Count - 1)];
            _workspace.ActiveTabId = _activeTab.Id;
            RenderTabs();
            UpdateCaption();
            PushActiveTabToEditor();
        }
        else
        {
            _workspace.Tabs.Remove(tab);
            RenderTabs();
        }
    }

    private void UpdateCaption()
    {
        _scriptCaptionText.Text = _activeTab.Title;
    }

    // ─────────────────────────── scripts ───────────────────────────

    private Control BuildScriptItemVisual(SirHurtLegacyScriptItem? item) => new TextBlock
    {
        Text = item?.Name ?? string.Empty,
        TextTrimming = TextTrimming.CharacterEllipsis,
        VerticalAlignment = VerticalAlignment.Center
    };

    private void RefreshScripts()
    {
        _scripts = ListScriptFiles(_scriptsDirectory);
        _scriptList.ItemsSource = _scripts;
        _dropdownList.ItemsSource = _scripts;
    }

    private static List<SirHurtLegacyScriptItem> ListScriptFiles(string directory)
    {
        var files = new List<SirHurtLegacyScriptItem>();
        try
        {
            Directory.CreateDirectory(directory);
            foreach (var path in Directory.EnumerateFiles(directory, "*", SearchOption.AllDirectories))
            {
                var extension = System.IO.Path.GetExtension(path);
                if (!extension.Equals(".lua", StringComparison.OrdinalIgnoreCase) &&
                    !extension.Equals(".luau", StringComparison.OrdinalIgnoreCase) &&
                    !extension.Equals(".txt", StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var relative = System.IO.Path.GetRelativePath(directory, path);
                files.Add(new SirHurtLegacyScriptItem(relative, path));
            }

            files.Sort((a, b) => string.Compare(a.Name, b.Name, StringComparison.OrdinalIgnoreCase));
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            // An unreadable folder simply renders as an empty list.
        }

        return files;
    }

    private void RefreshList_Click(object? sender, RoutedEventArgs e)
    {
        RefreshScripts();
        _ = ShowToastAsync($"Script list refreshed ({_scripts.Count})");
    }

    private void ScriptCaption_Click(object? sender, RoutedEventArgs e)
    {
        _scriptDropdown.IsOpen = true;
    }

    private async void DropdownList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_dropdownList.SelectedItem is not SirHurtLegacyScriptItem item)
        {
            return;
        }

        _scriptDropdown.IsOpen = false;
        await OpenScriptAsync(item);
    }

    private async void ScriptList_DoubleTapped(object? sender, TappedEventArgs e)
    {
        if (_scriptList.SelectedItem is not SirHurtLegacyScriptItem item)
        {
            return;
        }

        await OpenScriptAsync(item);
    }

    private async Task OpenScriptAsync(SirHurtLegacyScriptItem item)
    {
        try
        {
            var content = await File.ReadAllTextAsync(item.Path);
            var name = System.IO.Path.GetFileName(item.Name);
            var existing = _workspace.Tabs.FirstOrDefault(tab =>
                string.Equals(tab.Title, name, StringComparison.OrdinalIgnoreCase));
            if (existing is not null)
            {
                existing.Content = content;
                _activeTab = existing;
                _workspace.ActiveTabId = existing.Id;
            }
            else
            {
                var tab = new EditorTabState
                {
                    Title = name,
                    Extension = System.IO.Path.GetExtension(name) is { Length: > 0 } extension
                        ? extension
                        : ".lua",
                    Content = content
                };
                _workspace.Tabs.Add(tab);
                _activeTab = tab;
                _workspace.ActiveTabId = tab.Id;
            }

            RenderTabs();
            UpdateCaption();
            RevealEditor();
            PushActiveTabToEditor();
            _ = ShowToastAsync($"Opened {_activeTab.Title}");
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            _ = ShowToastAsync($"Read error: {ex.Message}");
        }
    }

    private async void Open_Click(object? sender, RoutedEventArgs e)
    {
        var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
        {
            Title = "Open script",
            AllowMultiple = false,
            FileTypeFilter =
            [
                new FilePickerFileType("Script files")
                {
                    Patterns = ["*.lua", "*.luau", "*.txt"]
                }
            ]
        });
        var file = files.FirstOrDefault();
        if (file is null)
        {
            return;
        }

        await using var stream = await file.OpenReadAsync();
        using var reader = new StreamReader(stream);
        var content = await reader.ReadToEndAsync();
        var existing = _workspace.Tabs.FirstOrDefault(tab =>
            string.Equals(tab.Title, file.Name, StringComparison.OrdinalIgnoreCase));
        if (existing is not null)
        {
            existing.Content = content;
            _activeTab = existing;
            _workspace.ActiveTabId = existing.Id;
        }
        else
        {
            var tab = new EditorTabState
            {
                Title = file.Name,
                Extension = System.IO.Path.GetExtension(file.Name) is { Length: > 0 } extension
                    ? extension
                    : ".lua",
                Content = content
            };
            _workspace.Tabs.Add(tab);
            _activeTab = tab;
            _workspace.ActiveTabId = tab.Id;
        }

        RenderTabs();
        UpdateCaption();
        RevealEditor();
        PushActiveTabToEditor();
        _ = ShowToastAsync($"Opened {file.Name}");
    }

    private async Task SaveCurrentFileAsync()
    {
        _activeTab.Content = await RequestEditorContentAsync();
        var file = await StorageProvider.SaveFilePickerAsync(new FilePickerSaveOptions
        {
            Title = "Save script",
            SuggestedFileName = SanitizeFileName(_activeTab.Title),
            DefaultExtension = "lua",
            FileTypeChoices =
            [
                new FilePickerFileType("Lua script") { Patterns = ["*.lua"] },
                new FilePickerFileType("Luau script") { Patterns = ["*.luau"] },
                new FilePickerFileType("Text file") { Patterns = ["*.txt"] }
            ]
        });
        if (file is null)
        {
            return;
        }

        await using var stream = await file.OpenWriteAsync();
        stream.SetLength(0);
        await using var writer = new StreamWriter(stream);
        await writer.WriteAsync(_activeTab.Content);
        _activeTab.Title = System.IO.Path.GetFileName(file.Name);
        _activeTab.Extension = System.IO.Path.GetExtension(file.Name) is { Length: > 0 } extension
            ? extension
            : ".lua";
        RenderTabs();
        UpdateCaption();
        _ = ShowToastAsync($"Saved {file.Name}");
    }

    private void Clear_Click(object? sender, RoutedEventArgs e)
    {
        _activeTab.Content = string.Empty;
        PushActiveTabToEditor();
        _ = ShowToastAsync("Text cleared");
    }

    // ─────────────────────────── actions ───────────────────────────

    private async void Execute_Click(object? sender, RoutedEventArgs e) => await ExecuteCurrentScriptAsync();

    private async Task ExecuteCurrentScriptAsync()
    {
        var source = await RequestEditorContentAsync();
        _activeTab.Content = source;
        if (string.IsNullOrWhiteSpace(source))
        {
            _ = ShowToastAsync("Nothing to execute");
            return;
        }

        ExecuteOnBridge(source);
    }

    private void ExecuteOnBridge(string source)
    {
        if (!_bridge.IsConnected)
        {
            _ = ShowToastAsync("Not attached — run Scripts/Orion Bridge.lua first");
            return;
        }

        _bridge.EnqueueExecute(source);
        _ = ShowToastAsync("Script executed");
    }

    private void Attach_Click(object? sender, RoutedEventArgs e)
    {
        RefreshClientTargets();
        if (_bridge.IsConnected && _selectedClientIdentifiers.Count > 0)
        {
            _ = ShowToastAsync("Attached — bridge connected");
        }
        else
        {
            _ = ShowToastAsync("Not attached — run Scripts/Orion Bridge.lua first");
        }
    }

    private void ScriptHub_Click(object? sender, RoutedEventArgs e) =>
        _ = ShowToastAsync("Script Hub is not part of this remake yet");

    private void OpenScripts_Click(object? sender, RoutedEventArgs e)
    {
        try
        {
            Directory.CreateDirectory(_scriptsDirectory);
            using var _ = Process.Start(new ProcessStartInfo
            {
                FileName = _scriptsDirectory,
                UseShellExecute = true
            });
        }
        catch (Exception)
        {
            _ = ShowToastAsync("Failed to open the scripts folder");
        }
    }

    // ─────────────────────────── settings ───────────────────────────

    private void Settings_Click(object? sender, RoutedEventArgs e)
    {
        _topMostCheck.IsChecked = Topmost;
        // The Monaco HWND always renders above managed content, so it must be
        // hidden while the settings overlay is up.
        _editor.IsVisible = false;
        _settingsOverlay.IsVisible = true;
    }

    private void SettingsClose_Click(object? sender, RoutedEventArgs e)
    {
        _settingsOverlay.IsVisible = false;
        RevealEditor();
    }

    private void SettingsBackdrop_Click(object? sender, PointerPressedEventArgs e)
    {
        _settingsOverlay.IsVisible = false;
        RevealEditor();
    }

    private void TopMost_Changed(object? sender, RoutedEventArgs e)
    {
        var enabled = _topMostCheck.IsChecked == true;
        Topmost = enabled;
        OrbitPreferences.SetTopMost(enabled);
    }

    // ─────────────────────────── bridge ───────────────────────────

    private void BridgeClientsChanged() =>
        Dispatcher.UIThread.Post(RefreshClientTargets);

    private void BridgeConnectionChanged(bool connected) =>
        Dispatcher.UIThread.Post(RefreshClientTargets);

    private void RefreshClientTargets()
    {
        var clients = _bridge.GetConnectedClients();
        var liveIdentifiers = new HashSet<string>(
            clients.Select(client => client.Identifier),
            StringComparer.OrdinalIgnoreCase);

        _selectedClientIdentifiers.RemoveWhere(identifier => !liveIdentifiers.Contains(identifier));
        _knownClientIdentifiers.RemoveWhere(identifier => !liveIdentifiers.Contains(identifier));
        foreach (var client in clients)
        {
            if (_knownClientIdentifiers.Add(client.Identifier))
            {
                _selectedClientIdentifiers.Add(client.Identifier);
            }
        }

        UpdateBridgeVisuals();
    }

    private void UpdateBridgeVisuals()
    {
        var connected = _bridge.IsConnected && _bridge.GetConnectedClients().Count > 0;
        _telemetryDll.Text = connected ? " In Game" : " Not Attached";
    }

    // ─────────────────────────── toast ───────────────────────────

    private async Task ShowToastAsync(string message)
    {
        _toastText.Text = message;
        var token = RestartFx();
        _toastTip.Opacity = 0;
        try
        {
            await AnimateAsync(
                TimeSpan.FromMilliseconds(120),
                progress => _toastTip.Opacity = progress,
                CubicEaseOut,
                token);

            await Task.Delay(1900, token);

            await AnimateAsync(
                TimeSpan.FromMilliseconds(180),
                progress => _toastTip.Opacity = 1 - progress,
                CubicEaseOut,
                token);
        }
        catch (OperationCanceledException)
        {
        }

        if (_fx is { IsCancellationRequested: false })
        {
            _toastTip.Opacity = 0;
        }
    }

    // ─────────────────────────── helpers ───────────────────────────

    private static string SanitizeFileName(string value)
    {
        var invalid = System.IO.Path.GetInvalidFileNameChars();
        var result = new string(value.Where(character => !invalid.Contains(character)).ToArray()).Trim();
        if (result.EndsWith(".lua", StringComparison.OrdinalIgnoreCase))
        {
            result = result[..^4];
        }
        return result.Length == 0 ? "script" : result;
    }

    private CancellationToken RestartFx()
    {
        _fx?.Cancel();
        _fx?.Dispose();
        _fx = new CancellationTokenSource();
        return _fx.Token;
    }

    private static async Task AnimateAsync(
        TimeSpan duration,
        Action<double> update,
        Func<double, double> easing,
        CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        while (stopwatch.Elapsed < duration)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var progress = Math.Clamp(
                stopwatch.Elapsed.TotalMilliseconds / duration.TotalMilliseconds,
                0d,
                1d);
            update(easing(progress));
            await Task.Delay(8, cancellationToken);
        }

        update(1d);
    }

    private static double CubicEaseOut(double progress) => 1d - Math.Pow(1d - progress, 3d);
}
