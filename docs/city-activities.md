# Music, minimap and activities

The supplied MP3 files are in `public/audio/music/`. City and dealership music
loop during exploration; racing and Hill Drive take priority while those
activities are open. Zone/activity changes crossfade over 1.25 seconds; rapid
changes reverse the existing fade without jumping volume. Playback starts after a key press/click, pauses when the
tab is hidden, and resumes when visible. The music button mutes music without
muting interaction effects. The standalone build embeds all four original MP3s.

## Runtime minimap

`RuntimeMap` reads the live scene every two seconds. `OpenWorldTown` registers
road dimensions and block footprints as it generates them; scene objects with
`userData.mapPOI = { label, color? }` appear at their current world positions.
Hidden or removed POIs disappear. The map follows the player/car with north up;
race flags and the next checkpoint remain indicated at the edge when off-map.
Roads and POIs are not a baked image or a separately maintained coordinate list.

## City Sprint

The first event appears after five minutes, then another every five minutes.
Each has a five-minute joining window, a top-center announcement, a gold ground
marker, a persistent world billboard, and a minimap flag. Drive within 24 scene
units of the start and press **F**. A three-second countdown holds the car's
brakes. Race two or three AI opponents through the gold beams in order; blue
beams preview upcoming checkpoints. Arrows point along the next road segment.
Win first place for the displayed random **$250-$3,500** prize. Higher prizes
raise route length, rival count and top speed, and shorten the deadline from
five to three minutes. Winnings enter the normal cash ledger and save; failed
required persistence rolls back the credit and the event cannot pay twice.
**X** abandons a race. Leaving/changing/resetting the car or exceeding its
deadline ends the run. Events and race times do not persist between reloads.

Opponents clone the player's selected model and all its physics settings,
with top speed reduced to 88-96% depending on difficulty. They use the same
shared physics world, suspension, tire forces, mass and collision solver. AI
applies steering and throttle each fixed step, slows for corners, reverses when
stuck and recovers missed checkpoints. Collisions can cost them the race; they
never teleport or follow a scripted transform.

Routes come from a graph of actual road-centerline intersections. A random
self-avoiding walk chooses 6-13 intersections, with checkpoints at each
intersection and each intervening midpoint. The grid starts on the first
midpoint, leaving room for cars side by side and producing 9-23 checkpoints. Consecutive edges follow the same road, turns occur only
at intersections, and no node/edge repeats or crosses an earlier section.
If a valid route cannot be found, an event is skipped instead of inventing
an off-road route. `RACE_INTERVAL` and `RACE_JOIN_WINDOW` are in `RaceSystem.ts`.

## Hill Drive

**E** at the former Sell Parts laptop opens a blocky laptop frame. Choose
**Start driving**. Hold **LMB** to drive right/forward and **RMB** to drive
left/backward; the same inputs rotate clockwise/counterclockwise while airborne.
Both buttons together coast. On-screen hold buttons support touch input.
The car is drawn from original block and wheel primitives; no car asset is reused.

Each run generates smooth random hills and clock pickups. The default timer is
30 seconds; each clock adds five seconds once. Two wheel suspension contacts,
gravity, pitch momentum and roof collisions allow jumps and flips. A roof impact
or an expired timer ends the run and pays `floor(furthest forward distance) × 2`.
Reversing cannot farm already-covered distance. **Esc** or closing an unfinished
round forfeits it. Losing tab visibility cancels the round without a reward.
Completed rounds settle once through the normal ledger and save transaction;
failed required persistence rolls the credit back. Saves discard unfinished
manual rounds. Old five-second manual payouts are removed.

Existing mechanic automatic parts income and its upgrades remain separate;
automatic batches pause during a manual hill run. Manual minigame rewards always
use the distance multiplier, regardless of laptop upgrade level.

Tune `HILL_CONFIG` in `HillDriveModel.ts`: timer, reward multiplier, pickup bonus,
gravity, acceleration, air torque and maximum speed. Terrain spacing/amplitude,
spring force and pitch inertia live beside the simulation. Physics uses fixed
1/120-second steps for consistent behavior at different rendering frame rates.

## Objective arrows and motion

The welcome HUD says **Welcome to Sell Cars! I'll show you the ropes!** A second
dialog sequence introduces the first phone call and points at Answer. These
dismissals persist with the save. Other guidance uses one screen-space arrow:
world objectives project through the camera, offscreen objectives point from
the screen edge, and open panels/repairs target their next actual control.
Repair guidance advances through wheels, bolts, draining, replacement filters,
upgrades and remaining work areas. It is drawn above the repair overlay.

Driving, walking and opponents share the fixed 120 Hz physics update. Each
render interpolates the previous/current chassis, wheel and player poses by
the remaining accumulator fraction; the chase camera follows that same pose.
Resets clear interpolation history so a teleport does not streak across frames.

## Verification

`npm test` includes 1,000 seeded route checks, runtime POI changes, race spawning,
expiry/join/finish/cancel/reset, AI driving with real collisions, persistent
prizes and rollback, objective controls, music crossfades and lifecycle, hill controls, timer,
pickup deduplication, flips, frame-rate consistency and actual tycoon payout/save
integration. Browser appearance, audio listening and touch-device feel still
need manual review because no browser automation surface was connected here.
