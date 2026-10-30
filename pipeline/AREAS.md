# Land and area authoring

Use this guide for changing a valley or clearing, adding paths or riverbanks, or making another area. Areas are **versioned documents** in `content/areas/` that both the rules and the renderer read. The main area is `kindle-hollow` (96×80, fourteen zones, five quests), alongside `rune-mill` (the original 16×12 regression clearing) and four instanced village room templates. Each area's land stands on whole levels (0–2, all 0 unless the document says otherwise). Blender building shells, authored/procedural trees and pure collision remain separate from rendering. The outdoor builder supports saved object, appearance and land-shape edits (levels, stairs, water); a full authored-map editor remains deferred.

## Understand the coordinate system

Wheel records optionally include `axle_to: [x,y]`; the bounded eastward axle/bearing joins the wheel's solid footprint. The quest wheel's document position now puts its lower paddles in river water. See [Buildings](BUILDINGS.md) for dimensions and presentation ownership.

Buildings and props accept optional `finishes: {part: material_id}` validated against that asset's declared finish slots. Interiors accept authored `materials` and saved `finishes` palettes with `floor`, `walls`, `timber`, `hearth`, `cloth` and `rug`. Neither changes layout or collision; see [Materials](MATERIALS.md).

Logical `[x, y, height]` becomes Godot `(x, height, -y)`. Cell centers are integers and one cell is one world unit. The fixed camera sits toward +x/−y: **+x runs toward the lower right of the screen, +y toward the upper right**, so a logical south-to-north road climbs up and to the right. Terrain rows in a document are written north-up (row 0 is the largest y) so a map reads like a map, which means the picture is that map turned 45°. Land is **terraced**: each cell has a whole land level, 0 (the valley floor) to 2, and the contract is extended exactly that far. A step between neighbouring cells needs the same level, or a flight of stairs walked along its line (`LabWorld.level_step`); everything that stands on land stands on one level. One level is `TerrainBuilder.LEVEL_RISE` (1.0) world units tall; raised paths and rock stacks are still presentation. The Python API keeps `z = 0` and does not read heights. Bridges over bridges, slopes and stacked floors are not part of the contract. See [shaping the land](BUILD.md#shaping-the-land).

## The document

`content/areas/<id>.json` (master source; edit it directly):

| Field | Meaning |
|---|---|
| `schema`, `id`, `title`, `version` | Identity. Bump `version` for a deliberate redesign and keep the old file. |
| `size`, `spawn` | Width/height in cells (4–160) and the starting cell. |
| `terrain` | `height` strings of `width` glyphs, north-up: `.` grass, `,` dirt path, `=` cobble, `~` water, `#` rock. Water blocks unless a bridge deck is built on it; rock always blocks. |
| `ground` | `{}` for terrain generated from the cells, or `{asset, water_rects}` to use a Blender land model (as `rune-mill` does with `clearing-ground`). |
| `levels` | Optional land levels: `height` strings of `width` digits `0`–`2`, north-up like `terrain`. Omitted means all valley floor. Water keeps the level of its cell. Buildings and props must stand on one level, off stairs. |
| `stairs` | Optional flights `{at: [x, y], up: "N"}`: on a dry cell, climbing toward `up` onto dry ground exactly one level higher, with dry ground of its own level at its foot; never straight onto another flight. |
| `paint` | Optional version-1 appearance block: 1–36 ground material IDs, `roughen` in 0–1, north-up rows twice the terrain width/height. `.` derives the default; base-36 digits pick materials. Water/rock overrides warn and are ignored. It never changes terrain or rules. See [Ground](GROUND.md). |
| `buildings` | `{id, asset, at, facing, scale}`. `asset` is a world-catalog entry (`cottage`, `log-cabin`, `mill-house`; swapping one for another with the same footprint changes nothing the rules see); `facing` is the side the door faces (`S` is −y, `E` is +x). The solid footprint comes from the catalog's `logical_footprint`, rotated and scaled. |
| `trees` | Procedural `[x, y]` / `[x, y, size]`, or model `{at: [x,y], size, asset}`. Procedural trunks use radius 0.18; model trunks use the catalog radius × size. Crowns are presentation. |
| `segments` | Axis-aligned `fence` (thin) and `wall` (0.5 thick) lines. They block the cells and edges they cross, so place them between cells or run a wall along a row and leave a gate cell. |
| `lamps`, `gates`, `bridges`, `wheels` | Mechanisms. Each names a `zone`. Lamps have `style` `post` (the adopted `lamppost` model, lantern toward +z) , `beacon` (procedural) or indoor `sconce`; gates have an `axis` (the direction the leaf spans); bridges list their sockets in build order, each on a water cell and neighboring the last. |
| `interior` | Optional `{exit: [x,y], furniture: [{kind, at, size}], host: {at, route}}`. Furniture blocks except rugs; the renderer makes a cutaway room. `host` supplies the owner's indoor positions when this template belongs to a resident. See [Village](VILLAGE.md). |
| `interior.outdoor` | Optional, for an outdoor room drawn like a room (Spindle Lane): `{sun: {rotation, color, energy}, ambient: {color, energy}, haze, backdrop, parallax}`. The view uses this daylight instead of the valley's warmth, `haze` fills behind everything, and `backdrop` (a PNG under `res://assets/`) hangs on the camera's far plane, drifting by `parallax` (0–0.6) and fading into the haze toward its foot. Presentation only. |
| `interior.life` | Optional street motions, presentation only: `smoke` `[{at, height}]` chimneys, `sway` (placed assets whose `cloth*` children move in the breeze), `tram` `{asset, out, stop, edge, fade, period, offset, travel}` (a placed asset's round trip along x: up from `out` to `stop` in `travel` seconds (default 7), a fifteen-second wait, back down, fading past `edge`), `gulls` `{at, height, count}`, `robots` `[{asset, path, speed, pause, loop}]` (a placed robot rolls along 2–16 points at up to 3 units a second, turning its `wheel*` nodes, waiting `pause` seconds at the ends of its round or at every lap with `loop`, and while the apprentice stands in its way; it never blocks a cell). Positions are map data, so they live here. |
| `boundary` | Optional `{apron, forest, mist}` scenic strips outside the logical bounds; apron is 16–64 units. |
| `villagers` | Optional unique `{id, at: [x,y], route: [[x,y], ...], home}` residents; identity comes from `content/villagers.json`. |
| `zones` | `{id, title, rect}` cell rectangles. A zone is **discovered** when the player first steps into it; only discovered zones are visible to the player's code. Overlaps resolve to the first listed. |

`<id>.quests.json` holds the lessons: `{id, title, concept, summary, requires, goal, focus, lesson, starter, hints, done, unlocks, optional, chapter}`. `unlocks` (optional) lists the abilities the lesson hands the player's code, from `AreaDef.CAPABILITIES` (`read`, `turn`); an unknown name rejects the document. A lesson hands them over when it becomes available (its goal needs them) and they are permanent once earned. Abilities are never saved: `Quests.capabilities` works them out from the quests reached. See [code that builds](../docs/PROGRAMMING.md#houses-trees-and-doodads).

`optional: true` marks a quest of a later chapter, and `chapter` is the heading it is listed under. The **main arc** is the quests that are not optional (`Quests.main`): the epilogue is shown when it finishes (`Quests.main_arc_done`), never again when an optional quest finishes, the title counts only it, and a main quest may not require an optional one. Kindle Hollow's five quests are the main arc; "Face the lane" is an optional second chapter after it.

Goals are `lamps_lit` (`zone`, `ids` or `all`), `bridge_built`, `gate_open`, `reach_zone`, `houses_facing` (`ids`, `facing` of `N`/`E`/`S`/`W`, `noun`; it counts the named houses that still stand, because the player may take one away) or `all` of those. Lesson text uses blank-line paragraphs, ``` fences, `**bold**` and `` `code` ``. Every id is cross-checked at load: an unknown zone, lamp, gate, bridge or quest rejects the whole document with a readable error.

`core/area_def.gd` parses and validates a document; `app/area_store.gd` reads the files. `core/lab_world.gd` builds a rules object from an `AreaDef` and indexes its solids by cell, caches the edges that cannot change and only re-evaluates edges near a gate or bridge socket, so routing across the expanded map stays fast.

## The files that define an area

| File | Responsibility |
|---|---|
| `content/areas/<id>.json` | The map and everything on it. **One source of truth** for rules and view. |
| `content/areas/<id>.quests.json` | Goals, lessons, starters, hints. |
| `core/area_def.gd`, `core/lab_world.gd`, `core/quests.gd` | Parsing, traversal and commands, goal evaluation. |
| `art/terrain_builder.gd` | Turns terrain cells and segments into batched voxel blocks (generated land). |
| `art/mechanism_builder.gd` | Lamps, the beacon, gates, bridge decks and the wheel. |
| `scenes/clearing_view.gd` | `setup(area)`: places buildings, trees and mechanisms, owns the following camera, lighting and the lamp light pool. |
| `pipeline/world-catalog.json` | Asset authority and footprints; its `areas` block lists the documents. |
| `docs/PROGRAMMING.md` | The player-visible API. |

Nothing about a map lives in code any more. If you find a coordinate in a `.gd` file, it is a bug.

## 1. Plan one small change

Copy [the area brief](templates/area-brief.md). Draw a simple cell plan with spawn, paths, water, solid objects, programmable objects and destinations. State the gameplay purpose and visual focus. Keep a route to every interaction the player must reach, using the foot footprint rather than a line between centers. Keep the camera readable with the notebook open: it covers the right third of the screen.

## 2. Edit the document

Change the cells and entities, then run `scripts/test.sh`. `test/test_area.gd` proves, for `kindle-hollow`, that every lamp has a reachable approach, every zone and building door can be reached once gates are open and bridges built, the locks really lock (the mill yard needs the bridge, the Lamp Road needs the gate), and that each quest has a reference solution that completes it under real Python while its starter does not. A new lock, lamp or quest needs a matching assertion there.

Tree placement for a large area is easiest with a small one-off generator (meadows without trees, groves, a denser border, nothing between the camera and the spawn), then hand-edit the JSON. Kindle Hollow was made that way; the JSON is the master and the generator is not part of the project.

## 3. Present the land

For a Blender land model, edit its `.blend` and run `scripts/world-art.sh build <id>`; follow [the Blender guide](BLENDER.md). Generated land retains its soil sides, banks, rock stacks, fences and walls through `art/terrain_builder.gd`; `art/water_surface.gd` supplies the animated water tops and spray. `art/ground_skin.gd` supplies flat chunk meshes with continuous pictures, half-cell paint and ragged pixel borders from pure `GroundPaint`. Both are deterministic. Generated land remains a procedural test; selecting `ground.asset` uses the adopted model instead. Flat ground skips shadow casting. See [Ground](GROUND.md).

Use the fixed camera and shared lighting to judge a change: `scripts/play.sh --resolution 1600x1000 -s res://tools/area_shot.gd -- <area id> <png> <x> <y> <zoom> <lit 0|1>` renders any spot of any area and reports build time and frame rate. Review a whole-district view and a gameplay-zoom detail.

## 4. Walk and program it

Run `scripts/test.sh`, then `scripts/play.sh`. Hold directions around new obstacles, click destinations on both sides of them, build the bridge, open the gate, and read the objective pill and notebook through the quests. `VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/playthrough.gd -- "$PWD/.cache/playthrough"` plays the level through the real controls and saves a frame per quest. Use [the review checklist](REVIEW.md) to record the evidence.

## Status of the second-area milestone

The earlier plan asked for a document extracted from the clearing, loaded by both rules and view, then a second area. That is **done**: `rune-mill` is the extraction (behavior preserved; its tests now run on the loader), `kindle-hollow` is the second area, and the view builds either through `ClearingView.setup`. Still open: **general outdoor-region transitions** (house instances now swap the single active session/view and retain the outdoor snapshot; see [Village](VILLAGE.md)), **an authored-map editor** and **adopting generated land into Blender**. Player saves exist (`app/save_store.gd`) and keep authored maps and player state distinct: a save stores state, quests and code, never the map.


## Sparks: downhill square

`haverlund-square.json` (version 3, Rootward Square, the hub) is a 72×64 saved exterior using `interior.style: workshop-square`. It is written once from [the square-hub plan](../art/source/world/square-hub/v1/README.md) and is the master from then on.

- **Arrival:** either cell of the lane's `town-steps` link arrives on its own side of a five-wide street in the south-west corner at level 2, at (1,7) or (1,9). The apprentice walks on two cells. Walking west from any of the street's five cells (0,6–10) climbs back. Two five-cell flights (x 6 and 11, rising west) carry it down.
- **Open exits:** three are left for later areas: Hill Street (x 12–17, out of the north edge, with its own flight at y 56), Lantern Row (y 43–48 at the east edge) and the Harbour Steps (x 57–64, beyond the south balustrade).
- **What the area document places:** the base ground `haverlund-square-ground` is the shell; on it stand the buildings, every railing bay and pier, the lamps, props and robots, and 56 background houses with per-placement looks.
- **Room asset `look`:** a seed, a palette name or `{seed, palette, plain}` dresses a modular house (`HouseVariants.look`). `AreaDef` checks its shape only.
- **Blocks:** only the blocks and the area's cells decide walking.
- **Earlier versions:** v1 and v2 are archived in `content/areas/archive/`.
- **Spindle Lane:** version 4 adds `haverlund-lane-surround` and its town round the old set, the same way.
- **Layout:** the square is laid out as a working town centre: active shop and civic edges, seats that face the Rootwell or a view with something at their backs, clear walks along the conduits, and light at two heights. The [square-hub README](../art/source/world/square-hub/v1/README.md) lists the choices.
- **Tests:** `test/test_square.gd` checks the traversable graph and all three exits, real travel, local program memory, tablet scope, WASI preview/Apply, arrival read flags and Continue. It also checks that the shops replaced the old terrace, that the Rootwell is placed 35 % larger, that every planter-bench faces it, and that the power pillars glow across their full width.

### Walking through a scene change

A room link can be wider than one cell, and the walk can carry on through the change:

| Field | Meaning |
|---|---|
| `cells` | 1–8 cells, including `at`, all in the area. A step in the link's `direction` from any of them crosses. |
| `arrivals` | One arrival cell per entry in `cells`, so each side of a wide stair lands on the matching side beyond. `arrival` stays as the default. |
| `walk_through` | The apprentice walks into the doorway, the clockwork veil ([UI](UI.md#scene-change-veil)) grows out of it, and in the next room the veil opens on the arrival cell while the apprentice walks in from 0.9 cell behind it, on to the cell `enter` leaves them on. Every cell of that walk is inside the map; what lies beyond a room's edge is hidden by the veil. |
| `enter` | 0–4 more cells to walk on from the arrival, if they are walkable. The player's saved cell is that last cell, and the walk to it is drawn under the veil. |
| `doors` | A placed room asset, or `"shell"`, whose hinged `door_leaf*` parts (each with a `swing` extra in degrees) swing open as the apprentice goes through. The link back in the next room opens its own doors, which close behind. |

Click-to-walk to a wide link heads for its nearest cell. Interior inspections are capped at 64 per room; other room lists stay at 24.
