# Interaction effects and replacement audio

The player and NPCs breathe, shift their weight, and occasionally look to either side while idle. Characters have staggered timing. Conversations add nods, head tilts and hand gestures. Walking, jumping, typing and repair poses still take priority; the face follows all head rotations.

World effects include collision dust and sparks at the physics contact point, tire dust during skids, sprint dust, jump/landing puffs, build/deal celebrations, income particles, tool sparks, wash/paint spray and camera flashes. Effects have no collision bodies and are limited to 320 live particles in one draw call. Distant events and resting contacts are filtered out; car-to-car collisions emit once per pair with a cooldown.

The repair overlay also shows small bursts at the clicked tool target or oil funnel, so feedback stays visible during a minigame. These are capped at 54 elements, expire in 0.6 seconds, and are hidden when the browser requests reduced motion.

Tire smoke/skid particles are silent. A short synthesized engine rev (`car.rev`) plays when a successful UI action sends a car to repairs or another destination, calls in a seller, sells a car for departure, or places a personal car in the garage. This centered UI cue also works for cars arriving from outside hearing range. Failed actions, ordinary menu browsing and ongoing travel do not repeat it. Replace it with your own MP3 using the same manifest workflow below.

## Replace a sound

1. Put your MP3 in `public/audio/`, for example `npc-greeting.mp3`.
2. Open `public/audio/sound-map.json`, find `npc.greeting`, and change its `file` from `null` to `"npc-greeting.mp3"`.
3. Reload the game. For a standalone HTML, run `npm run build:standalone` again; audio files are embedded automatically.

Each manifest entry has a stable ID and a description of where it plays. You can supply files named after these IDs (for example `car.impact.heavy.mp3`) or use your own filenames. File paths are relative to `public/audio/`. `volume` adjusts a replacement's gain from 0 (silent) to 2 (twice its default). Use short clips, typically 0.1–1 seconds for impacts/tools and 0.5–2 seconds for chatter. Clips are limited to eight seconds. The placeholders are synthesized locally, including wordless voiced chatter; there are no external audio services or asset licenses to manage.

The first keyboard or pointer interaction enables browser audio. World sounds fade with distance and pan with the camera. UI and phone sounds stay centered. At most 24 source voices play concurrently; repeated cues have individual cooldowns. Audio stops when the tab is hidden and resources are released when the game closes. Replacement clips load and decode once on first use; that first event uses the placeholder while loading, and subsequent events use the clip. Missing or undecodable files keep the placeholder without blocking play or retrying every frame.

## Quick QA

- Idle for 15 seconds: check breathing, weight shift and a smooth glance/return. Walk, jump, land, type and open a repair job; check the face stays attached and action poses reset cleanly.
- Drive into scenery and another car at low/high speeds. Check stronger hits produce a heavier sound and more particles at the contact. Park touching an obstacle: no continuous bursts.
- Talk to a seller, counter, accept/decline; listen for distinct responses. Walk near talking/working NPCs, then away, and rotate the camera to check attenuation and pan.
- Buy a pad, finish a parts sale, use repair tools, pour oil, wash/paint and take listing photos. Confirm effects occur on accepted actions and pouring does not flood the scene.
- Set one manifest entry to an MP3, reload, trigger it twice and confirm the replacement. Test an invalid filename to confirm the placeholder remains available. Hide the tab during playback and close the game.
