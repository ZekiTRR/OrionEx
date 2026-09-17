using System.Text.Json;
using Avalonia.Media;

namespace OrbitAvalonia;

internal sealed class VelocityOptions
{
    public double FontSize { get; set; } = 14;
    public string FontFamily { get; set; } = "JetBrains Mono";
    public bool Minimap { get; set; }
    public bool Topmost { get; set; }
    public bool AllowResize { get; set; } = true;
    public double WindowWidth { get; set; } = 920;
    public double WindowHeight { get; set; } = 620;
    public bool ExplorerVisible { get; set; } = true;
    public bool TerminalVisible { get; set; } = true;
    public bool ConfirmClose { get; set; } = true;
    public bool WelcomeSeen { get; set; }
    public double ExplorerWidth { get; set; } = 270;
    public double TerminalHeight { get; set; } = 170;
    public string Accent { get; set; } = "#2D7DFF";
    public string Background { get; set; } = "#080808";
    public string BackgroundFile { get; set; } = "";
    public double BackgroundOpacity { get; set; } = .15;

    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Orion", "velocity-options.json");

    internal static VelocityOptions Load()
    {
        try
        {
            var value = File.Exists(OptionsPath)
                ? JsonSerializer.Deserialize<VelocityOptions>(File.ReadAllText(OptionsPath)) ?? new()
                : new VelocityOptions();
            value.FontSize = double.IsFinite(value.FontSize) ? Math.Clamp(value.FontSize, 8, 28) : 14;
            value.ExplorerWidth = double.IsFinite(value.ExplorerWidth) ? Math.Clamp(value.ExplorerWidth, 160, 450) : 270;
            value.TerminalHeight = double.IsFinite(value.TerminalHeight) ? Math.Clamp(value.TerminalHeight, 140, 400) : 170;
            value.WindowWidth = double.IsFinite(value.WindowWidth) ? Math.Clamp(value.WindowWidth, 560, 7680) : 920;
            value.WindowHeight = double.IsFinite(value.WindowHeight) ? Math.Clamp(value.WindowHeight, 360, 4320) : 620;
            value.BackgroundOpacity = double.IsFinite(value.BackgroundOpacity) ? Math.Clamp(value.BackgroundOpacity, 0, .7) : .15;
            if (!Color.TryParse(value.Accent, out _)) value.Accent = "#2D7DFF";
            if (!Color.TryParse(value.Background, out _)) value.Background = "#080808";
            if (string.IsNullOrWhiteSpace(value.FontFamily)) value.FontFamily = "JetBrains Mono";
            value.BackgroundFile ??= "";
            return value;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException or ArgumentException)
        { return new(); }
    }

    internal bool Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(OptionsPath)!);
            File.WriteAllText(OptionsPath + ".tmp", JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true }));
            File.Move(OptionsPath + ".tmp", OptionsPath, true);
            return true;
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException) { return false; }
    }
}
