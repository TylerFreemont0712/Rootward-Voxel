# Iona Venn — shared-frame appearance

New signwriter for **A proper welcome**. Authoring used built-in `image_gen.imagegen`, with the existing Sparks Mira SE/NE sheets as pose/style references. Iona's cropped dark curls/silver forelock, cream smock, blue paint-marked apron, olive trousers and brown boots distinguish her from the established cast. The original cast and approved boy are preserved.

`v1/SE.png`, `NE.png` and `blink-generated.png` are original transparent generated sources. Exact prompts, reference hashes and generation records sit beside them. Existing `pipeline/prepare_cast_source.gd` assembled registered cells and the blink; `pipeline/reflow_cast_source.gd` registered whole figures in `v2`; `pipeline/prepare_directional_walk.gd` prepared directional sources. No bones, private timing or runtime image service were added.

`pipeline/character-catalog.json` selects `v2/sheet.png` as the hidden `iona` skin. `pipeline/character-template.json` still owns frames, anchors, walking, idle/breathing/blinks and mirrored SW/NW views. `scripts/art.sh` compiles `assets/characters/skins/iona.png` and the shared library. Use that build for updates; preserve original generated sheets and edit a new version.

The new whole-body dialogue painting has separate source/provenance under [portraits/sparks/v3](../../portraits/sparks/v3/README.md).
