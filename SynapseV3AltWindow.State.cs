using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace OrbitAvalonia;

public sealed partial class SynapseV3AltWindow
{
    private JsonObject _settings = [];
    private JsonObject _storage = [];
    private JsonObject _editorConfig = [];
    private JsonObject _workspace;

    private JsonObject ReadObject(string name)
    {
        try
        {
            var path = Path.Combine(_dataRoot, name);
            EnsureNoLinks(path);
            return File.Exists(path) ? JsonNode.Parse(File.ReadAllText(path)) as JsonObject ?? [] : [];
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or JsonException)
        {
            Log("warning", $"Could not read {name}; starting fresh. {error.Message}");
            return [];
        }
    }

    private void PersistObject(string name, JsonObject value)
    {
        EnsureNoLinks(_dataRoot);
        Directory.CreateDirectory(_dataRoot);
        var path = Path.Combine(_dataRoot, name);
        EnsureNoLinks(path);
        var temporary = Path.Combine(_dataRoot, $"{Guid.NewGuid():N}.tmp");
        try
        {
            using (var stream = new FileStream(temporary, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                JsonSerializer.Serialize(stream, value);
            File.Move(temporary, path, true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }

    private void SetValue(JsonObject container, string key, JsonNode? value, string file)
    {
        if (string.IsNullOrWhiteSpace(key) || key.Length > 200) throw new ArgumentException("A valid settings key is required.");
        container[key] = value?.DeepClone();
        PersistObject(file, container);
    }

    private static JsonObject RequireObject(JsonNode? value) => value is JsonObject obj
        ? (JsonObject)obj.DeepClone() : throw new ArgumentException("An object payload is required.");

    // Keep full frontend metadata separately: shared DTO deliberately only has id/title/content/extension.
    private void AcceptWorkspace(JsonNode? payload)
    {
        var workspace = RequireObject(payload);
        if (workspace["tabs"] is not JsonArray tabs || tabs.Count > 64)
            throw new ArgumentException("A workspace requires an array of up to 64 tabs.");
        var ids = new HashSet<string>();
        foreach (var node in tabs)
        {
            if (node is not JsonObject tab) throw new ArgumentException("Invalid workspace tab.");
            var id = tab["id"]?.GetValue<string>();
            if (string.IsNullOrWhiteSpace(id) || !ids.Add(id)) throw new ArgumentException("Every tab requires a unique id.");
            var content = tab["content"]?.GetValue<string>() ?? "";
            if (content.Length > 8_000_000) throw new ArgumentException("A workspace tab is too large.");
            tab["content"] = content;
            tab["title"] = tab["title"]?.GetValue<string>() ?? "Untitled";
            tab["extension"] = tab["extension"]?.GetValue<string>() ?? ".lua";
        }
        var active = workspace["activeTabId"]?.GetValue<string>();
        if (active is null || !ids.Contains(active)) workspace["activeTabId"] = tabs.FirstOrDefault()?["id"]?.DeepClone();
        _workspace = workspace;
    }

    private void RestoreTabMetadata()
    {
        if (ReadObject("workspace.json")["tabs"] is not JsonArray saved) return;
        foreach (var tab in _workspace["tabs"]!.AsArray().OfType<JsonObject>())
        {
            var id = tab["id"]!.GetValue<string>();
            var previous = saved.OfType<JsonObject>().FirstOrDefault(candidate =>
                candidate["id"] is JsonValue value && value.TryGetValue<string>(out var oldId) && SharedId(oldId).ToString() == id);
            if (previous is null) continue;
            foreach (var key in new[] { "savedValue", "filePath", "isFile", "pinned", "readonly", "customIcon", "isBookmark", "bookmarkUri" })
                if (previous.ContainsKey(key)) tab[key] = previous[key]?.DeepClone();
        }
    }

    private void PersistWorkspace()
    {
        // Workspace is returned via callback on close; local persistence only for settings/storage/editor-config
        var shared = ToShared();
        _workspaceService.SaveState(shared.Tabs, shared.ActiveTabId);
    }

    // Frontend new tabs may use non-GUID IDs: deterministically map them so every
    // periodic save and the final callback refer to the same shared tab IDs.
    private static Guid SharedId(string id) => Guid.TryParse(id, out var guid) ? guid :
        new Guid(SHA256.HashData(Encoding.UTF8.GetBytes(id)).AsSpan(0, 16));

    private EditorWorkspaceState ToShared()
    {
        var tabs = new List<EditorTabState>();
        Guid active = default;
        foreach (var tab in _workspace["tabs"]?.AsArray().OfType<JsonObject>() ?? [])
        {
            var state = new EditorTabState
            {
                Id = SharedId(tab["id"]!.GetValue<string>()),
                Title = tab["title"]?.GetValue<string>() ?? "Untitled",
                Content = tab["content"]?.GetValue<string>() ?? "",
                Extension = tab["extension"]?.GetValue<string>() ?? ".lua"
            };
            if (tab["id"]?.GetValue<string>() == _workspace["activeTabId"]?.GetValue<string>()) active = state.Id;
            tabs.Add(state);
        }
        if (active == default && tabs.Count > 0) active = tabs[0].Id;
        return new EditorWorkspaceState { Tabs = tabs, ActiveTabId = active };
    }

    private static JsonObject FromShared(EditorWorkspaceState workspace)
    {
        var tabs = new JsonArray();
        foreach (var tab in workspace.Tabs)
            tabs.Add(new JsonObject { ["id"] = tab.Id.ToString(), ["title"] = tab.Title, ["content"] = tab.Content,
                ["extension"] = tab.Extension, ["savedValue"] = tab.Content, ["filePath"] = null });
        return new JsonObject { ["tabs"] = tabs, ["activeTabId"] = (workspace.ActiveTabId != default ? workspace.ActiveTabId : workspace.Tabs.FirstOrDefault()?.Id ?? default).ToString() };
    }
}
