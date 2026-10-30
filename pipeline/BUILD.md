# Build mode

Build mode lets someone rearrange Kindle Hollow: **place** houses, trees and doodads, **move**, **turn** and **delete** them, and **paint** the ground, with undo, redo and saved edits. Everyone running this checkout has the `studio` policy. The `player` policy offers a smaller catalog with allowances. Press **B** (or the hammer) to enter and **B**, **Esc** or **Done** to leave.

The idea comes from the sibling Rootward's "Lanternroot Studio" decision record; nothing is copied from it and this project does not depend on it. The interface is this project's own kit (`pipeline/UI.md`).

Standing houses and props now offer **Materials** in their Move details, with per-part Original, undo/redo and saved finishes on 90 supported assets. **Land → Floors** includes four new floor paints. Inside a house, **B** opens **Room materials** with six finish selectors and its own saved history. See [Materials](MATERIALS.md) for the fifteen pictures, capabilities and source pipeline.

## How it works

The Houses shelf also includes **Hearth Bakery** and **Riverside Smithy**, with distinct oven/forge designs, centered entrances, saved room mappings and per-part finishes. The eight earlier building models and lamppost have completed a roof/door/detail pass; see [Buildings](BUILDINGS.md).

An edit is a plain dictionary. The list of edits is a layer over the area document, which stays the source of truth:

```
{op: "add",    kind: "building", id, item, asset, at: [x, y], facing, scale}
{op: "add",    kind: "tree",     item, at: [x, y], size}
{op: "move",   kind: "building", id, at, facing}      {op: "move", kind: "tree", from: [x, y], at: [x, y]}
                                                         // turning in place is a move to the same `at` with a new `facing` (and `turned: true` for the label)
{op: "remove", kind: "building", id}                  {op: "remove", kind: "tree", at: [x, y]}
{op: "add",    kind: "prop",     id, item, asset, at: [x, y], facing, scale}
{op: "move",   kind: "prop",     id, at, facing}      {op: "remove", kind: "prop", id, asset}
{op: "paint", material: "dirt", cells: [[sx, sy], ...]}  // empty material restores the default
{op: "finish", kind: "building", id, slot: "roof", material: "slate_shingles"}
{op: "finish", kind: "room", id: "", slot: "floor", material: "terracotta_tile"}
{op: "level", tool: "raise", level: 1, cells: [[x, y], ...]}   // raise or lower cells to one land level (0 to 2)
{op: "water", cells: [[x, y], ...]}                     {op: "land", cells: [[x, y], ...]}   // dig water in, fill it in
{op: "add",    kind: "stairs",   at: [x, y], up: "N"}   {op: "remove", kind: "stairs", at: [x, y], up}
```

Applying the list to a copy of the document (`AreaBuild.apply`) and parsing that copy gives an ordinary `AreaDef`, so the rules, the picture and the saves all see one world. The edits are stored in the player's save as `edits`; the shipped document is never rewritten. A saved edit that no longer fits (the document changed) is skipped and reported; a save whose edits break the valley is set aside whole.

| Layer | File | Job |
| --- | --- | --- |
| Data | `content/build/catalog.json` | Categories, items (a house or a doodad names a world-catalog asset, a tree carries a size and optionally an asset), `audience` (`player` or `studio`) and policies with allowances. |
| Rules | `core/area_build.gd` | Pure: footprints, snapping, `check_building`, `check_prop`, `check_tree`, `check_remove`, the reachability check, `apply`. |
| History | `core/build_ledger.gd` | The edit list with `place`, `move_*`, `remove_*`, `undo`, `redo`; keeps the current `area` and `rules`. |
| Picture | `scenes/clearing_view.gd`, `scenes/build_overlay.gd`, `art/build_grid.gdshader` | `sync_edits` redraws only what changed; the overlay draws the grid, the ghost, the footprint tiles, the door arrow and the hover; it also picks. |
| Controller | `app/build_mode.gd` | Tools, hover, what is chosen, clicks and drags, turning, the free camera, undo/redo and the Esc ladder. It asks the ledger and draws the answer; it also decides what the details panel shows. |
| Interface | `ui/build_hud.gd`, `ui/build_bubble.gd`, `ui/build_details.gd`, `ui/build_card.gd`, `scenes/model_turntable.gd`, `scenes/thumbnail_studio.gd` | The left rail of round tools, the bottom tray, the right details panel (live turntable, facing compass, code), cursor bubble, toasts, allowance chip; card pictures drawn from the real models. |
| Game | `app/game.gd` | Owns the ledger, rebuilds it from the save on Continue, saves after edits, swaps the session's world. |

## The rules a placement must satisfy

Each of these has a reason a player can read.

- **Inside the valley**, on **open ground**: not water, rock, a bridge socket, the starting spot or a gate's doorway.
- **Clear of other things**: a quarter-cell gap from other buildings, room round lamps, trees, fences, walls and the mill wheel. Trees stand on grass, 0.9 apart.
- **A door with ground in front of it**, not water, rock or another wall.
- **Doodads** (kind `prop`) have no door, and their rules are lighter: open ground (paths and cobbles are fine), clear of buildings, other doodads, lamps, trees, fences, walls and the mill wheel. A doodad whose asset has a catalog footprint **blocks movement** where it stands, so it must also stay off the player and the residents' stops, and the cut-off check applies to it. One with no footprint is a small thing to walk over. Buildings and trees keep clear of doodads too.
- **Not on the player or a resident’s walking stops.** Existing resident stops also remain reachable.
- **Nothing the player needs may be cut off.** Object edits flood the new world from the player with gates open and bridges built. Every previously reachable lamp, zone, door and starting spot must stay reachable. Otherwise the edit is refused with a useful reason. Paint and finishes only change appearance and skip this flood, retaining the existing rules/cache.
- **Locked things** (the mill, which carries the wheel and the lessons; lamps, gates and bridges, which are not in the catalog) cannot be moved or removed.
- **Level ground**: a building, doodad or tree stands on one land level and off any stairs, and a door opens onto ground of its own level. See [shaping the land](#shaping-the-land).
- **Allowances** (`player` policy): at most 8 buildings and 40 trees; taking one of your own down gives it back; moving something that was already there costs nothing.

Snapping: a building's centre snaps so its edges sit on the cell grid (whole cells for an odd number of cells, half cells for an even one); trees snap to half cells and doodads to quarter cells.

## Using it

The screen has three parts (see [the interface](UI.md)):

- **The rail** (left): round bubbles for **Move** (1), **Delete** (2), **Objects** (3) and **Land** (4), then Undo, Redo and Done. It stays put whichever tool is chosen.
- **The tray** (the whole bottom of the screen): Objects shows the catalog by category (Houses, Trees, Doodads, Furniture, Workshop, Market, Garden, Village & Magic) with search, in one row that scrolls sideways with the wheel or the page arrows. The category header scrolls separately and brings the chosen category into view, keeping search accessible at smaller sizes. Land shows the ground paints by group (Grass, Dirt, Stone, Soil, Floors), the brush sizes and Pick, then the land-shaping tools: **Terrain** (Raise land, Lower land, Stone stairs) and **Water** (Dig water, Fill in). Choosing Move or Delete, or pressing **Tab**, puts the tray away.
- **The details panel** (right, about a fifth of the width, sized to fit): it opens for whatever is chosen: a thing on the tray, a ground paint, or something standing in the valley.

| Tool | What it does |
| --- | --- |
| **Objects** (3) | Pick a card; the ghost follows the pointer, green where it fits, red with the reason where it does not; the grid glows round the pointer and a brass arrow shows the door. Click to place, **R** (Shift+R back) or the compass to turn, right-click or Esc to put the item away. |
| **Move** (1) | Click a house, tree, doodad (or a lamp, gate or bridge, to read it) to **choose** it: it stays where it is, wears a brass frame and opens its details. Click it again, or press and drag, to **lift** it; click or let go to set it down; Esc puts it back exactly. With something chosen, **R**, Shift+R or the compass **turn it on the spot** (one undo step; refused with the reason if it would then not fit). Delete or the panel's Remove takes it away. Click empty ground or press Esc to let go. |
| **Delete** (2, or X) | Click to remove; Ctrl+Z brings it back. |
| **Land** (4) | Pick a paint, then drag. Alt-click or I picks, `[`/`]` change the brush (half-cell, one-cell, two-cell). A drag shows a live proposal; release commits one undo step. Right-click/Esc cancels. Water/rock stay untouched. See [ground painting](GROUND.md). **Terrain** and **Water** shape the land the same way, one drag per undo step, with brushes of 1, 2 or 3 cells; stairs are one click each. See [shaping the land](#shaping-the-land). |

Captures of the layout: [the Objects tray](../evidence/build-place.png), [a refused spot](../evidence/build-refused.png), [Land](../evidence/build-land.png), [a chosen and turned house](../evidence/build-details-house.png), [a doodad on offer](../evidence/build-details-doodad.png) and [a lamp's code](../evidence/build-details-code.png).

**The details panel** shows, top to bottom: a live picture of the model, which turns slowly when the thing can be turned (and swings round to a facing you choose, then holds for a moment so you can see it); its name and blurb; a **facing compass** (the valley floor tile as the camera sees it, with S, E, N and W on its four sides, the lit one being where the front or door points, plus turn-left and turn-right buttons) when the thing can be turned; its facts; **what a program can do with it** when it has code; and **Remove** for things that may be removed. A tree has no front, so it has no compass. A ground paint shows its swatch.

**Code in the panel** appears for lamps, gates, bridges and the sixteen working props. It shows the actual instance id, how to fetch it (`world.prop("prop-N")` for a working prop), and its members from [the API reference](../core/api_reference.gd). Lesson lamps, gates and bridges stay locked; working props can be moved, turned and removed. **Write code for it** leaves build mode, opens the notebook and adds the fetching line. The button follows discovery: visit the object's district first, or stand nearby for a prop outside named districts. Houses, trees and doodads show `house = world.house("id")`, `tree = world.tree(x, y)` or `doodad = world.doodad("id")` and their members, in one of three honest states: **ready** (the button appears), **not learned yet** (the note names the lesson that teaches it) or **out of reach** (visit its place, or stand within 12 cells). A program's building is saved and undone like any builder edit; see [code that builds](../docs/PROGRAMMING.md#houses-trees-and-doodads). See the [programming guide](../docs/PROGRAMMING.md).

- **Camera**: WASD or middle-drag pans (relative to the screen), the wheel zooms, **Tab** hides the tray. Walking is off while building, and the quest beam is hidden.

Cards are 112×134 with picture frames, in one row on a full-width tray. Size facts live in tooltips and the details panel. Ctrl+F focuses search across titles, blurbs and categories; Esc clears it. Model thumbnails draw the visible category first, then fill the remaining cards in the background and stay cached. Window UI scale applies to the whole interface.

The six expansion models are studio shelf items: Hearth House, Lantern Loft, Brook Mill, Hearth Oak, Ridge Cedar and River Willow. They use the existing exported models; their sources remain unchanged and the expanded valley also places them in its new districts. Brook Mill is static scenery with a decorative wheel. Model trees retain their asset and catalog trunk radius when placed, moved, removed, undone or saved. Procedural tree arrays still load unchanged.

**The Doodads tab** offers twelve studio props, including chairs, planters, barrels, woodpiles, wheelbarrows, benches and tree stumps. The earlier 32-object handoff is recorded in [the doodads review](reviews/2026-10-23-voxel-doodads.md); the later [deletion pass](reviews/2026-10-29-asset-deletion-pass.md) removed requested assets. Doodads are saved in the document’s optional `props` list as `{id, asset, at, facing, scale}` (ids `prop-N`, never reused). Indoor furniture editing is not implemented.

The [village library](BUILDER_LIBRARY.md) adds **50 individually authored Blender objects**, ten per new category, making **82 props / 95 total builder entries**. They include cottage furniture, craft benches, food stalls, carts, garden shelters, village mechanisms and restrained magical pieces. All use the same prop edit/history/save rules. **Sixteen have a Boolean `active` capability**: after placing one, leave build mode and press **F** within 2.2 cells with a clear approach, or use `prop.set_active(True/False)` from Python. Animated poses, light and pump droplets follow committed state; preview only draws the proposal. Opening a chest does not remove its footprint. These are working scene props; inventory, crafting, animal simulation and bell audio are separate features.

Registered house assets also map to separate saved room templates. A moved house retains its room; newly placed houses get fresh identities. See [Village](VILLAGE.md).

## Adding something to the shelf

1. Register an exported model through [world assets](WORLD_ASSETS.md), with a rectangular `logical_footprint` for buildings or `trunk_radius` for model trees. A doodad's footprint is optional: one with none can be walked over. All fifty new library pieces have explicit blocking footprints. For a working prop, register an `interaction` with an allowed kind and on/off verbs; preserve the semantic pivot/material roles described in [the library guide](BUILDER_LIBRARY.md). Procedural trees need only a size. Add `asset` to a model tree's catalog item; its saved area entry is `{at, size, asset}`.
2. Add an item to `content/build/catalog.json` with a category, a `kind` (`building`, `tree` or `prop`), a title, a blurb and an `audience`. A prop item names its `asset`.
3. Run `scripts/test.sh`. `test/test_build.gd` checks every item has a real category and footprint, and that the rules still find room for it.

## Checks and review

`test/test_build.gd` covers catalog/rules/history/policies; `test/test_build_assets.gd` exercises the six new models; `test/test_ground.gd` proves appearance edits preserve rules; `test/test_build_mode.gd` drives the real input path, including choosing and dragging things, turning them in place and with the compass, the code panel, the layout of the rail, tray and details panel, a drag-paint, cancellation, eyedropper, saves and the growing catalog. `test/test_builder_library.gd` checks every new object, rotated placement, collision, edits, history, source/runtime registration, interactive model roles, command validation, discovery and real Python/WASI. `test/test_prop_flow.gd` covers F actions, preview/Apply/Undo, active-object movement and Continue. `tools/build_tour.gd` captures the tray, Land and model ghosts in a window; `tools/build_details_tour.gd` captures the details panel for a chosen and turned house, a tree, a doodad and a lamp's code; `tools/doodad_tour.gd` fills the Doodads tab and a yard of placed props in a window. The 50-object `tools/builder_library_review.gd` captures each model and five category scenes; `tools/builder_library_tour.gd` reviews the real builder, all sixteen F actions, Python and saved working states at gameplay size. Counts and captures are in the [library review](reviews/2026-10-24-builder-library.md); the [ground review](reviews/2026-10-23-ground-paint-and-builder.md) records the earlier painting work.

## Shaping the land

Land is terraced, as in Animal Crossing: every cell stands on **level 0** (the valley floor), **1** or **2**. The area document keeps this in an optional `levels` block and a `stairs` list (see [Areas](AREAS.md)); the player's terrain edits are a layer over it like every other edit, so they undo, redo and save the same way.

| Tool | What it does |
| --- | --- |
| **Raise land** | Drag over ground: every cell the brush crosses rises to one level above the cell the drag began on (so a drag across a slope makes one flat terrace). Up to level 2. Water cells rise too and stay water. |
| **Lower land** | The same, one level down. The valley floor is as low as land goes: dig water to go deeper. |
| **Stone stairs** | Click at the foot of a cliff exactly one level high: the flight stands on the lower cell and climbs toward the higher one. Where two cliffs meet, **R** chooses the way. The Delete tool (2) takes stairs away. |
| **Dig water** | Floods dry ground at its own level. Water that runs on to lower water falls as a **waterfall**. |
| **Fill in** | Turns water back into grass at the level it lay. |

The rules, all in `core/` (`AreaDef`, `LabWorld.level_step`, `AreaBuild.land_reason` / `check_stairs`, `BuildLedger.shape` / `place_stairs` / `remove_stairs`):

- **Cliffs block walking** in both directions; level ground joins level ground at any height. Stairs are walked only along their line, up onto the cell above them or down off their foot, never stepped on or off sideways. A flight climbs exactly one level, needs dry ground below, on and above it, room to stand at both ends, and may not lead straight onto another flight.
- **The ground under things keeps its shape**: houses (and the ground before their doors), doodads, trees, lamps, the gate and its neighbours, a bridge's crossing and banks, the mill race, walls and fences, stairs (with their foot and top), the starting spot, residents' stops and the player's own cell. A drag skips those cells and changes the rest; take the thing away first. Rock keeps its shape.
- Terrain edits run the same **cut-off check** as objects, so a cliff that would strand the player or cut off a lamp, a zone, a door or a resident is refused with the reason. Taking away the only stairs while someone stands on the terrace is refused the same way.
- Objects need **level ground** (above), and a front door or a working doodad cannot be used from another level.
- Code does not see heights yet: the Python API's cells keep `z = 0`.

The picture (`art/terrain_builder.gd`, `art/water_surface.gd`, `art/waterfall.gdshader`, `art/ground_skin.gd`): a level is one world unit tall (`TerrainBuilder.LEVEL_RISE`). A raised cell stands on a column of layered rock down to the valley floor, so wherever a neighbour is lower it shows as a cliff with a soil band, boulders and a turf lip with hanging tufts. The ground skin lies at each cell's height and draws a dark contour along every edge that drops away (so a terrace's far edges read from the fixed camera) and a soft shadow at the foot of a cliff. Stairs are four stone steps between stepped cheeks. Water lies at its own level behind stone kerbs; where it steps down, a sheet of falling water bulges over the kerb and drops to the pool below, whitening as it tips and as it lands, with spray at its foot. Shaping redraws only the terrain chunks it touched (and the skin, water and grid). The camera follows the player's height up and down stairs, and picking finds a terrace's top before the ground behind it.

The tools and the small sample of land each card shows are listed in `content/build/land-tools.json`. `test/test_terrain.gd` covers the document format, walking, every tool and refusal, waterfalls, saves and the block geometry; `test/test_build_mode.gd` drives the tools through the real input path; `tools/terrain_tour.gd` captures terraces, stairs and waterfalls at gameplay size ([review](reviews/2026-10-24-terrain-and-water.md)).

## Not built yet

- Moving or removing lamps, gates, bridges and the wheel; the mill stays locked.
- The code abilities beyond reading and turning (placing, moving and removing houses, trees and doodads by code), and code that reads or shapes land heights. Working props already expose `active` / `set_active`.
- Slopes and ramps (land is terraced in whole levels), more than three levels, bridges over raised water, and objects standing across a cliff edge.
- Turning several things at once, and a multi-select.
- Walls, fences and logical paths. House travel is implemented; indoor furniture editing remains separate future work.
- A rectangle select, copy and paste, and snapping off.
- Doodads standing on other doodads (a cup on a table), doodad colours, and a villager's allowance of doodads: they are studio-only for now.
- Per-player allowances stored with an account; today the policy is chosen by `VOXEL_BUILD_POLICY=player` for trying it.
