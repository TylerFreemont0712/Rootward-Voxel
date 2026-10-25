# Handoff, 2026-10-23: textures, bigger houses, blocked-facing, and build mode (in progress)

Written mid-work so anyone (or I, later) can pick up cleanly. Read `AGENTS.md` and `docs/PROJECT_HANDOFF.md` first. Another assistant works in this folder too (see "Other work in the folder").

The request this answers: wire in the new textures; start an in-game editor in the spirit of The Sims' build mode (add, delete, move for now, polished UI, eventually open to players in part); make houses about two tiles bigger per side and re-lay the town; make the character face a blocked direction (keys and click); and think about 2×2 ground sub-tiles.

## Status at a glance (updated after build mode was finished)

| Part | State |
| --- | --- |
| Face the blocked direction | **Done and tested** (keys and click-to-walk). |
| Wire the textures | **Done and documented** (`pipeline/WORLD_ASSETS.md`, `pipeline/BLENDER.md`). |
| Bigger houses and the re-laid town | **Done, tested and documented** (briefs written). |
| Build mode (add/move/delete) | **Done as a foundation: rules, ledger, saves, picture, controller and interface, with 96 + 48 tests and evidence frames.** See `pipeline/BUILD.md` and the review. No human session yet. |
| Ground sub-tiles | **Design and a full implementation prompt** ([GROUND_SUBTILES_PROMPT.md](GROUND_SUBTILES_PROMPT.md)); not built. The next feature. |

The sections below are the working notes from earlier in the day. Section 4's "Not started" list is now **done**; `pipeline/BUILD.md` is the current description of build mode.

## Test status when this was written

Every suite passed, run one by one: lab 73, area 90, **build 90 (new, now in `scripts/test.sh`)**, ui 32, app 89, movement 30, art 100, frame skins 42, world art 113, source protection 7, handoff/links 295. The other assistant's assets had finished building by then. Nothing is known to be broken. The view changes for build mode are in and covered only by the existing view tests; the new view functions (`sync_edits`, tree chunks, `build_tree_mesh`, the free camera) have **no dedicated tests yet**, so add some when wiring the app.

## 1. Face the blocked direction (done)

- `art/sprite_actor.gd` `face_screen_direction()`: turn to a screen direction without walking (ignored while moving; no change if already facing it).
- `scenes/clearing_view.gd` `face_player(logical)` and `_screen_direction()` (shared with `set_player_motion`).
- `app/session.gd`: `facing`, `turn_toward(direction)`, `_direction_toward(from, goal)`. `request_step` turns when the rules refuse the step (building, water, wall, map edge). `walk_to` turns toward the clicked cell when there is no route (blocked or unreachable): the larger part of the offset wins, east/west on a tie. Turning is ignored mid-step.
- Tests: `test/test_app.gd` (6 checks; 89 pass).
- Not tested with real held keys: headless has no window focus. `tools/movement_review.gd` in a window is the place to add that.

## 2. Textures (done in code; docs pending)

The delivered pack: `assets/world/textures/{solid,lush}/*.png` (24 materials each, 128 px), sources and prompts in `art/source/world/textures/v1/` (`manifest.json`, `prompts.md`, `contact-sheet.png`, `native/`, `raw/`).

- **Catalog:** `pipeline/texture-catalog.json` is the single source. `"set": "lush"` picks the set; each palette id maps to `{texture, tile, tint, mode, cells, emission}`. Modes: `world` (repeats every `tile` world units), `face` (one pane per face), `cells` (each face shows one painted cell of an n×n picture: roof tiles).
- **Loader:** `art/world_textures.gd` (`class_name WorldTextures`): `entry(id)`, `texture(name)`, `active_set()`.
- **Procedural geometry** (ground, trees, fences, walls, decks, wheel): `art/surface_materials.gd` `build(palette, world_space)` and public `painted(id, color, world_space)`. World-space triplanar for batched MultiMeshes; object-space for parts that move. `scenes/clearing_view.gd` keeps `_materials` and `_part_materials`; `_mesh_box` uses the latter.
- **Gotcha, fixed:** triplanar sharpness must stay low (4.0). Godot weights projections by instance scale, so a high sharpness underflows to black on thin slabs (the ground went black).
- **Imports:** the 48 PNGs' `.import` files were patched to `mipmaps/generate=true`. If Godot regenerates them with defaults, re-apply: `sed -i 's/^mipmaps\/generate=false/mipmaps\/generate=true/' assets/world/textures/*/*.png.import`, then re-import.
- **Water:** `art/water.gdshader` now samples `water_texture` (two drifting layers). **Paving:** `art/terrain_builder.gd` `_paving` is one slab per cell with broad-noise tone (per-cell tone made a checkerboard).
- **Lit lantern:** the `lit` material uses `lantern_glass_lit` with emission.
- **Baked into Blender sources** by a new deliberate step: `pipeline/blender_retexture.py`, run as `scripts/world-art.sh retexture <id>` (then `build`). It rewrites materials and UVs only (world-scale planar UVs, face panes, roof "cells"), keeps `model.pre-retexture.blend` beside the source and writes `retexture.json` (with the catalog hash). Done and rebuilt for: `cottage`, `mill-house`, `clearing-ground`, `log-cabin`, `log-cabin-large`, `log-cabin-large-teal`, `lamppost`. **Not done:** `tree` (unselected reference).
- **Lamppost:** it was open in the owner's Blender, so it was retextured inside that live session and saved. The file therefore also contains the owner's hand edit (post lifted onto the pedestal, `stone_dark_geometry` deleted) **and my unapproved `lantern_mullions_geometry` object** (cross bars on the lantern). Ask the owner whether to keep the bars (delete that one object to drop them, then `build lamppost`).
- **Drift guard:** `test/test_pipeline_handoff.py` fails if a baked asset's `retexture.json` hash differs from the catalog, and checks every catalogued picture exists in both sets.
- **Seeds:** `pipeline/world_seed.gd` clamps tints above 1 for seeds (glTF cannot store a factor over 1); `retexture` bakes the real tints into the pixels. Run `compare` **before** `retexture`.
- **Still to do:** update `PROMPT.md` (still says "nothing uses these yet"), `pipeline/BLENDER.md`, `pipeline/WORLD_ASSETS.md`, `pipeline/README.md`, `README.md`, `art/README.md`, `docs/PROJECT_HANDOFF.md` for the catalog, `retexture` and the new assets. Consider a Settings choice for solid/lush (procedural surfaces only; baked models are fixed until retextured).

## 3. Bigger houses and the town (done)

Interpreted "about two tiles on each side" as each house growing from 3 to 5 cells per side (4.7 units, blocks exactly 5×5 cells). The mill was left alone (it is `locked` and has the wheel).

- `pipeline/world_recipes.gd` is now parametric: defaults reproduce the 3-cell `log-cabin` exactly (checked: same geometry hash); `LARGE` is the 5-cell house. New assets (full pipeline done, round trip lossless): `log-cabin-large` (violet), `log-cabin-large-teal`. Catalog footprint `[-2.35, -2.35, 4.7, 4.7]`.
- `content/areas/kindle-hollow.json`: `home`, `row-north-a`, `row-north-b`, `row-south-a` are `log-cabin-large`; `row-workshop` is the small `log-cabin`; `miller-house` is `log-cabin-large-teal`; the mill is `"locked": true`. A fence end was shortened; no trees needed clearing.
- `core/area_def.gd`: buildings carry `locked`; `building(id)` added.
- Tests: `test/test_area.gd` (88 pass, includes "exactly 25 cells") and `test/test_world_art.gd` house checks.
- **Still to do:** asset briefs for the two large houses (copy the style of `art/source/world/log-cabin/v1/brief.md`), docs, and a decision on whether the mill and the plaster `cottage` should grow too.

## 4. Build mode (in progress)

### Design (the decisions, so they are not re-argued)

- Inspired by the sibling Rootward's "Lanternroot Studio" (`../Rootward/docs/decisions/ADR-0066-lanternroot-studio.md`, read-only; do not edit or depend on that repo, and do not copy its UI). Taken from it: a pure tested model, every edit a command with an inverse, snapped ghost that is green or red *with a reason*, a catalog as content, play and edit in the same view.
- **Edits are a layer over the area document**, not a new format. They are plain dictionaries applied in order to a copy of the document (`AreaBuild.apply`), then parsed into an `AreaDef`, so rules, rendering and saves all see the same data. They are saved in the player's save as `"edits"` (not yet wired).
- **Whole-world check:** after every edit the world is rebuilt and a flood fill (every gate open, every bridge built) must still reach everything it reached before: each lamp's surroundings, each zone, each door, the spawn. Only the gate and the bridge are chokepoints (the valley is open meadow). A refused edit names what it would cut off. Measured: about 110 ms to place, about 50 ms to refuse, so this can run live while the ghost moves (debounced).
- **Policies** in `content/build/catalog.json`: `studio` (everything) and `player` (only `audience: player` items, with allowances: 8 buildings, 40 trees). This is the hook for "eventually open to players in part".
- Locked things (lamps, gates, bridges, the wheel, the mill) cannot be moved or removed. Lamps, gates and bridges are not in the catalog at all.
- Snapping: odd-celled buildings to whole cells, even to half cells; trees to half cells; trees only on grass, 0.9 apart.

### Done and tested

- `content/build/catalog.json`: categories, policies, 7 items (3 houses open to players, the plaster cottage studio-only, 3 oaks).
- `core/area_build.gd` (`AreaBuild`, static, pure): footprint/snap/door helpers, `object_near`, `check_building`, `check_tree`, `check_remove`, `open_state`, `flood`, `needs`, `reach_problem`, `apply`, `next_building_id`, `allowed_items`, `limit_reason`.
- `core/build_ledger.gd` (`BuildLedger`): `check_item`, `check_move_building/tree`, `place`, `move_building/tree`, `remove_building/tree`, `undo`, `redo`, `describe`, `added`, `problems` (stale saved edits are skipped and reported; a save that breaks the valley is set aside whole).
- `test/test_build.gd`: 90 checks. **It is not yet in `scripts/test.sh`** (add the line after `test_area.gd`). Run it with `godot --headless --path . -s res://test/test_build.gd`. New `class_name` files need `godot --headless --editor --path . --import --quit` once.
- `scenes/clearing_view.gd`: `sync_edits(area, animate)` (diffs buildings by id and trees by position key, pop and shrink animations), trees now drawn in their own chunk nodes under `Trees` (`_sync_trees`, `_rebuild_tree_chunk`, a crown's shape now comes from its position via `tree_seed`, so existing crowns look different from before), `build_tree_mesh(size, seed)` (one merged mesh for a ghost or thumbnail), `CameraMode.FREE`, `pan_focus`, `focus_point`, and `_flush_batches(parent, bucket, prefix, collected)`.

### Was not started when this was written; all of it is now done (kept for the record)

1. **App wiring.** `AreaStore.read_source(id)` returning `{document, quests, assets}`. `Game` owns a `BuildLedger` (use `ledger.area`), rebuilds it from `save.edits` on Continue and from `[]` on a new game, calls `view.sync_edits(ledger.area, false)` then `session.begin(...)`. `GameSession.replace_area(area, rules)` (swap, cancel the route, bump the generation, clear any preview). `Game.save_now()` adds `ledger.edits` to the save. Tests in `test/test_app.gd`.
2. **`scenes/build_overlay.gd`** (`BuildOverlay`, child of the view): grid shader (brass lines near the cursor), footprint tile pool (green/red) plus a door arrow, building ghost (instantiate the GLB, tint with `material_overlay`), tree ghost (`build_tree_mesh`), hover highlight (overlay for a building, a ring for a tree), picking (`pick_object` by ray against each building's mesh AABB and a tree box; `ground_point`).
3. **`app/build_mode.gd`** (`BuildMode` controller): tools PLACE/MOVE/DELETE, item and facing, hover from `surface` mouse position (`event.position * world_viewport.size / surface.size`), click to act, right-click cancel, `R` rotate (S→E→N→W), `1/2/3` tools, `Ctrl+Z`/`Ctrl+Y`, `Esc` ladder (cancel carry, clear item, exit), screen-aligned panning (W = up the screen = logical (-x, +y)/√2; also middle-drag), wheel zoom, ghost validity from `ledger.check_*` (cheap) plus a debounced `reach_problem` via a dry-run. `session.input_enabled = false` while active; entering clears any preview.
4. **`ui/build_hud.gd`** (polished, the kit only): a toolbar pill (Place / Move / Delete, Undo / Redo, Done), a bottom catalog dock that slides up in Place (category tabs, item cards with thumbnails, size chip, blurb), a reason bubble near the cursor, a key-hint line, toasts from `ledger.describe`. Thumbnails: render each item once in a hidden `SubViewport` (same camera angle and light, transparent background, fit the AABB). Glyphs to add to `ui/glyph.gd`: `hammer`, `house`, `tree`, `move`, `trash`, `rotate`, `redo`.
5. **`Game` integration:** `B` and a HUD build button toggle it (not while typing or in a modal); free camera in, restore follow camera and the zoom setting on exit; save after each edit via `_queue_save`.
6. Tests (controller flow with simulated clicks, policy in the UI), a tour/evidence frames, `pipeline/BUILD.md`, and a docs pass (README, AGENTS.md architecture bullet, `docs/PROJECT_HANDOFF.md`, `pipeline/UI.md`).

## 5. Ground sub-tiles (design only)

The design grew into a full implementation brief for a model with image generation: **[GROUND_SUBTILES_PROMPT.md](GROUND_SUBTILES_PROMPT.md)**. In short: keep rules at cell resolution and add a presentation layer at half-cell resolution; an optional `paint` block in the area document (2×width by 2×height base-36 rows over a palette of ground materials); a derived default with per-sub-tile tone noise and deterministic border roughening; a single `R8` control map; one skin mesh per chunk with a shader that blends the four nearest sub-tiles per art pixel, biased by each picture's height, so borders are ragged, crisp and on the textures' own pixel grid; never rotate a picture per sub-tile (it draws seams); image generation only for aligned height maps, reference sheets and optional edge fringes; a Paint tool inside the build menu; and a smaller, scrolling, searchable shelf for many assets.

## Other work in the folder (not mine; leave it)

Another assistant is adding a set of candidate assets in `art/source/world/expansion-kit/` and registering `hearth-oak`, `ridge-cedar`, `river-willow`, `hearth-house`, `lantern-loft` and `brook-mill` in `pipeline/world-catalog.json` (status `candidate_unplaced`). While they were mid-build, `test_world_art` and `test_pipeline_handoff` briefly failed on their missing or unrecorded outputs (for example "Missing world output: hearth-oak"); those cleared once they finished. If it happens again it is theirs: do not delete or "fix" their assets; re-run the suites later. Always re-read a shared file (`pipeline/world-catalog.json`, `scenes/clearing_view.gd`, docs, `scripts/test.sh`) right before editing it.

## How to resume

```sh
cd /home/joejin/personal-project/Voxel-Rootward
godot --headless --editor --path . --import --quit     # after adding any class_name file
VOXEL_LAB_FRESH=1 godot --headless --path . -s res://test/test_build.gd   # build rules: 90 checks
scripts/test.sh                                         # everything (see the note on the other assistant's assets)
VOXEL_LAB_FRESH=1 godot --path . -s res://tools/area_shot.gd -- kindle-hollow /tmp/x.png 13 19 13 0 60   # look at the town
godot --path . -s res://tools/asset_shot.gd -- log-cabin-large /tmp/h.png runtime 11 90 0 2.4           # one asset
```

Always set `VOXEL_LAB_FRESH=1` for tests and reviews so they never touch the player's save or settings. Superseded generated drafts were moved to `.cache/superseded/` (git-ignored). Nothing has been committed; do not commit unless asked.

## Questions for the owner (still open)

1. Keep the cross bars on the lantern (`lantern_mullions_geometry`)? It is in the saved `lamppost` source.
2. Should the mill and the plaster cottage grow too, or stay as they are?
3. Which build-mode items should villagers get first, and what allowances (currently 8 buildings, 40 trees)?
4. Do you want a solid/lush choice in Settings (procedural surfaces only), or one fixed look?
