import { readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';

const types = { '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.webp': 'image/webp',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.ogg': 'audio/ogg', '.m4a': 'audio/mp4' };

/** Only runtime dependencies: the authored scene already contains the imported car models. */
export async function runtimeBuildAssets(publicDirectory) {
  const files = new Set(['vite.svg', 'scenes/main.scene.json', 'tycoon/dealership.json',
    'tycoon/journey.json', 'audio/sound-map.json', ...['city', 'tycoon', 'racing', 'moneyearnminigame'].map(name => `audio/music/${name}.mp3`)]);
  const addReference = (reference, directory) => {
    if (typeof reference !== 'string' || reference.startsWith('data:')) return;
    const root = new URL('https://build.invalid/'), url = new URL(reference, new URL(directory, root));
    if (url.origin !== root.origin) throw new Error(`Standalone asset must be local: ${reference}`);
    const key = decodeURIComponent(url.pathname.slice(1));
    if (key.includes('\\') || key.split('/').includes('..')) throw new Error(`Invalid asset path: ${reference}`);
    files.add(key);
  };
  const exported = JSON.parse(await readFile(join(publicDirectory, 'scenes/main.scene.json'), 'utf8'));
  for (const image of (exported.scene ?? exported).images ?? []) {
    for (const url of Array.isArray(image.url) ? image.url : [image.url]) addReference(url, 'scenes/');
  }
  const manifest = JSON.parse(await readFile(join(publicDirectory, 'audio/sound-map.json'), 'utf8'));
  for (const sound of Object.values(manifest.sounds ?? {})) if (sound.file) addReference(sound.file, 'audio/');
  const archive = Object.create(null);
  for (const key of [...files].sort()) {
    const text = extname(key).toLowerCase() === '.json';
    archive[key] = {
      type: types[extname(key).toLowerCase()] ?? 'application/octet-stream',
      encoding: text ? 'utf8' : 'base64',
      data: (await readFile(join(publicDirectory, key))).toString(text ? 'utf8' : 'base64'),
    };
  }
  return archive;
}
