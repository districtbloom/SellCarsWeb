# UI styling and motion

`src/ui-polish.css` is imported last by the game entry. It provides the shared
green, cream and gold theme across the dealership, HUD, phone, garage, map,
race notices, repair workbench, Hill Drive and title screen. All visuals use
CSS and existing assets; no font, image or animation-library downloads are added.

Enabled buttons scale up slightly on a mouse hover and compress on press.
Touch controls avoid sticky hover states. Keyboard focus uses a clear ring;
disabled controls do not scale. The independent CSS `scale` property preserves
the existing translate transforms that position repair buttons.

Each major frame has one 300 ms entrance. The persistent dealership panel
animates as a whole; its rebuilt content, tabs, prices and garage cards do not
replay entrance animations. The phone retains its single existing slide-in.
Reduced-motion settings remove decorative animations and transitions.

HUD panels retain the focused action and scroll position during live refreshes.
Tab and Shift+Tab cycle through enabled panel controls; Escape closes the panel
and returns focus to its opener. Opening another page starts at the top with
focus on Close. Smaller screens use a compact toolbar, then two rows on narrow
phones, with the minimap and race notice positioned below it.

Checks cover keyboard focus, scrolling, repair interactions, phone flow and
title-screen input. Production, standalone and split-upload builds are rebuilt;
the upload HTML remains below 2 MB. Browser visual inspection is still needed
because no browser or native computer-use connection was available this session.
