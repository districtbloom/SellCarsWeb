# ThreeJS TypeScript Template

## Sell Cars dealership tycoon

The [hands-on expansion](docs/tycoon-expansion.md) adds repair minigames, Parts shops,
delivery drivers, curved automatic driving, a residential driving tutorial, and
**Shift** sprint. Repair progress and delivery cargo save with your dealership.

Characters now breathe, shift their weight and look around while idle. Collisions,
repairs, purchases and other interactions have particles and distinct sound cues,
including wordless NPC chatter. See [effects and MP3 replacement instructions](docs/interaction-feedback.md)
and the editable [sound manifest](public/audio/sound-map.json).

The dealership geometry was rechecked against all 25,446 parts in the connected
Studio source. See [geometry alignment and stage audit](docs/geometry-alignment.md)
for the support, fixture and floor-contact corrections.

Dealership NPCs have name labels. Hired mechanics now handle the complete repair
flow. Press **E** near a repaired car travelling to sales to keep it, then browse
your named vehicles, respawn them, and change paint at the **Personal Garage** sign
or **Garage** button. Duplicate models are supported. See the
[staff and personal collection guide](docs/personal-garage.md).

`npm run dev` starts the Sell Cars tycoon with its $400 opening, 224 functional upgrades and 16 optional cosmetics,
recurring car deals, department work and staff automation. Integration's
customization, buyer preferences and rare Phoenix lead remain available.
Progress saves in this browser, with capped offline earnings and a repeatable
parts-sales typing job. Use **E** near interactions, **P** for the smartphone, **Enter** to answer calls, **Build** for
construction, and the guide button to walk to the next step.
**Ctrl + Shift + Backspace** deletes your tycoon save and closes the game.
If the browser keeps the tab open, the game stops on a closed screen.
Open **Garage** to browse all 14 cars with the left/right arrows, compare their
models and stats, and buy a personal car. Owned cars can be selected for free;
**Go to car** walks you over, then **E** drives it. See [car profiles and prices](docs/car-profiles.md).

See the [tycoon port guide](docs/tycoon.md) for controls, source mapping and fidelity
notes, including the supplied project bible. Open `/?journey=240` to review all 240 stages of the authored dealership,
or `/?tycoon=off` for the original walking/driving sandbox below.

## Walk and drive all 14 cars

Run `npm run dev`. You start on foot as a blue Seller-style character: **WASD / arrows** move
relative to the orbit camera and **Space** jumps. Approach any car and press **E**
when its prompt appears to drive; press **E** again to exit onto clear ground.
The on-foot camera keeps its orbit angle when idle.

While driving, use **W/S** or **Up/Down** for forward/backward drive;
**A/D** or **Left/Right** to steer; **Space** for the rear handbrake/drifting;
**R** to reset.
Every car has rear-wheel drive, suspension, drifting and a third-person chase camera,
with distinct [power and handling profiles](docs/car-profiles.md) editable in scene JSON.
Click the game to capture/hide the mouse; press **Esc** to release it.
Move the captured mouse to orbit and scroll to zoom; the camera returns to following after
two seconds without mouse input.
See the [driving guide](docs/driving.md) for tuning and editor requirements.

## Open world

Follow the paved road out of the dealership into Maple County. Its street grid
connects 40 suburban homes with garages, 12 shops, a service district, and parks
with walking pedestrians. Houses vary in size, height, and color; the seeded
layout stays the same between visits. Buildings currently have solid exteriors.

Walking automatically steps over curbs and ledges up to **0.5 scene units**
when there is headroom. The player and NPCs share a Seller-style block model
with opposite arm/leg swings while moving and a smooth return to idle.
Town scenery uses instanced geometry, distance culling, and simple colliders.

## Visual scene editing

Run `npm run editor` and open <http://127.0.0.1:5174/> to edit the cars, materials,
lights and camera in the local Three.js Editor. Choose **File > Export Scene**,
save the result as `public/scenes/main.scene.json`, and refresh `npm run dev`.

The JSON is the source of truth for the scene. See the [artist workflow](docs/artist-workflow.md)
for camera setup, saving, and preview instructions. The editor version matches the
installed Three.js runtime and is downloaded locally on first use.

The motivation behind this repository is to provide an idea for a good structure for a threejs application. The structure is oriented on the book [Discover three.js](https://discoverthreejs.com/book) with the key difference that it uses typescript.

I've always struggled to find a sophisticated structure for my threejs apps because I always ended up in a centralized explicit configuration of the scene. If we imagine that the objects in the scene form a tree structure, it would be nice if the components only have knowledge about their direct parents or children.

Another important aspect of this setup is, that it hides the three.js components behind the `World` interface. This makes it compatible to any framework, like Angular or React, and ensures that there is a clear boundary between "Web"- and "Three"-development.

### Setup

This repository uses [vite](https://vitejs.dev/). Install the dependencies as usual with

```
npm install
```

then you can run the app  with

```
npm run dev
```

in development mode.

### Build and deployment

You can build the app with

```
npm run build
```

or run the compiled app in preview mode with

```
npm run preview
```

To make a single HTML file that opens directly in a browser, including offline:

```
npm run build:standalone
```

Double-click `dist-standalone/game.html`. You can copy that file anywhere; it
contains the JavaScript, CSS, scene, models, textures, and game data. No server
or adjacent asset folder is required. Use a current Chrome, Edge, Firefox, or
Safari with WebGL and `DecompressionStream` support. The embedded assets are
compressed, so initial loading may take a few seconds. Rebuild after changing
code or files in `public/`. Browser saves may be separate from the hosted game
and may change when you move or rename the HTML file.

## Documentation

### World

The world provides an interface for non three developers to interact with the three scene. The world is the *root* scene. Here you can create cameras, the renderer, the loop (if necessary), lights, controls and objects that you want to put on your scene. It exposes three functions `render`, `start` and `stop`.

The render function is used to render the scene. This can happen either in the animationFrame loop or on user input. Use the `start` and `stop` methods if you want to start and stop the loop.

### CSG

There is the possibility to use constructive solid geometry (CSG) with three.js and TypeScript. CSG allows the user to union, intersect or subtract meshes from each. This allows the user to create much more complicated shapes easily. You can use the library [three-csg-ts](https://www.npmjs.com/package/three-csg-ts).

```ts
import { Mesh, BoxGeometry, SphereGeometry } from 'three';
import { CSG } from 'three-csg-ts';

const box = new Mesh(new BoxGeometry(2, 2, 2));
const sphere = new Mesh(new SphereGeometry(1.2, 8, 8));
box.updateMatrix();
sphere.updateMatrix();

const subRes = CSG.subtract(box, sphere);
const uniRes = CSG.union(box, sphere);
const intRes = CSG.intersect(box, sphere);
```
