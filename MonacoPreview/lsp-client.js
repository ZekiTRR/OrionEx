// Orion Luau LSP client.
//
// Bridges the Monaco editor page to luau-lsp.exe through two same-origin HTTP
// endpoints served by MonacoStaticServer:
//   POST /lsp                 -> one LSP request/response round-trip
//   GET  /lsp/notifications   -> long-poll batch of server notifications
//
// The page configures the client before this file loads:
//   window.OrionLspConfig = { language: "lua" | "luau", extension: "lua" };
//
// Behaviour:
//   * Every Monaco model on the page gets its own LSP document URI
//     (file:///orion-<session>/doc-N.<ext>), so multiple windows never mix
//     diagnostics. didOpen/didChange (full text, debounced)/didClose are sent
//     automatically as models appear, change and disappear.
//   * Registers completion / hover / signatureHelp providers on the configured
//     language, backed by the language server.
//   * publishDiagnostics notifications become Monaco markers.
//   * window.__lspReady flips on/off with LSP health; the page's static
//     fallback completion provider serves the user while the flag is off.

(function () {
    "use strict";

    var config = window.OrionLspConfig || {};
    var LANGUAGE = config.language || "lua";
    var EXTENSION = config.extension || "lua";

    var SESSION_ID = Math.random().toString(36).slice(2) + Date.now().toString(36);

    var docCounter = 0;
    // uri -> { model, uri, version, debounce, kindMapReady }
    var documents = new Map();
    // model.id -> uri, for change/dispose hooks
    var modelUris = new Map();

    var lspReady = false;
    var notificationCursor = 0;

    function setReady(value) {
        if (lspReady !== value) {
            lspReady = value;
            window.__lspReady = value;
        }
    }

    function sleep(ms) {
        return new Promise(function (resolve) { setTimeout(resolve, ms); });
    }

    // ------------------------------------------------------------------ LSP I/O

    function lspRequest(method, params) {
        return fetch("/lsp", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ method: method, params: params || {} })
        }).then(function (response) {
            if (!response.ok) {
                return response.json().catch(function () { return null; }).then(function (err) {
                    throw new Error((err && err.error) || ("LSP request failed: HTTP " + response.status));
                });
            }
            return response.json();
        });
    }

    function lspNotify(method, params) {
        // Notifications share the request endpoint; the bridge forwards them
        // without waiting for a response.
        return lspRequest(method, params).catch(function () { /* fire-and-forget */ });
    }

    // ------------------------------------------------------------- documents

    function documentUri(model) {
        var existing = modelUris.get(model.id);
        if (existing) return existing;
        docCounter += 1;
        var uri = "file:///orion-" + SESSION_ID + "/doc-" + docCounter + "." + EXTENSION;
        modelUris.set(model.id, uri);
        return uri;
    }

    function attachModel(model) {
        if (!model || modelUris.get(model.id)) return;
        var uri = documentUri(model);
        var doc = {
            model: model,
            uri: uri,
            version: 1,
            debounce: null,
            opened: false
        };
        documents.set(uri, doc);

        model.onDidChangeContent(function () {
            // Full-text sync with a short debounce; plenty for script-sized docs.
            if (doc.debounce) clearTimeout(doc.debounce);
            doc.debounce = setTimeout(function () { pushChange(doc); }, 250);
        });
        model.onWillDispose(function () {
            documents.delete(uri);
            modelUris.delete(model.id);
            lspNotify("textDocument/didClose", { textDocument: { uri: uri } });
        });

        pushOpen(doc);
    }

    function pushOpen(doc) {
        doc.version += 1;
        lspNotify("textDocument/didOpen", {
            textDocument: {
                uri: doc.uri,
                languageId: LANGUAGE,
                version: doc.version,
                text: doc.model.getValue()
            }
        }).then(function () { doc.opened = true; setReady(true); }, function () { setReady(false); });
    }

    function pushChange(doc) {
        if (!doc.opened) return Promise.resolve();
        doc.version += 1;
        return lspNotify("textDocument/didChange", {
            textDocument: { uri: doc.uri, version: doc.version },
            contentChanges: [{ text: doc.model.getValue() }]
        });
    }

    // Sends a pending debounced didChange immediately. Completion/hover/
    // signature providers await this so the server always analyses the exact
    // text the user sees before answering.
    function flushDocument(doc) {
        if (!doc) return Promise.resolve();
        if (doc.debounce) {
            clearTimeout(doc.debounce);
            doc.debounce = null;
            return pushChange(doc);
        }
        return Promise.resolve();
    }

    // -------------------------------------------------------- Monaco mapping

    // luau-lsp snippets include the implicit "self" parameter for methods
    // (e.g. `GetService(${1:self}, ${2:className})`); method calls in Luau
    // style are written with `:` and self is implicit, so drop it.
    function stripSelfFromSnippet(insertText) {
        if (typeof insertText !== "string") return insertText;
        return insertText
            .replace(/\(\$\{1:self\},\s*/g, "(${1:")
            .replace(/\(\$\{1:self\}\)/g, "()");
    }

    function toMonacoRange(range, model, position, fallback) {
        if (range && range.start && typeof range.start.line === "number") {
            return {
                startLineNumber: range.start.line + 1,
                startColumn: range.start.character + 1,
                endLineNumber: range.end.line + 1,
                endColumn: range.end.character + 1
            };
        }
        if (fallback) return fallback;
        var word = model.getWordUntilPosition(position);
        return {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: word.startColumn,
            endColumn: word.endColumn
        };
    }

    // Replacement range covering only the text after the last `:`/`.` on the
    // line, so accepting `Workspace` after `game.Wor` keeps the `game.` prefix.
    function tailRange(model, position) {
        var before = model.getValueInRange({
            startLineNumber: position.lineNumber, startColumn: 1,
            endLineNumber: position.lineNumber, endColumn: position.column
        });
        var idx = Math.max(before.lastIndexOf(":"), before.lastIndexOf("."));
        var tailLength = before.length - idx - 1;
        return {
            startLineNumber: position.lineNumber,
            endLineNumber: position.lineNumber,
            startColumn: position.column - tailLength,
            endColumn: position.column
        };
    }

    function toMonacoKind(kind) {
        var K = monaco.languages.CompletionItemKind;
        var map = {};
        map[1] = K.Text; map[2] = K.Method; map[3] = K.Function; map[4] = K.Constructor;
        map[5] = K.Field; map[6] = K.Variable; map[7] = K.Class; map[8] = K.Interface;
        map[9] = K.Module; map[10] = K.Property; map[11] = K.Unit; map[12] = K.Value;
        map[13] = K.Enum; map[14] = K.Keyword; map[15] = K.Snippet; map[16] = K.Color;
        map[17] = K.File; map[18] = K.Reference; map[19] = K.Folder; map[20] = K.EnumMember;
        map[21] = K.Constant; map[22] = K.Struct; map[23] = K.Event; map[24] = K.Operator;
        map[25] = K.TypeParameter;
        return map[kind] || K.Text;
    }

    function toDocumentation(documentation) {
        if (!documentation) return null;
        if (typeof documentation === "string") return documentation;
        if (documentation.value) return documentation.value;
        return null;
    }

    function positionToLsp(position) {
        return { line: position.lineNumber - 1, character: position.column - 1 };
    }

    function registerProviders() {
        var SnippetRule = monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet;

        monaco.languages.registerCompletionItemProvider(LANGUAGE, {
            triggerCharacters: [".", ":", "(", '"'],
            provideCompletionItems: function (model, position) {
                if (!lspReady) return { suggestions: [] };
                var uri = modelUris.get(model.id);
                if (!uri) return { suggestions: [] };
                var doc = documents.get(uri);
                var synced = flushDocument(doc);

                var fallbackRange = tailRange(model, position);

                return synced.then(function () {
                return lspRequest("textDocument/completion", {
                    textDocument: { uri: uri },
                    position: positionToLsp(position),
                    context: { triggerKind: 1 }
                }).then(function (result) {
                    setReady(true);
                    var items = Array.isArray(result) ? result : (result && result.items) || [];
                    var suggestions = [];
                    for (var i = 0; i < items.length && suggestions.length < 200; i++) {
                        var item = items[i];
                        var label = typeof item.label === "string" ? item.label : (item.label && item.label.label) || "";
                        if (!label) continue;

                        var isSnippet = item.insertTextFormat === 2;
                        var insertText = item.textEdit
                            ? (typeof item.textEdit.newText === "string"
                                ? item.textEdit.newText
                                : (item.textEdit.textEdit && item.textEdit.textEdit.newText) || item.insertText || label)
                            : item.insertText || label;
                        if (isSnippet) insertText = stripSelfFromSnippet(insertText);

                        suggestions.push({
                            label: label,
                            kind: toMonacoKind(item.kind),
                            detail: item.detail || undefined,
                            documentation: toDocumentation(item.documentation) || undefined,
                            sortText: item.sortText || undefined,
                            filterText: item.filterText || undefined,
                            insertText: insertText,
                            insertTextRules: isSnippet ? SnippetRule : undefined,
                            range: toMonacoRange(
                                item.textEdit ? (item.textEdit.range || (item.textEdit.insert && {
                                    start: item.textEdit.insert,
                                    end: item.textEdit.replace
                                })) : null,
                                model, position,
                                toMonacoRange(null, model, position, fallbackRange))
                        });
                    }
                    return { suggestions: suggestions };
                }, function () {
                    setReady(false);
                    return { suggestions: [] };
                });
                });
            }
        });

        monaco.languages.registerHoverProvider(LANGUAGE, {
            provideHover: function (model, position) {
                if (!lspReady) return null;
                var uri = modelUris.get(model.id);
                if (!uri) return null;
                return flushDocument(documents.get(uri)).then(function () {
                return lspRequest("textDocument/hover", {
                    textDocument: { uri: uri },
                    position: positionToLsp(position)
                }).then(function (hover) {
                    if (!hover || !hover.contents) return null;
                    var contents = hover.contents;
                    if (typeof contents === "string") {
                        return { contents: [{ value: contents }] };
                    }
                    if (contents.value !== undefined) {
                        return { contents: [{ value: contents.value }] };
                    }
                    var parts = (contents || []).map(function (part) {
                        return { value: typeof part === "string" ? part : part.value || "" };
                    }).filter(function (part) { return part.value; });
                    return parts.length ? { contents: parts } : null;
                }, function () { return null; });
                });
            }
        });

        monaco.languages.registerSignatureHelpProvider(LANGUAGE, {
            signatureHelpTriggerCharacters: ["(", ","],
            provideSignatureHelp: function (model, position) {
                if (!lspReady) return null;
                var uri = modelUris.get(model.id);
                if (!uri) return null;
                return flushDocument(documents.get(uri)).then(function () {
                return lspRequest("textDocument/signatureHelp", {
                    textDocument: { uri: uri },
                    position: positionToLsp(position)
                }).then(function (help) {
                    if (!help || !help.signatures || !help.signatures.length) return null;
                    return {
                        value: {
                            activeSignature: help.activeSignature || 0,
                            activeParameter: help.activeParameter || 0,
                            signatures: help.signatures.map(function (signature) {
                                var parameters = (signature.parameters || []).map(function (parameter) {
                                    if (Array.isArray(parameter.label)) {
                                        return { label: [parameter.label[0], parameter.label[1]] };
                                    }
                                    var text = typeof parameter.label === "string" ? parameter.label : "";
                                    var index = text ? signature.label.indexOf(text) : -1;
                                    return { label: [index >= 0 ? index : 0, index >= 0 ? index + text.length : 0] };
                                });
                                return {
                                    label: signature.label,
                                    documentation: toDocumentation(signature.documentation) || undefined,
                                    parameters: parameters
                                };
                            })
                        },
                        dispose: function () { }
                    };
                }, function () { return null; });
                });
            }
        });
    }

    // ------------------------------------------------------------ diagnostics

    var MarkerSeverity = null;

    function handleNotification(notification) {
        if (notification.method !== "textDocument/publishDiagnostics") return;
        var params = notification.params || {};
        var uri = params.uri;
        var doc = documents.get(uri);
        window.__orionLspDebug && window.__orionLspDebug.log.push({ event: "diag", uri: uri, known: !!doc, count: (params.diagnostics || []).length });
        if (!doc) return;

        MarkerSeverity = MarkerSeverity || monaco.MarkerSeverity;
        var severityMap = {};
        severityMap[1] = MarkerSeverity.Error;
        severityMap[2] = MarkerSeverity.Warning;
        severityMap[3] = MarkerSeverity.Info;
        severityMap[4] = MarkerSeverity.Info;

        var markers = (params.diagnostics || []).map(function (diagnostic) {
            var range = diagnostic.range || { start: { line: 0, character: 0 }, end: { line: 0, character: 0 } };
            return {
                startLineNumber: range.start.line + 1,
                startColumn: range.start.character + 1,
                endLineNumber: range.end.line + 1,
                endColumn: range.end.character + 1,
                message: diagnostic.message || "",
                severity: severityMap[diagnostic.severity] || MarkerSeverity.Error,
                source: diagnostic.source || "luau-lsp",
                code: diagnostic.code || undefined
            };
        });
        monaco.editor.setModelMarkers(doc.model, "luau-lsp", markers);
    }

    function pollLoop() {
        var stopped = false;
        function step() {
            if (stopped) return;
            window.__orionLspDebug && window.__orionLspDebug.log.push({ event: "pollStart", seen: notificationCursor });
            fetch("/lsp/notifications?seen=" + notificationCursor)
                .then(function (response) { return response.ok ? response.json() : null; })
                .then(function (data) {
                    if (!data) { return sleep(3000); }
                    notificationCursor = data.cursor || notificationCursor;
                    window.__orionLspDebug && window.__orionLspDebug.log.push({ event: "poll", cursor: notificationCursor, batch: (data.notifications || []).length });
                    (data.notifications || []).forEach(handleNotification);
                })
                .catch(function (e) {
                    window.__orionLspDebug && window.__orionLspDebug.log.push({ event: "pollError", error: String(e) });
                    return sleep(3000);
                })
                .then(step);
        }
        step();
        return function stop() { stopped = true; };
    }

    // ------------------------------------------------------------------ boot

    function waitForMonaco(attempt) {
        attempt = attempt || 0;
        if (window.monaco && window.monaco.editor && window.monaco.languages) {
            start();
            return;
        }
        if (attempt > 600) return; // ~60s, give up
        setTimeout(function () { waitForMonaco(attempt + 1); }, 100);
    }

    // Reconcile the document registry with the current model list. Some
    // Monaco builds (including the bundled 0.42 dev build) do not expose
    // monaco.editor.onDidChangeModels, so poll instead — this also covers the
    // tabbed SirHurtV5 editor, which creates one Monaco model per tab.
    function syncModels() {
        var alive = new Set(monaco.editor.getModels().map(function (model) { return model.id; }));
        modelUris.forEach(function (uri, modelId) {
            if (!alive.has(modelId)) {
                documents.delete(uri);
                modelUris.delete(modelId);
                lspNotify("textDocument/didClose", { textDocument: { uri: uri } });
            }
        });
        monaco.editor.getModels().forEach(attachModel);
    }

    function start() {
        window.__orionLspDebug = { log: [], cursor: function () { return notificationCursor; }, docs: function () { return [...modelUris.values()]; } };
        registerProviders();

        // Attach every model that exists now or appears later.
        syncModels();
        setInterval(syncModels, 1500);

        pollLoop();
    }

    window.OrionLsp = {
        attachModel: attachModel
    };

    waitForMonaco();
})();
