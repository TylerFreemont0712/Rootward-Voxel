# Rootward Voxel

A standalone Godot game about learning to program by changing a fantasy world with real Python. **Sparks & Machines** is the selected main game: a young lodger’s first morning above an automaton workshop in Haverlund. The world uses textured 3D geometry; the player is the approved painted boy with directional walking animations. Kindle Hollow and Village Morning are archived for later rework; their code, content and separate saves are retained.

The current asset cleanup has removed 29 retired props from the build shelf and legacy village placements; 16 deletion requests remain open. The original 50-model village library is now a 42-model active shelf; the historical index and project saves are retained. See the [deletion review](pipeline/reviews/2026-10-29-asset-deletion-pass.md).

## Run

```sh
scripts/play.sh
```

The game starts full screen with a compact 1920×1080 desktop layout. F11 toggles windowed mode; Settings offers 60–150% interface scale and separate 10–26 px code text. Lesson blocks use compact rows, and the tested Python fills the available drawer height. Existing display preferences migrate once to this layout, then remember subsequent choices. See [the desktop and room review](pipeline/reviews/2026-10-26-compact-desktop-and-room.md).

Godot 4.7.2 is installed here. You can also open the root `project.godot` in the editor. The local ignored `sandbox/runtime/` already contains the Python/WASI runtime; on a new Linux x86_64 checkout, run `scripts/setup-runtime.sh`.

For one-click Linux launching, run `python3 scripts/install-desktop.py` once. It adds **Rootward Voxel** to the applications menu and your existing desktop folder, with a lantern-and-roots icon. The shortcut opens this checkout directly without a terminal. Run the installer again if you move the project or change the Godot location; it records the current Godot executable, including a `GODOT_BIN` override. `--prepare-only` writes a reviewable launcher to `.cache/desktop/rootward-voxel.desktop` without installing it.

On a hybrid-graphics laptop the game uses the system's default GPU, usually the integrated one, which runs it comfortably at 60 fps. To draw it on the NVIDIA card instead (faster, but more power and heat), start it with `ROOTWARD_GPU=nvidia scripts/play.sh`, or install the shortcut with `python3 scripts/install-desktop.py --nvidia`; running the installer again without `--nvidia` switches the shortcut back. See the [frame rate review](pipeline/reviews/2026-10-25-frame-rate-and-gpu.md) for measurements.

The title opens over the loft: **Continue** resumes Sparks, **New game** goes directly to character naming, followed by **Character**, **Settings**, **Asset Showcase (Dev)** and **Quit**. Starting over replaces only the Sparks save. Archived saves do not redirect Continue or make it appear when there is no Sparks save. Existing application and save filenames stay compatible.

**Asset Showcase (Dev)** opens a separate, initially empty stage for buildings and props. Search the existing model catalog, select an asset, drag to turn and use the mouse wheel to zoom. Quarter-turn buttons, reset, auto-rotation, a metre grid and the approved boy as a scale guide help inspect details. **Reload** refreshes a rebuilt runtime model; **Clear** empties the stage. Esc or Back to title returns without changing progress. The entry is development-build-only and can be hidden later by setting `rootward/development/asset_showcase_on_title=false` in `project.godot`. New assets enter through the existing world catalog/build pipeline. See [the showcase review](pipeline/reviews/2026-10-29-main-route-and-asset-showcase.md).

Asset changes now use the showcase’s **Request update**, **Request new** and **Delete** actions. Notes and dropdown references become durable briefs in the top-level [asset-requests/](asset-requests/README.md) folder, with source/runtime paths and usage links for the agent. **Requests** opens the work queue; **Finished** filters delivered models awaiting review, and **Accept finished** clears reviewed work from that queue. An unused asset can be removed from the project after the deletion summary; an in-use asset creates a dependency-linked removal request first. [Workflow review](pipeline/reviews/2026-10-29-asset-request-workflow.md).

Pending deletion marks an asset name with a red tint and **X** at the right; pending updates use yellow and a square. Finished work clears these marks. Pip, Wick, Trowel, Heron, Tender and Tally now have detailed concept-led models and subtle independent eye blinks. Pip carries packages in his compartments, with the bag removed. Inspect them in the showcase or [see the native comparison gallery](docs/concept/v0.72/robot-model-refinement.md).

## Sparks & Machines — the workshop and the town

Plants now use pointed, gently folded leaves, branching sprigs and simple flower petals throughout the loft, workshop, lane and square, including window boxes and street trees. Thirty-five existing Blender models were revised through the normal asset pipeline; see the [plant review and comparisons](pipeline/reviews/2026-10-30-plant-style.md).

Choose **New game → Begin new journey**. Start beside the bed, walk to the desk and read Nell’s note under the mug. The note is put away when read. Use or click the loft terminal to open **Field Notes /00 · Hello, Hotaru**. The loft has bespoke outlined Blender furniture, painted oak and plaster, a slept-in teal patchwork bed, rag rug, desk and screen terminal, filled bookcase, a loose coat over the chair, a lower bag on taut straps, luggage, books and plants. The approved player and the two other journeys retain their art and lessons.

Begin with an editable message block or switch to Python; both run real Python through the sandbox. The first page shows where to type, then **Test code**. Your actual words ghost-type above the player in the room, including other names and multiple print calls; the terminal output and executed lines show what ran while Hotaru stays asleep. Replay repeats the ghost output. **Speak** feeds that same validated message to her. Hotaru has spent much of the week dozing while Nell is out on calls. A greeting addressed to her rings the terminal’s addressed-message bell, gets her attention and stamps the first job DONE. The player is an ordinary new lodger; their origins remain open. Hotaru’s waking question leads to three replies and a short conversation; the first page stays available for further experiments. Editing invalidates an old test; syntax errors identify their line and give plain help. Your code and Hotaru’s awake state persist through Continue. Hotaru’s waking conversation then sends the traveller to Nell’s field tablet, lying on the bed; picking it up is part of the room, not a menu. E and Field Notes open the relevant lesson; the pinned ticket opens the job book. The /00 page remains available for experiments.

The loft is the workshop’s upper floor, seen from the yard side, and matches the building on the lane: the three windows on its street wall and the round window and two more on its yard gable are the ones you see outside. A window seat, a wardrobe, a rocking chair with a knitting basket and two big potted plants fill its space. Go down through the railed stairwell in the middle of the floor to enter **Nell’s workshop**: the staircase comes down to the north wall beside the stove, changes the sprite’s elevation on every tread, and leads back up from there. Twenty-one outlined Blender assets furnish the herringbone room: workbenches, parts drawers, tool wall, assembly table, stove and kettle, a worn armchair, job board and green shop doors. The north wall is shared with Nell’s house next door, so it has a shelf of jars and parts where a window would look into her rooms. The downstairs furniture is smaller while the traveller keeps his approved loft size. A food cupboard holds an open bread tin and cut slices beneath a clock, giving Nell’s note a place in the room. A service trolley, books, plants and used tools fill the working corners. See [the workshop review](pipeline/reviews/2026-10-27-workshop-floor.md) and [editable workshop sources](art/source/world/sparks-workshop/v1/README.md).

The job board, food cupboard and repair corners offer inspections with **F**. Each floor retains its own position and program memory; notebook drafts and greeting progress travel with you, and **Continue** can resume downstairs. Repeated refusals reuse one visible message. The [loft and stair review](pipeline/reviews/2026-10-27-loft-lived-in-and-stairs.md) records the earlier room pass.

The loft keeps its desk computer for the first greeting. Downstairs, the zone node is a wall screen with a brass-collared socket: jack Nell’s field tablet into it once and the tablet remembers that room’s link. The screen and editor show the same zone name, and a lighting Test updates the real screen. Code reaches only what you stand beside: a lantern’s page opens beside the lantern, a whole zone at the wall screen, and Field Notes anywhere else is plain open code; F works within about a cell. The route to a click is drawn as round outlined dots with a ring at the end, and a panel or item you are heading for glows. See [zone terminals](docs/concept/v0.7/09-zone-terminals.md), the [tablet and wall screen review](pipeline/reviews/2026-10-27-tablet-and-wall-screen.md) and the [reach and markers review](pipeline/reviews/2026-10-27-reach-and-markers.md).

After Hotaru’s waking conversation, the next playable chapter is **The waiting ticket → The landing light → The morning round**. Read Nell’s ticket, restore the new stair lantern with a method call, then bring all three workshop fittings on with a loop. A worked example introduces lists and `for` loops one lamp at a time. Four short scenes and reply choices connect the jobs and leave a complaint from the north gate waiting for Nell. The notebook keeps the greeting and each job’s editable Python separately. Test previews translucent light at the actual fittings; Apply commits the same validated result. Story conversations use the two illustrated portraits, clear speaker highlighting and saved dialogue; ordinary object descriptions appear beside the object as dismissible speech bubbles. The stair lantern hangs by the foot of the stairs and stays visible while its routine is tested. Old saves keep their progress, and read scenes stay read after Continue. See [the first workshop jobs](pipeline/reviews/2026-10-27-workshop-first-jobs.md). The north-gate job and Nell’s return remain later work.

Walk out through the green street doors onto **Spindle Lane**, the journey’s first outdoor scene: a cobbled terrace above Haverlund with a painted harbour behind it. Three houses stand in a row along it: Nell’s workshop, its loft jettied over the street as a half-timbered upper floor, the doors a third of the way along as they are inside; Nell’s own stone house with its plum door; and Bram’s salmon cottage behind his white fence. Across the lane are telegraph poles and their wires, a post box, a notice board, a small green with two blossom trees, a bench and a pump, an allotment and shed, and at the rail a bench and a coin telescope beside the iron gate at the top of the steps into town. Steps lead down to the tram halt, where tram No. 7 comes up out of its cutting under the wire about once every minute and a half, waits at the shelter by the buffer stop, and goes back down. Chimneys smoke, the washing moves and gulls wheel over the harbour. The first time you step out, Hotaru has a few words about the street; after that, F beside her gets a remark. Fifteen places answer F, and the gate lamp opens its code from beside it with the tablet, though nobody has asked anything of it yet. The lane keeps its own position and program memory like the floors, and **Continue** can resume there. It is open whenever the workshop is; a later story step may lock it. See [the Spindle Lane review](pipeline/reviews/2026-10-28-spindle-lane.md) and [its sources](art/source/world/sparks-lane/v1/README.md).

From the iron gate at the top of the town steps, walk down into **Rootward Square**, the town's hub: a separate saved 72×64 area (version 3, rebuilt 2026-10-29).

- **Arrival:** you walk on through the gate and down into the head of a stepped street in its south-west corner, then down two flights past a café corner. Either side of the steps, and any cell of the street, is the way through.
- **Around the square:**
  - **West side:** three shops (Morning Loaf, the greengrocer, Finch & Sons) and a fruit market hall, with a news kiosk and a fingerpost at the arrival.
  - **North side:** Haverlund Savings (the bank), the guild hall, the post office and the Harbour Cup café, with a small walled park either side of the hall.
  - **The middle:** the Rootwell, 35 % larger than its model, on a wide ring of setts. Glowing conduits climb its steps, and eight planter-benches face it.
  - **Market:** two rows of stalls back to back, with lights strung along the aisle.
  - **East side:** a lawned garden with trees and benches.
  - **South side:** a promenade over the lower town with benches, a coffee cart and a telescope. The building yard is in the south-east.
- **Lighting:** banner lamps round the Rootwell and along the edges, low lit bollards along the main walks, and festoons over the market and the café.
- **Power:** whole glowing glass pillars hang down the retaining walls.
- **Doors:** the workshop's street doors swing open as you go through them, and you keep walking through every scene change.
- **Exits:** three ways are open for later areas: Hill Street to the north-west, Lantern Row to the north-east and the Harbour Steps down to the south-east.
- **The town round it:** past the balustrades, the lower town's houses stand 10 m down. Houses climb the hill to the west and the upper town rises behind the north buildings.
- **Spindle Lane:** it now stands in the same town instead of floating.
- **Modular build:** every building, railing bay and house is its own placement on one base ground model.
- **Unchanged:** the robots, banners, smoke, gulls, service screen, three lamps and the walk back up to the lane.

See the [square hub review](pipeline/reviews/2026-10-29-square-hub-v3.md) and the [town-centre pass](pipeline/reviews/2026-10-29-square-city-centre.md).

Scene changes now go through a clockwork veil (a gear-edged curtain with meshed gears turning on it) and the apprentice walks through doorways and up stairs rather than floating; the workshop doors open on black, and the fountain's water and the building layers no longer flicker. See the [doorways, scene changes and flicker review](pipeline/reviews/2026-10-30-doorways-transitions-and-flicker.md).

## Archived: Village Morning — the first slice

Retained for rework and regression checks, outside the public title flow. Development tools can still call `start_new_game("village-morning")` or `continue_game("village-morning")` explicitly. Wake beside your bed in a unique furnished room. **Hotaru**, a tiny fairy who follows you, guides the opening without player reply choices. Continue through her short explanation; the last page opens the relevant Field Notes automatically:

1. **Field Notes / 00 — Saying Hello.** Build a `print("Hello, Hotaru!")` block or write Python. **Test code** shows your voice in a separate preview and highlights the actual executed lines. **Speak** commits your words. A successful hello automatically starts Hotaru’s First Steps explanation, whose final page opens /01.
2. **Field Notes / 01 — Your first steps.** Edit code-like key events (`when key W: y += 1`) or write Python. Each block’s **>** tests only that event; **Test code** checks the whole program. Generated Python appears below the blocks during testing, with Replay, Pause and Next line. The separate mini-room demonstrates zero movement, one step or an overshoot; green/red blocks show what passed or needs fixing.
3. **Apply**, then **Continue · try my keys**. Practise all four directions in the actual room. The test window cannot move your real character or award practice. Edits clear old proposals/replays; Undo restores the last applied map.
4. Walk to the sill to enter the 64×72 village. Follow the lane to **Rootward Square**, its monumental enchanted tree and the **Town Hall**, which has its own saved council room. The cottage returns you one tile outside the closed door. The next inward attempt toward the frame opens the leaf and fades inside; walking onto the outside landing does not trigger entry early. Indoor floors end at the sill, and furniture sits against the walls. Your room, voice, controls and independent editor drafts persist through Continue.

Available keys are **W/A/S/D** and **UP/LEFT/DOWN/RIGHT**, with four grid directions. Click travel opens after practice. Hotaru follows as a tiny glowing orb with fluttering wings. Her generated black-haired fairy portrait appears in the same visual novel dialogue interface as the other characters. Talk with F or her speech bubble; read pages persist. Optional spoken replies unlock after Saying Hello. Portrait dialogue guides character speech; scenes can use a linear conversation without a topic menu. Her art builds through `scripts/art.sh`, with no collision or network requirement. The village now has the original cottage, the town hall and its council room, and the giant Rootward tree. Rootward uses a permanent trunk cutaway so its canopy does not hide the town; roots, lanterns, gold seams, ward stones and drifting lights remain visible. Village residents and further lessons remain future work. See [the trunk-view review](pipeline/reviews/2026-10-26-rootward-trunk-cutaway.md). See [the first-morning guide](pipeline/MORNING.md) and [guided tutorial review](pipeline/reviews/2026-10-26-guided-tutorial.md).

Village Morning now has a matching illustrated art study: a honey-timber cottage with violet tiles, a leafy voxel oak, low garden fences and amber hanging lanterns in limestone planters. Find the cottage beside the original home, with the fence and garden lamp across its lane; the village’s broad oaks use the new leaf-clump model. Fine sepia edges keep the shapes readable beside the painted boy. The existing camera, home and saved cottage rooms are preserved. See [the illustrated village review](pipeline/reviews/2026-10-26-illustrated-village.md).

## Archived: Kindle Hollow controls and systems

The following describes the retained Kindle Hollow implementation, accessible to development tools through an explicit `kindle-hollow` journey ID. Its builder, lessons and materials remain available for reuse. Village Morning uses its programmed movement keys.

| Key / action | Does |
|---|---|
| **WASD / arrows** (hold) | Walk one cell at a time, repeating. Four logical directions, shown as screen diagonals. |
| **Click** a cell | Travel there along a safe route, and read what is on it (terrain, zone, lamp/gate/bridge ids). |
| **E** | Open or close the **Village Notebook** (the code menu). |
| **F** | Talk to the resident under the speech bubble, or use the working thing under the hand (clicking either works too). Walk through a front door to go in or out. |
| **B** / hammer | Outdoors: builder, ground paints and object materials. Indoors: this home's room materials. |
| **Ctrl+Enter** | Run your program (preview). |
| **M** / **J** | Map / Journal. |
| **Esc** | Leave the text field, then close the notebook, then open the pause menu. |
| **Mouse wheel**, **F11** | Camera zoom, fullscreen. |

Residents with something to say wear a mark over their heads: **!** for something new, **?** when they can help with the lesson you are on. Beside one, a speech bubble shows who F would talk to; beside a working thing, a hand. Nobody walks through anybody: residents step round you, and you stop at them. Talking to a resident opens a **visual novel conversation** with that person’s detailed painted portrait, a bottom dialogue box, response choices, typewriter text, History, Auto, Skip read, Hide UI and settings. Portraits use the smaller scale, raised about 125 px at the standard size to show shoulders and upper body. Optional **Show code** explanations teach variables, loops, functions, lists and conditions; Copy example / Open notebook lets you try them while preserving your draft and the usual Run → preview → Apply flow. See [conversations and portraits](pipeline/DIALOGUE.md).

The HUD shows where you are, a translucent quest/next-step panel on the left, and a small row of tools. Quest completion appears in that same left panel. Code appears in a stitched side notebook on the right, with the camera making room for your character. Both journeys share this layout; Village Morning adds its separate movement test window without reserving more camera space. See [the interactive notebook review](pipeline/reviews/2026-10-25-interactive-notebooks.md).

### The Village Notebook

Four tabs: **Code** (a Python editor with colors, auto-indent, bracket pairing and completion that knows the game's own API), **Lesson** (the current quest as a short lesson with runnable examples and a three-step hint ladder), **Reference** (every object you can use, searchable, plus Python reminders) and **World** (what your program can currently see). **Run** previews; **Apply** commits that exact preview; **Undo** reverts the latest committed program or prop action (you stay where you are). Errors point at the line, explain the mistake in plain words, and suggest the name you probably meant.

### The level: Light the Hollow

Five quests, each teaching one idea: calling a method (**A spark at the landing**), lists and `for` loops (**Light the green**), variables (**A way across**: rebuild the mill bridge), `if`/`else` (**The night gate**) and functions (**Kindle the hollow**). The expanded valley has fourteen zones and twenty-three buildings, including North Common, Cedar Rise and the Eastbank neighborhood. The existing gate and bridge open the way to these districts. Your notebook only knows places you have visited, so exploring is part of the puzzle. Lighting lamps warms the whole valley. See [the programming guide](docs/PROGRAMMING.md) for the API.

Progress (world, quests, discovered places, your code, your name) saves automatically to this project's own user directory, `RootwardVoxelLab`, and **Continue** restores it. Settings (fullscreen, interface size, camera zoom, code text size, completion) live there too.

Each accessible house opens a separate furnished room. Cottage, workshop, loft and mill templates share artwork while keeping each house’s lamp state, discoveries and program memory separate. **Continue** can resume inside a house; the exit returns to that house’s doorstep with the valley as you left it. New houses placed through the builder also receive their own rooms. See [village and house systems](pipeline/VILLAGE.md).

Fifteen new painted materials add parquet, tiles, plaster, wallpaper, timber panels, brick, riverstone, slate/cedar shingles, copper, linen, quilts and leather. **B → Move → select an object → Materials** finishes individual parts on 91 supported assets; **Land → Floors** adds four paints. Indoors, **B → Room materials** changes six surfaces for that house. Finishes support Original, undo/redo and saved Continue. The four room templates have distinct palettes. See the [material library and controls](pipeline/MATERIALS.md).

## Art direction and workflow

The [Rootwell beacon asset concept](docs/concept/v0.72/rootwell-beacon.md) supplies the approved isolated front/rear paintings of the square’s central power source. Both transparent PNGs are in v0.72, with exact prompts and provenance; the existing in-game model is retained for a later source revision.

The [five background house studies](docs/concept/v0.72/background-houses.md) vary the town’s residential heights and rooflines. Their [material pack](docs/concept/v0.72/house-textures.md) supplies plaster, roof tiles, stone, timber and painted boards in three colours each. Native maps have their own source folder; `scripts/art.sh` builds the dedicated `assets/world/textures/seaside-houses/` output. House geometry and placements remain concept work.

The [Wick and Tender movement study](docs/concept/v0.72/wick-tender-movement.md) supplies four detailed rolling keys in each of four independently painted directions, preserving the lamp hand and asymmetric shell details. The accompanying [three seaside building directions](docs/concept/v0.72/seaside-buildings.md) show a chandlery, sail loft and neighbourhood baths from complementary street/rear views. These are art studies for review; the existing square models remain selected.

The [v0.72 cast and rolling-robot gallery](docs/concept/v0.72/cast-and-robots.md) contains five new shared-frame cast skins, six wheeled robot concepts, sprite/movement sheets and animated previews. The cast follows the selected concept wardrobes and compiles through `scripts/art.sh`; existing journeys retain their current artwork. The robot sheets remain design and motion references pending runtime registration.

The [doorway and test-window correction](pipeline/reviews/2026-10-25-doorway-and-test-window.md) aligns indoor frames and their collision, preserves walking animation through travel, and blocks the Concept Cottage’s visible wall edges. Known old saves at those edges recover without losing progress.

The [steps, doors and concept-cottage pass](pipeline/reviews/2026-10-25-steps-doors-and-cottage.md) makes feet follow house treads and terrain stairs, opens doors as you walk in, and repairs the larger buildings’ surface layering and the Lantern Loft turret. **B → Objects → Houses → Concept Cottage** offers a new building modeled from scratch after the left-hand cottage in the concept, with imagegen-painted oak and violet glaze, individual tiles, a limestone arch, flower box and a saved interior.

The latest [building pass](pipeline/BUILDINGS.md) brings the existing roofs into one painted tile family, gives older houses clearer oak-and-stone entrances, aligns the loft/mill doors with their approaches, and polishes the lamps. The quest mill's larger wheel now dips into the river and connects to the building through a fixed axle/bearing. Hearth Bakery and Riverside Smithy are placed in the village and available under **Objects → Houses**, with saved interiors and material controls.

The [voxel village concept](reference/voxel-isometric.png) is the target. The valley has violet/teal tiled houses, cobbled courts, full tree crowns, stone banks and a turning wheel. Water has layered flowing textures, shallow banks, foam, small waves, expanding ripples and wheel spray. A forest apron and faint mist continue beyond the playable boundary, hiding the terrain underside near the start.

The boy and all five residents use the approved **eight-pose painted walk** layout in four diagonal views. Each resident has separately painted artwork for every pose, sharing the original frame regions, timing, foot origin, scale and idle behavior. SW mirrors SE and NW mirrors NE, preserving pose order. Idle uses the ninth, neutral pose with a subtle breath; the two front views blink every 6–7 seconds. When scenery covers the character a faint silhouette still shows. The assembled cutout rig remains rejected and inactive; clothing customization is deferred. See [the character guide](pipeline/CHARACTERS.md).

Mira's [review and animated previews](pipeline/reviews/2026-10-23-mira.md) show the two characters together and her appearance at gameplay scale.

Houses and the original clearing's land load from editable **Blender sources exported to GLB**. Open `art/source/world/cottage/v1/model.blend`, edit visually, save, then run `scripts/world-art.sh build cottage` ([Blender guide](pipeline/BLENDER.md)). The violet-roofed **log cabin** (three of Kindle Hollow's homes) and the hanging-lantern **lamppost** (every post lamp) were recreated from the concept image and adopted the same way, from `art/source/world/log-cabin/v1` and `lamppost/v1` ([review](pipeline/reviews/2026-10-23-log-cabin-and-lamppost.md)). The homes are 5-cell **log-cabin-large** houses (the miller's under a teal roof). The delivered **texture pack** is wired in through `pipeline/texture-catalog.json`, and `scripts/world-art.sh retexture <id>` bakes it into an adopted source ([review](pipeline/reviews/2026-10-23-bigger-houses-textures-and-build-mode.md)). Kindle Hollow's land uses `art/terrain_builder.gd` and the continuous ground skin, a procedural test pending Blender adoption.

Playing needs no Blender, ComfyUI, AI service or network. Optional tools enter at a documented source boundary. The commands are:

```sh
scripts/art.sh                         # accepted character/icon/ground sources → runtime art
scripts/world-art.sh build cottage     # saved Blender source → checked runtime GLB
scripts/test.sh                        # all automated checks
scripts/screenshot.sh                  # tour of every screen and of build mode → .cache/, selected frames → evidence/
```

Six scenery models are on the **studio build shelf**: Hearth House, Lantern Loft, Brook Mill, Hearth Oak, Ridge Cedar and River Willow. Choose them in Build mode to place, move, remove, undo and save them. Brook Mill's wheel is decorative. These models also appear in the expanded districts. See the [scenery sheet](evidence/scenery-candidates.png) and [village review](pipeline/reviews/2026-10-23-village-expansion.md). The original **Doodads** tab holds thirty-two props. **Fifty additional objects** now fill five new shelves: **Furniture**, **Workshop**, **Market**, **Garden**, and **Village & Magic**. The studio builder has **98 entries, including 82 props**. Sixteen new pieces work: open a chest, pull a lever, run a pump or wheel, swing a bell, and light fires, crystals and lanterns. Use **F** beside them or `world.prop(id).set_active(True)` in the notebook; their states save with the journey. See the [50-object index](pipeline/BUILDER_LIBRARY.md) and [visual review](pipeline/reviews/2026-10-24-builder-library.md).

Build mode's left rail has **Move** (1), **Delete** (2), **Objects** (3) and **Land** (4). Land's **Terrain** and **Water** tabs shape the valley like an island in Animal Crossing: drag to raise land into terraces (levels 1 and 2) or lower it again, click at the foot of a cliff to build stone stairs, dig ponds and streams, and fill them in. Cliffs block walking and stairs climb them; water that runs off a terrace onto lower water falls as a waterfall. Each drag is one undo step, saved with your journey, and nothing you need may be cut off; see [shaping the land](pipeline/BUILD.md#shaping-the-land). Land is also for ground painting: drag to paint half-cell ground, use `[`/`]` for brush sizes, Alt-click or I to pick, and Eraser to restore the natural surface. Release commits one undo step; right-click/Esc cancels the proposal. Grass, dirt and cobble meet along ragged pixel borders. Painting changes appearance and leaves walking and quests unchanged. Painting lives in the **Land** menu; the tray runs along the bottom of the screen with search (Ctrl+F) on Objects and scrolls sideways. See [ground painting](pipeline/GROUND.md).

## Where things live

| Folder | Holds |
|---|---|
| `content/areas/` | **Area documents**: terrain, buildings, trees, lamps, gates, bridges, zones (`<id>.json`) and quests/lessons (`<id>.quests.json`). Sparks uses `workshop-loft`, `workshop-floor`, `haverlund-lane` and `haverlund-square`; legacy areas and room templates remain loadable. |
| `core/` | Pure rules: `area_def.gd` (parse/validate a document), `lab_world.gd` (walkability, routes, commands), `quests.gd`, `error_advice.gd`, `api_reference.gd`. No nodes, no files. |
| `app/` | `game.gd` (flow: title, play, pause, saves), `session.gd` (one playthrough), stores for areas, saves and settings. |
| `scenes/clearing_view.gd`, `art/` | The 3D view (data-driven, following camera) and its builders: terrain, mechanisms, materials, the sprite actor. |
| `ui/` | The interface kit and screens ([UI guide](pipeline/UI.md)). |
| `sandbox/` | Copied, pinned Wasmtime/CPython WASI runner and the Python harness that builds the `world` objects. |
| `pipeline/` | Playbooks, catalogs, importers and reviews. `art/source/` holds versioned sources and editable Blender masters. |

The [art brief](reference/README.md), [v0.6 spec](docs/concept/v0.6/04-voxel-world-prototype-spec.md), and [original art/AI research](docs/concept/v0.6/05-voxel-art-and-ai-research.md) stay with the project. The spec distinguishes the working slice from later gates. Follow [the pipeline](pipeline/README.md) for characters, [world assets](pipeline/WORLD_ASSETS.md), [areas](pipeline/AREAS.md), the [interface](pipeline/UI.md) and [review](pipeline/REVIEW.md).

## Checks and captures

```sh
scripts/test.sh
scripts/screenshot.sh
```

The game draws at most 60 frames a second (its movement runs at 60 Hz) and 30 while another window has focus, so a fast screen does not work the graphics card for nothing. `tools/perf_probe.gd` measures what a frame costs in everyday scenes; see the [frame rate review](pipeline/reviews/2026-10-25-frame-rate-and-gpu.md).

**Build mode** (press **B**, or the hammer) lets you place, move, turn and delete houses, trees and doodads, with undo and redo, a tray of the real models, a details panel on the right (a live turning picture, a facing compass to set which way a thing faces, and the code for lamps, gates, bridges and working props, and for houses, trees and doodads once the optional second chapter's lesson "Face the lane" has taught it: your Python can read them and turn houses and doodads, with a preview, Apply and Undo; see [the programming guide](docs/PROGRAMMING.md#houses-trees-and-doodads)), a green or red ghost with a reason, and a check that nothing you need is cut off; what you build is saved with your journey. See [build mode](pipeline/BUILD.md). The [village review](pipeline/reviews/2026-10-23-village-expansion.md) records house travel, isolated saves, resident art, water and boundary captures. The library adds 570 model/rule/WASI checks and 16 integration checks; windowed reviews cover every model and all sixteen F actions at 1600×1000 and 1280×720. The tests exercise the area documents and the five-quest arc with real Python/WASI (every reference solution completes its quest, every starter does not), atomic world commands, grid steps and routing on the expanded map, preview/apply/undo/revert, zone discovery, saves, the editor and the menus, and the sprite/idle contract. `tools/playthrough.gd` plays the whole level through the real controls; `tools/movement_review.gd` and `tools/facing_review.gd` drive real mouse and held-key input; `tools/ui_tour.gd` captures every screen. The [animation review](pipeline/reviews/2026-10-23-approved-directional-walk.md), the [world review](pipeline/reviews/2026-10-23-painted-and-blender.md) and the [Kindle Hollow review](pipeline/reviews/2026-10-23-kindle-hollow-and-notebook.md) record what was checked. Selected captures are in `evidence/`; temporary frames and logs belong in `.cache/`. Review and test runs set `VOXEL_LAB_FRESH=1`, which keeps them away from your saves.

This project has its own application identity and save directory, `RootwardVoxelLab`. The WASI runner is a copied, pinned boundary with hashes in `sandbox/PROVENANCE.json`; it does not load scenes or saves from the main Rootward game.

Rootward Square and Spindle Lane use [framed power conduits](pipeline/reviews/2026-10-29-integrated-power-conduits.md) recessed into paving and fitted around stairs and thresholds, with glowing glass power pillars down the retaining walls and conduits up the Rootwell's steps. The lane’s center stairs supply the street and tram platform, and the routes continue beyond the area edges. This is currently visual scenery.
