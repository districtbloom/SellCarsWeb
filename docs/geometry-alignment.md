# Dealership geometry alignment

On 2026-09-21, the connected **Sell Cars Integration** Studio place
(`105869926920733`) was inspected through MCP in Edit mode. All **25,446** parts
under `workspace.SellCars_Dealership_FullJourney` were exported again and compared
with `public/tycoon/dealership.json`. Every exported property matched, including
CFrames, sizes, stage attributes, meshes and labels. Enumeration IDs were ignored;
duplicate instances were retained. The opening composer also matched the port's
source reference. No objects in Studio were changed.

The source itself contains small gaps beneath furniture and equipment, and some
early purchases show wall or ceiling fixtures before their building exists.
The web renderer now:

- Adds short matching foundations beneath floor sections, equipment bases,
  cabinets, racks, pedestals and furniture feet where their visible floor is
  between 0.08 and 1 stud below them.
- Places small feet at the actual bottom of tilted tripod legs and caster wheels.
- Gives the early scrap rails, handmade founding sign, ready-stock sign and
  freestanding electrical panels supporting posts.
- Shows personal parking ceiling fixtures only once their workshop roof section
  is present (steps 62, 120 or 183).
- Grounds the web-only parts-sales desk on the current collision floor whenever
  construction changes the environment.

The exported source data remains intact. Additional
supports follow source visibility, materials and collision settings and join the
existing instanced rendering batches. This preserves assembled details and avoids
moving elevated wall art, ramps or upper floors down to the yard.

## Coplanar surfaces

`SurfaceSeparation.ts` inspects the positioned faces before generating foundations.
It compares real face polygons for blocks, wedges (including slopes) and the
renderer’s twelve-sided cylinders, and detects coincident curved meshes.
Coplanar faces with the same outward direction and a genuine area overlap are
separated. Edge contacts and opposite-facing joints are excluded.

Larger structural pieces take priority; smaller details receive translations in
0.012-stud increments along the conflicting surface normals. Collision surfaces
and attached text follow the same transform. The completed stage moves 2,423
source parts, with a largest translation of 0.06 studs. This is computed from each
stage's active geometry, including optional cosmetics, rather than applying one
fixed offset that might only work at the final stage.
The renderer also uses logarithmic depth so these small separations remain useful
when looking across the full campus rather than only at nearby objects.

The [surface audit](surface-audit.json) covers all 241 build states, with no
unresolved pairs under the positional detector. Its plane tolerance is 0.0015
studs, and overlap must exceed 0.01 studs to exclude touching seams. A second scan
of corrected early, middle and final stages finds no further adjustments.

```sh
npm run geometry:surfaces -- --all --write
```

## Verification

`npm run geometry:audit` checks finite transforms, positive dimensions and bounded
support heights across **all 241 states (0–240)**. The saved
[audit report](geometry-audit.json) also records the source fingerprint and the
completed MCP comparison. To repeat that comparison after collecting fresh export
chunks in `.editor-cache/studio-geometry-*.b64`, run:

```sh
npm run geometry:audit -- --studio --write
```

The geometry tests check roof dependencies, unchanged native geometry, connected
support endpoints, tripod feet, runtime collision construction and all four desk
legs resting on the active floor at opening and mature stages. Existing gameplay
tests cover walking, vehicle collision and dealership progression.

Studio screenshots and rendered web views of the early owner corner and completed
campus were inspected. Positional scans cannot prove the absence of every
distance-dependent GPU depth artifact or every unsupported decorative assembly;
the report records the geometric cases actually checked.
