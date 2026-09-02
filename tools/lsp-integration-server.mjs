// Integration test server: serves MonacoPreview statically and implements the
// same /lsp endpoints as MonacoStaticServer's LuauLspBridge, backed by the real
// luau-lsp.exe. Lets the browser test exercise the real lsp-client.js stack.
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";

const ROOT = "D:/Cheats/Orion";
const STATIC_ROOT = path.join(ROOT, "bin/Debug/net8.0-windows/win-x64/MonacoPreview");
const PORT = 18099;

// ------------------------------------------------------------------ LSP host
const proc = spawn(`${ROOT}/luau-lsp.exe`, [
    "lsp", "--stdio",
    `--definitions=${ROOT}/luau/globalTypes.d.luau`,
    `--definitions=${ROOT}/luau/sunc.d.luau`,
], { stdio: ["pipe", "pipe", "pipe"] });

let buf = Buffer.alloc(0);
const pending = new Map();
let nextId = 1;
let nextOutgoingId = 0;
const notificationLog = [];
const waiters = [];

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
            resolve(body);
        } else if (body.id === undefined) {
            body.__seq = ++nextOutgoingId;
            notificationLog.push(body);
            if (notificationLog.length > 400) notificationLog.shift();
            waiters.splice(0).forEach((w) => w());
        }
    }
});
proc.stderr.on("data", (c) => process.stderr.write("[lsp] " + c.toString()));

function writeFrame(obj) {
    const body = JSON.stringify(obj);
    proc.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
}
function request(method, params) {
    const id = nextId++;
    return new Promise((resolve) => {
        pending.set(id, { resolve });
        setTimeout(() => { if (pending.has(id)) { pending.delete(id); resolve({ error: "timeout" }); } }, 15000);
        writeFrame({ jsonrpc: "2.0", id, method, params });
    });
}

const workspace = "C:/orion-test";
await request("initialize", {
    processId: null,
    rootUri: "file:///" + workspace,
    capabilities: { textDocument: { completion: { completionItem: { snippetSupport: true, documentationFormat: ["markdown"] } } } },
});
writeFrame({ jsonrpc: "2.0", method: "initialized", params: {} });
console.log("LSP initialized");

// ------------------------------------------------------------------ HTTP
const MIME = {
    ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
    ".json": "application/json", ".png": "image/png", ".svg": "image/svg+xml",
    ".woff": "font/woff", ".woff2": "font/woff2", ".ttf": "font/ttf", ".map": "application/json",
};

const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, `http://127.0.0.1:${PORT}`);

    if (req.method === "POST" && url.pathname === "/lsp") {
        let raw = "";
        for await (const chunk of req) raw += chunk;
        try {
            const { method, params } = JSON.parse(raw);
            // LSP notifications (didOpen/didChange/...) must go out without an
            // id; luau-lsp never replies to them.
            const NOTIFICATIONS = new Set(["initialized", "exit", "textDocument/didOpen", "textDocument/didChange", "textDocument/didClose", "textDocument/didSave", "$/cancelRequest"]);
            if (NOTIFICATIONS.has(method)) {
                writeFrame({ jsonrpc: "2.0", method, params });
                res.writeHead(200, { "Content-Type": "application/json" });
                res.end("{}");
            } else {
                const response = await request(method, params);
                res.writeHead(200, { "Content-Type": "application/json" });
                res.end(JSON.stringify(response.result ?? {}));
            }
        } catch (e) {
            res.writeHead(502, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ error: String(e.message || e) }));
        }
        return;
    }

    if (req.method === "GET" && url.pathname === "/lsp/notifications") {
        const seen = parseInt(url.searchParams.get("seen") || "0", 10);
        const send = () => {
            const items = notificationLog.filter((n) => n.__seq > seen);
            res.writeHead(200, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ notifications: items, cursor: nextOutgoingId }));
        };
        if (nextOutgoingId > seen) { send(); }
        else { waiters.push(send); setTimeout(() => { const i = waiters.indexOf(send); if (i >= 0) { waiters.splice(i, 1); res.writeHead(200, { "Content-Type": "application/json" }); res.end(JSON.stringify({ notifications: [], cursor: nextOutgoingId })); } }, 25000); }
        return;
    }

    // Static files
    let filePath = path.join(STATIC_ROOT, decodeURIComponent(url.pathname));
    if (url.pathname.endsWith("/")) filePath = path.join(filePath, "index.html");
    if (!filePath.startsWith(STATIC_ROOT) || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        res.writeHead(404); res.end("not found"); return;
    }
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { "Content-Type": MIME[ext] || "application/octet-stream" });
    fs.createReadStream(filePath).pipe(res);
});

server.listen(PORT, "127.0.0.1", () => console.log(`TEST SERVER: http://127.0.0.1:${PORT}/index.html`));
