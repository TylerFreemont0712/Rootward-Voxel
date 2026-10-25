# Main-project handoff

The user has accepted this clearing's **size, camera scale, painted character, voxel-inspired world style and overall presentation** as the baseline for the next main project. Develop from this approved foundation. Keep these choices stable unless a deliberate feature requires a reviewed change.

This folder is a self-contained Godot project. No sibling Rootward repository was modified or connected. Moving this folder preserves its `res://` references; adopting its contents into another project is a separate, deliberate integration.

## Start and verify

Use Godot 4.7.2. A new Linux x86_64 machine installs the pinned local Python/WASI dependency once:

```sh
scripts/setup-runtime.sh
scripts/play.sh
```

Playing uses supplied runtime art and requires no art tools or network. After changing character sources/skins, run `scripts/art.sh`. After code/content changes, run `scripts/test.sh`. For an adopted world model, edit its existing Blender source and run `scripts/world-art.sh build <asset-id>`.

Linux quick launch: `python3 scripts/install-desktop.py` installs **Rootward Voxel** in the applications menu and existing desktop folder. Re-run after moving this checkout. Its lantern/roots/code-brackets icon is selected in `pipeline/art-catalog.json` and built through `scripts/art.sh`; the supplied PNGs need no authoring tools to play.

The project name and `RootwardVoxelLab` save-directory identity are retained so existing edited player programs are not silently abandoned. A future rename should include an explicit saved-source migration.

## Approved baseline

| Area | Current contract |
| --- | --- |
| Engine and presentation | Godot 4.7.2 desktop, orthographic camera with the original heading/elevation that follows the player (scale changed deliberately with the larger area: size 13 by default, a setting), voxel-inspired 3D world with painted billboard characters. |
| World size and coordinates | Kindle Hollow is 96×80 cells and the original clearing 16×12; one world unit per cell; logical `[x,y,height]` maps to Godot `(x,height,-y)`. Maps are area documents in `content/areas/`. |
| Movement | Four cardinal logical neighbors, 60 Hz input, 0.25-second steps, smooth presentation, held repeat and click routing. |
| Characters | Shared `painted_chibi_v1` frame template, eight-pose walk in four views, neutral breathing idle and front blinks. The approved boy is the player; Mira, Rowan, Bram, Tessa and Nell are residents with separate painted skins on the same template. |
| Source authority | Versioned painted art and adopted Blender files; derived runtime output is rebuilt from catalogs. |
| Programming | Bounded worker-thread Python/WASI, validated atomic commands, preview → Apply, Undo and stale-result rejection. |
| Current persistence | One save slot: world state, quests, discovered places, program memory, Python source, name and build/paint edits over the unchanged area document. House instances have separate state, discovery and memory, and Continue can resume indoors. Settings are separate. |

## Pipeline map

The [2026-10-25 steps and doors pass](../pipeline/reviews/2026-10-25-steps-doors-and-cottage.md) adds tread-following character support, upright sprite depth, directed walk-through house travel, separate hinged leaves and clear openings. The new Concept Cottage is on the studio house shelf with an isolated saved room; the existing 23 village placements stay intact. The Lantern Loft’s moved turret and continuous roof junction are saved in its existing Blender master.

The [building guide](../pipeline/BUILDINGS.md) covers the 2026-10-24 roof/entrance refresh, polished lamp, river-connected quest wheel, bakery and smithy. There are 23 placed buildings and 98 builder entries. Existing adopted source backups remain beside their masters; new shops use the same catalog/export/room/finish systems.

The [detail material library](../pipeline/MATERIALS.md) supplies fifteen additional painted surfaces, both texture styles, saved per-part controls on 90 models, four Land floor paints and six per-house interior finish controls. Cottage, workshop, loft and mill templates have distinct palettes. Source images, exact prompts, selection and deterministic packaging are versioned; the existing Blender masters and pictures are preserved. See [the material review](../pipeline/reviews/2026-10-24-detail-materials.md).

The [ground guide](../pipeline/GROUND.md) covers half-cell appearance painting, the chunk skin, texture/height catalogs and GPU seam proofs. The searchable [build tray](../pipeline/BUILD.md) offers all six expansion models and 82 props. The [50-object library](../pipeline/BUILDER_LIBRARY.md) adds five organized categories and sixteen working pieces with F/Python control; its [review](../pipeline/reviews/2026-10-24-builder-library.md) records individual art review and saved interactions. The [village review](../pipeline/reviews/2026-10-23-village-expansion.md) records the 2.5-times larger area, homes, residents, water and boundaries; the [ground review](../pipeline/reviews/2026-10-23-ground-paint-and-builder.md) covers painting.

| Work | Authoritative source and build | Verification |
| --- | --- | --- |
| Characters and appearance skins | [Shared character guide](../pipeline/CHARACTERS.md); template and skin catalogs; `scripts/art.sh`. | Exact keys, skin compatibility/state preservation, phase/idle tests and actual Godot playback. |
| Buildings, lampposts and static land | [Blender guide](../pipeline/BLENDER.md); `pipeline/world-catalog.json`; existing `art/source/world/` masters (cottage, mill-house, log-cabin, lamppost, clearing-ground); `scripts/world-art.sh build <id>`. | Export/source hashes, Godot GLB audit and scene review. |
| Furniture, workshop, market, garden and working props | [Builder library](../pipeline/BUILDER_LIBRARY.md); fifty individual `art/source/world/hollow-*/v1/model.blend` masters, world/build catalogs; `scripts/world-art.sh build <id>`. Pure `core/prop_interactions.gd`, `active` state in `lab_world.gd`, `art/prop_visual.gd` presentation. | 570 library checks, 16 real-game integration checks; windowed art and F/Python/save review at two sizes. |
| Trees, other mechanisms and materials | [World assets](../pipeline/WORLD_ASSETS.md); explicit procedural source in `scenes/clearing_view.gd`, `art/mechanism_builder.gd`, `art/world_palette.gd`, `art/surface_materials.gd`, `art/water.gdshader`; one-time seed recipes in `pipeline/world_recipes.gd`. | Rule/visual separation, deterministic recipes and fixed-camera review. |
| Area layout, lessons and collision | [Area guide](../pipeline/AREAS.md); `content/areas/<id>.json` and `.quests.json`, `core/area_def.gd`, `core/lab_world.gd`, `core/quests.gd`. | `test/test_area.gd` (reachability, locks, every quest solved by real Python), traversal and routing tests. |
| Conversations and portraits | [Dialogue](../pipeline/DIALOGUE.md); pure `core/village_dialogue.gd`, authored topics in `content/villagers.json`, versioned portrait paintings/prompts/provenance, selected art catalog and `scripts/art.sh`. | All five portrait contracts, actual WASI examples, modal/input/save/indoor checks and windowed reviews at two sizes and enlarged UI. |
| Homes and residents | [Village](../pipeline/VILLAGE.md); area/room/resident documents, pure house/route rules, `app/game.gd`. | `test/test_places.gd`, `test/test_house_flow.gd`, windowed village and character review tools. |
| New programming commands | [Current API](PROGRAMMING.md); plain-data rules in `core/`, WASI adapter in `sandbox/`, orchestration in `app/`. | Pure rules, invalid/atomic batches, real WASI and preview/apply integration tests. |
| UI and input | [Interface guide](../pipeline/UI.md); `app/game.gd`, `app/session.gd`, `ui/`, `project.godot` Input Map; font/license files under `ui/fonts/`. | `test/test_app.gd`, `test/test_ui.gd`, `tools/ui_tour.gd` captures, focus, click/held walking, source-edit invalidation and gameplay-size review. |
| Runtime dependency | [Sandbox setup](../sandbox/README.md), pinned bootstrap and `sandbox/PROVENANCE.json`. | Real bounded Python execution in the test suite. |
| Visual acceptance | [Review guide](../pipeline/REVIEW.md), focused Godot tools, selected `evidence/`. | Current full-scene and movement/idle captures. |

There is one active character pipeline. `scripts/character-art.sh` delegates to `scripts/art.sh`. Experimental direction sheets were removed from assets after preserving their approved sources and history in v9. Rejected cutout/interpolation/early 3D-player experiments are retained only in import-excluded source archives.

## Keep with the main project

Keep `project.godot`, `core/`, `app/`, `scenes/`, `ui/`, active `art/` code, selected `assets/`, `pipeline/`, `scripts/`, `test/`, `tools/`, documentation, reference and accepted source/provenance. Source archives preserve prior authored work; they are not runtime dependencies.

Do not transfer generated `.godot/`, disposable `.cache/`, or a different machine's ignored `sandbox/runtime/` as portable source. Recreate the local runtime with the bootstrap, or deliberately package a matching runtime for a distribution. Selected evidence belongs with the documentation; intermediate captures belong in `.cache/`.

The project plays without Blender, AI tooling, sibling repositories or services. Blender and host Python are optional authoring tools; submitted player code always runs in WASI, never host Python.

## Remaining product work

This foundation is ready for main-project development. These are separate features or release tasks, rather than reasons to replace the approved presentation:

- A save migration policy when area documents change version (a save with an impossible state is rejected and the area starts fresh).
- General outdoor-region travel. House doors already swap the active session/view into four saved room templates and restore the exterior on exit; see [Village](../pipeline/VILLAGE.md).
- **Code that builds** (read houses, trees and doodads; turn houses and doodads) is implemented behind lesson-earned abilities (`core/code_build.gd`, `unlocks` in the quest document) with preview/Apply/Undo through the builder's edit layer. Its first lesson, **Face the lane**, is an *optional second chapter* after the epilogue (quests with `optional` and a `chapter`; the five-quest arc and the epilogue are unchanged). Placing, moving and removing from code are planned, not built. See the [programming guide](PROGRAMMING.md#houses-trees-and-doodads).
- **Build mode** includes add/move/turn/delete, half-cell appearance painting and land shaping (the Land menu: terraces on levels 0–2, stone stairs, ponds and streams that fall as waterfalls; see [shaping the land](../pipeline/BUILD.md#shaping-the-land)), undo/redo, saved edits, a left rail of round tools, a full-width searchable tray and a right-hand details panel (turning picture, facing compass for new and standing things, code for lamps, gates, bridges and working props, and for houses, trees and doodads once a lesson has taught it). All six expansion candidates and 82 props are studio shelf items; the 50 new pieces include sixteen with saved F/Python interactions. Model trees keep catalog trunk radii and Brook Mill is static scenery. See [build mode](../pipeline/BUILD.md) and [ground](../pipeline/GROUND.md). Still open: indoor furniture editing, stacking, inventories, crafting, slopes and code that reads land heights, logical path changes, walls/fences, moving lesson mechanisms and a release policy for players.
- Further identities and resident behavior through the frame-skin contract. Five residents now have short deterministic strolls and visual novel conversations, high-definition portraits, response choices and optional code explanations; daily schedules and resident quests remain open. The twilight tint stays a hidden authoring example.
- New actions/items/quests only with explicit rules and matching artwork. Modular clothes, held items, bones and a world editor are not implemented.
- Audio content if requested; no audio pipeline or runtime provider is currently selected.
- Target-platform runtime packaging, export presets, licenses/credits review, performance measurements, hardware gamepad review and release testing.

This handoff does not create a release, publish or commit. The existing application identity, saves and sibling projects remain under their current ownership.
