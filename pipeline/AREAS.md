# Land and area authoring

Chapter 03 adds optional top-level `displays`: mounted object ID, title, zone, whole-cell approach, commission inspection and a default card. The approach must lie beside its placed object in the named zone. `DisplayCards` validates the one–three-page, 32-character text contract and physical writing access; the renderer does not decide whether text is legal. Saved world state adds `display_cards` keyed by known display ID. `display_messages` is the quest goal and `access: {kind: display, id: tram-welcome}` identifies its notebook connection. See the actual `content/areas/haverlund-lane.json` and [programming contract](../docs/PROGRAMMING.md#tram-message-cards).

The lane's validated `interior.welcome` block owns Braum's spawn/call/landing cells, Iona's standing cell, both skin IDs, the garden hinge name/position and display ID. App staging uses ordinary core routes over those cells. Garden fence collisions and sign posts remain in the area document; Blender hinge animation and live lettering do not define passage rules.

Use this guide for changing a room or street, adding paths, or making another area. Areas are **versioned documents** in `content/areas/` that both the rules and the renderer read. The journey's ten rooms are listed in `content/levels/catalog.json`; `haverlund-square` is the largest (88×64, terraced over three levels). Engine features that no shipped area uses (houses, procedural trees, terrain and water tools) are documented here for completeness and exercised over `test/fixtures/`.

## Understand the coordinate system

Wheel records optionally include `axle_to: [x,y]`; the bounded eastward axle/bearing joins the wheel's solid footprint. The quest wheel's document position now puts its lower paddles in river water. See Buildings for dimensions and presentation ownership.

Buildings and props accept optional `finishes: {part: material_id}` validated against that asset's declared finish slots. Interiors accept authored `materials` and saved `finishes` palettes with `floor`, `walls`, `timber`, `hearth`, `cloth` and `rug`. Neither changes layout or collision; see [Materials](MATERIALS.md).

Logical `[x, y, height]` becomes Godot `(x, height, -y)`. Cell centers are integers and one cell is one world unit. The fixed camera sits toward +x/−y: **+x runs toward the lower right of the screen, +y toward the upper right**, so a logical south-to-north road climbs up and to the right. Terrain rows in a document are written north-up (row 0 is the largest y) so a map reads like a map, which means the picture is that map turned 45°. Land is **terraced**: each cell has a whole land level, 0 (the valley floor) to 2, and the contract is extended exactly that far. A step between neighbouring cells needs the same level, or a flight of stairs walked along its line (`LabWorld.level_step`); everything that stands on land stands on one level. One level is `TerrainBuilder.LEVEL_RISE` (1.0) world units tall; raised paths and rock stacks are still presentation. The Python API keeps `z = 0` and does not read heights. Bridges over bridges, slopes and stacked floors are not part of the contract. See [shaping the land](BUILD.md#shaping-the-land).

## The document

`content/areas/<id>.json` (master source; edit it directly):

| Field | Meaning |
|---|---|
| `schema`, `id`, `title`, `version` | Identity. Bump `version` for a deliberate redesign and keep the old file. |
| `size`, `spawn` | Width/height in cells (4–160) and the starting cell. |
| `terrain` | `height` strings of `width` glyphs, north-up: `.` grass, `,` dirt path, `=` cobble, `~` water, `#` rock. Water blocks unless a bridge deck is built on it; rock always blocks. |
| `ground` | `{}` for terrain generated from the cells, or `{asset, water_rects}` to use a Blender land model (as the square does with `haverlund-square-ground`). |
| `levels` | Optional land levels: `height` strings of `width` digits `0`–`2`, north-up like `terrain`. Omitted means all valley floor. Water keeps the level of its cell. Buildings and props must stand on one level, off stairs. |
| `stairs` | Optional flights `{at: [x, y], up: "N"}`: on a dry cell, climbing toward `up` onto dry ground exactly one level higher, with dry ground of its own level at its foot; never straight onto another flight. |
| `paint` | Optional version-1 appearance block: 1–36 ground material IDs, `roughen` in 0–1, north-up rows twice the terrain width/height. `.` derives the default; base-36 digits pick materials. Water/rock overrides warn and are ignored. It never changes terrain or rules. See [Ground](GROUND.md). |
| `buildings` | `{id, asset, at, facing, scale}`. `asset` is a world-catalog entry (swapping one for another with the same footprint changes nothing the rules see); `facing` is the side the door faces (`S` is −y, `E` is +x). The solid footprint comes from the catalog's `logical_footprint`, rotated and scaled. |
| `trees` | Procedural `[x, y]` / `[x, y, size]`, or model `{at: [x,y], size, asset}`. Procedural trunks use radius 0.18; model trunks use the catalog radius × size. Crowns are presentation. |
| `segments` | Axis-aligned `fence` (thin) and `wall` (0.5 thick) lines. They block the cells and edges they cross, so place them between cells or run a wall along a row and leave a gate cell. |
| `lamps`, `gates`, `bridges`, `wheels` | Mechanisms. Each names a `zone`. Lamps have `style` `fixture` (a placed model whose `lamp_glass` mesh the game lights; see `interior.lamp_fixtures`), `beacon` (procedural) or indoor `sconce`; gates have an `axis` (the direction the leaf spans); bridges list their sockets in build order, each on a water cell and neighboring the last. |
| `interior` | Optional `{exit: [x,y], furniture: [{kind, at, size}], host: {at, route}}`. Furniture blocks except rugs; the renderer makes a cutaway room. `host` supplies the owner's indoor positions when this template belongs to a resident. See [Village](VILLAGE.md). |
| `interior.outdoor` | Optional, for an outdoor room drawn like a room (Spindle Lane): `{sun: {rotation, color, energy}, ambient: {color, energy}, haze, backdrop, parallax}`. The view uses this daylight instead of the valley's warmth, `haze` fills behind everything, and `backdrop` (a PNG under `res://assets/`) hangs on the camera's far plane, drifting by `parallax` (0–0.6) and fading into the haze toward its foot. Presentation only. |
| `interior.life` | Optional street motions, presentation only: `smoke` `[{at, height}]` chimneys, `sway` (placed assets whose `cloth*` children move in the breeze), `tram` `{asset, out, stop, edge, fade, period, offset, travel}` (a placed asset's round trip along x: up from `out` to `stop` in `travel` seconds (default 7), a fifteen-second wait, back down, fading past `edge`), `gulls` `{at, height, count}`, `robots` `[{asset, path, speed, pause, loop}]` (a placed robot rolls along 2–16 points at up to 3 units a second, turning its `wheel*` nodes, waiting `pause` seconds at the ends of its round or at every lap with `loop`, and while the apprentice stands in its way; it never blocks a cell). Positions are map data, so they live here. |
| `boundary` | Optional `{apron, forest, mist}` scenic strips outside the logical bounds; apron is 16–64 units. |
| `villagers` | Optional unique `{id, at: [x,y], route: [[x,y], ...], home}` residents; identity comes from `content/villagers.json`. |
| `zones` | `{id, title, rect}` cell rectangles. A zone is **discovered** when the player first steps into it; only discovered zones are visible to the player's code. Overlaps resolve to the first listed. |

`<id>.quests.json` holds the lessons: `{id, title, concept, summary, requires, goal, focus, lesson, starter, hints, done, unlocks, optional, chapter}`. `unlocks` (optional) lists the abilities the lesson hands the player's code, from `AreaDef.CAPABILITIES` (`read`, `turn`); an unknown name rejects the document. A lesson hands them over when it becomes available (its goal needs them) and they are permanent once earned. Abilities are never saved: `Quests.capabilities` works them out from the quests reached. See [code that builds](../docs/PROGRAMMING.md#houses-trees-and-doodads).

`optional: true` marks a quest of a later chapter, and `chapter` is the heading it is listed under. The **main arc** is the quests that are not optional (`Quests.main`): the main arc is done when they all finish (`Quests.main_arc_done`), the title counts only it, and a main quest may not require an optional one. The journey's main arc is chapters 00–05 across the loft, workshop and lane.

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
| `scenes/world_view.gd` | `setup(area)`: places buildings, trees and mechanisms, owns the following camera, lighting and the lamp light pool. |
| `pipeline/world-catalog.json` | Asset authority and footprints; its `areas` block lists the documents. |
| `docs/PROGRAMMING.md` | The player-visible API. |

Nothing about a map lives in code any more. If you find a coordinate in a `.gd` file, it is a bug.

## 1. Plan one small change

Copy [the area brief](templates/area-brief.md). Draw a simple cell plan with spawn, paths, water, solid objects, programmable objects and destinations. State the gameplay purpose and visual focus. Keep a route to every interaction the player must reach, using the foot footprint rather than a line between centers. Keep the camera readable with the notebook open: it covers the right third of the screen.

## 2. Edit the document

Change the cells and entities, then run `scripts/test.sh`. `test/test_area.gd` validates every room of the journey and plays each workshop job's reference solution through real Python; the room tests (`scripts/test.sh flow`) prove reachability of every inspection, lamp and exit, and that the locks lock.


## 3. Present the land

For a Blender land model, edit its `.blend` and run `scripts/world-art.sh build <id>`; follow [the Blender guide](BLENDER.md). Generated land retains its soil sides, banks, rock stacks, fences and walls through `art/terrain_builder.gd`; `art/water_surface.gd` supplies the animated water tops and spray. `art/ground_skin.gd` supplies flat chunk meshes with continuous pictures, half-cell paint and ragged pixel borders from pure `GroundPaint`. Both are deterministic. Generated land remains a procedural test; selecting `ground.asset` uses the adopted model instead. Flat ground skips shadow casting. See [Ground](GROUND.md).

Use the fixed camera and shared lighting to judge a change: `scripts/play.sh --resolution 1600x1000 -s res://tools/area_shot.gd -- <area id> <png> <x> <y> <zoom> <lit 0|1>` renders any spot of any area and reports build time and frame rate. Review a whole-district view and a gameplay-zoom detail.

## 4. Walk and program it

Run `scripts/test.sh`, then `scripts/play.sh`. Hold directions around new obstacles, click destinations on both sides of them, build the bridge, open the gate, and read the objective pill and notebook through the quests. `VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/playthrough.gd -- "$PWD/.cache/playthrough"` plays the level through the real controls and saves a frame per quest. Use [the review checklist](REVIEW.md) to record the evidence.

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

Natural Sparks crossings await resource preparation and incremental scene construction under the [clockwork veil](UI.md#scene-change-veil), then render a hidden warm-up before revealing. Travel owns the walking animation until the visual arrival completes, so disabled input cannot turn the crossing into an idle slide. Arrival duration follows the actual distance at `LabWorld.STEP_SECONDS`; it does not speed the character up to fit a fixed wipe. Logical room state and the validated final cell remain separate from this presentation.

## Shared city time and service devices — 2026-11-02

Sparks rooms opt into the journey-wide saved clock/supply with `interior.city_network: true`. The room state contains derived `time` and `city_power` mirrors; `GameSession.cycle`, serialized as `city_cycle`, is authoritative and replaces cached-room copies on travel. Loading/Undo never derives supply from a renderer or an individual room snapshot. Archived journeys retain their authored lighting.

A lamp may name `automatic: true` for its initial dusk relay. `lamp_fixtures` maps each logical fixture to an existing placed model; up to 128 mappings are supported for the square’s street network. The default is manual, preserving the early workshop lessons and older maps. Saved `lamp_programs[id] = {day: bool, night: bool}` override the default. A `lamp_program` quest goal requires a known lamp with day=False and night=True. The new shop pair share one approach and appear together in their slate’s Devices list.

`interior.evening` owns Nell’s arrival and standing cells on the lane. `city-hall` is a separately saved 28×22 room using the existing cutaway-room loader and its own adopted shell/desks. Reciprocal, walk-through links own the entry cells; the hall’s hinged leaves provide presentation only. The square’s front corridor ends at its room link, leaving no orphan walkable cell behind the façade.

Automatic street service cells remain normal passages for ambient traffic. Quest connections and doorway corridors retain their reserved-space rules. A worker may reach its own authored service stop without being prevented by a reservation for that fitting.

## Reusable placed barriers and the shop rooms — 2026-11-03

An `interior.assets` placement may explicitly set `solid: true`. `AreaDef` resolves its world-catalog `logical_footprint` (local `[x,y,width,depth]`) through the placement's quarter turn and scale into `interior.solids`; `LabWorld` indexes those rectangles for the same foot-circle and passage checks as other obstacles. Rendering bounds never determine collision. The default remains visual-only. Unknown/malformed footprints, nonpositive scale and diagonal turns are refused. Offset pivots are retained, including town railing bays authored from their run start. Builder prop placement uses that same offset convention.

Rootward Square now uses these envelopes for the three market shop bodies, its modular railings/garden walls/piers and one replacement retaining-wall bay. New doors use normal reciprocal room links into `shop-bakery`, `shop-greengrocer`, `shop-tailor` (Finch & Thread), `shop-clockmaker` and `shop-apothecary`. All five are registered Sparks journey rooms with separate saved state and memory. Old square saves covered by repaired barriers move only their feet to a nearby reachable cell; progress remains intact. The upper park is background dressing. Trading and new shop quests remain proposed.

## Spindle strip revision — 2026-11-03

Square v6 moves the lane crossing to the wider high landing: `uphill.at = [0,12]`, cells `[0,10]` through `[0,14]`. Lane `town-steps` retains its own gate cells but now targets `[1,12]`, with wide arrivals `[1,11]` / `[1,13]`. Both lower eastward stair flights remain, with four tread rows beside the enlarged landing. The left park and promenade have explicit level-two support matching the adopted ground v3. Four unbuilt frontage courts are recorded in `content/development/spindle-strip-plan.json`; they grant no collisions or capabilities until actual buildings are authored.

(Superseded 2026-11-05: Thyme & Tonic is placed again as an original model with a working door; see the [Spindle terrace review](reviews/2026-11-05-spindle-terrace-and-apothecary.md).) The clockmaker/apothecary exterior links were removed with their temporary models. Their room documents remain in the journey catalog so existing saves can resume inside and exit to a safe strip cell. All five shops have empty furniture/inspection lists and retain only shell, doors and lamp fittings. New furnishings and models remain deferred. Old saved feet covered by new park furniture relocate to a nearby reachable cell while keeping programs and memory.

## Authored outdoor layout shelf

The square v7 extends logical bounds 16 columns west (88×64), translating all former square coordinates equally. `interior.stair_steps` (optional, 2–12) tells the walking surface how many steps an authored ground cuts each level into; the square's Blender flights have 5 (procedural stairs have 4), so feet and contact shadows sit on the visible treads. `interior.map_offset: [16,0]` records this rebase; saved states carry their offset, and pure normalization applies only the difference when restoring feet. `interior.layout: {rect: [0,0,28,55], items: [...], export: "content/development/layouts/haverlund-square.json"}` enables an editing surface and shelf. Rectangles and item IDs are validated. Stairs and walls are never part of it, and an optional `levels` list keeps it to some terraces. Since 2026-11-06 the square's layout is the whole square (`[0,0,88,64]`), and `layout.scenery` lists the asset types of authored placements a designer may move. A document's optional `walls` list holds walls drawn along cell edges: `{id, from: [x, y], to: [x, y], style}`, with corners on half-cell coordinates and a style from `AreaBuild.WALL_STYLES` ([build mode](BUILD.md#freedom-in-the-layout-2026-11-06)). Source/master revisions and world-asset builds remain separate from player edits. [Layout guide](../docs/concept/v0.8/square-layout.md).


The current Rootward Square is v8: restored pre-flat terraces, retained `[16,0]` map offset and extended incoming loading, with `interior.layout_epoch: 8`. `BuildLedger.saved_edits()` preserves retired layout edits in metadata and applies only the current epoch. Exported user sketches remain review artifacts. `interior.depth_fog` configures the lower atmospheric layer; it never changes walking rules. The clockmaker's active facade link is `(16,21)` westward into its central shop door. See [the restoration review](reviews/2026-11-04-square-restoration-and-clockshop.md).

Current clockshop document v4 grows to 14×14 without changing origin/door cells. Its fourteen inspection IDs are individually reachable and read through the normal F flow. The square depth configuration uses `height: -7.0` and `fade_top: -2.8`; a depth overlay fades actual wall geometry rather than clipping it at a surface.


## The high square: white mist

Rootward Square stands high over the harbour, and below its retaining walls the town drops out of sight into solid white. `interior.depth_fog` in `haverlund-square.json` configures one alpha-only height overlay (`art/depth_mist.gdshader`, built as `LowerTownMist` in `scenes/world_view.gd`):

| Key | Meaning |
|---|---|
| `fade_top` | World height (m, level 0 = 0) where the mist begins to thicken (-2.8). |
| `height` | Height where the fade would end (-6.0); the overlay is fully opaque well before it. |
| `solid_by` | Fraction of that range at which the mist is solid (0.7), so nothing of the lower town, grass included, shows through. |
| `day`, `night` | Mist colours: white by day, a moonlit blue haze (`1d2b3b`) at night, never a black void; both follow the shared city daylight. |
| `light_floor` | Height below which the town's glowing power pillars and conduits stop shining (-3.2) and fade out above it, so no light burns inside the mist. The fittings stay whole below it (unlit glass, stone and brass) and the mist covers them. Applied through the `light_floor` shader global; areas without fog leave it at -1000. |
| `edge` | Optional `{start, end, max}` edge haze: the dressed town beyond the area's rectangle thins into the same mist, from `start` metres out to `max` opacity by `end`. Spindle Lane uses `{1, 18, 0.92}`; the square has none. |

The overlay samples the depth texture, so it needs no geometry below the line: anything beneath it, and the sky behind, is white. Masonry above the line is untouched. `test_square_lighting` checks the layer, its night colour and a gradual transition. Spindle Lane has the same layer (2026-11-06): its lower town at z -8 is under the mist (the houses that stood there were removed) and the town round it fades with the edge haze; `test_lane` checks both. See [the texture pass review](reviews/2026-11-06-texture-pass-and-lane-fog.md).
