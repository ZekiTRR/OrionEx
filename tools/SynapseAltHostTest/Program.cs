using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Nodes;
using Avalonia.Controls;
using OrbitAvalonia;

const BindingFlags Flags = BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public;
var windowType = typeof(SynapseV3AltWindow);
var serviceType = windowType.Assembly.GetType("OrbitAvalonia.EditorWorkspaceService")!;
using var service = (IDisposable)Activator.CreateInstance(serviceType)!;
var host = RuntimeHelpers.GetUninitializedObject(windowType);
var source = RuntimeHelpers.GetUninitializedObject(typeof(NativeWebView));
var scripts = Path.Combine(AppContext.BaseDirectory, "Scripts");
windowType.GetField("_workspaceService", Flags)!.SetValue(host, service);
windowType.GetField("_scriptsDirectory", Flags)!.SetValue(host, scripts);
windowType.GetField("_dialogFiles", Flags)!.SetValue(host, new HashSet<string>(StringComparer.OrdinalIgnoreCase));
var dispatch = windowType.GetMethod("DispatchAsync", Flags)!;
async Task<JsonNode?> Call(string method, params string[] args)
{
    var parameters = new JsonArray(args.Select(a => (JsonNode?)JsonValue.Create(a)).ToArray());
    var task = (Task<object?>)dispatch.Invoke(host, [source, method, parameters])!;
    return JsonSerializer.SerializeToNode(await task);
}
var name = "smoke-" + Guid.NewGuid().ToString("N");
var localFile = Path.Combine(scripts, name + ".lua");
var gistDirectory = (string)serviceType.GetProperty("GithubGistsDirectory")!.GetValue(service)!;
var gistFile = Path.Combine(gistDirectory, name + ".txt");
var sortDirectory = Path.Combine(scripts, name);
void AssertOrder(JsonArray entries)
{
    var names = entries.Select(entry => entry!["name"]!.GetValue<string>()).ToArray();
    if (!names.SequenceEqual(new[] { "AlphaFolder", "zFolder", "a.lua", "B.lua" }))
        throw new Exception("Unexpected explorer order: " + string.Join(", ", names));
}
try
{
    foreach (var root in new[] { sortDirectory, Path.Combine(sortDirectory, "AlphaFolder") })
    {
        Directory.CreateDirectory(Path.Combine(root, "zFolder"));
        Directory.CreateDirectory(Path.Combine(root, "AlphaFolder"));
        await File.WriteAllTextAsync(Path.Combine(root, "B.lua"), "");
        await File.WriteAllTextAsync(Path.Combine(root, "a.lua"), "");
        await File.WriteAllTextAsync(Path.Combine(root, "ignored.bin"), "");
    }
    var tree = (await Call("listScripts"))!.AsArray();
    var sorted = tree.First(entry => entry?["path"]?.ToString() == sortDirectory)!["children"]!.AsArray();
    AssertOrder(sorted);
    AssertOrder(sorted[0]!["children"]!.AsArray());
    Console.WriteLine("HOST_PASS Explorer sorts folders before scripts at both levels and filters non-scripts");
    await File.WriteAllTextAsync(localFile, "local bookmarked = 42");
    var files = await Call("listScripts");
    if (files?.AsArray().Any(f => f?["path"]?.ToString() == localFile) != true) throw new Exception("Local file missing from list");
    var local = await Call("readScript", localFile);
    if (local?["content"]?.ToString() != "local bookmarked = 42") throw new Exception("Bookmark file content mismatch");
    Console.WriteLine("HOST_PASS Local bookmark path lists and reads exact file contents");
    if (args.Contains("--local-only")) return 0;
    await File.WriteAllTextAsync(gistFile, "https://raw.githubusercontent.com/microsoft/vscode/main/README.md");
    var gists = await Call("listGists");
    if (gists?.AsArray().Any(g => g?["path"]?.ToString() == gistFile) != true) throw new Exception("Saved gist missing from list");
    var gist = await Call("readGist", gistFile);
    if (gist?["content"]?.ToString().Contains("Visual Studio Code") != true) throw new Exception("Remote GitHub content mismatch");
    Console.WriteLine("HOST_PASS Saved GitHub link loads real remote text through readGist dispatcher");
    try { await Call("readGist", localFile); throw new Exception("Unlisted gist path was accepted"); }
    catch (FileNotFoundException) { Console.WriteLine("HOST_PASS Gist reads reject paths outside the saved list"); }
    return 0;
}
catch (Exception error) { Console.Error.WriteLine("HOST_FAIL " + error); return 1; }
finally
{
    File.Delete(localFile);
    File.Delete(gistFile);
    if (Directory.Exists(sortDirectory)) Directory.Delete(sortDirectory, true);
}
