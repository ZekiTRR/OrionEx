// Smoke test: drives luau-lsp.exe over stdio and checks completions/hover/diagnostics.
import { spawn } from "node:child_process";

const ROOT = "D:/Cheats/Orion";
const proc = spawn(`${ROOT}/luau-lsp.exe`, [
  "lsp", "--stdio",
  `--definitions=${ROOT}/luau/globalTypes.d.luau`,
  `--definitions=${ROOT}/luau/sunc.d.luau`,
], { stdio: ["pipe", "pipe", "pipe"] });

let buf = Buffer.alloc(0);
const pending = new Map();
let nextId = 1;
const notifications = [];

proc.stdout.on("data", (chunk) => {
  buf = Buffer.concat([buf, chunk]);
  while (true) {
    const headerEnd = buf.indexOf("\r\n\r\n");
    if (headerEnd < 0) return;
    const header = buf.slice(0, headerEnd).toString();
    const m = /Content-Length: (\d+)/i.exec(header);
    if (!m) { buf = buf.slice(headerEnd + 4); continue; }
    const len = parseInt(m[1], 10);
    if (buf.length < headerEnd + 4 + len) return;
    const body = JSON.parse(buf.slice(headerEnd + 4, headerEnd + 4 + len).toString());
    buf = buf.slice(headerEnd + 4 + len);
    if (body.id !== undefined && pending.has(body.id)) {
      const { resolve } = pending.get(body.id);
      pending.delete(body.id);
      resolve(body.result);
    } else if (body.id === undefined) {
      notifications.push(body);
    }
  }
});
proc.stderr.on("data", (c) => process.stderr.write("[lsp-err] " + c.toString()));

function request(method, params) {
  const id = nextId++;
  return new Promise((resolve, reject) => {
    pending.set(id, { resolve });
    setTimeout(() => { if (pending.has(id)) { pending.delete(id); reject(new Error(`timeout: ${method}`)); } }, 30000);
    const body = JSON.stringify({ jsonrpc: "2.0", id, method, params });
    proc.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
  });
}
function notify(method, params) {
  const body = JSON.stringify({ jsonrpc: "2.0", method, params });
  proc.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function main() {
  const init = await request("initialize", {
    processId: null,
    rootUri: "file:///C:/orion-test",
    capabilities: {
      textDocument: {
        completion: { completionItem: { snippetSupport: true, documentationFormat: ["markdown", "plaintext"] } },
        hover: { contentFormat: ["markdown", "plaintext"] },
        signatureHelp: { signatureInformation: { documentationFormat: ["markdown", "plaintext"] } },
      },
    },
  });
  console.log("INIT serverName:", init?.serverInfo?.name, "version:", init?.serverInfo?.version);
  notify("initialized", {});

  const uri = "file:///C:/orion-test/test.luau";
  notify("textDocument/didOpen", {
    textDocument: {
      uri, languageId: "luau", version: 1,
      text: 'local Players = game:GetService("Players")\nlocal env = getgenv()\nlocal x = )\nlocal g = get\n',
    },
  });

  // Completion after "game:" on line 1 (LSP position: line 0, character 42 = after "game:")
  const line1 = 'local Players = game:';
  const comp1 = await request("textDocument/completion", {
    textDocument: { uri },
    position: { line: 0, character: line1.length },
    context: { triggerKind: 2, triggerCharacter: ":" },
  });
  const items1 = Array.isArray(comp1) ? comp1 : comp1?.items ?? [];
  const getService = items1.filter((i) => /GetService/i.test(i.label)).map((i) => i.label);
  console.log(`COMPLETION game: -> ${items1.length} items; GetService present:`, getService.length > 0 ? getService : "NO");

  // Completion for sUNC globals: line 3 is `local g = get`, prefix "get"
  const comp2 = await request("textDocument/completion", {
    textDocument: { uri },
    position: { line: 3, character: 12 },
    context: { triggerKind: 1 },
  });
  const items2 = Array.isArray(comp2) ? comp2 : comp2?.items ?? [];
  const suncItems = items2.filter((i) => /^(getgenv|getgc|getreg|getrenv|filtergc|getrawmetatable|loadstring|isexecutorclosure)$/.test(i.label));
  console.log(`COMPLETION "get" -> ${items2.length} items; sUNC fns:`, suncItems.map((i) => i.label).join(",") || "NO");

  // Hover on getgenv (line 1, "local env = getgenv()", character 16 inside the name)
  const hover = await request("textDocument/hover", { textDocument: { uri }, position: { line: 1, character: 16 } });
  const hoverText = hover?.contents?.value ?? "";
  console.log("HOVER getgenv:", JSON.stringify(hoverText.slice(0, 120)));

  // Wait for diagnostics
  await sleep(3000);
  const diags = notifications.filter((n) => n.method === "textDocument/publishDiagnostics");
  const all = diags.flatMap((d) => d.params.diagnostics);
  console.log(`DIAGNOSTICS: ${all.length}`, all.slice(0, 3).map((d) => `${d.range.start.line}:${d.range.start.character} ${d.message.slice(0, 60)}`));

  proc.kill();
  const failed = !getService.length || !suncItems.length || hoverText === "" || !all.length;
  console.log(failed ? "SMOKE TEST: FAIL" : "SMOKE TEST: PASS");
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error("FATAL:", e); proc.kill(); process.exit(1); });
