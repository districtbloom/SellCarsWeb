# Tycoon expansion acceptance checks

Automated checks exercise actual TypeScript game models through `import-typescript.mjs`. Browser checks remain necessary for visual placement, animation quality, pointer behavior, and touch controls.

Latest automated verification on 2026-09-18: `npm.cmd test` passes all 118 tests with none skipped; production and standalone builds pass. Coverage includes actual repair DOM controls, separate oil-filter removal and installation, precise oil pouring, tuning and save migration, randomized accepted work with stable prices/profits and no reload reroll, advisor/Manny prepositioning and short handover, mechanic unlock at step 40, exact action-camera preservation and vehicle transitions, category colors, projected selling progress, cash feedback and failed-save rollback, Parts economy/deliveries, full functional progression without cosmetics, smartphone reminders, and affordable Phoenix delivery. The production build retains Vite's large-bundle warning. Browser layout and rendered appearance remain unverified because neither a connected browser nor the in-app browser was available.

## Repair and movement

- Buy the tutorial car and watch its complete trip from seller to repair bay. It must roll while changing heading, steer through corners, arrive within interaction range, and remain clear of the player and scenery.
- Start each repair from the highlighted spatial region on the car. The highlight must remain useful when no separate engine/body part mesh exists.
- For two seconds, verify both hands reach forward/down to the latches, the head looks at the hands, then the hands rise with a smaller torso/leg response. No UI may accompany the opening animation; the minigame must not appear early. Repeated interaction during opening must not start duplicate work.
- Fit all four wheel holders; clicks on occupied holders must not remove wheels or grant progress. Each wheel needs 6–8 separate bolts. Rapid clicks on different bolts must complete each clicked bolt immediately while the power-tool icon catches up visually and its nozzle aligns with each bolt.
- Engine sequence: no drain pan, one central drain bolt, visible timed oil drainage, then removal of the gray used filter. Pick up the separate white replacement and fit it into the empty socket. Repeated clicks must not duplicate progress; pouring remains unavailable until the new filter is installed. Closing/reopening preserves the removed/installed stage but clears the held replacement.
- Across multiple accepted flips, verify task selection and order vary. Required damaged-part repairs stay present, Good flips require more work, worse condition biases toward heavier workloads, and listing photos come last. Quoted cash, Parts, duration and expected profit stay fixed; reloading never rerolls an accepted order. The tutorial retains just its two repairs.
- Tuning has its own minigame: remove one old air filter and four old spark plugs, select the matching upgraded part from the tray, and install it in each empty socket. Check that wrong parts cannot install and closing/reopening preserves completed work.
- Desktop: bottle follows the cursor and tilts 45 degrees while held. Touch: bottle can be dragged and tilts automatically when its tip is correctly above the funnel. The larger solid funnel has adequate room above it. Oil must begin at the bottle tip and register only when the tip is correctly above the funnel; misses fall straight down without filling.
- Close or reload during opening, wheel fitting, bolt tightening, draining, and pouring. Resume consistently without charging twice, skipping work, duplicating rewards, or trapping movement controls.
- Confirm mechanic automation completes repairs without requiring the owner to play the minigame.

## Economy and world

- Check Parts balance uses a nut/bolt icon and repair quotes clearly show both cash and Parts before purchase, for early and late vehicle tiers.
- Buy each shop bundle with its advertised hotkey. All available bundle prompts should be simultaneously visible on the shop, and touch users should have clickable equivalents.
- Reject purchases from too far away, while seated, with insufficient spendable cash, or with an invalid bundle. Cash, Parts, and protected repair funds must remain unchanged on rejection.
- Confirm all Car Part Shops occupy commercial/service areas and remain accessible from the roads.
- Hire delivery workers outside the dealership toward town. Each must have its own vehicle, leave for a shop, collect paid stock, return, unload exactly once, and repeat only when stock/cash rules allow.
- Pause/reload during each delivery stage. Its vehicle and cargo should resume without duplicated stock, repeated collection charges, or disappearing workers.
- Check the personal-car garage is near the dealership and the placeholder car is absent. Follow the personal-car/remote-seller tutorial through manual driving. The seller and destination must be in the residential area, reachable by road; declining and returning home must remain possible.

## Interface and controls

- Neither the on-foot label nor the driving version remains on screen.
- Hold sprint while walking: distance and gait cadence increase; release restores normal speed. Sprint must not leak into driving, menus, or a canceled input after window blur.
- Seller and other nearby interaction prompts appear above their world objects, stay aligned while the camera moves, hide behind the camera/out of range, and remain legible at narrow/mobile viewport widths.
- Complete the tutorial and an ordinary sale through real controls, then reload and verify balances, upgrades, and progress persist.
- Verify green Money-making/Architectural and blue Cosmetic pad categories use a Base and smaller Button. The separate category line in the prompt matches the pad color. Tutorial guidance never demands cosmetics, and skipping every cosmetic cannot block functional progression. Old sales displays are removed or reused.
- Verify the SELL CARS PART pad has green outlined text and a smaller dynamic payout label. Manual interaction starts furious typing hands while torso/legs stay still; money arrives only after animation finishes.
- Watch the smartphone slide up from the bottom-right with caller/message. Enter accepts its offer once and opens the expected follow-up; Remind me delays the call five minutes. Ordinary sellers continue to provide income while Phoenix is pending, and Phoenix is affordable by the required progression without the optional driving discount.
- Check constructed NPCs share the player rig and visibly interact with customers/cars, including the mechanic.
- With the sales advisor hired, watch them and Manny approach during repairs and wait beside the car. When repairs finish, the advisor photographs/lists it and Manny drives it to the sale point after a short handover, without another long walk. This includes the level-60 photo department. Check that disabling automation preserves manual listing and that special-car final negotiations remain manual. The mechanic unlocks at functional step 40 and works from the repair workshop.
- Opening, typing, deal dialogs, and rare-car discovery preserve the current camera. Repair labels float over the actual car while the player still approaches a separate point beside it.
- Watch the selling progress bar above the actual player throughout typing. It must remain visible while the regular HUD is hidden, advance with the sale, and disappear on completion or cancellation.
- Confirm each successful positive cash transaction sends a temporary copy of the wallet amount from the player toward the wallet, including sales, Parts payouts, and offline income. It should disappear on arrival, remain visible during transaction dialogs, avoid replaying old earnings, and show no gain if saving the payout fails.
- Finish an action and enter a vehicle immediately: the camera must switch to the normal chase view. Moving or rotating the view after an action should restore normal camera control without a cutaway.
