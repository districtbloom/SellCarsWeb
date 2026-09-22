# Hands-on dealership expansion

The game remains the local Three.js port. Start it with `npm run dev` (on this Windows shell, use `npm.cmd run dev`).

## Playing

- Hold **Shift** while walking to sprint. The distance-driven character animation naturally speeds up. The former walking/driving status panel is removed.
- Interactions appear above their world objects. Follow the objective arrow and use **E** at the current objective.
- Manual repairs highlight a spatial region of the car, with the interaction billboard anchored above the actual vehicle. Every interaction starts with a two-second two-handed latch/lift pose with no accompanying UI. The workbench appears afterward. Action animations lock the exact starting camera position, orientation, and zoom, and retain that view afterward until movement or mouse input. Repair opening, typing, negotiations, and rare-car discovery have no camera cutaway. **Esc** closes the repair; completed work remains saved, and reopening repeats the access animation.
- Wheels: place all four wheels, then click seven bolts per wheel. Bolts complete immediately; the moving power tool is visual feedback.
- Engine: remove one central drain bolt, wait for the oil to drain, then remove the darker used filter. Pick up the new white cylindrical filter and click the empty socket to install it. Filling remains locked until the replacement is fitted. There is no drain pan. Hold the mouse to tip the oil bottle 45 degrees, or drag its tip above the solid funnel on touch. Oil starts at the bottle tip and fills only when that tip is above the funnel mouth. Misses fall straight down without a penalty. The engine shifts lower during filling to leave room above the funnel.
- Tuning: remove the old air filter and four spark plugs, select a replacement from the tray, and click the matching empty socket to install it. The new blue high-flow filter and gold iridium plugs are visibly larger than the old components. Each removal and installation saves independently; choosing the wrong component does not lose progress.
- Body, wash, paint, detailing and listing jobs have their own themed six-area workbenches. Hired mechanics still complete their assigned work automatically.
- New work orders keep required damaged-part repairs, randomly select extra minigames, and shuffle their order. Good flips include tuning and more tasks than Quick flips; worse wear favors larger workloads. The first lesson keeps its engine and wheel repairs in varied order. Selected listing photos always come last. The flip selector shows a task-count range, while the quoted money, Parts, duration, and profit stay fixed. Accepted orders save their exact tasks, so reopening or reloading cannot reroll them.
- Your first personal car appears in the personal garage beside the dealership, with no placeholder car. Accept Elias's lead through the phone, drive to the residential destination in Maple Heights, park, and walk to the seller. Drive back and step out at the dealership afterward.
- **P** raises the smartphone from the bottom-right. An incoming call raises it automatically; **Enter** accepts and opens the conversation. A reminder postpones the call by five minutes. The Phoenix asks $2,200 delivered, or $1,900 when collected. Its first call waits until cash covers delivery, the basic repair, and any necessary Parts bundles. Ordinary sellers continue while the offer is pending; delivery can queue behind an active flip.
- Green purchase buttons are Money-making or Architectural; blue ones are Cosmetic. Each button sits on a larger base and shows its category nearby on its own line, colored to match the button. The construction guide follows 224 functional upgrades; 16 cosmetic purchases are optional and never block them. Former sales displays become customer parking.
- The parts laptop now opens [Hill Drive](city-activities.md): a 30-second hill-driving minigame with distance × $2 rewards, time pickups and LMB/RMB controls. **Esc** forfeits an unfinished round. Laptop upgrades affect mechanic side income, not distance rewards.
- Every committed cash credit sends a copy of the HUD cash text toward the wallet, then removes it. Income and spending in the same frame still show the earned amount. Earnings during UI-free repair animations wait until the HUD returns; failed transactions do not produce a gain effect. The wallet stays visible in menus so sale receipts and offline earnings have a visible destination.
- Built staff, customers, mechanics, and delivery workers use the player's proportions. Their routines include walking, inspecting cars, talking with customers, and performing their work.
- Manny and the sales advisor approach the repair bay while work is underway and wait beside the car. When it is ready, a short photo/key handover replaces the old walk from their desks. Manny drives the car to the sale point; the advisor photographs and lists both ordinary and special flips when automation is enabled. Special-car price negotiations still belong to the player. Disabling automation keeps manual listing available.
- Jo the repairman unlocks at authored step 40, **Junior mechanic workstation**, for **$375**. He waits beside the mechanical bay and walks to the active repair. Earlier repairs are manual; turning automation off keeps business repair jobs manual even after hiring him.

## Parts and deliveries

The nut icon in the top HUD displays Parts inventory. New and migrated profiles receive 40 starter Parts. The existing salvaged-parts laptop remains a separate cash-earning activity.

One Part replaces $10 of a repair's reference cost. Up to 20% of a plan is converted to whole Parts; the remainder is paid in cash. For example, a $500 plan costs $400 and 10 Parts. The opening lesson remains free. Ordinary recurring services now have tier-scaled input costs, reimbursed in their asking prices so dealership progression remains viable. Consignment cash costs settle at sale, while its Parts must be supplied upfront.

Three Car Part Shops occupy commercial/service locations. Their simultaneous prompts offer:

| Key | Parts | Cash |
| --- | ---: | ---: |
| 1 | 10 | $100 |
| 2 | 50 | $450 |
| 3 | 200 | $1,600 |

Tap the same prompts on touch screens. The delivery-driver depot is outside the dealership toward town. Three drivers cost $600, $1,200 and $1,800. Each has a car and repeats a drive/load/return/unload routine. A run buys 50 Parts for $400; cargo is credited only on return. Drivers preserve at least $500 and current reserved work funds, and stop ordering when inventory plus incoming cargo reaches 150 Parts.

## Implementation and verification

- `VehicleRoute.ts` trims road corners into tangent-continuous curves, then steers a moving axle with a curvature-limited path follower. Cars accelerate/brake and depart bays forward or in reverse without sliding sideways. Dense path progress is serialized, so resuming does not revisit old waypoints. These remain scripted vehicles rather than full traffic AI.
- `RepairGame.ts` validates the opening gate and ordered work at the session boundary. Per-wheel/per-bolt progress and oil fill persist in the job. `RepairController.ts` provides the workbench, pointer/touch input and opening pose.
- `TradingCarVisual.ts` adds translucent region volumes without depending on separate car-part meshes.
- HUD panels and phone tabs use renderer tables; guidance uses a status table. The persistent HUD shell and inventory nodes are built once.
- Parts purchases, repair funding and delivery transactions participate in existing save rollback. The save validator accepts old profiles and validates new inventory, cargo, route and repair fields.

Run `npm test`, `npm run build` and `npm run build:standalone`. The regression suite exercises both openings, functional progression without cosmetics, optional purchases, repair inputs and persistence, smooth routes, sprint physics/animation, residential visits, shop authority, courier delivery accounting, hill-driving payouts, NPC routines, and phone reminders and affordability. Browser visual acceptance checks are in `scripts/tycoon-expansion-qa.md`; this environment currently has no connected browser, so appearance and real-device touch behavior need visual verification.
