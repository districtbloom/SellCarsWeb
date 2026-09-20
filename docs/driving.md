# Walking and driving the car lineup

Run `npm run dev` and open the game. You start as a blue block player beside
Car 14. Click the game to capture the invisible mouse, then use WASD or the arrow
keys to walk relative to the orbit camera; Space jumps. Moving the mouse orbits
the player and scrolling zooms. The on-foot camera keeps its angle when idle.

Approach any of the 14 cars to see its **[E] Drive** prompt and estimated horsepower.
The nearest eligible car receives the prompt. Press E to enter and switch
to the car controls below. Press E again to exit onto clear ground beside the car.
Entry requires being within two meters of the chassis, with no wall in between,
and the car moving slower than two meters per second. Exit tries both sides and
both ends; if all are obstructed or unsupported, move the car and try again.
Empty cars apply their handbrakes but remain dynamic: collisions can push them.
R respawns the player near the last selected car while on foot, or resets that car
to its authored pose while driving. The initial player spawn remains beside Car 14.

The block uses an upright rigid-body collider, gravity, collision and grounded
jumping in the same physics world as the car. It is a basic walking controller;
automatic stair climbing and character animation are not implemented.

While driving:

| Key | Action |
| --- | --- |
| W / Up | Apply forward drive force |
| S / Down | Apply backward drive force |
| A / Left, D / Right | Steer the front wheels |
| Space | Rear-wheel handbrake; initiate a drift while turning at speed |
| E | Exit the vehicle |
| R | Reset the current car to its authored spawn pose |
| Click the game | Capture and hide the mouse |
| Move captured mouse | Orbit around the car |
| Mouse wheel | Zoom the orbit camera |
| Esc | Release the mouse cursor |

Releasing the accelerator lets the car slow through rolling resistance and engine
braking. Forward/backward input directly requests opposing tire force, with no
gear selection or automatic brake-before-reverse stage. The car still slows and
changes direction physically; velocity is never flipped instantly. Both directions
use the same cruising force and speed limit. Switching from reverse to forward
uses three times the throttle response and opposing tire force until the car
stops reversing, then returns to normal forward power.

Space is a **rear-wheel handbrake**. It cuts drive force and locks the rear axle,
leaving the front tires free to steer. Above about 25 km/h, existing yaw (rotation
around the car's up axis) progressively reduces rear grip, reaching 65% of normal
grip at higher speed/rotation. Momentum carries the rear sideways. Release Space
and countersteer to recover; grip returns progressively. At low speed or while
driving straight, Space slows/holds the car without inventing a turn. There is no
scripted yaw kick or lateral velocity assignment.

Throttle and steering build progressively. Steering response and recentering are
twice as fast as the previous setup (response rate 24 instead of 12),
with the same maximum lock. Steering lock still decreases with speed.

On PC, **click the game once** to capture the mouse using browser pointer lock.
The cursor is invisible and relative motion continues without hitting screen
edges. Move the mouse to orbit without holding a button; scroll to zoom. Press
**Esc** to release, and click again to re-capture. Unlocked mouse movement does
not rotate the camera. Browsers require the click gesture for capture; failed
capture shows a retry hint instead of hiding an unlocked cursor.

After **two seconds without mouse movement or
scrolling**, the camera smoothly returns behind the car. Driving keys do not keep
orbit mode active. Camera collision checks remain active in both modes. Switching
tabs clears held keys, and R also resets the camera to chase mode.

## What is simulated

`cannon-es` integrates all 14 rigid chassis under gravity in one world at 120 fixed
steps per second. Each car has its own mass and handling profile; Car 14 is 1,200 kg.
Four downward wheel rays per car find tire contact points. Each contact has spring
stiffness, compression damping, rebound damping, travel limits and tire grip.
Rear-wheel engine forces and tire friction impulses act at the contact points;
front-wheel steering changes the tire force direction. The handbrake locks the
rear wheels, with speed/yaw-dependent grip reduction and smooth grip recovery.
The car can coast, collide, bounce, lose grip and become airborne. Mesh transforms
only display the simulated chassis and wheel poses. Reset is an explicit teleport.

Suspension contact rays include the full configured extension travel, and wheels
extend when unsupported. The HUD reports front and rear contacts separately.
Grounded rear tires can drive with both front tires airborne. The front wheels
still visually steer in the air, but cannot generate a turning force without
ground contact. A chassis resting against an obstacle can still prevent movement.

Solid contact friction between car bodies and scenery or other cars is 0.4 / 3
(about 0.1333), one-third of the original value. Raycast tire grip is unchanged.

This provides Roblox-style suspension/driving behavior using **raycast wheels**.
It is not a full assembly of independently colliding wheel bodies, motors and
cylindrical joints. Wheel spin follows rolling/slip in the vehicle model; wheel
rays approximate tire contact. The chassis and scenery use box colliders. This
keeps the initial controller stable, but sharp curbs and wall/tire contact are
less detailed than a fully jointed vehicle. There is no gearbox or drivetrain
damage model.

Reference: [Cannon RaycastVehicle](https://pmndrs.github.io/cannon-es/docs/classes/RaycastVehicle.html).
Roblox's corresponding mechanical approach combines
[cylindrical constraints and springs](https://create.roblox.com/docs/physics/constraints/cylindrical).

## Artist workflow

Keep the JSON export workflow: `npm run editor`, edit, **File > Export Scene**, save
over `public/scenes/main.scene.json`, then refresh the game. Exporting a scene does
not save the car's position after a play session.

- Keep one group each named **Car 1** through **Car 14**. Their authored transforms
  are their spawn/reset poses.
- Keep each car's numbered wheel names: **WheelflN**, **WheelfrN**, **WheelrlN**,
  **WheelrrN**, where N is its car number. The front pair steer; the rear pair drive.
  Every model faces local -Z.
- Move the whole car or use a positive **uniform scale**. Wheel centers and radii
  are read from the meshes; the exported geometry's off-center origins are handled.
- The scene uses a conversion of **0.25 meters per scene unit** for physics. This
  puts the approximately 17-unit-long car at a plausible 4.25 meters.
- **MainCamera** must remain a perspective camera in the scene. In driving mode,
  the chase controller sets its runtime pose and FOV; its authored overview pose
  is useful in the editor but no longer controls the gameplay view.
- **Driving course** contains the ground, yellow suspension bumps and ramp. They
  are ordinary editable scene objects. Avoid placing a solid object over the spawn.
- A scenery mesh with User data `{"collider":"box"}` becomes a static oriented box
  collider based on its bounds. Use box-shaped meshes; complex shapes get an
  approximation. Keep collider scales positive and avoid nesting tagged colliders.
- Keep a ground mesh with User data
  `{"collider":"box","drivingGround":true}`. Ground top is initially Y = 0.
- All cars have dynamic chassis and suspension, including when unoccupied.
  Do not add separate scenery colliders inside a car group.

## Tune handling

Select any car and edit its **User data → vehicle** object. The supplied scene
contains individual profiles for all 14 cars. Save and refresh to apply changes.
See [car profiles](car-profiles.md) for the estimated power, weight and speed table.
The defaults below describe Car 14; the other cars have different values.

| Setting | Default | Effect |
| --- | ---: | --- |
| `mass` | 1200 | Chassis mass in kg |
| `horsepower` | 150 | Estimated power ceiling; limits drive force at speed using power / speed |
| `engineForce` | 5200 | Total rear-wheel drive force in newtons before speed falloff |
| `brakeForce` | 30000 | Total rear handbrake force converted into per-step impulses |
| `maxSpeedKmh` | 130 | Speed in either requested direction where drive force falls to zero |
| `maxSteer` | 0.48 | Low-speed steering limit in radians (about 27.5 degrees) |
| `suspensionRestLength` | 0.3 | Uncompressed suspension length in meters |
| `suspensionStiffness` | 35 | Cannon's mass-normalized suspension stiffness |
| `dampingCompression` | 4.4 | Damping while suspension compresses |
| `dampingRelaxation` | 5.2 | Damping while suspension extends |
| `suspensionTravel` | 0.2 | Travel limit around rest length in meters |
| `tireGrip` | 2.2 | Cannon tire friction/slip limit |

These values must be positive numbers. Stiffness and damping use Cannon vehicle
units, not Roblox SpringConstraint values. Retune suspension when changing scale.
There is no separate reverse speed cap.

## Verification and code

`npm test` checks spring equilibrium, acceleration/coasting/braking, signed forward/backward drive,
steering, loss of traction in the air, frame-rate independence, uneven suspension,
collision, reset and the actual authored wheel geometry. Node tests substitute
image decoding; they do not verify GPU rendering or how driving feels. Camera tests
cover pointer capture/release/failure, relative mouse movement, orbit input, zoom,
idle return, moving targets, collision and reset. Drift tests check actual lateral
slip, yaw, retained momentum, front/rear grip differences, recovery, and no fake
rotation when straight, slow or airborne.

- `src/world/driving/VehiclePhysics.ts`: physics, tuning and controls-to-forces logic.
- `src/world/driving/CarProfiles.ts`: individual car defaults, overridden by scene User data.
- `src/world/driving/CarInstance.ts`: each car's physics and visual wheel rig.
- `src/world/driving/SuspensionVehicle.ts`: suspension raycasts using full extension travel.
- `src/world/driving/CarRig.ts`: reads the artist's car/wheel geometry and spawn pose.
- `src/world/driving/DrivingSystem.ts`: scene colliders, wheel visuals, chase camera and HUD.
- `src/world/driving/DrivingInput.ts`: keyboard input and focus handling.
- `src/world/driving/SmartFollowCamera.ts`: mouse orbit, zoom and automatic chase return.
- `src/world/systems/loop.ts`: frame deltas; physics maintains its own fixed timestep.
