# Art, area and movement pipeline

This is the active pipeline for the approved main-project foundation. Keep the accepted style, painted character and voxel look as the baseline. The game runs from supplied runtime assets without Blender, AI tools or network access. See [the project handoff](../docs/PROJECT_HANDOFF.md) for the complete ownership map and setup.

## Current decisions — 2026-10-24

- Preserve the approved **painted whole-body character**. Shared frame skins use one template for all poses, anchors, timing, scale and idle behavior. The selected v9 walk has eight poses per diagonal view, mirrored SW/NW, neutral breathing and front blinks. Rejected cutout tools are archived, outside the active pipeline.
- Selected cottage, workshop, mill shell, log cabin, lamppost and the original clearing's land load from **Blender-authored GLBs**. Their `.blend` files are now editable sources. Old procedural recipes are one-time seeds, not competing masters.
- **Areas are documents** (`content/areas/`). The rules and the renderer both read them; no map lives in code. **Sparks & Machines** is the main route selected by `content/levels/catalog.json`. Kindle Hollow (96×80) and [Village Morning](MORNING.md) are archived for rework, with their sources, saves and tests retained. The original 16×12 clearing remains a regression fixture. Outdoor land is generated from its document by `art/terrain_builder.gd`, a procedural test with Blender adoption as the documented next step.
- Tree crowns and moving/stateful mechanisms (the beacon, gates, bridge decks, the wheel) remain procedural tests. The `post` lamp is the adopted lamppost model: the game lights it through its `lamp_glass` mesh. Water remains a Godot shader. The world uses ordinary meshes with a voxel-inspired finish, not an editable voxel volume.
- Movement uses integer neighbor cells, held-key repeat and click-to-walk, with smooth visual interpolation, under a **following** orthographic camera that keeps the original heading and elevation. The camera scale changed deliberately with the larger area: the world now fills the window and the default size of 13 gives the character the same on-screen height as in the concept (about 110 px at 1000 px tall); size is a player setting (8–20). The outdoor builder supports houses, trees, 82 props and ground painting; house doors now travel to separate saved rooms. General outdoor-region travel remains deferred.
- Hotaru follows as a tiny winged light, with a black-haired fairy portrait in the shared visual novel conversation scene. [The first voice revision](reviews/2026-10-26-hotaru-first-voice.md) adds hello before movement, execution replay, explicit Continue and safe door-sill travel.
- The [guided tutorial flow](reviews/2026-10-26-guided-tutorial.md) gives Hotaru linear introductions, automatic Field Notes handoffs and reply choices only after learning to speak. Portrait dialogue guides presentation; each scene chooses its interaction structure.
- The [compact desktop and room pass](reviews/2026-10-26-compact-desktop-and-room.md) uses a full-screen 1920×1080 reference layout, denser lesson rows, a larger readable Python pane, a practical bedroom arrangement and the cottage’s one-cell exterior landing offset.
- The [Rootward Square expansion](reviews/2026-10-26-rootward-square.md) adds a monumental enchanted tree, thirty hanging lanterns and drifting lights, an enterable town hall, and a 64×72 village layout. Bedroom candle/boot blocks are removed; doors open on the inward frame attempt.
- Rootward now uses a permanent [trunk cutaway](reviews/2026-10-26-rootward-trunk-cutaway.md) so its crown and spreading boughs cannot hide the village. Root lights and lanterns remain; the complete adopted tree is preserved.
- The interface is a code-drawn kit: see [the UI guide](UI.md).
- The [steps and doorway pass](reviews/2026-10-25-steps-doors-and-cottage.md) aligns character support with rendered treads, keeps sprite depth upright with unchanged projected proportions, adds directed walk-through doors and a newly modeled Concept Cottage on the house shelf.
- The [building pass](BUILDINGS.md) refreshes the existing eight building models and lamppost, adds two shop buildings, and connects the quest mill wheel to water and its bearing. Existing masters were deliberately edited with preserved backups, then exported through the usual world build.
- Fifteen painted [detail materials](MATERIALS.md) extend both texture styles, with saved per-part finishes on 90 assets, six room controls and four floor paints. Existing pictures and adopted Blender sources are preserved; `scripts/art.sh` builds the library.

The title’s **Asset Showcase (Dev)** provides an initially empty, isolated model stage with search, turning, zoom, reload, metre grid and the approved boy as a scale guide. It uses existing world-catalog runtime assets, with no session/save changes. Hide it through `rootward/development/asset_showcase_on_title=false`; release builds hide it automatically. See [the review](reviews/2026-10-29-main-route-and-asset-showcase.md).

The [local asset request workflow](../asset-requests/README.md) extends that stage with optional update notes, new-asset briefs with dropdown style references, a request browser, Finished/acceptance and dependency-aware deletion. `pipeline/asset_workflow.py` is the shared local authoring service for the menu and `scripts/asset-requests.sh`; requests live in the top-level `asset-requests/` folder. Existing art builds remain authoritative.

## Sources and ownership

The [Sparks loft pass](reviews/2026-10-27-sparks-loft-furnished-and-first-code.md) adds fourteen new editable room assets under `art/source/world/loft-*/v1/`, plus their [painted source pack](../art/source/world/sparks-loft/v1/README.md). All export through the normal world build. The room document owns placements and collision; the paper journal uses the existing WASI proposal/commit boundary. The [annotated refinement](reviews/2026-10-27-loft-refinement-and-live-speech.md) corrects the marked models and adds actual-output ghost typing and an interactive waking conversation.

The [illustrated village study](reviews/2026-10-26-illustrated-village.md) adds four adopted Blender masters: `square-lamppost`, `painted-cottage`, `painted-oak` and `painted-garden-fence`. Village Morning’s catalog presentation selects the lamp and the cottage/oak variants. Fine sepia hulls outline selected buildings and props without changing their original surfaces. The painted cottage retains the reference cottage’s entrance and collision; the earlier masters remain intact. Export each new master through `scripts/world-art.sh build <id>`.

| Location | Purpose |
|---|---|
| `reference/voxel-isometric.png` | Visual target. A picture, not recoverable geometry. |
| `content/areas/<id>.json`, `<id>.quests.json` | **Area documents**: terrain, buildings, trees, mechanisms, zones; quests, lessons, hints. The one source of truth for an area. See [Areas](AREAS.md). |
| `art/source/adventurer/` | Versioned painted design/keyframes and prompts; v9 contains the selected direction sheets, blink and registered atlas/provenance. |
| `pipeline/art-catalog.json` | Selects approved template artwork/source and derived output locations; links the shared template, world catalog and area folder. |
| `art/source/brand/v1-lantern-roots/`, `assets/brand/` | Application-icon master and exact imagegen prompt; `application_icon` in the art catalog pins its hash and 256/512 px runtime PNGs. `scripts/art.sh` rebuilds them. |
| `art/source/portraits/v1/`, `assets/portraits/` | Five high-definition dialogue portraits, exact prompts/reference hashes and lossless runtime outputs, built by `scripts/art.sh`. |
| `pipeline/character-template.json` | Owns the common frame layout, timing, anchor, scale and idle behavior for all skins. |
| `pipeline/character-catalog.json` | Registers appearance skins and selects the default. |
| `assets/characters/library.json` | Compiled skin library; skins reuse the common animation data. |
| `assets/characters/adventurer/` | Selected runtime PNG/import/SpriteFrames/manifest. |
| `art/source/characters/mira/v1/`, `assets/characters/skins/mira.png` | Mira's authored walk/neutral/blink source, prompts and provenance, and compiled shared-frame appearance. Mira is a resident; the boy remains the player. Rowan, Bram, Tessa and Nell have matching versioned sources and runtime skins. |
| `pipeline/world-catalog.json` | Per-world-asset authority, source/version, output, pivot and footprint notes; its `areas` block lists the area documents. |
| `art/source/world/<id>/<version>/model.blend` | Human-editable source after Blender handoff. |
| `art/source/world/village-library/v1/` | Fifty-object design index and protected one-time Blender authoring records; individual `hollow-*` sources are the editable masters. See [the library](BUILDER_LIBRARY.md). |
| `assets/world/<id>/model.glb` + manifest | Audited runtime handoff with source/export hashes. |
| `art/world_palette.gd`, `art/surface_materials.gd` | Shared palette and small mipmapped material recipes for generated land, seeds and tests. |
| `core/area_def.gd`, `core/lab_world.gd`, `core/quests.gd` | Document validation; actual traversal/support/command authority; goal evaluation. |
| `art/terrain_builder.gd`, `art/mechanism_builder.gd`, `scenes/clearing_view.gd`, `art/world_assets.gd` | Generated land, interactive parts, the data-driven view and camera, selected asset loading. |
| `ui/`, `app/` | Interface kit and screens; game flow, session, saves, settings. |
| `evidence/` | A small selected set of review captures. |
| `.cache/` | Disposable intermediate frames, candidate exports and logs. |

`art/source/` is excluded from Godot import. Inactive experiments are archived under `art/source/archive/`. Keep experiments outside selected runtime assets. Missing selected character or Blender output is an error; the game does not substitute an older player or regenerate adopted models.

## Follow the guide for the change

The application icon depicts a violet-capped amber lantern, golden roots and teal code brackets. It is separate from the code-drawn in-game glyphs. `project.godot` uses the 256 px PNG; the Linux launcher uses 512 px. `packaging/rootward-voxel.desktop.in` and `scripts/install-desktop.py` produce the applications-menu and desktop shortcuts for the current checkout. Installation needs host Python only; launching uses the existing `scripts/play.sh` and local game runtime. `--nvidia` makes the shortcut set `ROOTWARD_GPU=nvidia`, which `scripts/play.sh` turns into NVIDIA PRIME render offload for the game window only.

| Change | Guide |
|---|---|
| Character art, diagonal views, walk/idle, future outfits | [Characters](CHARACTERS.md) |
| Open/edit a supplied model visually, rebuild its GLB | [Blender workflow](BLENDER.md) |
| Resident dialogue, high-definition portraits and optional code explanations | [Conversations](DIALOGUE.md) |
| New bench/tree/house/material/interactive part | [World assets](WORLD_ASSETS.md) |
| Fifty new furniture, workshop, market, garden and working props | [Builder library](BUILDER_LIBRARY.md) and [review](reviews/2026-10-24-builder-library.md) |
| Land, path/river/footprint, zones, quests, a new area | [Areas](AREAS.md) |
| Buttons, panels, icons, a menu, the code editor, settings | [Interface](UI.md) |
| Decide whether the result is ready | [Review](REVIEW.md) |
| Character animation results | [Animation review](reviews/2026-10-23-approved-directional-walk.md) |
| Blender handoff and world gates | [World review](reviews/2026-10-23-painted-and-blender.md) |
| The valley, the notebook and the interface | [Kindle Hollow review](reviews/2026-10-23-kindle-hollow-and-notebook.md) |
| House instances, village residents, water and boundaries | [Village](VILLAGE.md) |
| Journey selection, the unique starting home and movement programming lesson | [Village Morning](MORNING.md) |
| Rearranging the valley in game: place, move, delete, undo, saves | [Build mode](BUILD.md) |
| Half-cell ground paint, height-biased pixel borders and art sources | [Ground](GROUND.md) |
| Bigger houses, textures, blocked-direction facing, build mode | [Review](reviews/2026-10-23-bigger-houses-textures-and-build-mode.md) |
| A concept-matched house and lamp, drawn and adopted into Blender | [Log cabin and lamppost review](reviews/2026-10-23-log-cabin-and-lamppost.md) |
| Unplaced voxel doodads: the original thirty-two farm, garden, furniture and street props, authored from scripts in Blender | [Voxel doodads review](reviews/2026-10-23-voxel-doodads.md) |

## Normal edit loops

For a character appearance, author a **new source version**, register its skin and run `scripts/art.sh`. All skins inherit the shared template. The build preserves approved pixels, verifies sources and validates skin compatibility; it never calls a model. Timing/layout changes belong to the shared template, not individual skins. `scripts/character-art.sh` delegates to this same pipeline.

For adopted world art, open the existing `.blend`, edit visually, save, and run:

```sh
scripts/world-art.sh build cottage
scripts/test.sh
scripts/play.sh
```

Replace `cottage` with another registered asset ID. Do not rerun `seed` or `init` on an adopted source. Those commands are protected, one-time initialization. `compare` is the stricter unedited round-trip proof; intentional art changes may correctly differ from the original seed. The Blender guide explains exact fields, export scope, grouping, axes and limitations.

For a map or a lesson, edit its document under `content/areas/` and run `scripts/test.sh`: the area test proves reachability, that the locks lock, and that every quest has a working solution.

One logical cell is one world unit. Logical `[x,y,height]` maps to Godot `(x,height,-y)`. The camera keeps a diagonal heading and about 31° elevation and follows the player. Keep models unsheared. glTF handles Blender/Godot axis conversion; do not compensate with arbitrary root rotations. Keep moving mechanisms separate with meaningful pivots. Visual mesh edits do not automatically change logical collision.

Keep the concept's main forms: cream/timber houses, violet/teal tiled roofs, pale foundations, full irregular crowns, turquoise stream, timber crossing and mill. Five shared-frame village residents are now part of the playable area. The original thirty-two voxel doodads and fifty new village-library pieces are studio-only props on the build shelf; none is auto-placed in the shipped valley. The new pieces fill five organized categories, with sixteen exposing validated `active` state to F and Python. The masters are versioned Blender sources; review [the library guide](BUILDER_LIBRARY.md) before editing the semantic moving parts or glow materials.

## Movement contract

- Input actions live in `project.godot`: physical WASD/arrows and left-stick axes. D projects SE, S SW, W NE, A NW. The view projects actual camera motion rather than using front/left/right/back labels. Hardware gamepad feel remains unreviewed.
- Physics runs at 60 Hz. `STEP_SECONDS = 13/60`, so each step takes thirteen physics ticks. Only cardinal one-cell logical steps are legal; authoritative positions are integers, with no fractional or two-axis steps.
- Holding a direction repeats without idle flashes. The most recently pressed direction wins on overlap. Releasing or turning completes the current step first.
- Click-to-walk finds a deterministic shortest route through current walkable cells; gold marks show the remainder. Keyboard walking cancels the route. Blocked cells remain inspectable, and clicking a cell tells you what is on it.
- Rules check both endpoints and the passage against the 0.18-unit foot footprint, buildings, trunks, posts, fences, walls, rock, wheel, water and closed gates. Canopies do not block their whole visual spread. Edges that cannot change are cached; only edges near a gate or bridge socket are re-evaluated, so routes across the expanded map stay fast.
- The app interpolates the picture and commits the validated integer destination at step completion. Animation phase does not determine traversal. Eight approved walk poses span two steps; starts/turns/stops follow the character guide.
- Starting a step clears stale previews/results. Run cancels a route and waits for the active step; Apply is blocked while walking. Undo reverts what the last program changed and never moves the player; Reset darkens the world but keeps code, quests and discoveries. A text field or a menu owning the keyboard stops walking after the current step.
- Entering a zone discovers it, and only discovered zones are visible to the player's Python. The save holds world state, quests, discoveries, memory, source and the player's name. Land is terraced in whole levels (0–2) joined by stairs, and build mode can raise, lower, dig and fill it ([shaping the land](BUILD.md#shaping-the-land)). Slopes, stacked floors, jumping and an area editor need separate rules and evidence.

## Commands and review

```sh
scripts/art.sh                          # accepted source → pinned import → frames/manifest/checks
scripts/world-art.sh build cottage      # saved .blend → audited GLB; source not overwritten
scripts/test.sh                         # rules, areas, WASI, UI helpers, app flow, movement, art, world art, source guards
scripts/play.sh
scripts/screenshot.sh                   # every screen → .cache/tour; selected frames → evidence/
```

Review tools run through `scripts/play.sh --resolution 1600x1000 -s res://tools/<name>.gd -- <args>`. Set `VOXEL_LAB_FRESH=1` so they leave the player's saves and settings alone.

| Tool | Reviews |
|---|---|
| `area_shot.gd <area> <png> [x y zoom lit]` | Any spot of any area at gameplay scale, with build time and frame rate. |
| `village_tour.gd`, `villager_character_review.gd` | House travel, resident conversations, builder categories; all resident walks and blinks at gameplay scale. |
| `builder_library_review.gd <dir> [gallery-only]`, `builder_library_tour.gd <dir>` | All fifty models, five categories, the actual 95-entry builder, all sixteen F interactions, Python preview/Apply/Undo and saved working state. |
| `ground_shot.gd <dir>` | Six ground transition pairs and GPU pixel proofs across sub-tile and chunk edges. |
| `asset_shot.gd <id> <png> [recipe\|runtime\|<file.glb>] [zoom yaw lit ...]` | One world asset in the game's camera and light beside the character: the procedural recipe before `seed`, the exported GLB after `build`, or a candidate GLB before promoting it. |
| `blender_preview.py` (run by Blender) | An editable `.blend` rendered from the game's camera angle, without saving it. |
| `ui_tour.gd <dir>` | Every screen and state of the real game, as PNGs. |
| `playthrough.gd <dir>` | The whole level through the real controls, a frame per quest, then the finale. |
| `doorway_review.gd <dir>`, `door_input_review.gd` | Treads at all four orientations, house walk-in/exit, the placed concept cottage, and real keyboard/mouse doorway travel. |
| `movement_review.gd`, `facing_review.gd` | Real mouse and held-key input; the four projected views. |
| `perf_probe.gd [fullscreen\|windowed] [ab]` | Frame cost of the title, standing, walking, zoomed out and indoors: frames per second, script time, world CPU/GPU time, draw calls and triangles; `ab` also prices shadows and MSAA. |
| `art_study.tscn`, `painted_study.tscn` | The actual selected character; `VOXEL_ART_STUDY=house` reviews the Blender-selected cottage, and `seed_house` explicitly shows its old procedural seed. |

The user has accepted the baseline's style and corrected painted animation. Review new skins, areas and world edits against that baseline. Five resident identities and saved house instances are implemented through the shared-frame and area contracts. General outdoor-region transitions remain future work. Earlier reviews retain historical selections.

The [lived-in loft revision](reviews/2026-10-27-loft-lived-in-and-stairs.md) edits three adopted furniture masters and gives the hatch an area-owned descending tread profile. Both player support and picking use it. The [workshop floor](reviews/2026-10-27-workshop-floor.md) extends that hatch into a second saved room, with twenty adopted masters, two new material paintings, thirteen rising treads and inspections. Its [source pack](../art/source/world/sparks-workshop/v1/README.md) records the smaller furniture layout, household additions and deliberate touchups; the existing loft and character sources are preserved.

The [first workshop jobs](reviews/2026-10-27-workshop-first-jobs.md) add an adopted stair lantern, connect it and the two existing pendants to logical lamp state, and link the ticket reading to two real Python jobs. Fixtures map to existing room assets through the area document; they do not add a second model or a floor collision post. The windowsill plant is deliberately removed from the loft keepsakes master, preserving its book and box and all other loft models. Scene reads, inspection discoveries and separate job drafts persist through the journey’s saved room boundary.


The [downhill square and stair follow-up](reviews/2026-10-29-stairs-and-square.md) adds a fourth saved Sparks area through the lane’s town gate. Ten adopted Blender masters use the lane’s paintings and outlined forms, with T3/T5 guiding the Rootwell and civic centre. The tram remains a separate future route; square quests are deferred. The follow-up also retains the workshop’s stair arrival and trolley after native input review. [.codex/MEMORY.md](../.codex/MEMORY.md) records current project decisions.
