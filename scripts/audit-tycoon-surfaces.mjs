import { readFile, writeFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';
const root = new URL('../src/world/tycoon/', import.meta.url);
const { partPose } = await importTypescript(new URL('BuildingProgression.ts', root));
const { separateSurfaces } = await importTypescript(new URL('SurfaceSeparation.ts', root));
const { parts } = JSON.parse(await readFile(new URL('../public/tycoon/dealership.json', import.meta.url)));
const steps = process.argv.includes('--all') ? Array.from({ length: 241 }, (_, i) => i) : [1, 6, 24, 40, 64, 120, 140, 183, 196, 240];
const report = { sourceParts: parts.length, tolerance: .0015, separation: .012, stages: [] };
for (const step of steps) {
  const entries = parts.map(part => ({ part, pose: partPose(part, step) })).filter(e => e.pose.visible && e.pose.transparency < 1);
  const start = performance.now(), result = separateSurfaces(entries);
  const worst = Math.max(0, ...result.adjustments.map(a => Math.hypot(...a.offset)));
  report.stages.push({ step, checkedParts: entries.length, movedParts: result.adjustments.length, unresolved: result.unresolved, maxOffset: worst });
  console.log(JSON.stringify({ ...report.stages.at(-1), ms: Math.round(performance.now() - start) }));
  assert.equal(result.unresolved, 0, `Unresolved coplanar surfaces at ${step}`);
  assert.ok(worst < .25, `Excessive geometry movement at ${step}: ${worst}`);
  if (step === 240) report.examples = result.adjustments.slice(0, 40);
}
if (process.argv.includes('--write')) await writeFile(new URL('../docs/surface-audit.json', import.meta.url), JSON.stringify(report, null, 2) + '\n');
