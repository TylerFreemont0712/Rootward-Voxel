# Kindle Hollow, the notebook and the new interface — 2026-10-23

- **Area/source version:** `content/areas/kindle-hollow.json` v1 and `.quests.json` (new); `content/areas/rune-mill.json` v1 (the 16×12 clearing, extracted unchanged); interface kit under `ui/` (new); `scenes/clearing_view.gd` made data-driven.
- **Intended change and reference qualities:** a proper larger starting area (user choice: ~64×48, following camera, level theme "light the hollow", live 3D title backdrop) with a HUD that stays out of the way, a summonable code notebook built for a programming-learning game, a pause menu, settings, a title screen and a character screen, in a semi-fantasy style taken from the voxel concept's own HUD. Painted character, camera heading/elevation, voxel look and the excluded-prop list are unchanged.
- **Build/check commands actually run:**
  - `scripts/test.sh`: **481 Godot checks passed** — 73 rules/WASI (`test_lab`), 86 area documents and the teaching arc (`test_area`), 32 learner helpers (`test_ui`), 75 session/game flow and real key routing (`test_app`), 30 movement and large-map routing (`test_movement`), 100 painted art, 30 frame skins, 52 world art and area views (`test_world_art`), 3 source protection; plus the Python guards: source protection (3) and `test_pipeline_handoff.py` (167: links, retired-path guard).
  - `tools/facing_review.gd` (real held keys, all four views and logical axes): passed.
  - `tools/movement_review.gd` (real clicks across the green, the bridge built through the notebook, click across it, held key repeat, release settles on a cell, typing in the editor does not move the player): passed.
  - `tools/playthrough.gd` (the whole level through the real controls: walk to each place, type the reference solution, Run, Apply): **5 of 5 quests complete, 19 of 19 lamps lit**.
  - `tools/ui_tour.gd` / `scripts/screenshot.sh`: 19 frames of every screen and state, reviewed by eye at 1600×1000, with four spot checks at 1280×720.
- **Gameplay resolution/camera and renderer:** 1600×1000 (and 1280×720, 2560×1440), GL Compatibility on an AMD Radeon 680M (integrated). Orthographic camera, 31° elevation, size 13 following the player; the notebook shifts the view. Build of the whole valley: about 210 ms; 167 fps at 1600×1000 and 125 fps at 2560×1440 with about 300–1000 draw calls.
- **Selected evidence:** [title](../../evidence/title.png), [play start](../../evidence/voxel-clearing.png), [notebook](../../evidence/notebook-code.png), [lesson](../../evidence/notebook-lesson.png), [a failed run](../../evidence/notebook-error.png), [map](../../evidence/map.png), [character](../../evidence/character.png), [live movement](../../evidence/sprite-movement.png).

## What was observed

- The district shots read as the concept: violet-roofed cottages, a cobbled green with lamps on stone bases, the mill with its turning wheel beside the river and the bridge, a dry-stone wall with the night gate, a winding lamp road and the beacon. Lit lamps get an additive halo and a pooled real light; the valley warms as the player lights lamps (blue hour to golden), and a lit beacon sends up embers.
- Real Python drives everything: previews are drawn as translucent proposals, Apply commits that exact result, Undo reverts only the program's effects, errors name the line and offer a did-you-mean (for example `Ture` → `True`).
- The character stays readable under tree crowns and roofs through a faint silhouette. The first version of the spawn view had a tree in front of the player; the generator now keeps the camera's line to the spawn clear.
- The interface scales cleanly between 1280×720 and 2560×1440. Menus take keyboard focus; HUD buttons are mouse-only with hotkeys; Esc peels back text focus, then the notebook, then opens the pause menu.

## Defects found and fixed during the work

- `StyleBox.duplicate()` silently dropped the plaque's non-exported properties, so icon buttons looked dark and unreadable. All `FantasyBox` properties are now `@export`; a test guards it.
- A tabbed row left earlier tabs looking pressed (`set_pressed_no_signal` does not enforce `ButtonGroup`); the notebook now unpresses the others itself.
- Lamp halos rendered as solid squares until their material was given alpha transparency; they are soft radial glows now.
- The objective pill slid under the notebook (its right group's offsets were moved asymmetrically) and the quest banner centered under it; centered elements now live on a stage that shrinks with the drawer.
- Several early screenshots were taken from stale run results because `CodeEdit.text_changed` is deferred; real use is unaffected, the review tool now waits a frame.

## Known gaps

- Everything is mouse/keyboard. There is no gamepad review, no audio, and no localization (the main game's EN/JP is not carried over).
- Kindle Hollow's land is generated procedurally (`art/terrain_builder.gd`); it has not been adopted into a Blender source. Trees, lamps, the gate, bridge decks and the wheel are still procedural tests.
- One area per session; there are no transitions between areas, no terrain height and no map editor. Quest content is five quests in one level; no curriculum beyond calls, lists/loops, variables, conditions and functions.
- The painted character remains the only look; the character screen says so. Clothing, held items and a second character are still deferred.
- Frame-rate figures are from an integrated GPU on one machine; no long-session or low-end measurement was done. Fonts were copied once from the main project; credits/licences for a release have not been reviewed.

## Decision

Accept as the first playable level and interface baseline; keep the generated land and procedural mechanisms as candidates.

## Next smallest proofs

1. A human play session through the five quests, noting where the lessons or hints confuse (the reference solutions pass, which does not show that the teaching works).
2. One new hand-made Blender asset (a watchtower for the Old Watch) taken through `scripts/world-art.sh` to prove the catalog path for something that is not a seed.
3. Adopt Kindle Hollow's land into Blender the way `clearing-ground` was, then set `ground.asset` in the document.
