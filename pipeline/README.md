# Art, area and movement pipeline

This is the active pipeline for the approved foundation of **Sparks & Machines**. Keep the accepted style, painted character and voxel look as the baseline. The game runs from supplied runtime assets without Blender, AI tools or network access. See [the project handoff](../docs/PROJECT_HANDOFF.md) for the ownership map and setup.

## Current decisions

- Preserve the approved **painted whole-body character**. Shared frame skins use one template for all poses, anchors, timing, scale and idle behavior. The selected v9 walk has eight poses per diagonal view, mirrored SW/NW, neutral breathing and front blinks. Rejected cutout tools are archived under import-excluded `art/source/archive/`.
- Every shipped building, prop, room piece, robot and ground is a **Blender master** (`art/source/world/<id>/<version>/model.blend`) exported to an audited GLB. Edit the master, or start a new version directory for a deliberate redesign; procedural seeds are one-time bootstraps, never competing masters.
- **Areas are documents** (`content/areas/`). The rules and the renderer both read them; no map lives in code. `content/levels/catalog.json` lists the one journey and its ten rooms.
- The beacon, gates, bridge decks and the wheel stay procedural mechanisms; water is a Godot shader. The world uses ordinary meshes with a voxel-inspired finish, not an editable voxel volume.
- Movement uses integer neighbor cells, held-key repeat and click-to-walk under a **following** orthographic camera at the original heading and elevation (size 13 by default, a setting; rooms author their own zoom).
- The interface is a code-drawn paper-and-enamel kit: see [the UI guide](UI.md).
- Six surface-material libraries (fifteen painted detail materials, the seaside house pack, the clockshop parquet and the ground set) are built by `scripts/art.sh`; see [MATERIALS](MATERIALS.md) and [GROUND](GROUND.md).
- The title's **Asset Showcase (Dev)** is an isolated model stage (search, turn, zoom, reload, metre grid, the boy as a scale guide). Hide it with `rootward/development/asset_showcase_on_title=false`; release builds hide it. The [asset request workflow](../asset-requests/README.md) adds update/new/delete requests behind it, shared by the menu and `scripts/asset-requests.sh` through `pipeline/asset_workflow.py`.

## Sources and ownership

| Location | Purpose |
|---|---|
| `reference/voxel-isometric.png` | Visual target. A picture, not recoverable geometry. |
| `content/areas/<id>.json`, `<id>.quests.json` | **Area documents**: terrain, levels, placements, mechanisms, zones; quests, lessons, hints. The one source of truth for an area. See [Areas](AREAS.md). |
| `content/journeys/sparks-and-machines.json` | The journey's opening, scenes, chapters, tickets and pay. |
| `art/source/adventurer/` | Versioned painted design/keyframes and prompts; v9 contains the selected direction sheets, blink and registered atlas/provenance. |
| `pipeline/art-catalog.json` | Selects approved template artwork/source and derived output locations; links the shared template, world catalog and area folder. |
| `art/source/brand/`, `assets/brand/` | Application-icon master and prompt; `application_icon` pins its hash and 256/512 px runtime PNGs. |
| `art/source/ui/nells-field-slate/`, `assets/ui/nells-field-slate/` | Nell's field slate, the painted frame around the live code screen; `interface_frames` pins its crop, nine-slice margins and sockets. |
| `art/source/portraits/`, `assets/portraits/` | Dialogue portraits (Nell, Hotaru, the traveller, Iona, Braum), exact prompts and lossless runtime outputs. |
| `pipeline/character-template.json`, `character-catalog.json` | The common frame layout, timing, anchor, scale and idle behavior; the registered appearance skins. |
| `assets/characters/` | The selected runtime PNG/SpriteFrames, the compiled skin library and the anonymous-crowd masks. Skin sheets for earlier residents are kept for reuse. |
| `pipeline/world-catalog.json` | Per-asset authority, source/version, output, pivot and footprint notes; its `areas` block lists the area documents. |
| `art/source/world/<id>/<version>/model.blend` | Human-editable source after Blender handoff. |
| `assets/world/<id>/model.glb` + manifest | Audited runtime handoff with source/export hashes. |
| `core/area_def.gd`, `core/lab_world.gd`, `core/quests.gd` | Document validation; actual traversal/support/command authority; goal evaluation. |
| `scenes/clearing_view.gd`, `art/world_assets.gd`, `art/mechanism_builder.gd` | The data-driven view and camera, selected asset loading, interactive parts. |
| `evidence/` | Selected review captures that travel with the reviews. |
| `.cache/` | Disposable intermediate frames, candidate exports, test reports and logs. |

`art/source/` is excluded from Godot import. Missing selected character or Blender output is an error; the game does not substitute an older player or regenerate adopted models.

## Follow the guide for the change

| Change | Guide |
|---|---|
| Character art, diagonal views, walk/idle, outfits | [Characters](CHARACTERS.md) |
| Open/edit a supplied model visually, rebuild its GLB | [Blender workflow](BLENDER.md) |
| New prop, building, material, interactive part | [World assets](WORLD_ASSETS.md) |
| Land, zones, quests, a new area | [Areas](AREAS.md) |
| Townspeople, errands, service rounds | [Townspeople](VILLAGE.md) |
| Buttons, panels, icons, the code editor, settings | [Interface](UI.md) |
| Pay, bag, bank | [Property](PROPERTY.md) |
| The layout studio: place, move, turn, paint, undo | [Build mode](BUILD.md), [Ground](GROUND.md) |
| Decide whether the result is ready | [Review](REVIEW.md) |
| Foundation and baseline reviews | [Prototype foundation](reviews/2026-10-22-prototype-foundation.md), [directional walk](reviews/2026-10-23-approved-directional-walk.md), [Blender handoff](reviews/2026-10-23-painted-and-blender.md) |

## Normal edit loops

For a character appearance, author a **new source version**, register its skin and run `scripts/art.sh`. All skins inherit the shared template; the build preserves approved pixels, verifies sources and validates skin compatibility, and never calls a model.

For adopted world art, open the existing `.blend`, edit visually, save, then:

```sh
scripts/world-art.sh build <asset-id>
godot --headless --editor --import --quit     # before any capture or test reads the GLB
scripts/test.sh flow
```

Do not rerun `seed` or `init` on an adopted source; they refuse by design. `compare` is the stricter unedited round-trip proof.

For a map or a lesson, edit its document under `content/areas/` and run `scripts/test.sh`: the area tests prove reachability, that the locks lock, and that every quest has a working reference solution.

One logical cell is one world unit. Logical `[x,y,height]` maps to Godot `(x,height,-y)`. The camera keeps a diagonal heading and about 31° elevation and follows the player. Keep models unsheared; glTF handles Blender/Godot axis conversion.

## Movement contract

- Input actions live in `project.godot`: physical WASD/arrows and left-stick axes. D projects SE, S SW, W NE, A NW. The view projects actual camera motion rather than using front/left/right/back labels.
- Physics runs at 60 Hz. `STEP_SECONDS = 13/60`, so each step takes thirteen physics ticks. Only cardinal one-cell logical steps are legal; authoritative positions are integers.
- Holding a direction repeats without idle flashes. The most recently pressed direction wins on overlap. Releasing or turning completes the current step first.
- Click-to-walk finds a deterministic shortest route through current walkable cells; marks show the remainder. Keyboard walking cancels the route.
- Rules check both endpoints and the passage against the 0.18-unit foot footprint and everything that blocks. Edges that cannot change are cached.
- The app interpolates the picture and commits the validated integer destination at step completion. Animation phase never decides traversal.
- Starting a step clears stale previews. Run cancels a route and waits for the active step; Apply is blocked while walking. Undo reverts what the last program changed and never moves the player.
- Entering a zone discovers it, and only discovered places are visible to the player's Python.

## Commands and review

```sh
scripts/art.sh                          # accepted source -> pinned import -> frames/manifest/checks
scripts/world-art.sh build <asset-id>   # saved .blend -> audited GLB; source not overwritten
scripts/test.sh [quick|flow|full|smoke] # see ../test/README.md
scripts/play.sh
```

Review tools run through `scripts/play.sh --resolution 1600x1000 -s res://tools/<name>.gd -- <args>`; set `VOXEL_LAB_FRESH=1` so they leave the player's saves and settings alone.

| Tool | Reviews |
|---|---|
| `area_shot.gd <area> <png> [x y zoom lit frames free]` | Any spot of any area at gameplay scale, with build time and frame rate. |
| `asset_shot.gd <id> <png> [runtime\|<file.glb>] [zoom yaw lit ...]` | One world asset in the game's camera and light beside the character, or a candidate GLB before promoting it. |
| `square_layout_review.gd`, `square_shop_review.gd`, `square_lighting_review.gd`, `spindle_strip_review.gd` | The layout studio with real mouse and keys, shop doorways, the light budget, and the west strip. |
| `clockmaker_review.gd`, `depth_mist_review.gd`, `depth_fight_probe.gd` | The clockmaker's exterior and room, the white depth mist, and coplanar-surface flicker. |
| `lane_polish_review.gd`, `tram_workspace_review.gd`, `welcome_review.gd`, `tablet_review.gd`, `town_life_review.gd` | The lane, the tram sign workspace, the welcome job, the tablet and the crowd. |
| `city_cycle_review.gd`, `transition_review.gd`, `gear_veil_review.gd`, `dialogue_transition_review.gd` | The clock, dusk and overload, scene changes and the clockwork veil, dialogue windows. |
| `sparks_cast_review.gd`, `sparks_sprite_gallery.gd`, `robot_*_review.gd`, `wick_tender_review.gd`, `phantom_crowd_review.gd` | Cast skins, robot models and movement, anonymous crowd. |
| `ground_shot.gd <dir>`, `detail_texture_board.gd`, `seaside_house_textures_review.gd`, `plant_style_review.gd` | Ground transitions and materials. |
| `desktop_graphics_review.gd`, `memory_review.gd`, `depth_mist_perf.gd` | Renderer choices, cache release, mist cost. |
| `blender_preview.py` (run by Blender) | An editable `.blend` rendered from the game's camera angle, without saving it. |
| `art_study.tscn`, `painted_study.tscn`, `skin_study.tscn` | The actual selected character and skins. |

The user has accepted the baseline's style and corrected painted animation. Review new skins, areas and world edits against that baseline, at the real camera scale.
