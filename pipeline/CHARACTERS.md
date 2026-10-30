# Shared-frame character skins

The approved painted adventurer is the main character baseline. All compatible characters use one **painted-frame template**: the same poses, frame order, animation names, timing, foot anchor, world scale, breathing and blink behavior. A skin supplies appearance. This is the user's selected approach; the game does not use a bone or cutout rig.

## Ownership

| File | Owns |
| --- | --- |
| `pipeline/character-template.json` | The shared `painted_chibi_v1` frame/motion/idle/scale contract. |
| `pipeline/art-catalog.json` | The approved template artwork, source version and compiled output locations. |
| `pipeline/character-catalog.json` | Registered appearance skins and the active default. |
| `art/source/adventurer/v9-directional-walk/` | Approved four-direction paintings, blink, prompts, source history and packed atlas. |
| `pipeline/prepare_directional_walk.gd` | Optional source packing with integer registration, refusing an existing prepared version. |
| `pipeline/build_art.gd`, `pipeline/frame_skin_builder.gd` | The one offline build path and appearance validation. |
| `assets/characters/adventurer/`, `assets/characters/library.json` | Compiled template frames, manifest, atlas and skin library. |
| `art/frame_skin.gd`, `art/sprite_actor.gd` | Appearance retargeting, playback, idle and projected facing. |

`scripts/art.sh` builds everything selected. `scripts/character-art.sh` is an alias to that same build, not another pipeline. Sources are excluded from Godot import. Temporary review sheets have been removed from runtime assets; their unique source history is preserved with v9.

## Shared frame contract

The approved raw directional sheets are 1254×1254, with nine 418×418 cells read left-to-right, top-to-bottom. Cells 1–8 are walking; cell 9 is neutral idle. SW mirrors each SE cell; NW mirrors each NE cell, preserving frame order. The SE closed-eye frame is also mirrored exactly for SW.

The packed atlas is 1536×5376, containing four columns and twelve rows of 384×448 cells. Each direction occupies three rows, in SE/SW/NE/NW order. Indices 0–7 are walking, index 8 is neutral, and index 9 is the front-facing blink. Rear views have one idle drawing. Remaining slots are unused.

Every frame uses foot origin `[192,420]`. Eight walk poses at 240/13 FPS form a cycle across two 13/60-second grid steps. Each step takes exactly thirteen physics ticks. World height is 1.45. Source packing uses integer translation only: head silhouettes register horizontally and the lowest opaque boot pixel meets the foot origin. Approved pixels remain unchanged.

Turns and held movement preserve phase. Starting from idle begins at walk frame zero; stopping displays neutral pose 9 immediately. Idle breathes on a 3.6-second cycle, with at most 0.6% vertical change in front views and 0.4% in rear views, anchored at the feet. Front views blink for 120 ms with starts 6–7 idle seconds apart. Rear views only breathe. Walking cancels idle effects.

Movement and player commands remain independent of animation. Skins cannot override timing, direction mapping, anchors, scale, idle settings or animation layout.

## Existing skins

`adventurer` is the approved default, with unchanged artwork and tint. **`mira`** is a separately painted female lantern cartographer: wavy espresso bob, brass hair clips, warm brown skin, plum coat, ochre scarf, sage cuffs, moss trousers and chestnut boots. Her versioned nine-cell SE/NE sheets, exact SW/NW mirrors and eye-only blink are under `art/source/characters/mira/v1/`; the packed atlas is compiled to `assets/characters/skins/mira.png` through the same build.

The player is the approved boy (`adventurer`). Mira is a village NPC, alongside four newly painted residents. The Character screen names and turns the boy; resident skins are hidden from its picker. Older Mira player preferences resolve to the boy without changing saved progress.

| Skin | Village role and appearance |
| --- | --- |
| `rowan` | Millwright; silver hair and beard, teal vest, rust scarf. |
| `bram` | Carpenter; dark curls, copper vest, burgundy sleeves, leather apron. |
| `tessa` | Gardener; strawberry braid, moss cap, russet jacket, sage scarf. |
| `nell` | Herbalist; grey braided bun, round brass spectacles, teal shawl, violet tunic. |

Each has SE/NE nine-pose paintings, exact per-cell SW/NW mirrors, front eye-only blinks and an integer-registered packed atlas under `art/source/characters/<id>/v1/`. `prompts.json`, prompt text, generated inputs, `authoring.json` and `provenance.json` record the source process. The image tool did not expose a model identifier or seed; the record says so. `pipeline/prepare_villager_source.gd` is a guarded one-time source adapter for mirroring and feathered eye patches; the existing directional packer and `scripts/art.sh` compile everything. See [village source notes](../art/source/characters/village-v1.md) and the [review](reviews/2026-10-23-village-expansion.md).

`adventurer_twilight` remains a cooler whole-character tint example, hidden from the player picker with `"selectable": false`. This optional catalog boolean controls picker visibility only and cannot override motion. NPC skins explicitly set it false; the current game settings permit only the boy as the player.

Actor usage:

```gdscript
var actor := SpriteAdventurer.new()
actor.skin_id = "adventurer"
add_child(actor)
actor.set_skin("adventurer_twilight")
```

Changing a skin preserves facing, walk frame/subframe, playback state, idle drawing, breathing phase, blink deadline, position and foot origin. Unknown skins return false without changing the actor. Authored alternate atlases inherit the same frame regions, durations, speeds and loops; the approved template resource is never mutated.

## Dialogue portraits

Residents also have separately painted 1024×1536 portraits for [visual novel conversations](DIALOGUE.md), selected in the art catalog and built through `scripts/art.sh`. Their sources/prompts/provenance live under `art/source/portraits/v1/`; runtime pictures and a manifest live in `assets/portraits/`. This UI illustration layer preserves the approved boy, resident walk/idle pixels and shared motion template. Author a new version when changing a portrait; it is not an enlarged atlas frame or a private motion setting.

## Add an appearance

For a tint, register a new skin using `"atlas": "template"` and an RGBA `tint` with alpha 1. Run `scripts/art.sh` and review it beside the approved default.

For a newly painted appearance:

1. Start from the approved pose reference and copy the packed atlas into a **new source version** under `art/source/characters/<id>/<version>/`. Keep the exact canvas, pose order, foot origin, apparent scale and blink locations. Repaint appearance across every required frame; changing one idle drawing does not create a complete skin.
2. Keep the editable painting document when available, flattened atlas, source/prompt/edit record and `provenance.json` together. Provenance contains `output_sha256` for the flattened atlas and a `sources` mapping of source resource paths to SHA-256 hashes. For raw nine-cell sheets, the optional packing adapter below creates that provenance.
3. Add an entry to `pipeline/character-catalog.json`:

```json
{
  "label": "New character",
  "source": "res://art/source/characters/new_character/v1/sheet.png",
  "provenance": "res://art/source/characters/new_character/v1/provenance.json",
  "runtime": "res://assets/characters/skins/new_character.png",
  "tint": [1, 1, 1, 1]
}
```

4. Run `scripts/art.sh`. The compiler validates source hashes, copies to the derived runtime path, pins lossless/mipmap import and checks every required pose for size, transparency, clipping, foot registration and height. Skins cannot write over source or supply private animation settings.
5. Review all views in motion and neutral/blink at normal camera scale. Code cannot verify that a new painting follows the intended leg gesture. Select the default only after visual approval.

The source packer expects `SE.png`, `SW.png`, `NE.png`, `NW.png`, `blink-se.png` and `blink-sw.png` in a new source folder:

```sh
godot --headless --path . -s res://pipeline/prepare_directional_walk.gd -- \
  --source res://art/source/characters/<id>/<new-version>
scripts/art.sh
scripts/test.sh
```

The packer refuses existing `sheet.png` or `provenance.json`. Source variations require a new version, not regeneration over accepted paintings.

## Scope and source history

The [Wick/Tender movement study](../docs/concept/v0.72/wick-tender-movement.md) is a separate robot source family with four rolling keys per direction. Their carried item and asymmetric shell fittings require independently painted SE/SW/NE/NW views; never derive their left views with the human template’s mirroring convention. The guarded `prepare_robot_movement.gd` registers source candidates without resampling. Existing human template settings and the square’s adopted robot models remain unchanged.

The [v0.72 Sparks cast pack](../docs/concept/v0.72/cast-and-robots.md) adds five separate `sparks_*` skins using the selected concept wardrobes. Existing resident IDs and the boy retain their art. Selected registered sources live under `art/source/characters/<id>/sparks-v2/`, with the original generated paintings preserved in `sparks-v1/`; [source notes](../art/source/characters/sparks-v072.md) document the guarded `prepare_cast_source.gd` neutral/eye-patch adapter, followed by the existing directional packer and `scripts/art.sh`. Its cropped blink references are authoring inputs; complete neutral/blink frames retain the whole body. Six wheeled robot sheets accompany the pack as concepts, pending runtime atlas registration.

A frame skin is a complete appearance using common painted poses. It does not automatically recover bones, hidden anatomy, separable clothes or hand-item slots from a flattened PNG. Those would need a deliberate layered-art feature and another visual acceptance pass. Different body proportions, animation actions or genuinely asymmetric equipment require an explicit template revision/family rather than per-skin patches.

Rejected cutout tools, rig resources and runtime samples are archived under `art/source/archive/rejected-cutout/`; superseded interpolation tooling is under `art/source/archive/painted-interpolation/`. They are excluded from import and absent from active build commands. Earlier accepted painted source versions remain provenance history.

Normal builds and play do not need imagegen, ComfyUI, Blender or a network service. Review [the project handoff](../docs/PROJECT_HANDOFF.md) and [review guide](REVIEW.md) before expanding content.
