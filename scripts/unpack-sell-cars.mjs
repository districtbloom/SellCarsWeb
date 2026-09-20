import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { zstdDecompressSync } from 'node:zlib';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
const root = new URL('../reference/roblox-sell-cars/', import.meta.url);
const file = process.argv[2] ?? 'initial.b64';
const entries = JSON.parse(zstdDecompressSync(Buffer.from(await readFile(new URL(file, root), 'utf8'), 'base64')));
for (const entry of entries) {
  const path = fileURLToPath(new URL(entry.path.replaceAll('.', '/') + '.luau', root));
  await mkdir(dirname(path), { recursive: true }); await writeFile(path, entry.source);
}
console.log(`Unpacked ${entries.length} Sell Cars scripts`);
