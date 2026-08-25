using System.Text.Json;

namespace OrbitAvalonia;

internal sealed class WaveEditorOptions
{
    public bool Minimap { get; set; }
    public bool InlayHints { get; set; } = true;
    public bool SmoothCursor { get; set; } = true;
    public bool SmoothScroll { get; set; } = true;
    public string ScriptsFolder { get; set; } = string.Empty;
    public string WorkspaceFolder { get; set; } = string.Empty;
}

internal static class WaveEditorOptionsStore
{
    private static readonly object Gate = new();
    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "Wave-editor-options.json");

    public static WaveEditorOptions Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(OptionsPath)) return new WaveEditorOptions();
                var options = JsonSerializer.Deserialize<WaveEditorOptions>(
                    File.ReadAllText(OptionsPath));
                return options ?? new WaveEditorOptions();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new WaveEditorOptions();
            }
        }
    }

    public static void Save(WaveEditorOptions options)
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

internal static class WaveFavouritesStore
{
    private static readonly object Gate = new();
    private static readonly string FavouritesPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "Wave-favourites.json");

    public static HashSet<string> Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(FavouritesPath)) return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                var paths = JsonSerializer.Deserialize<List<string>>(File.ReadAllText(FavouritesPath));
                return new HashSet<string>(paths ?? [], StringComparer.OrdinalIgnoreCase);
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            }
        }
    }

    public static void Save(HashSet<string> favourites)
    {
        lock (Gate)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(FavouritesPath)!);
                File.WriteAllText(
                    FavouritesPath,
                    JsonSerializer.Serialize(favourites.OrderBy(path => path, StringComparer.OrdinalIgnoreCase).ToList()));
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}


