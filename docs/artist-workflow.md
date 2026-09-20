# Editing the scene

The game loads `public/scenes/main.scene.json`. This file contains the objects,
geometry, materials, textures, lights, background and startup camera. The supplied
scene has all 14 cars, grouped so you can move a whole car without separating its parts.

The game now drives **Car 14** with a chase camera. See the [driving guide](driving.md)
for controls, suspension tuning, wheel names and ground/collider requirements.

## Open the editor

1. Run `npm run editor` in the project folder.
2. Open <http://127.0.0.1:5174/>. Accept the editor's prompt to load the project file.
3. The scene opens from the JSON currently saved in the project.

The editor is the official Three.js Editor, pinned to the installed Three.js
version (currently r145). Its first launch downloads it from the official GitHub
repository into `.editor-cache/`; subsequent launches use that local copy.
Use this local editor for this project instead of the continually updated online editor.
On Windows, use `npm.cmd` if PowerShell blocks `npm.ps1`.

## Make changes

- Expand **Car lineup** in the scene tree and select **Car 1**, **Car 2**, etc.
  Select the whole group to move, rotate, scale, duplicate or delete a complete car.
- Use **W**, **E**, **R** for move, rotate and scale. Press **F** to focus the selection.
- Select an individual body part to edit its material in the inspector.
  Duplicated objects can share materials: changes to a shared material affect all its users.
- Edit **Sky light**, **Sun**, or add lights. Background and fog belong to the Scene.
- Keep exactly one perspective camera named **MainCamera**. It provides the editor
  overview; the driving controller follows Car 14 and sets the runtime pose and FOV.
- The viewport camera dropdown lets you inspect **MainCamera**. Navigating the
  **Editor camera** does not change the authored camera. Select MainCamera in
  the scene tree to edit its transform and camera properties.
- MainCamera's **User data** includes `focusDistance`, the orbit pivot distance
  along its viewing direction for the authored overview. Keep it positive; driving
  uses its own chase target.

Renderer settings are maintained in TypeScript: sRGB output, physically correct
lighting, soft PCF shadows and no tone mapping. The local editor starts with the
same settings. Changes under the editor's Project/Renderer panel are not part of
an Export Scene file; change the application renderer in code if those must change.

## Export changes into the game

1. Choose **File > Export Scene** (not Export Object or Export Geometry).
2. Save the downloaded `scene.json` as **`public/scenes/main.scene.json`**, replacing
   that file. Check that the filename has no extra `(1)` or `.json` suffix.
3. Run `npm run dev` in another terminal and refresh the game page.
4. Check the result in the game; run `npm run build` when preparing a release.

The editor downloads JSON; it does not automatically write into your project.
Its browser autosave is a working copy, not a saved game scene. To resume an
unexported autosaved session, open <http://127.0.0.1:5174/editor/> without the
`#file=` fragment. Reopening the root URL offers to replace it with the disk scene.

The starter embeds its textures, so exchanging the JSON does not require the OBJ
or texture folder. Import new models/textures with the editor, wait for them to
finish loading, then export the entire scene. Files with external texture URLs
must retain accessible URLs; relative ones resolve beside `main.scene.json`.

Authored scenery placement is preserved. All 14 cars start at their authored poses
and follow physics, including when unoccupied. Select a car and edit its
**User data → vehicle** values to tune its power, mass, suspension and grip;
see [car profiles](car-profiles.md). Preserve the numbered car and wheel names.
The player starts on foot beside Car 14 and can enter any car with E. The game
camera switches between player orbit and car follow and adjusts to the window.

## Developer notes

- `src/world/authoredScene.ts` loads scene JSON (and also accepts a project wrapper
  with a `scene` field), validates MainCamera, and derives the orbit target.
- Editor scripts are not executed by the game. Keep behavior in TypeScript.
  Animation clips may be present in the scene; automatic playback needs runtime code.
- `npm test` checks scene export round trips, camera handling and asset references.
- The starter is approximately 28 MB because JSON includes full geometry and textures.
  Allow it time to load. The editor is served separately and is not part of the game build.
- `npm run scene:seed` recreates the starter from the OBJ only when the destination
  does not exist. `npm run scene:seed -- --force` explicitly replaces artist edits
  with the original lineup. Neither dev nor build runs this command.
