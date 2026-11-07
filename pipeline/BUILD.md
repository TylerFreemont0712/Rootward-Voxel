# Build mode and the layout studio

Build mode lets the player rearrange part of the world: **place**, **move**, **turn** and **delete** pieces, and **paint** the ground, with undo, redo and saved edits. In Sparks & Machines it is the **layout studio** in Rootward Square (**B**, or **Layout · B**): a scoped tray of fourteen park and barrier pieces (declared in the square's `interior.layout`), half-cell appearance paint and movement of the existing park props. Everyone running this checkout has the `studio` policy; the `player` policy (`VOXEL_BUILD_POLICY=player`) adds allowances for trying what a villager would get.

The interface is this project's own kit ([UI](UI.md)). Nothing is copied from, or depends on, the separate Rootward project.

## Engine features without shipped content

The build engine still supports houses with saved room instances, procedural trees, instance finishes ("Materials"), room finishes, terrain levels, stairs and water (below). The Kindle Hollow and Village Morning content that used them was removed on 2026-11-05, and `content/build/catalog.json` now lists only models that ship (34 entries). Their rules are proved over the plain-data village in `test/fixtures/` (`AreaStore.use_fixtures()`). Strip them, and the fixtures, together if the studio stays small.

## How it works

An edit is a plain dictionary. The list of edits is a layer over the area document, which stays the source of truth:

```
{op: "add",    kind: "prop",     id, item, asset, at: [x, y], facing, scale}
{op: "move",   kind: "prop",     id, at, facing}      {op: "remove", kind: "prop", id, asset}
                                                         // turning in place is a move to the same `at` with a new `facing` (and `turned: true` for the label)
{op: "paint", material: "limestone_flags", cells: [[sx, sy], ...]}   // empty material restores the default
{op: "finish", kind: "prop", id, slot, material}                     // engine feature: instance finishes
{op: "move",   kind: "scenery", id, asset, at, turn}  // an authored lamp standard, bench, stall... (never added or removed)
{op: "add",    kind: "wall", id, from: [x, y], to: [x, y], style}   {op: "remove", kind: "wall", id, style}
{op: "add"/"move"/"remove", kind: "building" | "tree", ...}          // engine features: houses and trees
{op: "level" | "water" | "land" | "add stairs" ...}                  // engine features: terrain (see below)
```

Applying the list to a copy of the document (`AreaBuild.apply`) and parsing that copy gives an ordinary `AreaDef`, so the rules, the picture and the saves all see one world. The edits are stored in the player's save as `edits`, wrapped with an epoch and the archive of retired layouts (`BuildLedger.saved_edits()`); the shipped document is never rewritten. **Done** also exports a review snapshot to `content/development/layouts/` in source checkouts.

| Layer | File | Job |
| --- | --- | --- |
| Data | `content/build/catalog.json` | Categories, items (a prop names a world-catalog asset), `audience` (`player` or `studio`) and policies. |
| Rules | `core/area_build.gd` | Pure: footprints, snapping, `check_prop` and friends, the reachability check, `apply`. |
| History | `core/build_ledger.gd` | The edit list with `place`, `move_*`, `remove_*`, `paint`, `undo`, `redo`; keeps the current `area` and `rules`. |
| Picture | `scenes/clearing_view.gd`, `scenes/build_overlay.gd`, `art/build_grid.gdshader`, `art/ground_skin.gd` | `sync_edits` redraws only what changed; the overlay draws the grid, ghost, footprint and hover, and picks. |
| Controller | `app/build_mode.gd` | Tools, hover, choice, clicks and drags, turning, the free camera, undo/redo and the Esc ladder. |
| Interface | `ui/build_hud.gd`, `ui/build_bubble.gd`, `ui/build_details.gd`, `ui/build_card.gd`, `scenes/model_turntable.gd`, `scenes/thumbnail_studio.gd` | The left rail of round tools, the bottom tray, the right details panel with a live turning model and a facing compass. |
| Game | `app/game.gd` | Owns the ledger, rebuilds it from the save on Continue, saves after edits, swaps the session's world. |

## The rules a placement must satisfy

Each has a reason a player can read.

- **Inside the layout region** (`interior.layout.rect`), on open ground: not water, not a stair bay, a room link, the loading entrance or a terminal's approach.
- **Clear of other things:** a footprint gap from authored buildings, scenery, lamps, railings and other props. A placed prop with a catalog footprint **blocks movement** where it stands, so it also stays off the player and the residents' stops.
- **Nothing the player needs may be cut off.** Object edits flood the new world from the player; every previously reachable lamp, zone, door, link and terminal must stay reachable, otherwise the edit is refused with a useful reason. Paint only changes appearance and skips the flood.
- **Authored things are not locked** unless the document says so: the existing park benches, planters and tree can be moved with the same tool.
- **Allowances** (`player` policy) cap buildings and trees; taking one of your own down gives it back.

Snapping: props snap to quarter cells, buildings so their edges sit on the grid, trees to half cells.

## Using it

- **The rail** (left): round bubbles for **Move** (1), **Delete** (2), **Objects** (3) and **Land** (4), then Undo, Redo and Done. In the square, Land offers the ground paints only (Terrain and Water are hidden on authored terraces).
- **The tray** (bottom): Objects shows the allowed pieces with search; Land shows the paints by group.
- **The details panel** (right): opens for whatever is chosen: a piece on the tray, a paint, or a prop standing in the square.

| Tool | What it does |
| --- | --- |
| **Objects** (3) | Pick a card; the ghost follows the pointer, green where it fits, red with the reason where it does not. Click to place, **R** (Shift+R back) or the compass to turn, right-click or Esc to put the item away. |
| **Move** (1) | Click a prop to **choose** it (a brass frame and its details). Click again, or press and drag, to **lift** it; click or let go to set it down; Esc puts it back exactly. **R**, Shift+R or the compass turn it on the spot (one undo step). |
| **Delete** (2, or X) | Click to remove; Ctrl+Z brings it back. |
| **Land** (4) | Pick a paint, then drag. Alt-click or I picks, `[`/`]` change the brush (half-cell, one-cell, two-cell). A drag shows a live proposal; release commits one undo step; right-click/Esc cancels. See [ground painting](GROUND.md). |

## Adding something to the shelf

1. Register an exported model through [world assets](WORLD_ASSETS.md), with a rectangular `logical_footprint` for anything that blocks.
2. Add an item to `content/build/catalog.json` naming the asset, category, title and `audience`.
3. To offer it in the square, add its item id to `interior.layout.items` in `content/areas/haverlund-square.json`.
4. Run `scripts/test.sh flow` (`test_layout_flow` drives the real input path; `test_square_layout` checks the rules) and look at it with `tools/square_layout_review.gd`.

`test_build` covers catalog, rules, history and policies over the fixture village; `test_ground` proves appearance edits preserve rules; `test_terrain` covers the terrain engine; `test_layout_flow` drives the studio the way a player does.

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

The tools and the small sample of land each card shows are listed in `content/build/land-tools.json`. `test/test_terrain.gd` covers the document format, walking, every tool and refusal, waterfalls, saves and the block geometry; `test/test_layout_flow.gd` drives the studio as a player does.gd` captures terraces, stairs and waterfalls at gameplay size (review).


## Not built yet

- Interior furnishing: room finishes and furnishing tools for the shop rooms are deferred; the clockshop is authored and furnished.
- Multi-select, rectangle select, copy and paste, and snapping off.
- Per-player allowances stored with an account.
- Code that places or removes things (`core/code_build.gd` remains as an engine rule layer with no lesson that unlocks it).

## Freedom in the layout (2026-11-06)

Only the frame is fixed: the ground's levels and walls, the stairs and the loading entrances. Everything else can be designed. See the [proposal](../docs/concept/v0.8/build-mode-freedom.md) and the [review](reviews/2026-11-06-build-freedom.md).

- **Scope.** `interior.layout.rect` may cover the whole area. `layout_contains` refuses stairs and walls (`#`) everywhere, and an optional `layout.levels` list can keep a layout to some terraces. The square's layout is the whole square.
- **Authored scenery moves.** `interior.layout.scenery` lists the asset types a designer may move (the square lists lamp standards, benches, trees, stalls, the kiosk, bins, bollards, planters and so on). `AreaDef.scenery` holds each placement that stands on the ground inside the area, unless it is marked `locked`. The Move tool chooses, lifts, sets down and turns it like a prop. A move takes along the furniture collision at exactly its position, the fixture lamps mapped to it (their position and the cell they are worked from) and its height (a move onto another level keeps it on the ground). A lamp keeps its id, program and light. Scenery is never deleted. `AreaBuild.check_scenery` applies the prop rules, ignoring the thing itself.
- **Walls (Sims-style).** The **Walls** tab offers a garden wall, a balustrade and an iron railing. Press on a cell corner and drag along the grid, or click one corner and then another. A run lies on cell edges (half-cell coordinates), on one level, clear of stairs, entrances, buildings, scenery and the spawn. It blocks the edges it runs along (it is also a `segment`). The picture is assembled from the town's wall kit (`AreaBuild.wall_pieces`): the fewest whole bays of the style, stretched to fit, with one pier or post at every joint, end, corner and T-junction (the heavier style's where styles meet). Delete takes a run down. Walls are drawn, not carried: to move one, delete it and draw it again. Height choices and hedges are not built yet.
- **Town ground.** Land → **Town** paints the square's own limestone flags and sandstone cobbles, plus granite setts, brick paving, garden gravel, a planting bed and the town lawn ([ground](GROUND.md#town-ground)). Paving is cut straight on the half-cell grid. Lawn, bed and gravel get a limestone kerb wherever they meet paving, including the authored surface round a painted patch.
- **Code.** In a layout district under the `studio` policy, programs get `read`, `turn` and `move`. `world.doodads` includes the scenery, and a doodad's `lamps` names the lamps it carries. `doodad.move_to(x, y)` (command `relocate`) and `doodad.face(...)` are checked by `CodeBuild` under exactly the mouse's rules, atomically per run. Players will earn these through lessons. The notebook's preview does not yet ghost moved scenery; Apply commits it.

Not built yet: on/off capabilities (`light`, `open`, `ring`, `flow`) for simple objects. They need a `mechanism` pivot or `state_glow` material authored into each model ([PropInteractions](../core/prop_interactions.gd)), so they are an art pass per object. Conduits do not re-route to a moved lamp.

## Sparks & Machines layout

Rootward Square exposes the existing builder through **B / Layout · B** for its restored upper terraces, with a scoped fourteen-piece garden/barrier tray, half-cell appearance painting, existing placement movement and saved undo/redo. Seventy-four park and upper railing placements are normal props with collision footprints. Required room links and terminals are part of the cut-off check; authored buildings and scenery also reject overlapping props. Other Sparks rooms remain outside this layout workflow. The clockshop is authored and furnished; interactive interior furnishing tools remain deferred. **Done** also exports a review snapshot in source checkouts. See [controls and sharing](../docs/concept/v0.8/square-layout.md) and [current review](reviews/2026-11-04-square-restoration-and-clockshop.md).
