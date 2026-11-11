# Braum and Iona dialogue paintings

Selected sources: `braum.png` and `iona.png`, 1024×1536 RGBA. Built-in `image_gen.imagegen` created both paintings. Exact prompts are in [prompt.json](prompt.json), with identity/style reference hashes and source hashes in [provenance.json](provenance.json). Per-image generation records retain the original generated-file provenance. Model and seed were not exposed by the tool.

Braum retains the existing `sparks_bram` carpenter identity and clothes, with his full body facing screen right. Iona matches her new shared-frame skin and also faces her conversation partner. The main character's approved painting remains selected separately in v2. These are dialogue illustrations, not walking atlases.

`pipeline/art-catalog.json` selects these sources. `scripts/art.sh` validates hashes, copies them losslessly to `assets/portraits/sparks/`, configures UI imports and builds `welcome-library.json`. Native views confirmed clean transparent compositing. The dark colours visible outside the silhouette in some raw image viewers are RGB under zero alpha; they do not appear in the game. Unselected background-extraction prompts are retained as authoring notes; they do not replace either selected painting.

Runtime needs no generation service. See the [review](../../../../../pipeline/reviews/2026-11-02-welcome-quest-and-property.md).
