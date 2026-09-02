// Standalone integration test for the real MonacoStaticServer + LuauLspBridge
// HTTP bridge. Starts one server instance against the built MonacoPreview
// folder and drives the same endpoints the editor pages use.
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using OrbitAvalonia;

var staticRoot = args.Length > 0
    ? args[0]
    : "D:/Cheats/Orion/bin/Debug/net8.0-windows/win-x64/MonacoPreview";

using var server = new MonacoStaticServer(staticRoot);
var baseUri = new Uri(server.Address.GetLeftPart(UriPartial.Authority));
Console.WriteLine("Server: " + baseUri);

using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(60) };

async Task<JsonNode?> CallLsp(string method, object parameters)
{
    var payload = JsonSerializer.Serialize(new { method, @params = parameters });
    var response = await http.PostAsync(new Uri(baseUri, "/lsp"),
        new StringContent(payload, Encoding.UTF8, "application/json"));
    var text = await response.Content.ReadAsStringAsync();
    Console.WriteLine($"  {method}: HTTP {(int)response.StatusCode} len={text.Length}");
    if ((int)response.StatusCode != 200)
    {
        Console.WriteLine("  error body: " + text[..Math.Min(300, text.Length)]);
        return null;
    }
    return JsonNode.Parse(text);
}

var uri = "file:///orion-test/prog.lua";
await CallLsp("textDocument/didOpen", new
{
    textDocument = new { uri, languageId = "lua", version = 1, text = "game:" },
});

var completion = await CallLsp("textDocument/completion", new
{
    textDocument = new { uri },
    position = new { line = 0, character = 5 },
});

var all = completion?.ToJsonString() ?? "";
var itemCount = 0;
if (completion is JsonArray arr)
{
    itemCount = arr.Count;
}
else if (completion?["items"] is JsonArray inner)
{
    itemCount = inner.Count;
}
else
{
    Console.WriteLine("  raw head: " + all[..Math.Min(200, all.Length)]);
}

Console.WriteLine($"  completion items: {itemCount}, contains GetService: {all.Contains("GetService")}");

var ok = itemCount > 0 && all.Contains("GetService");
Console.WriteLine(ok ? "BRIDGE TEST: PASS" : "BRIDGE TEST: FAIL");
return ok ? 0 : 1;
