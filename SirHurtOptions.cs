using System.Text.Json;

namespace OrbitAvalonia;

internal sealed class SirHurtOptions
{
    public bool CloseTabConfirmation { get; set; }
}

internal static class SirHurtOptionsStore
{
    private static readonly object Gate = new();
    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "sirhurt-options.json");

    public static SirHurtOptions Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(OptionsPath)) return new SirHurtOptions();
                var options = JsonSerializer.Deserialize<SirHurtOptions>(
                    File.ReadAllText(OptionsPath));
                return options ?? new SirHurtOptions();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new SirHurtOptions();
            }
        }
    }

    public static void Save(SirHurtOptions options)
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
