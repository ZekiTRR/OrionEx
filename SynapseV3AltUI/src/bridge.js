// Native UI-only protocol. args is always a positional array; script content is never executed.
const pending = new Map();
const listeners = new Map();
let sequence = 0;
let bootstrap = { settings: {}, storage: {}, workspace: { tabs: [], activeTabId: null } };
let windowState = { isMaximized: false };
let workspaceReader = () => bootstrap.workspace;
let hydrated = false;
const consolePage = /\/console\//.test(window.location?.pathname || '');
let storageTimer;
const rootURL = new URL(/* @vite-ignore */ '../', import.meta.url);
// Vite bundles this module under assets/ in both pages.
export const assetURL = path => new URL(path, rootURL).href;
const transport = () => typeof window.invokeCSharpAction === 'function'
  ? json => window.invokeCSharpAction(json)
  : window.chrome?.webview?.postMessage ? json => window.chrome.webview.postMessage(json) : null;

export function request(method, ...args) {
  const send = transport();
  if (!send) return Promise.reject(new Error('Native host unavailable (standalone preview).'));
  const id = `ui-${++sequence}`;
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => { pending.delete(id); reject(new Error(`Native request timed out: ${method}`)); }, 15000);
    pending.set(id, { resolve, reject, timer });
    try { send(JSON.stringify({ synapseAlt: 1, id, method, args })); }
    catch (error) { clearTimeout(timer); pending.delete(id); reject(error); }
  });
}
window.synapseAltResolve = (id, result, error) => {
  const task = pending.get(String(id));
  if (!task) return;
  pending.delete(String(id)); clearTimeout(task.timer);
  if (error) task.reject(new Error(typeof error === 'string' ? error : error.message || JSON.stringify(error)));
  else task.resolve(result);
};
function on(name, callback) {
  if (!listeners.has(name)) listeners.set(name, new Set());
  listeners.get(name).add(callback);
  return () => listeners.get(name)?.delete(callback);
}
window.synapseAltEvent = (name, payload) => {
  if (name === 'windowState') windowState = { ...windowState, ...payload };
  if (name === 'settingsChanged') {
    const changes = payload?.key ? { [payload.key]: payload.value } : (payload?.settings || payload || {});
    Object.assign(bootstrap.settings, changes);
    for (const [key, value] of Object.entries(changes)) localStorage.setItem(`synapse_setting_${key}`, typeof value === 'object' ? JSON.stringify(value) : String(value));
  }
  for (const callback of listeners.get(name) || []) { try { callback(payload); } catch (error) { console.error(error); } }
};
export function reportError(error) {
  const message = error instanceof Error ? error.message : String(error);
  if (window.HWToast) window.HWToast.error(message, '', 'UI-only port');
  else {
    let el = document.getElementById('synapse-alt-error');
    if (!el) { el = document.createElement('div'); el.id = 'synapse-alt-error'; el.setAttribute('role', 'alert'); el.style.cssText = 'position:fixed;bottom:12px;left:12px;z-index:9999;padding:12px;background:#57232b;color:white;max-width:80vw'; document.body.append(el); }
    el.textContent = message;
  }
  window.synapseAltEvent('consoleMessage', { level: 'error', text: message });
  return { ok: false, error: message };
}
const safe = (method, fallback = null) => async (...args) => {
  try { return await request(method, ...args); } catch (error) { reportError(error); return fallback; }
};
function storageSnapshot() {
  const result = {};
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key.startsWith('synapse_') && key !== 'synapse_tabs' && key !== 'synapse_active_tab') result[key] = localStorage.getItem(key);
  }
  return result;
}
export function setWorkspaceReader(reader) { workspaceReader = reader; }
window.synapseAltSnapshot = () => ({ settings: { ...bootstrap.settings }, storage: storageSnapshot(), workspace: workspaceReader() });
export async function saveWorkspace(workspace) {
  bootstrap.workspace = workspace;
  if (transport()) return safe('saveWorkspace')(workspace);
}
const bundledThemes = () => fetch(assetURL('themes/manifest.json')).then(res => { if (!res.ok) throw new Error('Bundled theme manifest unavailable'); return res.json(); });
let themePromise;
window.hwAPI = {
  getBootstrap: () => request('getBootstrap'),
  getSetting: async (key, fallback) => bootstrap.settings[key] ?? fallback,
  setSetting: async (key, value) => {
    bootstrap.settings[key] = value;
    if (key === 'always_on_top' && transport()) safe('setAlwaysOnTop')(!!value);
    window.synapseAltEvent('settingsChanged', { key, value });
    if (transport()) return safe('setSetting')(key, value);
    return true;
  },
  getEditorConfig: async key => transport() ? safe('getEditorConfig', {})(key) : JSON.parse(localStorage.getItem(`synapse_editor_${key}`) || '{}'),
  setEditorConfig: async (key, value) => {
    localStorage.setItem(`synapse_editor_${key}`, JSON.stringify(value));
    if (transport()) return safe('setEditorConfig')(key, value);
    return true;
  },
  listSystemFonts: () => request('listSystemFonts'),
  listScripts: async () => transport() ? safe('listScripts', [])() : [],
  listGists: safe('listGists', []),
  addGist: safe('addGist', false), readGist: safe('readGist'),
  readScript: safe('readScript'), saveScript: safe('saveScript', { ok: false }),
  openFileDialog: safe('openFileDialog'), saveFile: safe('saveFile'), deleteScript: safe('deleteScript', false),
  saveWorkspace, saveStorage: safe('saveStorage'),
  listThemes: async () => {
    const bundled = await (themePromise ||= bundledThemes());
    if (!transport()) return bundled;
    try {
      const host = await request('listThemes');
      return [...new Map([...bundled, ...(Array.isArray(host) ? host : [])].map(t => [t.id, t])).values()];
    } catch { return bundled; }
  },
  loadTheme: async id => {
    const bundled = await (themePromise ||= bundledThemes());
    if (transport()) { try { const result = await request('loadTheme', id); if (result?.cssContent) return result; } catch {} }
    return bundled.find(t => t.id === id || t.folderName === id) || bundled.find(t => t.id === 'hollywood-dark');
  },
  minimize: safe('minimize'), maximize: safe('maximize'), close: safe('close'),
  startWindowDrag: safe('startWindowDrag'), setAlwaysOnTop: safe('setAlwaysOnTop'),
  isMaximized: () => !!windowState.isMaximized,
  isConnected: () => false,
  execute: async () => reportError('Execution is unsupported in SynapseV3Alt (UI-only). No script was executed.'),
  openConsole: safe('openConsole'), flushConsoleLogs: safe('flushConsoleLogs'), clearConsole: safe('clearConsole'),
  openThemeFolder: safe('openThemeFolder'), showItemInFolder: safe('showItemInFolder'),
  openExternal: async () => reportError('External navigation is unavailable in this offline UI-only port.'),
  setZoomFactor: scale => {
    const zoom = Math.max(0.25, Math.min(1.5, Number(scale) || 1));
    document.documentElement.style.setProperty('--interface-scale', String(zoom));
    document.documentElement.style.zoom = String(zoom);
    window.monaco?.editor.remeasureFonts();
    window.monacoEditor?.layout();
  },
  getChangelog: async () => 'SynapseV3Alt: local editor with local-file bookmarks and on-demand GitHub Gists. Execution, external clients and plugins are unavailable.',
  onScriptsChanged: cb => on('scriptsChanged', cb), onThemesChanged: cb => on('themesChanged', cb),
  onConsoleMessage: cb => on('consoleMessage', cb), onConsoleSnapshot: cb => on('consoleSnapshot', cb),
  onSettingsChanged: cb => on('settingsChanged', cb), onWindowState: cb => on('windowState', cb),
  onClientAttach: cb => { cb(false); return () => {}; }
};
export async function hydrate() {
  if (transport()) {
    bootstrap = { ...bootstrap, ...await request('getBootstrap') };
    windowState = { ...windowState, ...bootstrap.windowState };
    // Native storage is authoritative. Never let a previous WebView session replace host state.
    for (const key of Object.keys(localStorage)) if (key.startsWith('synapse_')) localStorage.removeItem(key);
    for (const [key, value] of Object.entries(bootstrap.storage || {})) if (key.startsWith('synapse_')) localStorage.setItem(key, String(value));
    for (const [key, value] of Object.entries(bootstrap.settings || {})) localStorage.setItem(`synapse_setting_${key}`, typeof value === 'object' ? JSON.stringify(value) : String(value));
    localStorage.setItem('synapse_tabs', JSON.stringify(bootstrap.workspace?.tabs || []));
    localStorage.setItem('synapse_active_tab', String(bootstrap.workspace?.activeTabId || ''));
  } else {
    for (const key of Object.keys(localStorage)) if (key.startsWith('synapse_setting_')) {
      const value = localStorage.getItem(key);
      try { bootstrap.settings[key.slice(16)] = JSON.parse(value); } catch { bootstrap.settings[key.slice(16)] = value; }
    }
  }
  bootstrap.settings ||= {};
  hydrated = true;
  // Capture all extra original UI storage writes, not only settings/tabs.
  for (const method of ['setItem', 'removeItem', 'clear']) {
    const original = Storage.prototype[method];
    Storage.prototype[method] = function (...args) {
      const result = original.apply(this, args);
      if (this === localStorage && hydrated && !consolePage) {
        clearTimeout(storageTimer);
        storageTimer = setTimeout(() => { if (transport()) window.hwAPI.saveStorage(storageSnapshot()); }, 350);
      }
      return result;
    };
  }
  window.addEventListener('pagehide', () => { if (transport() && !consolePage) { window.hwAPI.saveStorage(storageSnapshot()); saveWorkspace(workspaceReader()); } });
  return bootstrap;
}
