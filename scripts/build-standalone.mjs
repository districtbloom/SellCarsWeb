import { readdir, readFile, mkdir, writeFile, unlink } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';
import { build } from 'vite';
import { runtimeBuildAssets } from './runtime-build-assets.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const split = process.argv.includes('--split');
const fileLimit = 2_000_000, partSize = 1_900_000;
const archive = await runtimeBuildAssets(join(root, 'public'));
const compressed = gzipSync(JSON.stringify(archive), { level: 9 });
const parts = Array.from({ length: Math.ceil(compressed.length / partSize) }, (_, index) => {
  const data = compressed.subarray(index * partSize, (index + 1) * partSize);
  return { file: `assets-${String(index).padStart(3, '0')}.bin`, bytes: data.length, data };
});
const payload = split ? JSON.stringify({ parts: parts.map(({ file, bytes }) => ({ file, bytes })) }) : compressed.toString('base64');
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
    <script id="standalone-assets" type="application/octet-stream" data-format="${split ? 'parts' : 'base64'}">${payload}</script>
    <script>${scripts[0].code.replace(/<\/script/gi, '<\\/script')}</script>`);
if (!html.includes('id="standalone-assets"') || html.includes('src="/src/main.ts"')) {
  throw new Error('Could not replace the game entry in index.html');
}
if (split && Buffer.byteLength(html) > fileLimit) throw new Error('Game HTML exceeds the 2,000,000-byte upload limit');
const directory = join(root, split ? 'dist-upload' : 'dist-standalone');
await mkdir(directory, { recursive: true });
if (split) {
  // Remove only this generator's old part files, never other files in the output directory.
  for (const name of await readdir(directory)) if (/^assets-\d+\.bin$/.test(name)) await unlink(join(directory, name));
  for (const part of parts) await writeFile(join(directory, part.file), part.data);
}
const destination = join(directory, split ? 'index.html' : 'game.html');
await writeFile(destination, html);
console.log(`\n${split ? 'Upload build' : 'Standalone game'}: ${destination}\n${Buffer.byteLength(html).toLocaleString('en-US')} bytes HTML; ${Object.keys(archive).length} runtime assets.`);
console.log(split ? `${parts.length} asset parts; each file under ${fileLimit.toLocaleString('en-US')} bytes. Total ${(compressed.length + Buffer.byteLength(html)).toLocaleString('en-US')} bytes.\nUpload ALL files together to the same directory on a web host. This is a per-file limit, not a 2 MB total build. Serve over HTTP(S); opening index.html directly cannot fetch the parts.` : 'Open game.html directly in a current browser. No server required.');
