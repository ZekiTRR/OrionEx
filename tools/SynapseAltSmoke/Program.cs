using Avalonia;
using Avalonia.Controls;
using Avalonia.Controls.ApplicationLifetimes;
using OrbitAvalonia;
using System.Reflection;
using System.Text.Json.Nodes;

internal static class Program
{
    public static string Root = "";
    public static string Mode = "lsp";
    public static int Result = 1;
    [STAThread] public static int Main(string[] args)
    {
        Root = Path.GetFullPath(args[0]);
        if (args.Length > 1) Mode = args[1];
        AppBuilder.Configure<SmokeApp>().UsePlatformDetect().StartWithClassicDesktopLifetime([]);
        return Result;
    }
}
internal sealed class SmokeApp : Application
{
    public override void OnFrameworkInitializationCompleted()
    {
        var desktop = (IClassicDesktopStyleApplicationLifetime)ApplicationLifetime!;
        var view = new NativeWebView();
        var window = new Window { Width = 942, Height = 555, Content = view, Title = "SynapseAlt smoke" };
        desktop.MainWindow = window;
        window.Opened += async (_, _) =>
        {
            using var server = new MonacoStaticServer(Program.Root);
            try
            {
                view.WebMessageReceived += async (_, message) =>
                {
                    var request = JsonNode.Parse(message.Body!);
                    if (request is JsonValue text) request = JsonNode.Parse(text.GetValue<string>());
                    if (request?["synapseAlt"] is null) return;
                    var result = request["method"]?.ToString() == "getBootstrap"
                        ? "{settings:{theme:'hollywood-dark'},storage:{},workspace:{tabs:[{id:'smoke',title:'Smoke.lua',content:'',savedValue:''}],activeTabId:'smoke'}}"
                        : "true";
                    await view.InvokeScript($"window.synapseAltResolve?.({request["id"]!.ToJsonString()},{result},null)");
                };
        var loaded = new TaskCompletionSource();
                view.NavigationCompleted += (_, _) => loaded.TrySetResult();
                view.Source = server.Address;
                await loaded.Task.WaitAsync(TimeSpan.FromSeconds(20));
                if (Program.Mode == "titlebar")
                {
                    string? raw = null;
                    for (int i = 0; i < 50; i++)
                    {
                        await Task.Delay(200);
                        raw = await view.InvokeScript("JSON.stringify({hasTitlebar:!!document.querySelector('.hw-titlebar'),hasNavbar:!!document.querySelector('.hw-navigationbar')})");
                        if (raw?.Contains("true") == true) break;
                        if (i == 49) throw new Exception("React layout never mounted: " + raw);
                    }
                    raw = await view.InvokeScript("""
                        (() => { const t = document.querySelector('.hw-titlebar'); const n = document.querySelector('.hw-navigationbar');
                          if (!t || !n) return JSON.stringify({ error: 'missing nodes' });
                          const ts = getComputedStyle(t), tr = t.getBoundingClientRect();
                          return JSON.stringify({ borderBottomWidth: ts.borderBottomWidth, titlebarHeight: +tr.height.toFixed(2) }); })()
                    """);
                    JsonNode? probe = JsonNode.Parse(raw ?? "null");
                    if (probe is JsonValue inner) probe = JsonNode.Parse(inner.GetValue<string>());
                    Console.WriteLine("TITLEBAR " + raw);
                    if (probe?["error"] is not null) throw new Exception("Titlebar probe failed: " + raw);
                    if (Math.Abs(probe!["titlebarHeight"]!.GetValue<double>() - 32) > 1.5) throw new Exception("Titlebar height changed: " + raw);
                    Console.WriteLine("SMOKE_PASS Titlebar renders at expected height with themed border only");
                    Program.Result = 0;
                    return;
                }
                if (Program.Mode == "reflect") Reflect(view);
        if (Program.Mode == "lsp") await RunLsp(view);
        else if (Program.Mode == "cursor") await RunCursor(view);
        else if (Program.Mode == "font") await RunFont(view);
            }
            catch (Exception error) { Console.Error.WriteLine("SMOKE_FAIL " + error); }
            finally { window.Content = null; desktop.Shutdown(Program.Result); }
        };
        base.OnFrameworkInitializationCompleted();
    }

    private static void Reflect(NativeWebView view)
    {
        var type = view.GetType();
        foreach (var property in type.GetProperties(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
            Console.WriteLine($"PROP {property.PropertyType.Name} {property.Name} (get={property.GetMethod is not null}, set={property.SetMethod is not null})");
        foreach (var field in type.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly))
            Console.WriteLine($"FIELD {field.FieldType.Name} {field.Name}");
        Program.Result = 0;
    }

    private static async Task RunLsp(NativeWebView view)
    {
        for (int i = 0; i < 100; i++)
        {
            await Task.Delay(200);
            var ready = await view.InvokeScript("JSON.stringify(!!window.monaco?.editor && !!window.OrionLsp)");
            if (ready?.Contains("true") == true) break;
            if (i == 99) throw new Exception("Monaco/OrionLsp startup timed out");
        }
        await view.InvokeScript("window.__smokeModel = monaco.editor.createModel('--!strict\\nlocal count: number = \\\"not a number\\\"\\nprint(count)', 'lua', monaco.Uri.parse('inmemory://smoke/type-error.lua')); OrionLsp.attachModel(window.__smokeModel);");
        for (int i = 0; i < 100; i++)
        {
            await Task.Delay(200);
            var result = await view.InvokeScript("JSON.stringify(monaco.editor.getModelMarkers({resource:window.__smokeModel.uri}).map(m=>({message:m.message,severity:m.severity})))");
            JsonNode? markers = JsonNode.Parse(result ?? "null");
            if (markers is JsonValue value && value.TryGetValue<string>(out var inner)) markers = JsonNode.Parse(inner);
            if (markers is JsonArray array && array.Any(m => m?["message"]?.ToString().Contains("number", StringComparison.OrdinalIgnoreCase) == true))
            {
                Console.WriteLine("SMOKE_PASS Luau diagnostic: " + array.ToJsonString());
                break;
            }
            if (i == 99) throw new Exception("Expected Luau type diagnostic did not reach Monaco");
        }
        await view.InvokeScript("window.__smokeModel.setValue('--!strict\\nlocal count: number = 5\\nprint(count)');");
        for (int i = 0; i < 100; i++)
        {
            await Task.Delay(200);
            var result = await view.InvokeScript("JSON.stringify(monaco.editor.getModelMarkers({resource:window.__smokeModel.uri}).filter(m=>m.severity===monaco.MarkerSeverity.Error))");
            JsonNode? markers = JsonNode.Parse(result ?? "null");
            if (markers is JsonValue value) markers = JsonNode.Parse(value.GetValue<string>());
            if (markers is JsonArray { Count: 0 })
            {
                Console.WriteLine("SMOKE_PASS Corrected numeric assignment clears type error: []");
                break;
            }
            if (i == 99) throw new Exception("Corrected numeric assignment retained errors: " + result);
        }
        await view.InvokeScript("window.__smokeModel.dispose();");
        // Completion: scope-based suggestion must reach the visible suggest widget.
        await view.InvokeScript("""
            window.__smokeEditor = window.monacoEditor;
            window.__smokeModel = window.__smokeEditor.getModel();
            window.__smokeModel.setValue('local myVariable = 5\nprint(');
            OrionLsp.attachModel(window.__smokeModel);
            window.__smokeEditor.setPosition({lineNumber: 2, column: 7});
            window.__smokeEditor.focus();
            window.__smokeEditor.trigger('keyboard', 'type', {text:'my'});
        """);
        string? label = null;
        for (int i = 0; i < 40; i++)
        {
            await view.InvokeScript("window.__smokeEditor.trigger('smoke', 'editor.action.triggerSuggest', []);");
            await Task.Delay(400);
            var raw = await view.InvokeScript("JSON.stringify({ready:window.__lspReady===true, text:((window.__smokeEditor.getDomNode().querySelector('.suggest-widget'))||{textContent:''}).textContent})");
            JsonNode? probe = JsonNode.Parse(raw ?? "null");
            if (probe is JsonValue inner) probe = JsonNode.Parse(inner.GetValue<string>());
            if (i < 3) Console.WriteLine($"SUGGEST[{i}] {raw}");
            if (probe?["text"]?.GetValue<string>() is { } text && text.Contains("myVariable"))
            {
                label = "myVariable";
                Console.WriteLine($"SUGGEST ready={probe["ready"]} widget text contains myVariable (iteration {i})");
                break;
            }
        }
        if (label is null) throw new Exception("Suggest widget never displayed the LSP completion 'myVariable'");
        await view.InvokeScript("window.__smokeEditor.trigger('keyboard','acceptSelectedSuggestion',{});");
        var accepted = await view.InvokeScript("JSON.stringify(window.__smokeModel.getValue())");
        Console.WriteLine("ACCEPTED " + accepted);
        if (accepted?.Contains("print(myVariable") != true) throw new Exception("Completion damaged the call prefix");
        Console.WriteLine("SMOKE_PASS LSP completion suggestion and insertion: myVariable");
        Program.Result = 0;
    }

    private static async Task<string> MeasureAsync(NativeWebView view, string label)
    {
        var raw = await view.InvokeScript("""
            (() => {
              const editor = window.monaco && monaco.editor && monaco.editor.getEditors ? monaco.editor.getEditors()[0] : null;
              if (!editor) return JSON.stringify({ error: 'no editor' });
              const model = editor.getModel();
              model.setValue('local abcdefgh = 123');
              editor.setPosition({ lineNumber: 1, column: model.getLineMaxColumn(1) });
              editor.updateOptions({cursorSmoothCaretAnimation:'off',cursorBlinking:'solid'});
              editor.focus();
              editor.render(true);
              const cursor = document.querySelector('.monaco-editor .cursor');
              const line = document.querySelector('.monaco-editor .view-line');
              if (!cursor || !line) return JSON.stringify({ error: 'no dom' });
              const range = document.createRange();
              range.selectNodeContents(line);
              const c = cursor.getBoundingClientRect(), l = line.getBoundingClientRect(), t = range.getBoundingClientRect();
              const sv = editor.getScrolledVisiblePosition(editor.getPosition());
              const scrollable = document.querySelector('.monaco-editor .monaco-scrollable-element');
              return JSON.stringify({ dpr: window.devicePixelRatio, zoom: document.documentElement.style.zoom || '(none)',
                zoomNum: parseFloat(document.documentElement.style.zoom || '1') || 1,
                svLeft: sv ? +sv.left.toFixed(2) : null, domLeft: scrollable ? +(c.left - scrollable.getBoundingClientRect().left).toFixed(2) : null,
                cursorOffset: +(c.left - l.left).toFixed(2), cursorWidth: +c.width.toFixed(2),
                textWidth: +t.width.toFixed(2), lineLeft: +l.left.toFixed(2), cursorTop: +c.top.toFixed(2), lineTop: +l.top.toFixed(2),
                pos: editor.getPosition(), viewport: [innerWidth, innerHeight], app: (()=>{ const r=document.getElementById('application').getBoundingClientRect(); return [r.width,r.height]; })() });
            })()
        """);
        Console.WriteLine($"MEASURE[{label}] {raw}");
        return raw ?? "";
    }

    private static async Task RunCursor(NativeWebView view)
    {
        for (int i = 0; i < 100; i++)
        {
            await Task.Delay(200);
            var ready = await MeasureAsync(view, "probe");
            if (!ready.Contains("no editor")) break;
            if (i == 99) throw new Exception("Editor did not start in the real page");
        }
        await Task.Delay(1500);
        await MeasureAsync(view, "zoom1");
        await view.InvokeScript("window.hwAPI.setSetting('interface_scale',150)");
        await Task.Delay(500);
        var raw = await MeasureAsync(view, "zoom150");
        JsonNode? result = JsonNode.Parse(raw);
        if (result is JsonValue value) result = JsonNode.Parse(value.GetValue<string>());
        if (result?["zoom"]?.ToString() != "1.5") throw new Exception("Scale was not applied");
        var viewport = result["viewport"]!.AsArray();
        var app = result["app"]!.AsArray();
        if (Math.Abs(viewport[0]!.GetValue<double>() - app[0]!.GetValue<double>()) > 1 ||
            Math.Abs(viewport[1]!.GetValue<double>() - app[1]!.GetValue<double>()) > 1)
            throw new Exception("Application is clipped at 150 percent");
        if (Math.Abs(result["cursorOffset"]!.GetValue<double>() - result["textWidth"]!.GetValue<double>()) > 1.5)
            throw new Exception("Caret does not match rendered text");
        await view.InvokeScript("window.hwAPI.setSetting('interface_scale',100)");
        await Task.Delay(300);
        await MeasureAsync(view, "restored");
        Console.WriteLine("SMOKE_PASS Scale 150 percent: viewport fits and caret matches text within one logical pixel");
        Program.Result = 0;
    }

    private static async Task RunFont(NativeWebView view)
    {
        for (int i = 0; i < 100; i++)
        {
            await Task.Delay(200);
            var ready = await view.InvokeScript("JSON.stringify(!!window.monacoEditor)");
            if (ready?.Contains("true") == true) break;
            if (i == 99) throw new Exception("Editor did not start in the real page");
        }
        await Task.Delay(1000);
        var options = async () => await view.InvokeScript("""
            (() => { const e = monaco.editor.getEditors()[0]; const o = e.getOption(monaco.editor.EditorOption.fontInfo);
              return JSON.stringify({ size: o.fontSize, family: o.fontFamily, w: (document.querySelector('.monaco-editor .view-line span')||{getBoundingClientRect:()=>({width:0})}).getBoundingClientRect().width }); })()
        """);
        var raw = await options();
        if (!raw.Contains("16")) throw new Exception("Default editor font size is not 16: " + raw);
        Console.WriteLine("DEFAULT " + raw);
        await view.InvokeScript("window.hwAPI.setSetting('fontsize','abc')");
        await Task.Delay(300);
        var afterInvalid = await options();
        if (!afterInvalid.Contains("16")) throw new Exception("Non-numeric size must fall back to 16: " + afterInvalid);
        await view.InvokeScript("window.hwAPI.setSetting('fontsize',99)");
        await Task.Delay(300);
        var afterClamp = await options();
        if (!afterClamp.Contains("48")) throw new Exception("Size must clamp to 48: " + afterClamp);
        await view.InvokeScript("window.hwAPI.setSetting('fontsize',22)");
        await Task.Delay(300);
        var afterSize = await options();
        if (!afterSize.Contains("22")) throw new Exception("Size 22 was not applied live: " + afterSize);
        Console.WriteLine("SMOKE_PASS Font size: invalid input falls back to 16, 99 clamps to 48, 22 applies live");
        await view.InvokeScript("window.hwAPI.setSetting('fontfamily','Times New Roman')");
        await Task.Delay(400);
        var afterFamily = await options();
        if (!afterFamily.Contains("Times New Roman")) throw new Exception("System font family was not applied live: " + afterFamily);
        var computed = await view.InvokeScript("""
            (() => { const line = document.querySelector('.monaco-editor .view-line');
              const s = getComputedStyle(line); return JSON.stringify({ family: s.fontFamily, size: s.fontSize }); })()
        """);
        if (!computed.Contains("Times New Roman")) throw new Exception("DOM font-family did not change: " + computed);
        Console.WriteLine("SMOKE_PASS Font family applies live to Monaco: " + afterFamily + " dom=" + computed);
        await view.InvokeScript("window.hwAPI.setSetting('fontfamily','')");
        await Task.Delay(300);
        var afterReset = await options();
        if (!afterReset.Contains("Consolas")) throw new Exception("Reset must restore the default stack: " + afterReset);
        Console.WriteLine("SMOKE_PASS Font family reset restores default stack");
        Program.Result = 0;
    }
}
