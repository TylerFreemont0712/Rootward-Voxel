# Shared instructions for AI coding agents

These instructions are tool- and model-neutral. Use them when working anywhere inside this folder. The person maintaining the project decides which coding assistant or model to run.

## Project purpose

This is the approved Godot foundation for a game in which the player substantially controls a slightly fantastical world by writing real programs. The user has accepted the current clearing's size, camera scale, style and painted character as the main-project baseline. Preserve the approved camera, boy artwork and style while developing its systems. The user subsequently requested the 96×80 village expansion, saved house interiors and five village NPCs; these are now part of the playable foundation. Read `docs/PROJECT_HANDOFF.md` for setup, ownership and remaining feature work (the selected main game is Sparks & Machines, starting in `content/areas/workshop-loft.json`; Kindle Hollow and Village Morning are archived for rework with their code and saves retained); the [concept image](reference/voxel-isometric.png) remains an art reference.

The main Rootward game is a separate project. Do not make it depend on this project, add a main-menu link, or edit a sibling repository as part of work here. Keep changes, saves, runtime configuration, content and tests in `Voxel-Rootward/` unless the user explicitly asks otherwise. Do not add a second engine or AI provider dependency without a clear reason.

## Asset requests and review queue

For asset creation, updates or removals, read `asset-requests/README.md` and the relevant request brief/JSON under `asset-requests/requests/`. `scripts/asset-requests.sh list` shows the local queue. Notes, selected style references, editable/runtime paths, manifests, usage files and source-pack links are attached. Work on requests relevant to the current user task; do not silently start unrelated queued work. Reference assets are design inputs, not additional edit targets.

Use the existing art/world builds, run the applicable checks and full `scripts/test.sh`, inspect the result in Godot, and write a review. `scripts/asset-requests.sh finish` puts audited world models into the dev menu’s **Finished** queue; leave acceptance to the user. A deletion request is asset-specific authorization to resolve its dependencies and remove that asset through the workflow’s current deletion plan, preserving other authored work and saves. Never force deletion past live references or shared ownership. See the queue README for the exact lifecycle and commands.

## Current art decision — 2026-10-23

Preserve the approved painted whole-body sprite's proportions, face, clothes and style. The selected v9 keys use integer registration, with SW mirroring SE per cell and NW mirroring NE. Idle uses neutral pose 9, subtle breathing and front blinks every 6–7 idle seconds; rear views only breathe. The user explicitly selected **shared frame skins preserving the approved art**, rather than a layered bone rig. `pipeline/character-template.json` owns all common frame/timing/anchor/scale/idle settings; `pipeline/character-catalog.json` registers appearance skins. Skins cannot introduce private motion settings, and swaps preserve playback/idle state. `scripts/art.sh` is the single build; `scripts/character-art.sh` delegates to it. Rejected cutout/rig and superseded interpolation tools are archived under import-excluded `art/source/archive/`, never selected based on old code tests. The Blender world workflow remains separate. Read `pipeline/CHARACTERS.md` before adding a skin; modular clothes, bones and hand-item slots are not implemented.

## Architecture

- Godot 4.7.2, typed GDScript, desktop. `project.godot` sits at this folder's root. Match the installed Godot version.
- `core/` contains deterministic world rules over plain data; it does not create nodes, read files or decide visual outcomes.
- The player occupies integer cells and takes four-direction grid steps, with smooth visual interpolation, held-key repeat and click-to-walk routing. A small circular foot footprint checks passages; construction also uses integer cells. Maps are versioned area documents in `content/areas/`; their layout and collision data live there and nowhere else. Keep 60 Hz input/movement, four selected screen-diagonal views (SE/SW/NE/NW, with the approved mirrored pairs), phase-preserving SpriteFrames and material conventions documented in `pipeline/README.md`. Follow its linked character, world-asset, area and review playbooks. The outdoor builder supports houses, trees and appearance paint; house instances use the room catalog and preserve the outdoor snapshot. A full authored-map editor remains deferred. Keep the prototype standalone and prove the pipelines before expanding production scope.
- `scenes/` presents that state in the orthographic 3D view (fixed heading and elevation, following the player). Rendering and animation never determine whether a cell is walkable or a command is legal. `ui/` is the code-drawn interface kit and its screens (`pipeline/UI.md`); `app/` holds game flow, the session and saves. Build mode (`pipeline/BUILD.md`) follows the same split: `core/area_build.gd` and `core/build_ledger.gd` decide what may stand where (and keep what the player needs reachable), `scenes/build_overlay.gd` and `ui/build_hud.gd` draw and show it, `app/build_mode.gd` only asks and acts. The player's edits are a saved layer over the area document, never a rewrite of it.
- Player Python runs through the copied Wasmtime / CPython WASI runner (`sandbox/`). Never execute submitted source using host Python or the engine process. Every returned command must pass `core/` validation before it changes world state.
- Scene state and the code editor are parts of the experiment. A preview must remain a proposal until Apply commits that same validated proposal. Clear stale previews after a source edit, move, undo or reset. The notebook explains errors in plain words and a player's code only sees places they have visited; keep both properties when adding capabilities.
- World assets may begin as procedural tests. The selected cottage, mill-house, log-cabin, lamppost and clearing-ground have completed Blender handoff: read `pipeline/world-catalog.json`, edit their existing versioned `.blend` visually or through a deliberate source edit, and use `scripts/world-art.sh build <id>`. Never regenerate adopted source from the old maker or silently fall back when selected GLB output is missing. `seed`/`init` are one-time initialization and must refuse existing source. Trees, the beacon, gates, bridge decks, the wheel and Kindle Hollow's generated land remain procedural until separately adopted. A `post` lamp is the adopted lamppost: keep its glass a separate mesh with the material `lamp_glass`, which the game finds and lights. Generated concept images are references; approved sprite/texture images may be runtime assets after the documented pipeline and in-game review. Keep source images and prompts under `art/source/`, active choices in `pipeline/art-catalog.json`, and selected runtime outputs in `assets/`. Use `scripts/art.sh`; do not make parallel undocumented art pipelines.
- Use the local `sandbox/runtime/` when running player code. It is ignored by Git and is a platform-specific local dependency. Keep `sandbox/PROVENANCE.json` with the copied source boundary.
- The Python runner executes on a worker thread, respects its WASI limits, and returns to the UI without freezing the scene.

## Work style

1. Read this file, `README.md`, `pipeline/README.md`, the relevant spec/research under `docs/concept/v0.6/`, and the code before changing behavior.
2. Preserve the working project and user's edits. Inspect `git status` first. Do not delete, reset or overwrite authored work.
3. Build one small, reviewable gameplay or art slice at a time. Keep the game directly launchable at each step.
4. Give every world command an explicit type, target, range, occupancy/support rule, and useful error. Apply batches atomically. Never expose NodePaths, engine objects, or raw renderer coordinates to player code.
5. Add meaningful tests for new pure rules, area documents and sandbox boundaries (a new quest needs a reference solution in `test/test_area.gd`). Run `scripts/test.sh` and check visible changes in Godot at gameplay size before calling them complete. Report any skipped or failing check accurately.
6. Keep the project playable without access to Claude, ChatGPT, ComfyUI, Blender integrations or a network service. These can help author source artifacts; they are not runtime requirements.
7. Do not create or publish a commit, push, release or external message unless the user asks.

## Done means

The project opens from this folder, the relevant checks pass, the changed view is reviewed at its actual camera scale, and the README/spec reflect what really works. Distinguish proposed features from implemented features.
