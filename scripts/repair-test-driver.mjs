import assert from 'node:assert/strict';
import { importTypescript } from './import-typescript.mjs';

const { performRepair, repairProgress, drainProgress, REPAIR_OPEN_SECONDS } = await importTypescript(new URL('../src/world/tycoon/RepairGame.ts', import.meta.url));

// Exercise the same validated inputs as the UI; never set job completion flags.
export function exerciseManualRepair(state, send = input => performRepair(state, input)) {
  const job = state.car?.plan?.jobs.find(job => !job.done);
  if (state.car?.status !== 'repair' || !job?.manual || !job.started) return;
  const game = repairProgress(job, state.clock);
  if (game.complete || state.clock - game.openedAt + 1e-8 < REPAIR_OPEN_SECONDS) return;
  const input = value => assert.ok(send(value), `Repair input accepted: ${JSON.stringify(value)}`);
  if (game.kind === 'wheels') {
    game.wheels.forEach((done, index) => { if (!done) input({ kind: 'wheel', index }); });
    game.bolts.forEach((done, index) => { if (!done) input({ kind: 'bolt', index }); });
  } else if (game.kind === 'engine') {
    if (!game.bolts[0]) input({ kind: 'bolt', index: 0 });
    if (drainProgress(game, state.clock) < 1) return;
    if (!game.bolts[1]) input({ kind: 'bolt', index: 1 });
    if (!game.filterInstalled) input({ kind: 'oil-filter' });
    for (let i = 0; game.oil < 1 && i < 100; i++) input({ kind: 'pour', amount: .05 });
    assert.equal(game.oil, 1);
  } else if (game.kind === 'tuning') {
    game.bolts.forEach((done, index) => { if (!done) input({ kind: 'remove', index }); });
    game.targets.forEach((done, index) => { if (!done) input({ kind: 'install', index, part: index === 0 ? 'filter' : 'plug' }); });
  } else game.targets.forEach((done, index) => { if (!done) input({ kind: 'target', index }); });
  assert.equal(job.progress, 1);
}
