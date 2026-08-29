using System.Text.Json;

namespace OrbitAvalonia;

internal sealed class WaveOldEditorOptions
{
    public bool TopMost { get; set; }
    public bool Minimap { get; set; } = true;
    public int FontSize { get; set; } = 14;
}

internal static class WaveOldOptionsStore
{
    private static readonly object Gate = new();
    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "WaveOld-editor-options.json");

    public static WaveOldEditorOptions Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(OptionsPath)) return new WaveOldEditorOptions();
                var options = JsonSerializer.Deserialize<WaveOldEditorOptions>(
                    File.ReadAllText(OptionsPath));
                return options ?? new WaveOldEditorOptions();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new WaveOldEditorOptions();
            }
        }
    }

    public static void Save(WaveOldEditorOptions options)
    {
        lock (Gate)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(OptionsPath)!);
                File.WriteAllText(
                    OptionsPath,
                    JsonSerializer.Serialize(options, new JsonSerializerOptions { WriteIndented = true }));
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
