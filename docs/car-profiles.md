# Car profiles

These are visual/gameplay estimates based on the supplied screenshot, not identified
real vehicles or manufacturer specifications. Screenshot order is Car 14 on the left
to Car 1 on the right. All retain rear-wheel drive and the same controls.

| Car | Visual profile | Estimated hp | Mass (kg) | Speed setting (km/h) | Peak drive force (N) |
| --- | --- | ---: | ---: | ---: | ---: |
| 14 | Everyday sedan | 150 | 1200 | 130 | 5200 |
| 13 | Boxy sedan | 125 | 1250 | 145 | 4700 |
| 12 | Sport coupe | 230 | 1300 | 205 | 7200 |
| 11 | Tall off-roader | 220 | 2050 | 150 | 8200 |
| 10 | City hatchback | 105 | 1050 | 140 | 4300 |
| 9 | Older compact | 85 | 1000 | 120 | 3700 |
| 8 | Family minivan | 180 | 1650 | 155 | 6500 |
| 7 | Boxy van | 140 | 1800 | 135 | 6000 |
| 6 | Sports roadster | 300 | 1250 | 230 | 8500 |
| 5 | Compact off-roader | 165 | 1550 | 140 | 6500 |
| 4 | Utility pickup | 240 | 2000 | 155 | 8500 |
| 3 | Tow truck | 260 | 2900 | 125 | 11000 |
| 2 | Heavy pickup | 320 | 2350 | 165 | 10000 |
| 1 | Track racer | 650 | 1150 | 280 | 12500 |

Profiles also vary steering lock, tire grip, suspension length/stiffness/travel,
damping and braking force. Compacts are light and modestly powered, trucks are
heavier with longer suspension, and sports cars are firmer and grippier.

Horsepower sets a power ceiling on drive force at speed (hp × 745.7 / speed).
Low-speed force is limited by engineForce, and force tapers toward maxSpeedKmh.
The speed setting is a drive-force limit, not a guaranteed measured top speed;
traction, mass, slope and collisions affect actual performance. Reverse-to-forward
boost, handbrake drift and steering response are shared with Car 14.

Select any Car N group in the editor, edit User data → vehicle, export the scene
to public/scenes/main.scene.json and refresh. Explicit scene values override
src/world/driving/CarProfiles.ts defaults. Existing artist values are preserved by
the scene-seeding/course script; it only supplies missing profile settings.

## Dealership flip cars

Flip cars use complete copies of the authored assets, including their textures,
lights, glass, interiors, and wheels. The mapping in
`src/world/tycoon/TradingCarVisual.ts` keeps model choice separate from deal
economics and saved progress:

| Deal car | Asset | Role |
| --- | --- | --- |
| Rusty / Rusty Sedan | Car 9 · Older compact | Common starter project |
| City Hatch / Hondo Civix EK | Car 10 · City hatchback | Common everyday car |
| Desert Coupe | Car 12 · Sport coupe | Uncommon enthusiast car |
| Bavora | Car 14 · Everyday sedan | Uncommon recurring sedan |
| G-Block | Car 11 · Tall off-roader | Progression-unlocked utility car |
| 1972 Phoenix GT | Car 6 · Sports roadster | Rare collector deal |

These are visual stand-ins from the available asset pack; story names, rarity,
prices, unlocks, repairs, and sale values stay with the existing deal definitions.
The scripted cars retain their full size and face along their travel routes.
Rusty's actual front-left wheel stays hidden until repaired. Paint and wheel
previews use private materials, with stripes projected onto the body; they never
repaint the personal garage or dispose its shared textures and geometry.

## Personal garage

Open **Garage** in the tycoon HUD (or **Phone → Garage → Choose your car**).
The left/right buttons and arrow keys cycle all 14 complete authored models on a
rotating 3D preview. The card uses each live car's horsepower, speed target and
mass, including scene overrides. **Buy & use** pays once and selects the car;
**Use this car** switches to a previously purchased car for free. **Bring to garage**
recalls the selected car, and **Go to car** walks to an entry point. Use **E** to
drive with the existing physics controller. Purchases open after the first sale,
reserve current work money, and require stepping out of a car.

| Car | Personal-car price |
| --- | ---: |
| 9 · Older compact | $1,500 |
| 10 · City hatchback | $2,400 |
| 13 · Boxy sedan | $3,200 |
| 14 · Everyday sedan | $3,900 |
| 7 · Boxy van | $4,800 |
| 8 · Family minivan | $6,200 |
| 5 · Compact off-roader | $7,400 |
| 4 · Utility pickup | $9,800 |
| 11 · Tall off-roader | $11,800 |
| 3 · Tow truck | $13,500 |
| 12 · Sport coupe | $16,500 |
| 2 · Heavy pickup | $21,000 |
| 6 · Sports roadster | $28,500 |
| 1 · Track racer | $65,000 |

These are initial game-balance prices based on the established visual categories,
power, speed, weight and utility. Edit
`src/world/tycoon/PersonalCars.ts` to rebalance them.

The collection, active model and parking pose save with the dealership. Existing
personal-coupe saves and the original display reward map to **Car 12**, without a
new charge. Reaching the display milestone after buying another car keeps that
selection and still unlocks the rare lead. The selected model also replaces the
placeholder on the guided Elias trip. The original 14-car sandbox remains available;
the garage reuses those physical instances rather than spawning duplicate vehicles.
