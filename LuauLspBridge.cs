using System.Diagnostics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace OrbitAvalonia;

/// <summary>
/// Hosts one <c>luau-lsp.exe</c> process per MonacoStaticServer and bridges it to
/// the editor pages over two HTTP endpoints: POST /lsp (request/response) and
/// GET /lsp/notifications (long-poll fan-out of server notifications such as
/// textDocument/publishDiagnostics). The initialize/initialized handshake is
/// performed internally, so pages only send ordinary LSP requests like
/// textDocument/completion or textDocument/didOpen.
/// </summary>
internal sealed class LuauLspBridge : IDisposable
{
    private static readonly TimeSpan RequestTimeout = TimeSpan.FromSeconds(15);
    private static readonly TimeSpan PollTimeout = TimeSpan.FromSeconds(25);

    private readonly object _gate = new();
    private readonly List<NotificationWaiter> _waiters = new();
    private readonly Dictionary<long, TaskCompletionSource<JsonNode?>> _pending = new();
    private readonly List<JsonObject> _notificationLog = new();
    private long _notificationTotal;

    private Process? _process;
    private Stream? _stdin;
    private Task? _readyTask;
    private long _nextRequestId;
    private bool _disposed;

    private sealed class NotificationWaiter
    {
        public required TaskCompletionSource<bool> Signal;
        public long Seen;
    }

    private static readonly HashSet<string> NotificationMethods = new(StringComparer.Ordinal)
    {
        "initialized",
        "exit",
        "$/cancelRequest",
        "textDocument/didOpen",
        "textDocument/didChange",
        "textDocument/didClose",
        "textDocument/didSave",
        "workspace/didChangeConfiguration",
        "workspace/didChangeWatchedFiles",
    };

    /// <summary>Sends one LSP message (the body contains "method" and "params").
    /// Notifications (didOpen/didChange/...) are forwarded without an id — the
    /// server never replies to them. Requests return the server's "result"
    /// JSON. Throws on timeout / dead process.</summary>
    public async Task<JsonNode?> RequestAsync(JsonObject body)
    {
        if (body is null)
        {
            throw new ArgumentException("Body is required.");
        }

        await EnsureStartedAsync().ConfigureAwait(false);

        var method = body["method"]?.GetValue<string>();
        if (string.IsNullOrEmpty(method))
        {
            throw new ArgumentException("Body must contain a \"method\" property.");
        }

        if (NotificationMethods.Contains(method))
        {
            var notification = new JsonObject
            {
                ["jsonrpc"] = "2.0",
                ["method"] = method,
                ["params"] = body["params"]?.DeepClone() ?? new JsonObject(),
            };
            await WriteFrameAsync(notification).ConfigureAwait(false);
            return null;
        }

        long id;
        TaskCompletionSource<JsonNode?> completion;
        lock (_gate)
        {
            id = ++_nextRequestId;
            completion = new TaskCompletionSource<JsonNode?>(TaskCreationOptions.RunContinuationsAsynchronously);
            _pending[id] = completion;
        }

        var frame = new JsonObject
        {
            ["jsonrpc"] = "2.0",
            ["id"] = id,
            ["method"] = method,
            ["params"] = body["params"]?.DeepClone() ?? new JsonObject(),
        };

        try
        {
            await WriteFrameAsync(frame).ConfigureAwait(false);
        }
        catch
        {
            lock (_gate) { _pending.Remove(id); }
            throw;
        }

        try
        {
            var completed = await Task.WhenAny(completion.Task, Task.Delay(RequestTimeout)).ConfigureAwait(false);
            if (completed != completion.Task)
            {
                throw new TimeoutException($"luau-lsp did not answer '{method}' within {RequestTimeout.TotalSeconds:0}s.");
            }
            return completion.Task.Result;
        }
        finally
        {
            lock (_gate) { _pending.Remove(id); }
        }
    }

    /// <summary>Long-poll: waits up to PollTimeout for notifications the caller
    /// has not yet seen (identified by the running <paramref name="seen"/> counter)
    /// and returns the batch plus the new cursor.</summary>
    public async Task<(JsonArray Items, long Cursor)> PollNotificationsAsync(long seen)
    {
        TaskCompletionSource<bool> signal;
        lock (_gate)
        {
            if (seen < _notificationTotal)
            {
                return (TakeNotifications(seen), _notificationTotal);
            }
            if (_disposed)
            {
                return (new JsonArray(), _notificationTotal);
            }
            signal = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
            _waiters.Add(new NotificationWaiter { Signal = signal, Seen = seen });
        }

        var completed = await Task.WhenAny(signal.Task, Task.Delay(PollTimeout)).ConfigureAwait(false);
        lock (_gate)
        {
            _waiters.RemoveAll(w => ReferenceEquals(w.Signal, signal));
            return (TakeNotifications(seen), _notificationTotal);
        }
    }

    private JsonArray TakeNotifications(long seen)
    {
        var items = new JsonArray();
        foreach (var notification in _notificationLog)
        {
            var index = notification["__seq"]?.GetValue<long>() ?? 0;
            if (index > seen)
            {
                var clone = (JsonObject)notification.DeepClone();
                clone.Remove("__seq");
                items.Add(clone);
            }
        }
        return items;
    }

    public void Dispose()
    {
        lock (_gate)
        {
            _disposed = true;
            foreach (var waiter in _waiters)
            {
                waiter.Signal.TrySetResult(false);
            }
            _waiters.Clear();
        }
        KillProcess();
    }

    // ---------------------------------------------------------------- startup

    private async Task EnsureStartedAsync()
    {
        var ready = _readyTask;
        if (ready is not null)
        {
            await AwaitReadyAsync(ready).ConfigureAwait(false);
        }
        else
        {
            var task = InitializeAsync();
            var existing = Interlocked.CompareExchange(ref _readyTask, task, null);
            await AwaitReadyAsync(existing ?? task).ConfigureAwait(false);
        }

        lock (_gate)
        {
            if (_process is { HasExited: true })
            {
                // The process died; drop it so the next call restarts it.
                CleanupProcess();
            }
        }

        if (_process is null)
        {
            var task = InitializeAsync();
            _readyTask = task;
            await AwaitReadyAsync(task).ConfigureAwait(false);
        }
    }

    /// <summary>Awaits the initialize task; on failure clears it so the next
    /// request starts a fresh process instead of failing forever.</summary>
    private async Task AwaitReadyAsync(Task ready)
    {
        try
        {
            await ready.ConfigureAwait(false);
        }
        catch
        {
            _readyTask = null;
            throw;
        }
    }

    private async Task InitializeAsync()
    {
        var (exePath, definitionPaths) = ResolveLuauLsp();
        var workspace = Path.Combine(Path.GetTempPath(), "OrionLuauLsp");
        Directory.CreateDirectory(workspace);

        var startInfo = new ProcessStartInfo
        {
            FileName = exePath,
            UseShellExecute = false,
            CreateNoWindow = true,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            WorkingDirectory = workspace,
        };
        startInfo.ArgumentList.Add("lsp");
        startInfo.ArgumentList.Add("--stdio");
        foreach (var definition in definitionPaths)
        {
            startInfo.ArgumentList.Add($"--definitions={definition}");
        }

        var process = Process.Start(startInfo)
            ?? throw new InvalidOperationException("Failed to start luau-lsp.exe.");

        lock (_gate)
        {
            _process = process;
            _stdin = process.StandardInput.BaseStream;
        }

        _ = ReadOutputLoopAsync(process);
        _ = process.StandardError.ReadToEndAsync(); // drain stderr so the child never blocks

        var rootUri = new Uri(workspace + Path.DirectorySeparatorChar).AbsoluteUri;
        await WriteFrameAsync(new JsonObject
        {
            ["jsonrpc"] = "2.0",
            ["id"] = 0,
            ["method"] = "initialize",
            ["params"] = new JsonObject
            {
                ["processId"] = null,
                ["rootUri"] = rootUri,
                ["capabilities"] = new JsonObject
                {
                    ["textDocument"] = new JsonObject
                    {
                        ["completion"] = new JsonObject
                        {
                            ["completionItem"] = new JsonObject
                            {
                                ["snippetSupport"] = true,
                                ["documentationFormat"] = new JsonArray("markdown", "plaintext"),
                            },
                        },
                        ["hover"] = new JsonObject
                        {
                            ["contentFormat"] = new JsonArray("markdown", "plaintext"),
                        },
                        ["signatureHelp"] = new JsonObject
                        {
                            ["signatureInformation"] = new JsonObject
                            {
                                ["documentationFormat"] = new JsonArray("markdown", "plaintext"),
                            },
                        },
                    },
                },
            },
        }).ConfigureAwait(false);

        // Await the initialize response from the read loop.
        var response = await WaitForResponseAsync(0).ConfigureAwait(false);
        if (response is null)
        {
            KillProcess();
            throw new InvalidOperationException("luau-lsp.exe failed to initialize (no response).");
        }

        await WriteFrameAsync(new JsonObject
        {
            ["jsonrpc"] = "2.0",
            ["method"] = "initialized",
            ["params"] = new JsonObject(),
        }).ConfigureAwait(false);
    }

    private async Task<JsonNode?> WaitForResponseAsync(long id)
    {
        var completion = new TaskCompletionSource<JsonNode?>(TaskCreationOptions.RunContinuationsAsynchronously);
        lock (_gate)
        {
            _pending[id] = completion;
        }
        try
        {
            var completed = await Task.WhenAny(completion.Task, Task.Delay(TimeSpan.FromSeconds(30))).ConfigureAwait(false);
            return completed == completion.Task ? completion.Task.Result : null;
        }
        finally
        {
            lock (_gate) { _pending.Remove(id); }
        }
    }

    private static (string ExePath, string[] Definitions) ResolveLuauLsp()
    {
        var baseDirectory = AppContext.BaseDirectory;

        string? FindUpwards(string fileName)
        {
            var directory = new DirectoryInfo(baseDirectory);
            for (var i = 0; i < 8 && directory is not null; i++, directory = directory.Parent)
            {
                var candidate = Path.Combine(directory.FullName, fileName);
                if (File.Exists(candidate))
                {
                    return candidate;
                }
            }
            return null;
        }

        var exePath = Path.Combine(baseDirectory, "luau-lsp.exe");
        if (!File.Exists(exePath))
        {
            exePath = FindUpwards("luau-lsp.exe")
                ?? throw new FileNotFoundException("luau-lsp.exe was not found next to Orion.exe or in the repository root.");
        }

        string? FindDefinitions(string fileName)
        {
            var nextToExe = Path.Combine(Path.GetDirectoryName(exePath)!, "luau", fileName);
            if (File.Exists(nextToExe))
            {
                return nextToExe;
            }
            var directory = new DirectoryInfo(baseDirectory);
            for (var i = 0; i < 8 && directory is not null; i++, directory = directory.Parent)
            {
                var candidate = Path.Combine(directory.FullName, "luau", fileName);
                if (File.Exists(candidate))
                {
                    return candidate;
                }
            }
            return null;
        }

        var globalTypes = FindDefinitions("globalTypes.d.luau");
        var sunc = FindDefinitions("sunc.d.luau");

        var definitions = new List<string>();
        if (globalTypes is not null) definitions.Add(globalTypes);
        if (sunc is not null) definitions.Add(sunc);
        return (exePath, definitions.ToArray());
    }

    // -------------------------------------------------------------------- I/O

    private async Task WriteFrameAsync(JsonObject body)
    {
        var stream = _stdin;
        if (stream is null)
        {
            throw new InvalidOperationException("The luau-lsp process is not running.");
        }

        var payload = JsonSerializer.Serialize(body);
        var bytes = Encoding.UTF8.GetBytes(payload);
        var header = Encoding.ASCII.GetBytes($"Content-Length: {bytes.Length}\r\n\r\n");

        await _writeLock.WaitAsync().ConfigureAwait(false);
        try
        {
            await stream.WriteAsync(header).ConfigureAwait(false);
            await stream.WriteAsync(bytes).ConfigureAwait(false);
            await stream.FlushAsync().ConfigureAwait(false);
        }
        finally
        {
            _writeLock.Release();
        }
    }

    private readonly SemaphoreSlim _writeLock = new(1, 1);

    private async Task ReadOutputLoopAsync(Process process)
    {
        var buffer = new byte[64 * 1024];
        var accumulated = new List<byte>();
        var stream = process.StandardOutput.BaseStream;

        try
        {
            while (true)
            {
                var read = await stream.ReadAsync(buffer).ConfigureAwait(false);
                if (read <= 0)
                {
                    break; // process exited
                }
                accumulated.AddRange(buffer.Take(read));

                while (TryParseFrame(accumulated, out var body, out var consumed))
                {
                    accumulated.RemoveRange(0, consumed);
                    if (body is not null)
                    {
                        DispatchMessage(body);
                    }
                }
            }
        }
        catch
        {
            // Stream errors mean the process is going away; fail pending below.
        }

        FailAllPending(new InvalidOperationException("luau-lsp.exe exited."));
    }

    private static bool TryParseFrame(List<byte> buffer, out JsonObject? body, out int consumed)
    {
        body = null;
        consumed = 0;

        // Find the \r\n\r\n header terminator.
        int headerEnd = -1;
        for (var i = 0; i + 3 < buffer.Count; i++)
        {
            if (buffer[i] == 13 && buffer[i + 1] == 10 && buffer[i + 2] == 13 && buffer[i + 3] == 10)
            {
                headerEnd = i;
                break;
            }
        }
        if (headerEnd < 0)
        {
            return false;
        }

        var headerText = Encoding.ASCII.GetString(buffer.Take(headerEnd).ToArray());
        var match = System.Text.RegularExpressions.Regex.Match(headerText, @"Content-Length:\s*(\d+)", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
        if (!match.Success)
        {
            consumed = headerEnd + 4;
            return true; // skip malformed frame
        }

        var length = int.Parse(match.Groups[1].Value);
        if (buffer.Count < headerEnd + 4 + length)
        {
            return false;
        }

        var payload = Encoding.UTF8.GetString(buffer.Skip(headerEnd + 4).Take(length).ToArray());
        consumed = headerEnd + 4 + length;
        body = JsonSerializer.Deserialize<JsonObject>(payload);
        return true;
    }

    private void DispatchMessage(JsonObject message)
    {
        var idNode = message["id"];
        if (idNode is not null)
        {
            TaskCompletionSource<JsonNode?>? completion;
            var id = idNode.GetValue<long>();
            lock (_gate)
            {
                _pending.Remove(id, out completion);
            }
            completion?.TrySetResult(message["result"]);
            return;
        }

        var method = message["method"]?.GetValue<string>();
        if (string.IsNullOrEmpty(method))
        {
            return;
        }

        long sequence;
        lock (_gate)
        {
            sequence = ++_notificationTotal;
            var stored = (JsonObject)message.DeepClone();
            stored["__seq"] = sequence;
            _notificationLog.Add(stored);
            if (_notificationLog.Count > 400)
            {
                _notificationLog.RemoveRange(0, _notificationLog.Count - 400);
            }
            foreach (var waiter in _waiters)
            {
                waiter.Signal.TrySetResult(true);
            }
        }
    }

    private void FailAllPending(Exception error)
    {
        TaskCompletionSource<JsonNode?>[] completions;
        lock (_gate)
        {
            completions = _pending.Values.ToArray();
            _pending.Clear();
            CleanupProcess();
        }
        foreach (var completion in completions)
        {
            completion.TrySetException(error);
        }
    }

    private void CleanupProcess()
    {
        _stdin = null;
        if (_process is not null)
        {
            try
            {
                if (!_process.HasExited)
                {
                    _process.Kill(entireProcessTree: true);
                }
            }
            catch
            {
                // The process may already be gone.
            }
            _process.Dispose();
            _process = null;
        }
    }

    private void KillProcess()
    {
        lock (_gate)
        {
            CleanupProcess();
        }
    }
}
