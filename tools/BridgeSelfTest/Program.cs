// Self-test of UnifiedBridgeServer: registers a synthetic client over the real
using System.Text.Json;
// HTTP endpoints (the same flow Orion Bridge.lua uses) and exercises the
// execute -> poll -> result -> log path plus event notifications.
using System.Text;
using System.Text.Json.Nodes;
using OrbitAvalonia;

using var bridge = UnifiedBridgeServer.Shared;
var connected = new List<bool>();
var logs = new List<(string Level, string Message)>();
var clientsChanged = 0;
bridge.ConnectionChanged += connectedEvent => { lock (connected) connected.Add(connectedEvent); };
bridge.LogReceived += (level, message) => { lock (logs) logs.Add((level, message)); };
bridge.ClientsChanged += () => clientsChanged++;

var http = new HttpClient { BaseAddress = new Uri("http://127.0.0.1:31337/") };
const string Protocol = "orion-bridge-v2";

async Task<JsonObject?> CallAsync(string path, HttpContent? content = null)
{
    using var response = await http.PostAsync(path + $"?protocol={Protocol}", content ?? new StringContent("", Encoding.UTF8, "application/json"));
    var text = await response.Content.ReadAsStringAsync();
    return response.StatusCode == System.Net.HttpStatusCode.OK ? JsonNode.Parse(text) as JsonObject : null;
}

var hello = await CallAsync("/port_bridge/hello", new StringContent(
    JsonSerializer.Serialize(new { client = "selftest", username = "SelfTest", session_id = "selftest-1", requested_identifier = "User1" }), Encoding.UTF8, "application/json"));
if (!string.Equals(hello?["ok"]?.ToString(), "true", StringComparison.OrdinalIgnoreCase)) throw new Exception("hello failed: " + hello?.ToJsonString());
Console.WriteLine($"HELLO identifier={hello["identifier"]} transport={hello["transport"]}");

var queued = bridge.EnqueueExecute("print('bridge selftest')");
Console.WriteLine($"ENQUEUED {queued}");

var pollUri = new Uri("http://127.0.0.1:31337/port_bridge/next?protocol=" + Protocol + "&session_id=selftest-1");
using var longPoll = await http.GetAsync(pollUri, HttpCompletionOption.ResponseHeadersRead);
var next = JsonNode.Parse(await longPoll.Content.ReadAsStringAsync())!;
var exec = next["exec"]!;
var source = Encoding.UTF8.GetString(Convert.FromBase64String(exec["source_b64"]!.ToString()));
Console.WriteLine("NEXT raw: " + next.ToJsonString());
if (exec["id"]!.ToString() != queued) throw new Exception("Execution id mismatch");

await CallAsync("/port_bridge/result", new StringContent(
    JsonSerializer.Serialize(new { id = exec["id"]!.ToString(), ok = true }), Encoding.UTF8, "application/json"));
await CallAsync("/port_bridge/log", new StringContent(
    JsonSerializer.Serialize(new { level = "info", message = "Hello from the game" }), Encoding.UTF8, "application/json"));

await Task.Delay(300);
var status = JsonNode.Parse(await http.GetStringAsync("/status"))!;
Console.WriteLine($"STATUS connected={status["connected"]} clients={status["clients"].AsArray().Count}");

lock (logs)
{
    foreach (var entry in logs) Console.WriteLine($"LOG[{entry.Level}] {entry.Message}");
    if (!logs.Any(l => l.Message.Contains($"Execution {queued} completed"))) throw new Exception("Completion log missing");
    if (!logs.Any(l => l.Message == "Hello from the game")) throw new Exception("Client log missing");
}
lock (connected) if (!connected.Contains(true)) throw new Exception("ConnectionChanged(true) missing");
Console.WriteLine(clientsChanged > 0 ? "BRIDGE SELFTEST: PASS" : "BRIDGE SELFTEST: FAIL (no client events)");
return clientsChanged > 0 ? 0 : 1;
