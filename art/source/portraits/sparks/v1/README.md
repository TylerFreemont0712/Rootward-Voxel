# Sparks story portrait

The approved second Hotaru portrait is adopted unchanged from `docs/concept/v0.7/art/2-hotaru/H3-portrait.png`. This 1024×1536 RGBA painting preserves the selected floating design; no pixels are edited and no new image is generated. Its original prompt record is copied in `prompts.json`; `provenance.json` records source/reference hashes and the adoption.

The additional portrait library in `pipeline/art-catalog.json` uses the existing `PortraitBuilder` through `scripts/art.sh`. Output is `assets/portraits/sparks/hotaru-robot.png` with a compiled `library.json`. Linear filtering, lossless RGBA, repaired alpha borders and no mipmaps match the other dialogue portraits. The five village portraits retain their original library and source files.

The portrait is used in the bottom portrait stage for important Sparks conversations. Narration and written tickets leave the avatar hidden; player replies keep Hotaru visible but subdued. Object descriptions and incidental remarks use world speech bubbles and do not enter the saved story log.
