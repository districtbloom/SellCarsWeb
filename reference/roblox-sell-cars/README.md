# Sell Cars source capture

Read-only capture from the open **Sell Cars** Studio project, place
**104040320298951**, in Edit mode on 2026-09-16. No Studio scripts, objects,
production profiles or publication state were changed.

The 55 Luau files preserve FullJourney, the older tycoon modules and supporting
economy/service/vehicle configuration. The original return values were compressed
with EncodingService/Zstandard and stored as base64. Run
`node scripts/unpack-sell-cars.mjs archive-0.b64` (etc.) to unpack a capture.
Initial/categorical captures overlap with the complete numbered archive.

`catalog-fixture.b64` contains results of evaluating the pure FullJourneyCatalog
in Studio: all 240 purchase entries and capabilities at every step from 0 to 240.
It does not execute the gameplay bootstrap. `npm run tycoon:data` converts the
archived catalog and this fixture to their TypeScript/test counterparts.

`geometry-audit.json` records counts and aggregate canonical position/size
components grouped by FJ_First. All 25,446 records agree with the existing
Integration environment export; the environment was reused.

`PROJECT_BIBLE_EN.md` is the user's supplied v3.59 document, copied verbatim from
Downloads. It documents an earlier game state and is retained as reference.
Use the open project's executable consumers to resolve historical differences.

See [the port guide](../../docs/tycoon.md) for implemented systems, compatibility
choices, offline-rate bindings and the remaining older systems. An archived
module is not evidence that every system it contains has been activated in TS.
