import { hydrate, assetURL, reportError } from './bridge';
import './localIcons';
async function loadScript(path) {
  await new Promise((resolve, reject) => {
    const script = document.createElement('script'); script.src = assetURL(path);
    script.onload = resolve; script.onerror = () => reject(new Error(`Unable to load ${path}`)); document.head.append(script);
  });
}
async function start() {
  const state = await hydrate();
  await loadScript('vs/loader.js');
  window.require.config({ paths: { vs: assetURL('vs') } });
  await new Promise((resolve, reject) => window.require(['vs/editor/editor.main'], resolve, reject));
  const lspEnabled = state.settings?.lua_language_server !== false && state.settings?.lua_language_server !== 'false';
  window.OrionLspConfig = { language: 'lua', extension: 'lua' };
  if (lspEnabled) await loadScript('lsp-client.js');
  window.hwAPI.onSettingsChanged(async change => {
    if (change.key !== 'lua_language_server') return;
    const enabled = change.value !== false && change.value !== 'false';
    if (enabled === lspEnabled) return;
    const snapshot = window.synapseAltSnapshot();
    const saved = await window.hwAPI.saveWorkspace(snapshot.workspace);
    if (saved === true) window.location.reload();
  });
  await import('./main.jsx');
}
start().catch(error => { reportError(error); document.getElementById('root').textContent = 'Unable to initialize the local UI. Reload after checking the native bridge and local assets.'; });
