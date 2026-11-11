# Workshop wall screen — 2026-10-27

The workshop’s zone node: a flat enamel panel with a long glass and a brass-collared socket under it, where the field tablet’s plug seats. Source/version: `v1/model.blend`; this saved master owns future shape and material edits. Authoring record: [`wall_screen.py`](../../sparks-workshop/v1/wall_screen.py), which refuses an existing master. Review: [tablet and wall screen](../../../../../pipeline/reviews/2026-10-27-tablet-and-wall-screen.md).

Blender +Y is the wall and the front faces −Y / Godot +Z; the origin is the bottom centre of the teal backplate, so a placement’s `height` is the bottom edge’s height above the floor. The model is 1.30 wide, 0.84 tall and 0.15 deep, plus a conduit rising to 1.95. The glass is the mesh named `terminal_screen` and the indicator is `connection_lamp`; the game lays its zone lettering on the former (`scenes/zone_terminal_display.gd` sizes it from the glass) and recolours the latter. The catalog marks the model as a terminal (`zone_terminal`), which the area document’s `terminals` list needs.

Placement, the approach cell, the item it requires and what it says without it belong to `content/areas/workshop-floor.json`. The model has no collision. It is mounted on the west wall plane at about x = −0.355, turned 90°.

Edit the existing master, then run `scripts/world-art.sh build workshop-wall-screen` and review it in Godot at gameplay scale. Never rerun the one-time authoring record over an existing master.
