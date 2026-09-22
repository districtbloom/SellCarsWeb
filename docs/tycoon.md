# Sell Cars TypeScript tycoon

Run `npm run dev` and open <http://127.0.0.1:5173/>. A new game uses the
**Sell Cars** FullJourney setup: **$400**, 240 sequential purchases, and the
Rusty tutorial. The existing player controller and 14-car driving scene remain
available. Dealer stock follows business routes; the player does not drive it.

Walk onto purchase pads or press **E** nearby. Green arrows point to the next
world objective, menu button or repair action. The HUD dialog introduces the
game and first phone call. **Build** opens the next
purchase, **P** opens the phone, and **Esc** closes a panel. Phone → Home guides
you to the Hill Drive laptop. Phone → Team can pause staff automation; Phone →
Deals can pause arrivals and request an ordinary or special deal.

**Garage** opens the personal-car picker: left/right arrows change the actual
3D model, with live driving stats and 14 distinct prices. Purchases and ownership
save; selecting an owned car is free. **Go to car** walks to the selected car and
**E** drives it using the existing controller. Prices, controls and old-coupe
compatibility are documented in [car profiles](car-profiles.md#personal-garage).

**Ctrl + Shift + Backspace** immediately resets the save and closes the game.
It removes both current and legacy tycoon saves, disables further saving, and
stops the simulation. If the browser refuses to close the tab, a closed screen
remains; reload for a fresh start. The shortcut ignores typing and held-key repeats.
Temporary runs (`?save=off` or `?journey=...`) and the driving sandbox close without
touching the normal save. A failed deletion keeps the game open and reports the error.

## Source and merge decisions

The active source is **Sell Cars**, place **104040320298951**, read from Studio
Edit without modifying the place. Its active `FullJourneySystem` supersedes its
disabled `TycoonBootstrap`. The new source archive is
`reference/roblox-sell-cars/`; the earlier Integration archive remains under
`reference/roblox/`.

The user-provided [Project Bible](../reference/roblox-sell-cars/PROJECT_BIBLE_EN.md)
is preserved verbatim. It is a dated reference, not a fresh implementation audit.
Its older $3,300/99-pad progression differs from the open build's $400/240-step
runtime. Executable FullJourney code determines this port's progression; older
DataService and StationService supply the missing offline and parts-sales loops.

### Playable FullJourney

- All 240 stable purchase IDs, titles, chapter/milestone descriptions, original
  costs, suggested pad positions, prerequisites and 92 capability thresholds.
- Source tutorial gates: claim and seller corner → buy Rusty for $25 → repair
  kit → manually repair Engine then Wheels → wash caddy, photo listing and Manny
  → manually accept the $1,000 sale. Source FullJourney repairs are free;
  six construction purchases total $150, leaving **$1,225** after that sale.
- Repeating Rusty/Hondo stock, Bavora at step 90, and G-Block resolved from its
  stable wash-enclosure unlock ID (currently step 72).
- Source purchase-price and sale-profit formulas, single 10% acquisition haggle
  and 5% sale increase, seller refusal, replacement buyers, and zero-deposit
  consignment with 75% of service profit. An open offer stays fixed even if
  construction advances.
- Source CIRC02 arrival/opening routes, permanent mechanical-bay relocation,
  rear cross-lane routing, and Wash → Body → Tune → Paint → Detail → Photo
  departments as they become available.
- Manny listing transport at 6, car buyer at 29, sales advisor at 33, mechanic at
  40 and specialists at their original thresholds. Until a specialist is hired,
  the player performs that department's service.
- Live staged geometry, safe pad placement, physical purchases and guided
  walking. The construction sequence is no longer just a visual preview.
- Car discovery index, receipts, transaction history and factual rolling
  business revenue over the last 60 seconds.

FullJourney's current source operates **one dealer car at a time**, even though
its catalog declares future capacity upgrades. This port keeps that boundary.
Capacity values and architectural unlocks are exported faithfully; they do not
silently create older multi-car queues.

### Integration features retained

The newer Integration work remains: Quick/Good work plans, upfront repair
funding and protected work money, Jo's training, paint/wheels/stripe choices,
enthusiast/collector preferences, Maya's lowball buyer and replacement, Nora's
City Hatch, photo/listing, the personal coupe, Elias's Phoenix reveal and
pickup/return trip, and the $300 visited-lead discount.

Maya and Nora are available from Phone → Deals after the finish capability;
the personal coupe/rare lead unlock at step 22. Special deals keep their
Integration prices and conditions, using the expanded dealership's repair and
sales routes. Pause ordinary arrivals while arranging a special deal, and use
manual mode to take over from hired staff.

The optional Good plan adds Integration's $220 finishing job; its premium uses
the corresponding Integration car archetype's original Quick/Good offer
difference. The normal Quick business cycle keeps Sell Cars' source economics.

The original 20-pad/$7,000 Integration opening remains available for comparison
at `?opening=integration&save=off`; its four-car Luau fixture still ends at
$10,220. The default is the merged Sell Cars progression.

### Parts sales and offline earnings

The opening manual job point now opens [Hill Drive](city-activities.md), a
30-second hill-driving game paying **distance × $2**. It needs no inventory
purchase. Time pickups add five seconds; crashes and timeout finish the round.
Cancelled rounds do not pay or resume. Existing mechanic side income remains
**$28 per batch**, plus **$16 per level**, with 20 levels and upgrade costs of
`floor(220 * 1.35^(level - 1))`. These upgrades do not change minigame rewards.

Offline earnings follow the older DataService:

- Completed tutorial, hired mechanic, and an existing saved timestamp required.
- No credit below **90 seconds**; credited absence capped at **8 hours**.
- `floor(creditedSeconds * rate)`, added before the welcome-back receipt.
- New and migrated profiles without timestamps receive no retroactive reward.
- Timestamp and money commit together; reopening cannot claim the same interval
  again. The popup only acknowledges money already credited.

The older pad IDs have an explicit bridge to new facility purchases:

| Source pad | FullJourney step | Dollars/second |
| --- | ---: | ---: |
| CashRegister | 2 | 0.12 |
| FirstSalesman | 6 | 0.35 |
| RB_CarLift | 79 | 0.85 |
| RB2_Foundation | 126 | 0.55 |
| CW_BrushMachine | 41 | 1.35 |
| CW2_BrushMachine | 124 | 1.35 |
| TA_DynoRollers | 91 | 2.25 |
| TA_BodyKitStation | 46 | 2.75 |
| TA_PaintControl | 97 | 3.15 |

These facility correspondences are integration choices; FullJourneyProfiles
does not itself consume the old offline table. Previously owned Integration
intake/sales-desk/mechanic abilities also count.

## Saving and compatibility

The browser stores a version-2 envelope at `sell-cars.tycoon.v2`, including
economy, construction step, jobs, routes, tutorial, personal car, leads,
cosmetics, ledger, parts station, timestamp, revision and renewable session lease.
Transactions save immediately; background progress autosaves every five seconds.
Closing/hiding releases the lease and suspends simulation. Returning reloads
the latest saved state and settles offline time.

`sell-cars-integration.tycoon.v1` migrates automatically and remains as a backup.
Migration preserves cash, owned pads/abilities, cars, paid work, routes,
customization, staff and leads. It grants a corresponding completed opening
prefix without charging, and retains older owned construction art. This
deliberately resumes paid work rather than refunding/restarting unfinished cars
as the source FullJourney profile does.

Invalid or unsupported saves are not overwritten with blank data. Failed
durable player transactions roll back. Failed offline writes do not grant
uncommitted income. A best-effort browser lease prevents sequential tabs from
overwriting one another; it is not a cross-server transactional datastore.

This is a **single-player browser implementation**. Local storage and device
time are not authoritative accounts, cloud saves, or anti-cheat. A multiplayer
host must own the session and replace the storage adapter. Roblox production
player DataStores are not accessed.

- `?save=off`: temporary fresh run, no normal save read or write.
- `?tycoon=off`: original driving sandbox.
- `?journey=240`: unsaved architectural review, all 240 stages selectable.

## Assets, structure and broader systems

The **25,446-part** dealership import was cross-checked against Sell Cars'
per-stage part counts and aggregate canonical positions/sizes with no
differences. It retains clipping, moves, retirements, material transitions,
signs and collision. Parts are instanced by shape/material. Source
`(3035, 1.43, 112)` maps to scene `(-300, 0, 100)`; one stud remains one scene unit.

| TypeScript file | Responsibility |
| --- | --- |
| FullJourneyCatalog.ts / journeyData.ts | Source catalog, costs, capabilities, service thresholds |
| FullJourney.ts | Tutorial gates, compatibility, work plans, stock selection, routes |
| TycoonModel.ts / TycoonSession.ts | Economy and gameplay state; validated actions |
| PartsStation.ts / OfflineEarnings.ts | Parts work, offline settlement, revenue window |
| TycoonSave.ts | Versioning, migration, persistence and browser session ownership |
| BuildingProgression.ts / TycoonEnvironment.ts | Construction, rendering, collision, pad placement |
| TycoonActors.ts / TycoonHUD.ts / TycoonGuidance.ts | World activity, phone, progression, interactions |
| TycoonSystem.ts | Controller integration, input/camera ownership, save lifecycle |

The broader legacy game in the bible also has independent street-customer
service queues, towing, phone fence, the legacy personal-car resale market and detailed
cosmetics, multiplayer racing, radio/weather, monetization and telemetry. The
older queue, market and racing systems are disabled by the source's current
FullJourney migration and are **not claimed as playable ports here**. Relevant
tycoon sources/configs are archived for subsequent integration. This pass
implements the active FullJourney business, retains Integration additions and
supplies save/offline/parts groundwork.

UI is a DOM adaptation with phone/short-landscape and tablet sizing. Trading
cars and people still use Integration's primitive presentation; the detailed
controller fleet is unchanged. Native Roblox textures, rig animation,
cinematics, audio, effects and asset packaging remain polish/integration work.
The scene JSON is about 27 MB before HTTP compression, plus the controller scene.

## Regeneration and verification

`npm run tycoon:data` regenerates both catalogs from archived Luau, with Sell
Cars journey data taking precedence. `node scripts/unpack-sell-cars.mjs <file.b64>`
unpacks source captures using Node 24's Zstandard support.
`node scripts/unpack-tycoon.mjs` rebuilds the environment.

`npm test` covers executable-Luau parity for 240 purchases and 241 capability
states; both tutorials with real player/car physics and imported collision;
affordability of the full progression; staff, departments, consignment,
transaction guards, parts jobs, save migration, offline boundaries, duplicate
settlement, failed writes and tab ownership. The Integration four-car fixture
and controller/vehicle/camera tests also run. `npm run build` checks strict
TypeScript and the production bundle.

World tests construct real gameplay/physics classes with minimal DOM services
in Node. They are not browser/GPU screenshots or device acceptance. Rendered
mobile/tablet/desktop visual QA remains outstanding because no browser surface
is available through the connected computer tools.
