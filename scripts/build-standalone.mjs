import { readdir, readFile, mkdir, writeFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';
import { build } from 'vite';

const root = fileURLToPath(new URL('../', import.meta.url));
const types = {
  '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp',
  '.obj': 'text/plain', '.mtl': 'text/plain', '.woff2': 'font/woff2',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.m4a': 'audio/mp4',
};
const archive = Object.create(null);
async function collect(directory, prefix = '') {
  const entries = (await readdir(directory, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name));
  for (const entry of entries) {
    const path = join(directory, entry.name), key = prefix + entry.name;
    if (entry.isDirectory()) await collect(path, `${key}/`);
    else if (entry.isFile()) archive[key] = {
      type: types[extname(entry.name).toLowerCase()] ?? 'application/octet-stream',
      data: (await readFile(path)).toString('base64'),
    };
  }
}

await collect(join(root, 'public'));
const payload = gzipSync(JSON.stringify(archive), { level: 9 }).toString('base64');
const result = await build({
  root, configFile: false, base: './', publicDir: false,
  build: {
    write: false, copyPublicDir: false, sourcemap: false, minify: true,
    cssCodeSplit: false,
    lib: { entry: join(root, 'src/main.ts'), name: 'SellCars', formats: ['iife'] },
  },
});
const output = (Array.isArray(result) ? result : [result]).flatMap(result => result.output);
const scripts = output.filter(file => file.type === 'chunk');
if (scripts.length !== 1 || scripts[0].imports.length || scripts[0].dynamicImports.length) {
  throw new Error('Standalone build must contain exactly one script with no external imports');
}
const styles = output.filter(file => file.type === 'asset' && file.fileName.endsWith('.css'));
const extra = output.filter(file => file.type === 'asset' && !file.fileName.endsWith('.css'));
if (extra.length) throw new Error(`Unexpected external build assets: ${extra.map(file => file.fileName).join(', ')}`);
const css = styles.map(file => file.source.toString()).join('\n');
if (/@import\b|url\(\s*["']?(?!data:)[^\s"')]/i.test(css)) {
  throw new Error('Standalone CSS contains an external asset; embed it before building');
}
const template = await readFile(join(root, 'index.html'), 'utf8');
const favicon = archive['vite.svg'];
const html = template
  .replace(/<link\b[^>]*rel="icon"[^>]*>/, () => `<link rel="icon" href="data:${favicon.type};base64,${favicon.data}">`)
  .replace('</head>', () => `<style>${css.replace(/<\/style/gi, '<\\/style')}</style>\n</head>`)
  .replace(/<script\b[^>]*src="\/src\/main\.ts"[^>]*><\/script>/, () => `
    <p id="standalone-loading" style="position:fixed;top:16px;left:16px;z-index:100;background:#121a25;color:white;padding:16px;font:16px system-ui">Loading game…</p>
    <noscript>Enable JavaScript to play this game.</noscript>
    <script id="standalone-assets" type="application/octet-stream">${payload}</script>
    <script>${scripts[0].code.replace(/<\/script/gi, '<\\/script')}</script>`);
if (!html.includes('id="standalone-assets"') || html.includes('src="/src/main.ts"')) {
  throw new Error('Could not replace the game entry in index.html');
}
const directory = join(root, 'dist-standalone');
await mkdir(directory, { recursive: true });
const destination = join(directory, 'game.html');
await writeFile(destination, html);
console.log(`\nStandalone game: ${destination}\n${(Buffer.byteLength(html) / 1024 / 1024).toFixed(1)} MB; ${Object.keys(archive).length} embedded assets.\nOpen game.html directly in a current browser. No server required.`);
