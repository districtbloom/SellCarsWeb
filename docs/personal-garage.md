# Dealership staff and personal collection

Dealership characters now have name labels above their heads. Sellers and buyers
show the current deal person's name; the core staff are Jo, Manny, Riley and Avery.
The imported supporting cast also has named labels.

Once a mechanic is hired, buying a car is enough to start repair preparation.
The mechanic chooses the Quick plan, purchases missing Parts using the dealership's
cash, starts each job, finishes any partially manual job, and sends the completed
car toward the selling area. The manual-deals switch no longer disables hired
repair staff. If repair funds are short, work waits and resumes automatically when
cash is available. Repair charges and Parts purchases still appear in the ledger.

## Keeping cars

Walk near your repaired car **while it is travelling to the selling area** and
press **E · Keep as personal car**. It disappears in a cloud and plays the
`garage.store` cue. The car enters your saved collection without awarding sale
income. Consignment cars show their ownership and unpaid repair settlement cost
in the prompt; that cost must be covered before the car can be kept.

The transfer is saved before the visual or sound effect plays. Failed saves keep
the original car and cannot create a duplicate. Keeping the tutorial car also
finishes the tutorial so the business can continue.

## Browsing, spawning and paint

Press E at the **Personal Garage** entrance sign, or use the **Garage** button.
The left/right buttons and arrow keys browse every owned vehicle individually.
Two cars of the same model can coexist; each receives a permanent generated name
and a separate saved ID. For example, Amber Comet 001 and Midnight Comet 002 are
different vehicles even if both use the compact model.

**Spawn at garage** brings the selected car to the garage. **Respawn at garage**
returns the active car there. One physical personal car is active at a time; all
others remain owned. **Go to car** walks to its entry point. The garage entrance
sign is offset from the parking spot so it does not consume E when entering a car.

Eight paint buttons update the preview and save the color for that specific car.
An active personal car updates immediately. Paint uses private material copies,
including the imported emissive tint, without recoloring other owned instances,
glass, wheels, or shared source assets. Paint changes and respawns are free.

Old saves that owned cars by model are projected into the collection and retain
their selected car and entitlement. **Browse cars to buy** opens the existing
fourteen-model showroom.

To replace the storage poof sound, set the `garage.store` file in
[`public/audio/sound-map.json`](../public/audio/sound-map.json) to your MP3 filename
and put that file in `public/audio/`. The procedural placeholder works until then.
