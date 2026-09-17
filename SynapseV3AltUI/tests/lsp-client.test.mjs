import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../../MonacoPreview/lsp-client.js', import.meta.url), 'utf8');

async function complete(line, word, items) {
  const providers = [];
  const model = {
    id: 'test', getValue: () => line,
    onDidChangeContent() {}, onWillDispose() {},
    getWordUntilPosition: () => ({ word, startColumn: line.length - word.length + 1, endColumn: line.length + 1 })
  };
  const monaco = {
    editor: { getModels: () => [model] },
    languages: {
      CompletionItemInsertTextRule: { InsertAsSnippet: 4 }, CompletionItemKind: { Variable: 4, Text: 0 },
      registerCompletionItemProvider: (_, provider) => providers.push(provider),
      registerHoverProvider() {}, registerSignatureHelpProvider() {}
    }
  };
  const context = vm.createContext({
    window: { monaco }, monaco, setInterval() {}, setTimeout, clearTimeout,
    fetch: async (url, options) => url.startsWith('/lsp/notifications') ? new Promise(() => {}) : {
      ok: true, json: async () => JSON.parse(options.body).method === 'textDocument/completion' ? items : null
    }
  });
  vm.runInContext(source, context);
  await new Promise(resolve => setTimeout(resolve, 0));
  return providers[0].provideCompletionItems(model, { lineNumber: 1, column: line.length + 1 });
}

for (const [line, word] of [['print(my', 'my'], ['local x = my', 'my'], ['game.Wor', 'Wor'], ['game:GetS', 'GetS']]) {
  test(`completion only replaces the current word in ${line}`, async () => {
    const { suggestions } = await complete(line, word, [{ label: 'replacement', kind: 6 }]);
    const range = suggestions[0].range;
    assert.equal(range.startColumn, line.length - word.length + 1);
    assert.equal(range.endColumn, line.length + 1);
    assert.equal(line.slice(0, range.startColumn - 1) + suggestions[0].insertText, line.slice(0, -word.length) + 'replacement');
  });
}
test('completion candidates beyond index 200 remain available to Monaco filtering', async () => {
  const items = Array.from({ length: 205 }, (_, i) => ({ label: `other${i}`, kind: 6 }));
  items.push({ label: 'myVariable', kind: 6 });
  const { suggestions } = await complete('print(my', 'my', items);
  assert.equal(suggestions.length, 206);
  assert.ok(suggestions.some(item => item.label === 'myVariable'));
});
