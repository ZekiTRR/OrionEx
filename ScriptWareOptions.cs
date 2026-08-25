using System.Text.Json;

namespace OrbitAvalonia;

internal sealed class ScriptWareOptions
{
    public bool CloseTabConfirmation { get; set; }
    public bool Resizable { get; set; } = true;
}

internal static class ScriptWareOptionsStore
{    private static readonly object Gate = new();
    private static readonly string OptionsPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "scriptware-options.json");

    public static ScriptWareOptions Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(OptionsPath)) return new ScriptWareOptions();
                var options = JsonSerializer.Deserialize<ScriptWareOptions>(
                    File.ReadAllText(OptionsPath));
                return options ?? new ScriptWareOptions();
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return new ScriptWareOptions();
            }
        }
    }

    public static void Save(ScriptWareOptions options)
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

internal sealed record ScriptWareSavedTab(string Title, string Extension, string Content);

internal static class ScriptWareSessionStore
{
    private static readonly object Gate = new();
    private static readonly string SessionPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "Orbit",
        "scriptware-tabs.json");

    public static List<ScriptWareSavedTab>? Load()
    {
        lock (Gate)
        {
            try
            {
                if (!File.Exists(SessionPath)) return null;
                return JsonSerializer.Deserialize<List<ScriptWareSavedTab>>(File.ReadAllText(SessionPath));
            }
            catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException)
            {
                return null;
            }
        }
    }

    public static void Save(List<ScriptWareSavedTab> tabs)
    {
        lock (Gate)
        {
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(SessionPath)!);
                File.WriteAllText(
                    SessionPath,
                    JsonSerializer.Serialize(tabs, new JsonSerializerOptions { WriteIndented = true }));
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
