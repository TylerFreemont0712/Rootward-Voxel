# Sparks traveller dialogue portrait v2

The 1024×1536 RGBA `traveller.png` is a new full-body dialogue painting: the approved auburn boy in his teal tunic, cream cuffs, golden scarf and boots, with torso/hips and gaze turned toward Hotaru on screen-left. It is separate from gameplay animation. The previous traveller and Hotaru source paintings remain in `../v1/`; the approved v9 boy/template are preserved.

Generated with the **built-in `image_gen.imagegen` tool**, requesting a transparent background. The selected output was copied unchanged from the tool's generated-images directory into this source pack; the supplied alpha is preserved. No CLI/API fallback, image cleanup or repaint script was used. Model and seed were not exposed by the tool.

- [Exact final prompt and reference roles](traveller-prompt.json)
- [Source, prompt and reference SHA-256 provenance](traveller-provenance.json)
- [Selected source painting](traveller.png)

Identity authority is `art/source/adventurer/v9-directional-walk/idle-se.png`. The old `art/source/portraits/sparks/v1/traveller.png` supplies identity details; `hotaru-robot.png` supplies the painterly finish. They are reference inputs, not edit targets.

`pipeline/art-catalog.json` selects this source and its prompt/provenance in the existing traveller `portrait_libraries` entry. Run `scripts/art.sh` to validate hashes, copy losslessly to `assets/portraits/sparks/traveller.png` and build `traveller-library.json`. No image service is required to play or rebuild. The native review is [dialogue and clockwork transitions](../../../../../pipeline/reviews/2026-11-02-dialogue-and-clockwork-transitions.md).
