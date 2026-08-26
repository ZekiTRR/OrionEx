using Avalonia;
using Avalonia.Controls;
using Avalonia.Input;
using Avalonia.Interactivity;
using Avalonia.Markup.Xaml;
using Avalonia.VisualTree;

namespace OrbitAvalonia;

public sealed partial class SentinelScriptHubWindow : Window
{
    private readonly SentinelWindow? _owner;
    private readonly string _scriptsDirectory;
    private string? _loadedFile;

    public SentinelScriptHubWindow() : this(null, System.IO.Path.Combine(AppContext.BaseDirectory, "Scripts"))
    {
    }

    public SentinelScriptHubWindow(SentinelWindow? owner, string scriptsDirectory)
    {
        _owner = owner;
        _scriptsDirectory = scriptsDirectory;
        AvaloniaXamlLoader.Load(this);

        if (owner is not null)
        {
            Position = new PixelPoint(
                owner.Position.X + (int)owner.Width + 12,
                owner.Position.Y);
        }
    }

    private void HubItem_Click(object? sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string tag } ||
            this.FindControl<TextBox>("PreviewBox") is not { } preview ||
            this.FindControl<TextBlock>("StatusText") is not { } status)
        {
            return;
        }

        var path = System.IO.Path.Combine(_scriptsDirectory, tag + ".lua");
        try
        {
            if (File.Exists(path))
            {
                var source = File.ReadAllText(path);
                preview.Text = source;
                _loadedFile = path;
                status.Text = $"{tag}.lua — {source.Length} chars loaded.";
                return;
            }
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException)
        {
            preview.Text = string.Empty;
            _loadedFile = null;
            status.Text = $"Failed to read '{tag}.lua': {ex.Message}";
            return;
        }

        preview.Text = string.Empty;
        _loadedFile = null;
        status.Text = $"'{tag}.lua' was not found. Put the script into the Scripts folder under this name.";
    }

    private void Execute_Click(object? sender, RoutedEventArgs e)
    {
        if (_loadedFile is null ||
            this.FindControl<TextBox>("PreviewBox") is not { } preview ||
            string.IsNullOrWhiteSpace(preview.Text))
        {
            return;
        }

        UnifiedBridgeServer.Shared.EnqueueExecute(preview.Text);
        _owner?.AppendConsoleLine("info", $"Script Hub: executed {System.IO.Path.GetFileName(_loadedFile)}.");
    }

    private void Close_Click(object? sender, RoutedEventArgs e) => Close();

    private void TitleBar_PointerPressed(object? sender, PointerPressedEventArgs e)
    {
        var point = e.GetCurrentPoint(this);
        if (!point.Properties.IsLeftButtonPressed) return;
        if (e.Source is Avalonia.Visual v && (v is Button || v.GetVisualAncestors().OfType<Button>().Any())) return;
        BeginMoveDrag(e);
    }
}
