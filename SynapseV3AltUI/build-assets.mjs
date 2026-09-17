import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as sass from 'sass';
const root = path.dirname(fileURLToPath(import.meta.url));
const out = path.join(root, 'dist');
const readJSON = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const copy = (from, to) => { fs.mkdirSync(path.dirname(to), { recursive: true }); fs.cpSync(from, to, { recursive: true }); };
const write = (file, value) => { fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, value); };
// Only presentation assets are shipped. Legacy renderer helpers and Lua examples are not runnable output.
for (const name of ['fonts', 'lang', 'loginbgs', 'styles']) copy(path.join(root, 'assets', name), path.join(out, 'assets', name));
for (const name of fs.readdirSync(path.join(root, 'assets'))) if (/\.(png|svg|ico)$/.test(name)) copy(path.join(root, 'assets', name), path.join(out, 'assets', name));
copy(path.join(root, 'themes'), path.join(out, 'themes'));
copy(path.join(root, '../MonacoPreview/vs'), path.join(out, 'vs'));
copy(path.join(root, '../MonacoPreview/lsp-client.js'), path.join(out, 'lsp-client.js'));
copy(path.join(root, 'node_modules/@fontsource/ubuntu-mono/files'), path.join(out, 'assets/fonts/ubuntu-mono'));
const fontCSS = [400,700].flatMap(weight => ['normal','italic'].map(style => `@font-face{font-family:'Ubuntu Mono';font-style:${style};font-weight:${weight};src:url('assets/fonts/ubuntu-mono/ubuntu-mono-latin-${weight}-${style}.woff2') format('woff2');}`)).join('\n');
const fluent = readJSON(path.join(root,'node_modules/@iconify-json/fluent/icons.json'));
const check = fluent.icons['checkmark-12-filled'];
const checkURL = 'data:image/svg+xml,' + encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12">${check.body.replaceAll('currentColor','white')}</svg>`);
function localCSS(css, source) {
  css = css.replace(/@import\s+(?:url\([^)]*https?:[^)]*\)|["']https?:[^"']*["'])[^;]*;/g, '');
  css = css.replace(/url\(\s*(['"]?)(.*?)\1\s*\)/g, (whole, quote, url) => {
    if (url.startsWith('data:') || url.startsWith('#')) return whole;
    if (url.includes('svgur.com')) return "url('assets/logo_white.svg')";
    if (url.includes('api.iconify.')) return `url('${checkURL}')`;
    if (/^https?:/.test(url)) throw new Error(`Unbundled remote CSS asset: ${url}`);
    let dest;
    if (url.includes('assets/')) dest = url.slice(url.indexOf('assets/'));
    else dest = path.relative(root, path.resolve(path.dirname(source), url)).replaceAll('\\','/');
    return `url('${dest}')`;
  });
  return css;
}
const manifest = [];
const editorThemes = readJSON(path.join(root,'assets/styles/editor-themes.json'));
for (const name of fs.readdirSync(path.join(root,'assets/styles/prebuilt'))) {
  if (!name.startsWith('_prebuilt-') || !name.endsWith('.css')) continue;
  const id = name.slice(10,-4);
  const source = path.join(root,'assets/styles/prebuilt',name);
  manifest.push({id, name:id.split('-').map(w=>w[0].toUpperCase()+w.slice(1)).join(' '),folderName:id,meta:{},icons:{},editorTheme:editorThemes[id] || null,cssContent:localCSS(fs.readFileSync(source,'utf8'),source),cssExists:true,isCustom:false,cssPath:`assets/styles/prebuilt/${name}`});
}
for (const folder of fs.readdirSync(path.join(root,'themes'))) {
  const dir = path.join(root,'themes',folder);
  if (!fs.existsSync(path.join(dir,'theme.json'))) continue;
  const meta = readJSON(path.join(dir,'theme.json'));
  const file = fs.readdirSync(dir).find(f => f.endsWith('.scss')) || fs.readdirSync(dir).find(f=>f.endsWith('.css'));
  if (!file) throw new Error(`Theme stylesheet missing: ${folder}`);
  const source = path.join(dir,file);
  let css = file.endsWith('.scss') ? sass.compile(source,{loadPaths:[path.join(root,'assets/styles')],style:'expanded',silenceDeprecations:['legacy-js-api','color-functions','global-builtin','import'],logger:sass.Logger.silent}).css : fs.readFileSync(source,'utf8');
  css = localCSS(css,source);
  if (folder === 'nixday-hc') css = fontCSS + '\n' + css;
  if (folder === 'hazy-trips') css = "@font-face{font-family:W95FA;src:url('themes/hazy-trips/W95FA.otf')}\n" + css;
  const cssPath = `themes/${folder}/compiled.css`;
  write(path.join(out,cssPath),css);
  const optional = name => fs.existsSync(path.join(dir,name)) ? readJSON(path.join(dir,name)) : null;
  manifest.push({id:meta.id || folder,name:meta.name || folder,folderName:folder,meta,icons:optional('icons.json') || {},editorTheme:optional('editor.json'),cssContent:css,cssExists:true,isCustom:false,cssPath});
}
write(path.join(out,'themes/manifest.json'),JSON.stringify(manifest,null,2));
// Remove legacy injectable HTML/maps and remote font imports from output styles; original copies remain intact.
for (const dir of [path.join(out,'assets/styles'),path.join(out,'assets/styles/prebuilt')]) {
  for (const name of fs.readdirSync(dir)) {
    const file=path.join(dir,name);
    if (/\.(html|map|scss)$/.test(name)) fs.rmSync(file);
    else if (name.endsWith('.css')) write(file,fs.readFileSync(file,'utf8').replace(/@import\s+(?:url\([^)]*https?:[^)]*\)|["']https?:[^"']*["'])[^;]*;/g,''));
  }
}
// Preserve all discovered package/source notices in distributable output.
for (const pkg of ['react','react-dom','iconify-icon','@iconify-json/fluent','@iconify-json/mdi','@iconify-json/heroicons','@iconify-json/bx','@iconify-json/ci','@iconify-json/ri','@iconify-json/svg-spinners','@fontsource/ubuntu-mono']) {
  const dir=path.join(root,'node_modules',pkg);
  for (const name of fs.readdirSync(dir)) if (/^(license|copying|notice|ofl)/i.test(name)) copy(path.join(dir,name),path.join(out,'licenses',pkg.replaceAll('/','-'),name));
}
console.log(`Copied local Monaco and assets; compiled ${manifest.length} bundled themes.`);

write(path.join(out,'licenses/source-package.json'), JSON.stringify({source:'Synapse-Z-V3/SynapseV3-UI',declaredLicense:'ISC',note:'Original source package declares ISC; no standalone source LICENSE was present. Original notices remain in copied presentation assets, including loginbgs/ArtLicense.pdf.'},null,2));
