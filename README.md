# Rootward Voxel

A standalone Godot game about learning to program by changing a fantasy world with real Python. You are the new lamplighter's apprentice in **Kindle Hollow**, a 96×80 voxel valley whose lanterns have gone dark. Walk the valley, visit homes and residents, open your notebook, write code, preview what it would do, and make it real. The world uses textured 3D geometry; the player is the approved painted boy with directional walking animations.

## Run

```sh
scripts/play.sh
```

Godot 4.7.2 is installed here. You can also open the root `project.godot` in the editor. The local ignored `sandbox/runtime/` already contains the Python/WASI runtime; on a new Linux x86_64 checkout, run `scripts/setup-runtime.sh`.

For one-click Linux launching, run `python3 scripts/install-desktop.py` once. It adds **Rootward Voxel** to the applications menu and your existing desktop folder, with a lantern-and-roots icon. The shortcut opens this checkout directly without a terminal. Run the installer again if you move the project or change the Godot location; it records the current Godot executable, including a `GODOT_BIN` override. `--prepare-only` writes a reviewable launcher to `.cache/desktop/rootward-voxel.desktop` without installing it.

On a hybrid-graphics laptop the game uses the system's default GPU, usually the integrated one, which runs it comfortably at 60 fps. To draw it on the NVIDIA card instead (faster, but more power and heat), start it with `ROOTWARD_GPU=nvidia scripts/play.sh`, or install the shortcut with `python3 scripts/install-desktop.py --nvidia`; running the installer again without `--nvidia` switches the shortcut back. See the [frame rate review](pipeline/reviews/2026-10-25-frame-rate-and-gpu.md) for measurements.

The game opens on a title screen drawn over the live valley: **Continue** (when there is a save), **New journey** (name your apprentice), **Character**, **Settings**, **Quit**. The boy is the player. Mira is the village cartographer, joined by Rowan the millwright, Bram the carpenter, Tessa the gardener and Nell the herbalist.

## Playing

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

The HUD is deliberately small: where you are, the current quest, and four round buttons. Code appears only when you ask for it. The notebook slides over the right of the screen and the camera makes room so you can still see your character.

### The Village Notebook

Four tabs: **Code** (a Python editor with colors, auto-indent, bracket pairing and completion that knows the game's own API), **Lesson** (the current quest as a short lesson with runnable examples and a three-step hint ladder), **Reference** (every object you can use, searchable, plus Python reminders) and **World** (what your program can currently see). **Run** previews; **Apply** commits that exact preview; **Undo** reverts the latest committed program or prop action (you stay where you are). Errors point at the line, explain the mistake in plain words, and suggest the name you probably meant.

### The level: Light the Hollow

Five quests, each teaching one idea: calling a method (**A spark at the landing**), lists and `for` loops (**Light the green**), variables (**A way across**: rebuild the mill bridge), `if`/`else` (**The night gate**) and functions (**Kindle the hollow**). The expanded valley has fourteen zones and twenty-three buildings, including North Common, Cedar Rise and the Eastbank neighborhood. The existing gate and bridge open the way to these districts. Your notebook only knows places you have visited, so exploring is part of the puzzle. Lighting lamps warms the whole valley. See [the programming guide](docs/PROGRAMMING.md) for the API.

Progress (world, quests, discovered places, your code, your name) saves automatically to this project's own user directory, `RootwardVoxelLab`, and **Continue** restores it. Settings (fullscreen, interface size, camera zoom, code text size, completion) live there too.

Each accessible house opens a separate furnished room. Cottage, workshop, loft and mill templates share artwork while keeping each house’s lamp state, discoveries and program memory separate. **Continue** can resume inside a house; the exit returns to that house’s doorstep with the valley as you left it. New houses placed through the builder also receive their own rooms. See [village and house systems](pipeline/VILLAGE.md).

Fifteen new painted materials add parquet, tiles, plaster, wallpaper, timber panels, brick, riverstone, slate/cedar shingles, copper, linen, quilts and leather. **B → Move → select an object → Materials** finishes individual parts on 91 supported assets; **Land → Floors** adds four paints. Indoors, **B → Room materials** changes six surfaces for that house. Finishes support Original, undo/redo and saved Continue. The four room templates have distinct palettes. See the [material library and controls](pipeline/MATERIALS.md).

## Art direction and workflow

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
| `content/areas/` | **Area documents**: terrain, buildings, trees, lamps, gates, bridges, zones (`<id>.json`) and quests/lessons (`<id>.quests.json`). `kindle-hollow` is the game; four village room templates and the original `rune-mill` clearing are also loadable. |
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
