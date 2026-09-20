import { createServer } from 'node:http';
import { mkdir, readFile, writeFile, access } from 'node:fs/promises';
import { dirname, resolve, sep, extname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { REVISION } from 'three';
import { editorProject } from './editor-project.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const revision = `r${REVISION}`;
const cache = resolve(root, '.editor-cache', revision);
const marker = resolve(cache, '.complete');

async function download(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`${response.status}: ${url}`);
  return response;
}

async function installEditor() {
  try { await access(marker); return; } catch { /* First launch. */ }
  console.log(`Downloading the official Three.js Editor ${revision}...`);
  const response = await download(`https://api.github.com/repos/mrdoob/three.js/git/trees/${revision}?recursive=1`);
  const tree = await response.json();
  if (tree.truncated || !Array.isArray(tree.tree)) throw new Error('Incomplete editor file listing');
  const files = tree.tree.filter(entry => entry.type === 'blob' && (
    entry.path.startsWith('editor/') || entry.path === 'LICENSE' ||
    /^files\/favicon.*\.ico$/.test(entry.path)
  ));
  // Keep installation bounded while downloading independent upstream files.
  let index = 0;
  await Promise.all(Array.from({ length: 6 }, async () => {
    while (index < files.length) {
      const file = files[index++];
      const destination = resolve(cache, file.path);
      if (!destination.startsWith(cache + sep)) throw new Error('Invalid editor path');
      const data = await download(`https://raw.githubusercontent.com/mrdoob/three.js/${revision}/${file.path}`);
      await mkdir(dirname(destination), { recursive: true });
      await writeFile(destination, Buffer.from(await data.arrayBuffer()));
    }
  }));
  await writeFile(marker, revision);
  console.log(`Editor ${revision} is installed locally.`);
}

await installEditor();
if (process.argv.includes('--install-only')) process.exit(0);

const mime = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.ico': 'image/x-icon',
  '.wasm': 'application/wasm', '.woff': 'font/woff', '.woff2': 'font/woff2',
};

const server = createServer(async (request, response) => {
  try {
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      response.writeHead(405).end(); return;
    }
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    if (pathname === '/') {
      response.writeHead(302, { Location: '/editor/#file=/project.json' }).end(); return;
    }
    if (pathname === '/project.json') {
      const json = JSON.parse(await readFile(resolve(root, 'public/scenes/main.scene.json'), 'utf8'));
      const project = editorProject(json);
      response.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
      response.end(request.method === 'HEAD' ? undefined : JSON.stringify(project)); return;
    }
    let base;
    if (pathname.startsWith('/editor/') || pathname.startsWith('/files/')) base = cache;
    else if (/^\/(build|examples|src)\//.test(pathname)) base = resolve(root, 'node_modules/three');
    else { response.writeHead(404).end(); return; }
    const path = resolve(base, '.' + pathname, pathname.endsWith('/') ? 'index.html' : '');
    if (!path.startsWith(base + sep)) { response.writeHead(403).end(); return; }
    let data = await readFile(path);
    // Match the game's fixed renderer settings when opening or clearing a scene.
    // Upstream files stay untouched in the cache.
    if (pathname === '/editor/' || pathname === '/editor/index.html') {
      data = data.toString().replace('const editor = new Editor();', `const editor = new Editor();
        editor.config.setKey('project/renderer/physicallyCorrectLights', true,
          'project/renderer/shadowType', 2, 'project/renderer/shadows', true,
          'project/renderer/toneMapping', 0, 'project/renderer/toneMappingExposure', 1);`)
        .replace("navigator.serviceWorker.register( 'sw.js' );", '// Use fresh local editor files on every reload.');
    } else if (pathname === '/editor/js/Sidebar.Project.Renderer.js') {
      data = data.toString()
        .replace('currentRenderer.physicallyCorrectLights = false;', 'currentRenderer.physicallyCorrectLights = true;')
        .replace('currentRenderer.shadowMap.type = THREE.PCFShadowMap;', 'currentRenderer.shadowMap.type = THREE.PCFSoftShadowMap;');
    }
    response.writeHead(200, { 'Content-Type': mime[extname(path)] ?? 'application/octet-stream', 'Cache-Control': 'no-store' });
    response.end(request.method === 'HEAD' ? undefined : data);
  } catch (error) {
    response.writeHead(error.code === 'ENOENT' ? 404 : 500).end('Unable to load editor resource');
    console.error(error.message);
  }
});
server.on('error', error => { console.error(error.message); process.exitCode = 1; });
server.listen(5174, '127.0.0.1', () => {
  console.log(`Three.js Editor ${revision}: http://127.0.0.1:5174/`);
  console.log('Export Scene JSON to public/scenes/main.scene.json, then refresh the game.');
});
