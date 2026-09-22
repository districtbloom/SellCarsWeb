import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { gzipSync, gunzipSync } from 'node:zlib';
import { DefaultLoadingManager } from 'three';
import { importTypescript } from './import-typescript.mjs';

const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const { initializeStandaloneAssets, assetUrl } = await importTypescript(new URL('../src/runtimeAssets.ts', import.meta.url));

test('upload files respect the decimal 2 MB limit and retain every runtime asset byte for byte', async () => {
  const directory = new URL('../dist-upload/', import.meta.url);
  for (const name of await readdir(directory)) assert.ok((await readFile(new URL(name, directory))).length < 2_000_000, name);
  const html = await readFile(new URL('index.html', directory), 'utf8');
  const manifest = JSON.parse(/id="standalone-assets"[^>]*>([\s\S]*?)<\/script>/.exec(html)[1]);
  const parts = [];
  for (const part of manifest.parts) {
    const bytes = await readFile(new URL(part.file, directory)); assert.equal(bytes.length, part.bytes); parts.push(bytes);
  }
  const archive = JSON.parse(gunzipSync(Buffer.concat(parts)));
  for (const required of ['scenes/main.scene.json', 'tycoon/dealership.json', 'tycoon/journey.json', 'audio/sound-map.json',
    ...['city', 'tycoon', 'racing', 'moneyearnminigame'].map(name => `audio/music/${name}.mp3`)]) assert.ok(archive[required], required);
  assert.ok(!Object.keys(archive).some(key => key.startsWith('carAssets/')), 'Source OBJ and redundant textures are excluded');
  for (const [key, asset] of Object.entries(archive)) {
    assert.equal(hash(Buffer.from(asset.data, asset.encoding ?? 'base64')), hash(await readFile(new URL('../public/' + key, import.meta.url))), key);
  }
});

test('asset loader reconstructs split downloads, preserves standalone loading and reports missing uploads', async () => {
  const nativeFetch = globalThis.fetch, created = [];
  const compressed = gzipSync(JSON.stringify({
    'sample.json': { type: 'application/json', data: Buffer.from('{"ok":true}').toString('base64') },
    'text.json': { type: 'application/json', encoding: 'utf8', data: '{"name":"Sell Cars — тест"}' },
  }));
  let bad = false, short = false;
  const parts = [compressed.subarray(0, 17), compressed.subarray(17)];
  const payload = { dataset: { format: 'parts' }, textContent: JSON.stringify({ parts: parts.map((data, i) => ({ file: `assets-${i}.bin`, bytes: data.length })) }), remove() { this.removed = true; } };
  globalThis.document = { getElementById: () => payload };
  globalThis.window = { location: { href: 'https://example.invalid/games/index.html', protocol: 'https:' } };
  globalThis.fetch = async url => {
    if (String(url).startsWith('blob:')) return nativeFetch(url);
    assert.ok(String(url).startsWith('https://example.invalid/games/assets-'));
    const index = Number(/assets-(\d+)/.exec(url)[1]);
    return new Response(short ? parts[index].subarray(1) : parts[index], { status: bad ? 404 : 200 });
  };
  try {
    await initializeStandaloneAssets(); assert.ok(payload.removed);
    const first = assetUrl('./sample.json'); created.push(first); assert.deepEqual(await (await fetch(first)).json(), { ok: true });
    assert.equal(assetUrl('./sample.json'), first, 'Repeated requests reuse the decoded blob');
    const text = assetUrl('./text.json'); created.push(text); assert.equal((await (await fetch(text)).json()).name, 'Sell Cars — тест');
    bad = true; await assert.rejects(initializeStandaloneAssets(), /Missing game asset/); bad = false;
    short = true; await assert.rejects(initializeStandaloneAssets(), /Incomplete game asset/); short = false;
    window.location.protocol = 'file:'; await assert.rejects(initializeStandaloneAssets(), /needs a web server/);
    payload.dataset.format = 'base64'; payload.textContent = compressed.toString('base64');
    await initializeStandaloneAssets(); const second = assetUrl('./sample.json'); created.push(second);
    assert.deepEqual(await (await fetch(second)).json(), { ok: true });
  } finally {
    globalThis.fetch = nativeFetch; DefaultLoadingManager.setURLModifier(undefined); created.forEach(url => URL.revokeObjectURL(url));
  }
});
