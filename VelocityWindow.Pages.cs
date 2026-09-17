using Avalonia;
using Avalonia.Controls;
using Avalonia.Layout;
using Avalonia.Media;
using Avalonia.Media.Imaging;
using Avalonia.Platform.Storage;

namespace OrbitAvalonia;

public sealed partial class VelocityWindow
{
    private int _pageAnimation;

    private void ShowPage(string page)
    {
        if (_disposed) return;
        _currentPage = page;
        _workspaceView.IsVisible = page == "editor";
        _page.IsVisible = page != "editor";
        _clientList = null;
        _page.Children.Clear();
        if (page != "editor")
        {
            var content = new StackPanel { Spacing = 14, Margin = new(28, 20), MaxWidth = 880, HorizontalAlignment = HorizontalAlignment.Stretch };
            switch (page)
            {
                case "settings": BuildSettings(content); break;
                case "theme": BuildTheme(content); break;
                case "clients": BuildClients(content); break;
                default: BuildAbout(content); break;
            }
            _page.Children.Add(new ScrollViewer { Content = content, HorizontalScrollBarVisibility = Avalonia.Controls.Primitives.ScrollBarVisibility.Disabled });
            _ = AnimatePageAsync(content);
        }
        UpdateNavigation(); RevealEditor();
    }

    private async Task AnimatePageAsync(Control content)
    {
        var version = ++_pageAnimation;
        var transform = new TranslateTransform(0, 9);
        content.RenderTransform = transform;
        content.Opacity = 0;
        try
        {
            for (var step = 0; step <= 12; step++)
            {
                if (version != _pageAnimation || _disposed) return;
                var progress = 1 - Math.Pow(1 - step / 12d, 3);
                content.Opacity = progress; transform.Y = 9 * (1 - progress);
                await Task.Delay(14, _lifetime.Token);
            }
            content.RenderTransform = null;
        }
        catch (OperationCanceledException) { }
    }

    private void PageHeading(StackPanel host, string title, string description)
    {
        var top = new Grid { ColumnDefinitions = new("*,Auto"), Margin = new(0, 0, 0, 8) };
        Put(top, new TextBlock { Text = title, FontSize = 25, Foreground = Brushes.White, FontWeight = FontWeight.SemiBold });
        Put(top, MakeButton("Back to editor", () => ShowPage("editor")), column: 1);
        host.Children.Add(top);
        host.Children.Add(new TextBlock { Text = description, Foreground = Brush.Parse("#888888"), TextWrapping = TextWrapping.Wrap });
    }

    private Control Card(string title, string description, Control? control = null)
    {
        var content = new Grid { ColumnDefinitions = new("*,Auto"), ColumnSpacing = 18 };
        var text = new StackPanel { Spacing = 5, VerticalAlignment = VerticalAlignment.Center };
        text.Children.Add(new TextBlock { Text = title, FontWeight = FontWeight.SemiBold, Foreground = Brush.Parse("#DDDDDD"), TextWrapping = TextWrapping.Wrap });
        text.Children.Add(new TextBlock { Text = description, FontSize = 11, Foreground = Brush.Parse("#858585"), TextWrapping = TextWrapping.Wrap });
        Put(content, text);
        if (control is not null)
        {
            control.VerticalAlignment = VerticalAlignment.Center;
            Put(content, control, column: 1);
            content.RowDefinitions = new("Auto,Auto");
            bool? compact = null;
            content.SizeChanged += (_, e) =>
            {
                var narrow = e.NewSize.Width < 580;
                if (compact == narrow) return;
                compact = narrow;
                Grid.SetRow(control, narrow ? 1 : 0);
                Grid.SetColumn(control, narrow ? 0 : 1);
                Grid.SetColumnSpan(text, narrow ? 2 : 1);
                Grid.SetColumnSpan(control, narrow ? 2 : 1);
                control.HorizontalAlignment = narrow ? HorizontalAlignment.Left : HorizontalAlignment.Right;
                control.Margin = narrow ? new Thickness(0, 12, 0, 0) : new Thickness(0);
            };
        }
        return new Border { Child = content, BorderThickness = new(1), BorderBrush = Line, Background = Brush.Parse("#A00C0C0C"), CornerRadius = new(5), Padding = new(16, 13) };
    }

    private CheckBox Toggle(bool value, Action<bool> update)
    {
        var toggle = new CheckBox { IsChecked = value, MinWidth = 28 };
        toggle.IsCheckedChanged += (_, _) => { update(toggle.IsChecked == true); SaveOptions(); };
        return toggle;
    }

    private void BuildSettings(StackPanel host)
    {
        PageHeading(host, "Settings", "Velocity preferences are stored separately from Orion. Workspace tabs always come from the current Orion handoff.");
        BuildWindowSizeSettings(host);
        var fonts = FontManager.Current.SystemFonts.Select(family => family.Name)
            .Append("JetBrains Mono").Append(_options.FontFamily)
            .Distinct(StringComparer.OrdinalIgnoreCase).OrderBy(name => name, StringComparer.CurrentCultureIgnoreCase).ToArray();
        var font = new ComboBox { ItemsSource = fonts, SelectedItem = fonts.First(name => string.Equals(name, _options.FontFamily, StringComparison.OrdinalIgnoreCase)), Width = 210, MaxDropDownHeight = 280 };
        font.SelectionChanged += (_, _) =>
        {
            if (font.SelectedItem is not string selected) return;
            _options.FontFamily = selected; SaveOptions(); Run(ApplyEditorOptionsAsync);
        };
        host.Children.Add(Card("Editor font", "All installed system font families and bundled JetBrains Mono. Reopen Settings after installing a new font.", font));
        var size = new NumericUpDown { Minimum = 8, Maximum = 28, Value = (decimal)_options.FontSize, Increment = 1, Width = 110, FormatString = "0" };
        size.ValueChanged += (_, _) => { _options.FontSize = (double)(size.Value ?? 14); SaveOptions(); Run(ApplyEditorOptionsAsync); };
        host.Children.Add(Card("Font size", "Monaco editor text size, from 8 to 28 px.", size));
        host.Children.Add(Card("Minimap", "Show a miniature overview of the active script.", Toggle(_options.Minimap, enabled => { _options.Minimap = enabled; Run(ApplyEditorOptionsAsync); })));
        host.Children.Add(Card("Always on top", "Keep this Velocity window above other windows.", Toggle(_options.Topmost, enabled => Topmost = _options.Topmost = enabled)));
        host.Children.Add(Card("Scripts explorer", "Show the resizable local scripts panel. Shortcut: Ctrl+B.", Toggle(_options.ExplorerVisible, enabled => { _options.ExplorerVisible = enabled; ApplyPanels(); })));
        host.Children.Add(Card("Terminal", "Show bridge logs, local output and file controls. Keyboard file shortcuts remain available while hidden.", Toggle(_options.TerminalVisible, enabled => { _options.TerminalVisible = enabled; ApplyPanels(); })));
        host.Children.Add(Card("Confirm tab close", "Ask before closing every tab. Unsaved changes always require confirmation.", Toggle(_options.ConfirmClose, enabled => _options.ConfirmClose = enabled)));
        host.Children.Add(Card("Reset panel sizes", "Restore the 270 px explorer and 170 px terminal.", MakeButton("Reset", () => { _options.ExplorerWidth = 270; _options.TerminalHeight = 170; ApplyPanels(); SaveOptions(); Toast("Panel sizes restored."); })));
        host.Children.Add(Card("Editor recovery", "Reload Monaco using the latest synchronized workspace. If the editor is unresponsive, return is blocked rather than discarding uncertain edits.", MakeButton("Reload", () => Run(ReloadEditorAsync))));
        host.Children.Add(Card("Welcome", "View the introduction and supported features again.", MakeButton("Show", () => _ = WelcomeAsync())));
        host.Children.Add(Card("Return to Orion", "Return all tabs, order, active tab, names and latest editor text to Orion.", MakeButton("Return", () => _ = ReturnAsync())));
    }

    private void BuildTheme(StackPanel host)
    {
        PageHeading(host, "Appearance", "The original Velocity palette, with a local background image and custom accents. No theme downloads or remote assets.");
        var preview = new Border { Height = 64, Background = Brush.Parse(_options.Background), BorderBrush = Accent, BorderThickness = new(3, 0, 0, 0), Padding = new(18, 10), Child = new TextBlock { Text = "Velocity   /   Your workspace", FontSize = 19, Foreground = Accent, VerticalAlignment = VerticalAlignment.Center } };
        host.Children.Add(preview);
        TextBox accentBox = new() { Text = _options.Accent, Width = 130, MaxLength = 9 };
        TextBox backgroundBox = new() { Text = _options.Background, Width = 130, MaxLength = 9 };
        Control ColorField(TextBox box, string fallback)
        {
            var reset = MakeButton("↺", () => box.Text = fallback, tip: "Return this color to the original " + fallback);
            reset.Width = 28; reset.Padding = new(0);
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, VerticalAlignment = VerticalAlignment.Center };
            row.Children.Add(box); row.Children.Add(reset);
            return row;
        }
        host.Children.Add(Card("Accent color", "Hex color used for active navigation, tabs and the editor cursor. ↺ restores the original #2D7DFF.", ColorField(accentBox, "#2D7DFF")));
        host.Children.Add(Card("Background color", "Solid shell and Monaco background. ↺ restores the original #080808.", ColorField(backgroundBox, "#080808")));
        void ApplyColors(bool notify)
        {
            if (!Color.TryParse(accentBox.Text, out var color) || !Color.TryParse(backgroundBox.Text, out var bg) || color.A != 255 || bg.A != 255)
            { if (notify) Toast("Enter valid opaque colors, for example #2D7DFF and #080808."); return; }
            _options.Accent = $"#{color.R:X2}{color.G:X2}{color.B:X2}";
            _options.Background = $"#{bg.R:X2}{bg.G:X2}{bg.B:X2}";
            ApplyAppearance(); SaveOptions();
            preview.Background = Brush.Parse(_options.Background); preview.BorderBrush = Accent;
            if (preview.Child is TextBlock text) text.Foreground = Accent;
            if (notify) Toast("Velocity colors applied.");
        }
        accentBox.TextChanged += (_, _) => ApplyColors(false);
        backgroundBox.TextChanged += (_, _) => ApplyColors(false);
        host.Children.Add(MakeButton("Apply colors", () => ApplyColors(true)));
        host.Children.Add(Card("Background image", "Local image shown in the window and editor. Adjust Image opacity below to control its visibility.", MakeButton("Choose file", () => Run(ChooseBackgroundAsync))));
        host.Children.Add(new TextBlock { Text = string.IsNullOrEmpty(_options.BackgroundFile) ? "No background image selected." : _options.BackgroundFile, FontSize = 11, Foreground = Brush.Parse("#777777"), TextWrapping = TextWrapping.Wrap });
        var opacity = new Slider { Minimum = 0, Maximum = .7, Value = _options.BackgroundOpacity, Width = 150 };
        opacity.PropertyChanged += (_, e) =>
        {
            if (e.Property != Avalonia.Controls.Primitives.RangeBase.ValueProperty) return;
            _options.BackgroundOpacity = opacity.Value; ApplyAppearance(); SaveOptions();
        };
        host.Children.Add(Card("Image opacity", "Keep the shell readable; opacity is limited to 70%.", opacity));
        var actions = new WrapPanel();
        actions.Children.Add(MakeButton("Remove image", () => { _options.BackgroundFile = ""; _options.BackgroundOpacity = .15; LoadBackground(); ApplyAppearance(); SaveOptions(); ShowPage("theme"); }));
        actions.Children.Add(MakeButton("Restore default theme", () =>
        {
            _options.Accent = "#2D7DFF"; _options.Background = "#080808"; _options.BackgroundFile = ""; _options.BackgroundOpacity = .15;
            LoadBackground(); ApplyAppearance(); SaveOptions(); ShowPage("theme");
        }));
        host.Children.Add(actions);
    }

    private async Task ChooseBackgroundAsync()
    {
        _nativeDialogDepth++; RevealEditor();
        try
        {
            var files = await StorageProvider.OpenFilePickerAsync(new FilePickerOpenOptions
            { Title = "Velocity · Choose local background", AllowMultiple = false, FileTypeFilter = [new("Images") { Patterns = ["*.png", "*.jpg", "*.jpeg", "*.bmp", "*.webp"] }] });
            var path = files.FirstOrDefault()?.TryGetLocalPath();
            if (path is null || _disposed) return;
            if (new FileInfo(path).Length > 20_000_000) { Toast("Choose an image smaller than 20 MB."); return; }
            // Decode before changing the persisted preference, and cap decoded dimensions.
            using var stream = File.OpenRead(path);
            var bitmap = Bitmap.DecodeToWidth(stream, 1920);
            _backgroundImage.Source = null; _backgroundBitmap?.Dispose();
            _backgroundBitmap = bitmap; _backgroundImage.Source = bitmap; _backgroundImage.Opacity = _options.BackgroundOpacity;
            _options.BackgroundFile = path;
            if (_options.BackgroundOpacity == 0) _options.BackgroundOpacity = .3;
            CacheEditorBackground(); ApplyAppearance(); SaveOptions(); ShowPage("theme");
        }
        finally { _nativeDialogDepth--; RevealEditor(); }
    }

    private string? _backgroundDataUrl;

    private void ApplyAppearance()
    {
        Background = _root.Background = Brush.Parse(_options.Background);
        _backgroundImage.Opacity = _options.BackgroundOpacity;
        UpdateNavigation(); RenderTabs(); RefreshClients();
        Run(ApplyEditorOptionsAsync);
    }

    private void CacheEditorBackground()
    {
        _backgroundDataUrl = null;
        if (_backgroundBitmap is null) return;
        using var encoded = new MemoryStream();
        _backgroundBitmap.Save(encoded);
        _backgroundDataUrl = "data:image/png;base64," + Convert.ToBase64String(encoded.ToArray());
    }

    private void LoadBackground()
    {
        _backgroundDataUrl = null;
        _backgroundImage.Source = null; _backgroundBitmap?.Dispose(); _backgroundBitmap = null;
        if (string.IsNullOrEmpty(_options.BackgroundFile)) return;
        try
        {
            if (new FileInfo(_options.BackgroundFile).Length > 20_000_000) return;
            using var stream = File.OpenRead(_options.BackgroundFile);
            _backgroundBitmap = Bitmap.DecodeToWidth(stream, 1920);
            _backgroundImage.Source = _backgroundBitmap; _backgroundImage.Opacity = _options.BackgroundOpacity;
            CacheEditorBackground();
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or ArgumentException or NotSupportedException)
        { AppendLog("warn", "Background image unavailable: " + ex.Message); }
    }

    private void BuildClients(StackPanel host)
    {
        PageHeading(host, "Client manager", "Read-only live connection information from Orion Bridge. This UI does not inject, attach to a process, or start a client.");
        host.Children.Add(Card("Orion Bridge", "Existing clients and their reported names appear below. Execute is unavailable in this frontend-only port.", MakeButton("Refresh", RefreshClients)));
        _clientList = new StackPanel { Spacing = 8 };
        host.Children.Add(_clientList);
        RenderClients();
        host.Children.Add(Card("Connection control, not injection", "The original Inject action has deliberately not been ported. The Connect control only refreshes this list. No VelocityApi, process manipulation, downloads, or system settings are used."));
    }

    private void BuildAbout(StackPanel host)
    {
        PageHeading(host, "Velocity for Orion", "A native Avalonia adaptation of the Velocity Lite interface, using Orion's shared Monaco editor.");
        var logo = Asset("Vel/Vel_meteor-HQ.png", 68); logo.HorizontalAlignment = HorizontalAlignment.Left;
        host.Children.Add(logo);
        host.Children.Add(Card("A real local workspace", "Resizable script explorer and terminal; searchable local files; tab rename, duplicate, close and reorder actions; Open / Save; isolated appearance and editor preferences."));
        host.Children.Add(Card("What this port does not do", "It does not ship VelocityApi, inject into any process, execute scripts on clients, download an executor, change Defender, terminate clients, or claim to be an official Velocity release. Remote news, cloud scripts and update feeds are not reproduced."));
        host.Children.Add(Card("Native editor visibility", "Monaco is a native webview. It is hidden while settings, clients, theme, about, dialogs or file pickers are displayed, so native child-window layering cannot obscure these pages."));
        host.Children.Add(Card("Workspace handoff", "Tabs are cloned from Orion on entry and synchronized back on return. A tagged message stream associates edits with the correct tab; the latest text is not replaced with an older asynchronous snapshot."));
        host.Children.Add(Card("Shortcuts", "Ctrl+T new tab · Ctrl+W close tab · Ctrl+O open · Ctrl+S save · Ctrl+B explorer · Escape close dialog / return to editor. When Monaco has focus, its own shortcuts may take precedence."));
        host.Children.Add(Card("Version information", "This is an Orion interface port, not the upstream Velocity runtime. No runtime version or execution success is fabricated."));
        host.Children.Add(MakeButton("Return to Orion", () => _ = ReturnAsync()));
    }

    private async Task WelcomeAsync()
    {
        var result = await PromptAsync("Welcome to Velocity", "Your Orion workspace is ready in a new native shell.\n\nExplore local scripts, customize your editor and switch back to Orion without losing your tabs.\n\nThis is a frontend-only port. Execute and injection are unavailable; connection status and logs are read-only.", "Get started");
        if (result is not null) { _options.WelcomeSeen = true; SaveOptions(); }
    }

    private async Task<string?> PromptAsync(string title, string description, string accept, string? initialText = null)
    {
        if (_disposed || _returnRequested || _modalCompletion is not null) return null;
        var completion = new TaskCompletionSource<string?>(TaskCreationOptions.RunContinuationsAsynchronously);
        _modalCompletion = completion;
        var stack = new StackPanel { Spacing = 16 };
        stack.Children.Add(new TextBlock { Text = title, FontSize = 23, FontWeight = FontWeight.SemiBold, Foreground = Brushes.White, TextWrapping = TextWrapping.Wrap });
        stack.Children.Add(new TextBlock { Text = description, FontSize = 13, LineHeight = 21, TextWrapping = TextWrapping.Wrap, Foreground = Brush.Parse("#A5A5A5") });
        TextBox? input = null;
        if (initialText is not null)
        {
            input = new TextBox { Text = initialText, MaxLength = 100 };
            stack.Children.Add(input);
            input.KeyDown += (_, e) => { if (e.Key == Avalonia.Input.Key.Enter) { CompleteModal(input.Text ?? ""); e.Handled = true; } };
        }
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, HorizontalAlignment = HorizontalAlignment.Right };
        buttons.Children.Add(MakeButton("Cancel", () => CompleteModal(null)));
        var acceptButton = MakeButton(accept, () => CompleteModal(input?.Text ?? "ok"));
        acceptButton.Background = Accent; acceptButton.Foreground = Brushes.White;
        buttons.Children.Add(acceptButton); stack.Children.Add(buttons);
        var dialog = new Border { Child = stack, MaxWidth = 480, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Background = Brush.Parse("#101010"), BorderBrush = Line, BorderThickness = new(1), CornerRadius = new(8), Padding = new(28) };
        _modal.Child = new ScrollViewer { Content = dialog, VerticalScrollBarVisibility = Avalonia.Controls.Primitives.ScrollBarVisibility.Auto };
        _modal.IsVisible = true;
        RevealEditor();
        _ = AnimateDialogAsync(dialog);
        if (input is not null) { input.Focus(); input.SelectAll(); } else acceptButton.Focus();
        return await completion.Task;
    }

    private async Task AnimateDialogAsync(Control dialog)
    {
        var scale = new ScaleTransform(.95, .95);
        dialog.RenderTransform = scale; dialog.RenderTransformOrigin = RelativePoint.Center; dialog.Opacity = 0;
        try
        {
            for (var i = 0; i <= 12; i++)
            {
                if (!_modal.IsVisible || _disposed) return;
                var value = 1 - Math.Pow(1 - i / 12d, 3);
                scale.ScaleX = scale.ScaleY = .95 + .05 * value; dialog.Opacity = value;
                await Task.Delay(14, _lifetime.Token);
            }
            dialog.RenderTransform = null;
        }
        catch (OperationCanceledException) { }
    }

    private void CompleteModal(string? value)
    {
        var completion = _modalCompletion;
        _modalCompletion = null;
        _modal.IsVisible = false;
        _modal.Child = null;
        completion?.TrySetResult(value);
        RevealEditor();
    }
}
