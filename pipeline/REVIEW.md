# Review and baseline acceptance

The user accepted the current clearing's size, scale and style as the main-project baseline. Review changes against that accepted result, the selected captures and [handoff](../docs/PROJECT_HANDOFF.md). The concept image remains an art reference; it is not a demand to redesign approved assets.

Use the [review record](templates/review-record.md) to record changed sources, commands, visible results and remaining limitations.

## Routine checks

```sh
scripts/art.sh                  # after changing character source/template/skins
scripts/test.sh                 # rules, WASI, app, motion, art, skins and source guards
scripts/play.sh
scripts/screenshot.sh           # every screen of the real game → .cache/tour; selected frames → evidence/
```

`VOXEL_LAB_FRESH=1` (set by the test and screenshot scripts) starts review runs from a new journey and stops them reading or writing the player's save and settings. Normal play saves the world, quests, discoveries, memory, source and name together.

For an adopted world asset, edit its existing Blender source, save and run `scripts/world-art.sh build <id>`. Never reinitialize an adopted source. `compare` verifies an unedited seed round trip; an intentional visual change can correctly differ from the original seed.

## Character review

The selected character uses the [shared frame-skin pipeline](CHARACTERS.md). Review the approved adventurer and the changed skin side by side. Keep the same frame order, apparent scale, foot anchor and motion. Check all eight poses, loop seam, turn/start/stop, alpha edges, neutral placement, the slight breath and a complete front blink interval. Rear views should only breathe.

Skin changes must preserve animation frame/subframe, facing, blink clock, breathing and position. An authored new appearance must satisfy the compiler and visual review; a tint example does not prove a newly painted body or outfit.

Focused views:

```sh
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1000x1000 res://tools/painted_study.tscn
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1000x1000 res://tools/skin_study.tscn
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/facing_review.gd
```

`tools/painted_record.gd` records actual selected actors. Set `VOXEL_IDLE_REVIEW=1` for eight idle seconds and front-blink observation. `tools/skin_study.tscn` compares the unchanged default with Mira in all four directions, using shared frames. `tools/character_review.gd -- <output-directory>` records their walks and eight idle seconds, selects Mira through the real Character controls, and captures her portrait and normal-scale gameplay. Run review tools with `VOXEL_LAB_FRESH=1`.

## World and interaction review

| Review | Expected behavior |
| --- | --- |
| Approved look | Preserve the painted player, voxel-inspired palette/forms, camera heading/elevation and the on-screen size of the character. The camera follows the player and fills the window; the original single-clearing composition is no longer the screen layout. |
| Movement | Smooth one-cell steps; held walking and turns preserve phase; click routes respect obstacles; editor focus stops repetition after the current step. |
| Collision/support | Building/trunk/post footprints, bridge gaps and gate state use core rules, independently of canopies and decorative overhang. |
| Depth and materials | Correct geometry occlusion, planted feet, calm texture detail and readable lamps/water at the normal camera. |
| Programming | Preview stays a proposal; Apply commits the same validated result; source edits/moves invalidate it; Undo reverts a program's effects without moving the player; Reset keeps code, quests and discoveries. |
| Interface | The HUD stays small and the code is summoned; every screen is checked at 1600×1000 and 1280×720 (`scripts/screenshot.sh`, see [the interface guide](UI.md)); an error names its line and suggests a fix; Esc peels back one layer at a time. |
| Level | Every lamp, zone and door is reachable; the locks lock; each quest has a reference solution that completes it and a starter that does not (`test/test_area.gd`); `tools/playthrough.gd` finishes the level through the real controls. A human play session is still needed to judge whether the lessons teach. |
| Source ownership | Accepted painted/Blender sources stay unchanged unless deliberately edited; builds verify their hashes and derived output. |
| Skin reuse | One common animation/template contract; appearance changes do not create per-skin motion settings. |

`tools/movement_review.gd` drives actual mouse/keyboard walking in the real game: clicks across the green, builds the bridge through the notebook, crosses it, checks held input/release/focus and saves temporary frames plus selected movement evidence. `tools/playthrough.gd` finishes the whole level and `tools/area_shot.gd` renders any spot of an area. `tools/build_tour.gd` drives build mode through the real game and `tools/build_overlay_shot.gd` renders its drawing alone. `tools/asset_shot.gd` shows one world asset beside the character (a recipe before adoption, the exported GLB after), and `tools/blender_preview.py` renders an editable `.blend` from the game's angle. `tools/art_study.tscn` is the selected character detail; `VOXEL_ART_STUDY=house` uses the adopted cottage instead.

Keep a small current set of selected captures in `evidence/`. Intermediate frames/logs live in ignored `.cache/`. Preserve source history in `art/source/`, with inactive experiments in import-excluded `art/source/archive/`.

## Current foundation and expansion

| Pipeline | Implemented | Deliberate next work |
| --- | --- | --- |
| Character | Approved eight-pose paintings, neutral breath/blink, shared frame/skin registry, phase-preserving appearance changes. | More authored identities; additional actions or different proportions need a reviewed template revision. |
| World art | Protected Blender source/export/audit for cottage, mill, log cabin, lamppost and land; documented procedural trees/mechanisms/materials. | Adopt further assets as their visual/source edits are reviewed. |
| Area | Versioned area documents loaded by rules and view: Kindle Hollow (64×48, nine zones, five quests) and the original clearing, with reachability and lock tests. | Area transitions, Blender adoption of generated land, a map editor. |
| Programming | Bounded real WASI execution, atomic commands, preview/apply/undo/reset and stale-result guards. | Add capabilities for concrete gameplay needs. |
| Persistence | One save slot (world, quests, discoveries, memory, source, name) and a settings file; Continue restores them. | A migration policy when area versions change; more than one slot. |

These remaining features are recorded in the handoff; they do not reopen the user's acceptance of the present size/style. Release packaging and platform verification remain distinct from starting main-project development.
