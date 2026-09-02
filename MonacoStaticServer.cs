using System.Net;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;

namespace OrbitAvalonia;

internal sealed class MonacoStaticServer : IDisposable
{
    private readonly WebApplication _application;
    private readonly LuauLspBridge _lspBridge = new();

    public MonacoStaticServer(string rootDirectory)
    {
        var contentRoot = Path.GetFullPath(rootDirectory);
        var fileProvider = new PhysicalFileProvider(contentRoot);
        var builder = WebApplication.CreateSlimBuilder();

        builder.WebHost.ConfigureKestrel(options =>
            options.Listen(IPAddress.Loopback, 0));

        _application = builder.Build();
        _application.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = fileProvider,
            ServeUnknownFileTypes = false
        });

        // Luau LSP bridge: the editor pages talk to luau-lsp.exe over these
        // two same-origin endpoints. POST /lsp performs a request/response
        // round-trip; GET /lsp/notifications long-polls server notifications
        // (diagnostics, ...). One luau-lsp process serves every page of this
        // server instance; sessions are distinguished by document URIs.
        _application.MapPost("/lsp", async (HttpContext context) =>
        {
            try
            {
                using var document = await JsonDocument.ParseAsync(context.Request.Body).ConfigureAwait(false);
                var body = JsonSerializer.SerializeToNode(document.RootElement) as JsonObject;
                var result = await _lspBridge.RequestAsync(body!).ConfigureAwait(false);
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsync(
                    JsonSerializer.Serialize(result ?? new JsonObject()), context.RequestAborted).ConfigureAwait(false);
            }
            catch (Exception error)
            {
                context.Response.StatusCode = 502;
                context.Response.ContentType = "application/json";
                var failure = JsonSerializer.Serialize(new { error = error.Message });
                await context.Response.WriteAsync(failure, context.RequestAborted).ConfigureAwait(false);
            }
        });

        _application.MapGet("/lsp/notifications", async (HttpContext context) =>
        {
            long seen = 0;
            var seenQuery = context.Request.Query["seen"];
            if (seenQuery.Count > 0 && long.TryParse(seenQuery[0], out var parsed))
            {
                seen = parsed;
            }

            try
            {
                var (items, cursor) = await _lspBridge.PollNotificationsAsync(seen).ConfigureAwait(false);
                context.Response.ContentType = "application/json";
                var payload = JsonSerializer.Serialize(new { notifications = items, cursor });
                await context.Response.WriteAsync(payload, context.RequestAborted).ConfigureAwait(false);
            }
            catch (OperationCanceledException)
            {
                // The page navigated away mid-poll; the response is dropped.
            }
        });

        _application.StartAsync().GetAwaiter().GetResult();

        var addresses = _application.Services
            .GetRequiredService<IServer>()
            .Features
            .Get<IServerAddressesFeature>()?
            .Addresses;
        var serverAddress = addresses?.SingleOrDefault()
            ?? throw new InvalidOperationException("The Monaco server did not start.");

        Address = new Uri(new Uri(serverAddress), "index.html");
    }

    public Uri Address { get; }

    public void Dispose()
    {
        // Stop the host on a worker thread with a bounded wait: StopAsync must
        // never run on the Avalonia UI thread, where an internal await captures
        // the UI SynchronizationContext and deadlocks against the blocking
        // wait (in-flight /lsp/notifications long-polls make this a certainty).
        _lspBridge.Dispose();
        try
        {
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            Task.Run(() => _application.StopAsync(timeout.Token))
                .Wait(TimeSpan.FromSeconds(7));
        }
        catch
        {
            // The process is on its way out; a partially stopped host is fine.
        }

        try
        {
            _application.DisposeAsync().AsTask().Wait(TimeSpan.FromSeconds(3));
        }
        catch
        {
        }
    }
}
