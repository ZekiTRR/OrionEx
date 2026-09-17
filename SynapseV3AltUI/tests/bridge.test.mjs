import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
class MemoryStorage {
  get length() { return Object.keys(this).length; }
  key(index) { return Object.keys(this)[index] ?? null; }
  getItem(key) { return this[key] ?? null; }
  setItem(key, value) { this[key] = String(value); }
  removeItem(key) { delete this[key]; }
  clear() { for (const key of Object.keys(this)) delete this[key]; }
}
globalThis.Storage = MemoryStorage;
globalThis.localStorage = new MemoryStorage();
const messages = [], errors = [];
const guid = '9682db70-d7d1-4a7e-a9aa-0c49c29d5482';
const workspace = { tabs: [{id:guid,title:'Orion tab',content:'-- text only',savedValue:'',filePath:null,extension:'.lua'}],activeTabId:guid };
globalThis.window = {
  addEventListener() {},
  HWToast: { error: value => errors.push(value) },
  invokeCSharpAction(json) {
    const message = JSON.parse(json); messages.push(message);
    const result = message.method === 'getBootstrap' ? {settings:{fontsize:19},storage:{synapse_sidebar_width:'320'},workspace,windowState:{isMaximized:true},externalClient:false} : message.method === 'saveScript' ? {ok:false,error:'Denied'} : true;
    queueMicrotask(() => window.synapseAltResolve(message.id, result, null));
  }
};
const bridge = await import('../src/bridge.js');

test('hydration precedes React and preserves host GUID/workspace', async () => {
  localStorage.setItem('synapse_tabs','stale');
  await bridge.hydrate();
  assert.deepEqual(JSON.parse(localStorage.getItem('synapse_tabs')), workspace.tabs);
  assert.equal(localStorage.getItem('synapse_active_tab'),guid);
  assert.equal(localStorage.getItem('synapse_setting_fontsize'),'19');
  assert.equal(localStorage.getItem('synapse_sidebar_width'),'320');
  assert.equal(window.hwAPI.isMaximized(),true);
  assert.deepEqual(messages[0],{synapseAlt:1,id:'ui-1',method:'getBootstrap',args:[]});
});
test('workspace snapshot and save retain exact positional shape', async () => {
  bridge.setWorkspaceReader(() => workspace);
  assert.deepEqual(window.synapseAltSnapshot().workspace,workspace);
  await bridge.saveWorkspace(workspace);
  const sent=messages.findLast(m=>m.method==='saveWorkspace');
  assert.deepEqual(sent.args,[workspace]);
});
test('settings event refresh and window state cache are synchronous', async () => {
  let changed;
  const dispose=window.hwAPI.onSettingsChanged(value=>changed=value);
  await window.hwAPI.setSetting('bookmarks',[{name:'Example',uri:'https://example.invalid'}]);
  assert.equal(changed.key,'bookmarks');
  assert.equal((await window.hwAPI.getSetting('bookmarks',[])).length,1);
  dispose();
  window.synapseAltEvent('windowState',{isMaximized:false});
  assert.equal(window.hwAPI.isMaximized(),false);
});
test('execution never reaches native transport and reports visible failure', async () => {
  const count=messages.length;
  const result=await window.hwAPI.execute('untrusted code');
  assert.equal(result.ok,false);
  assert.match(result.error,/unsupported.*UI-only/);
  assert.equal(messages.length,count);
  assert.equal(errors.at(-1),result.error);
  assert.equal(window.hwAPI.isConnected(),false);
});
test('save failure is not reported as success', async () => {
  assert.equal((await window.hwAPI.saveScript('a.lua','text')).ok,false);
  const source=fs.readFileSync(path.join(root,'src/context/EditorContext.jsx'),'utf8');
  assert.match(source,/if \(!wrote\)/);
  assert.match(source,/res\?\.ok === true/);
});
test('WebView2 fallback also transports serialized JSON', async () => {
  const original=window.invokeCSharpAction;
  delete window.invokeCSharpAction;
  window.chrome={webview:{postMessage:original}};
  await bridge.request('minimize');
  assert.equal(messages.at(-1).method,'minimize');
  window.invokeCSharpAction=original;
});
test('native errors reject raw RPC while safe methods preserve failure', async () => {
  const original=window.invokeCSharpAction;
  window.invokeCSharpAction=json=>{const m=JSON.parse(json);queueMicrotask(()=>window.synapseAltResolve(m.id,null,'Host denied'));};
  await assert.rejects(bridge.request('readScript','missing.lua'),/Host denied/);
  assert.equal(await window.hwAPI.readScript('missing.lua'),null);
  window.invokeCSharpAction=original;
});
test('extra local storage writes persist via saveStorage', async () => {
  localStorage.setItem('synapse_folder_accents','{"folder":"red"}');
  await new Promise(resolve=>setTimeout(resolve,450));
  assert.equal(messages.findLast(m=>m.method==='saveStorage').args[0].synapse_folder_accents,'{"folder":"red"}');
});
test('all bundled themes and local Monaco artifacts exist', () => {
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'dist/themes/manifest.json')));
  assert.equal(manifest.length,20);
  assert.equal(new Set(manifest.map(m=>m.id)).size,20);
  for (const theme of manifest) {
    assert.ok(theme.cssContent.length>0);
    assert.doesNotMatch(theme.cssContent,/(?:url\(['"]?https?:|@import[^;]*https?:)/);
    for (const [,url] of theme.cssContent.matchAll(/url\(['"]?((?:assets|themes)\/[^)'"?#]+)/g)) assert.ok(fs.existsSync(path.join(root,'dist',url)),`${theme.id}: ${url}`);
  }
  for (const name of ['vs/loader.js','vs/editor/editor.main.js','lsp-client.js','console/index.html']) assert.ok(fs.existsSync(path.join(root,'dist',name)));
  assert.equal(fs.readFileSync(path.join(root,'dist/lsp-client.js'),'utf8'),fs.readFileSync(path.join(root,'../MonacoPreview/lsp-client.js'),'utf8'));
});
test('bootstrap and source contain no Synapse LSP/network execution path', () => {
  const source=fs.readFileSync(path.join(root,'src/bootstrap.js'),'utf8');
  assert.ok(source.indexOf('await hydrate()') < source.indexOf("import('./main.jsx')"));
  assert.equal(fs.existsSync(path.join(root,'src/services/lspService.js')),false);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'src/components/editor/MonacoView.jsx'),'utf8'),/lspService|https:\/\/cdn/);
});
