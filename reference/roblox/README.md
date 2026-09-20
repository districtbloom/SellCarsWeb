# Sell Cars Integration source snapshot

Read from the open Studio Edit model on 2026-09-16, place **105869926920733**.
`manifest.json` records the 171 exported script paths and original enabled/disabled
flags. Script folders reproduce their Studio service paths. Nested recovery and
comparison archives are excluded; the current scripts, including disabled prior
prototypes and authoring installers, are retained for reference.

The active gameplay entry points in this place are `HubServer` and `HubClient`.
The enabled V5 review/ambience scripts return immediately because their place ID
guard targets a different place. The TypeScript port follows the active Hub loop.

`scene/*.b64` contains all 25,446 BaseParts from
`Workspace.SellCars_Dealership_FullJourney`, in stable export order. Each batch is
base64-encoded Zstandard JSON, including original paths, transforms, shapes,
colors/materials, collision flags, attributes, SpecialMeshes and sign text.
The raw capture preserves metadata beyond that currently consumed by the port.

`model-parity.luau` is the reference four-car scenario. Its result, captured from
the original pure Luau model in Studio, is checked in at
`scripts/fixtures/tycoon-roblox.json`. No live player or place state was used by
the scenario. The TypeScript tests compare its balances, ledger, conditions,
staff and complete car histories with the same action sequence.

These files are reference material. No Luau is evaluated by the web application.
