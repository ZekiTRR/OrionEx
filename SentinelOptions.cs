using System.Text.Json;

namespace OrbitAvalonia;

internal sealed class SentinelOptions
{
    public bool UnlockFps { get; set; } = true;
    public bool AutoLaunch { get; set; }
    public bool AutoAttach { get; set; } = true;
    public bool InternalUi { get; set; } = true;
    public bool LegacyUi { get; set; } = true;
    public bool TopMost { get; set; } = true;
}

internal static class SentinelOptionsStore
{
    private static readonly object Gate = new();
    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "Sentinel-options.json");

    public static SentinelOptions Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(OptionsPath)) return new SentinelOptions();
                return JsonSerializer.Deserialize<SentinelOptions>(File.ReadAllText(OptionsPath))
                       ?? new SentinelOptions();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new SentinelOptions();
            }
        }
    }

    public static void Save(SentinelOptions options)
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
