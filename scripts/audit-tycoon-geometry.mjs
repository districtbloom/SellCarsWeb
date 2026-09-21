import { readFile, readdir, writeFile } from 'node:fs/promises';
import { zstdDecompressSync } from 'node:zlib';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';

const root = new URL('../', import.meta.url);
const { parts, placeId } = JSON.parse(await readFile(new URL('public/tycoon/dealership.json', root), 'utf8'));
const { partPose } = await importTypescript(new URL('src/world/tycoon/BuildingProgression.ts', root));
const { geometrySupports } = await importTypescript(new URL('src/world/tycoon/GeometryAlignment.ts', root));
const { separateSurfaces } = await importTypescript(new URL('src/world/tycoon/SurfaceSeparation.ts', root));
const canonical = value => Array.isArray(value) ? value.map(canonical) : value && typeof value === 'object'
  ? Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])])) : value;
const fingerprint = rows => createHash('sha256').update(rows.map(({ id, ...part }) => JSON.stringify(canonical(part))).sort().join('\n')).digest('hex');
const report = { placeId, parts: parts.length, sourceFingerprint: fingerprint(parts), studioComparison: 'not requested', stages: [] };
if (process.argv.includes('--studio')) {
  const directory = new URL('.editor-cache/', root);
  const files = (await readdir(directory)).filter(file => /^studio-geometry-\d+\.b64$/.test(file));
  const live = (await Promise.all(files.map(async file => JSON.parse(zstdDecompressSync(Buffer.from((await readFile(new URL(file, directory), 'utf8')).trim(), 'base64')).toString())))).flat();
  assert.equal(live.length, parts.length, 'Every live Studio part was exported');
  assert.equal(fingerprint(live), report.sourceFingerprint, 'Source parity ignores unstable enumeration IDs, but preserves duplicate instances');
  report.studioComparison = 'all exported properties match the connected Sell Cars Integration model';
}
for (let step = 0; step <= 240; step++) {
  const source = parts.map(part => ({ part, pose: partPose(part, step) })).filter(({ pose }) => pose.visible && pose.transparency < 1);
  const separated = separateSurfaces(source), entries = separated.entries;
  assert.equal(separated.unresolved, 0, `Unresolved coplanar surfaces at ${step}`);
  const alignment = geometrySupports(entries);
  for (const { pose, part } of [...entries, ...alignment.entries]) {
    assert.ok([...pose.cf, ...pose.size].every(Number.isFinite), `${step}: invalid transform ${part.path}`);
    assert.ok(pose.size.every(size => size > 0), `${step}: collapsed geometry ${part.path}`);
  }
  for (const support of alignment.audit) {
    assert.ok(support.top > support.bottom && support.top - support.bottom <= (support.role === 'footing' ? 1 : 12));
  }
  if ([0, 1, 3, 6, 22, 24, 62, 64, 120, 140, 183, 196, 240].includes(step)) report.stages.push({
    step, visibleSourceParts: entries.length, separatedParts: separated.adjustments.length, addedFootings: alignment.audit.filter(a => a.role === 'footing').length,
    addedMounts: alignment.audit.filter(a => a.role === 'mount').length,
  });
}
report.checkedStages = 241;
if (process.argv.includes('--write')) await writeFile(new URL('docs/geometry-audit.json', root), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report, null, 2));
