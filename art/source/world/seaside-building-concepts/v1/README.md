# Seaside-town architecture studies — v1

Three unselected concept plates, generated 2026-10-29 with the built-in `image_gen.imagegen` tool. Each requested two complementary complete orthographic views at approximately 31° downward elevation and a 45° diagonal azimuth, matching the game’s elevated view. These are architectural direction references rather than measured construction drawings.

Selected plates within the candidate pack: **A-tideglass-chandlery.png**, **B-gullstitch-sail-loft-v2.png**, **C-lowtide-baths.png**. No building direction has yet been chosen by the user.

- **A — Tideglass Chandlery:** a tide-clock corner bay, maritime stock and rear loading hatch.
- **B — Gullstitch Sail Loft:** tall loft shutters, a connected sail hoist and timber net gallery.
- **C — Lowtide Baths & Washhouse:** glazed rooflight, private bathing rooms and useful rear wash/boiler yard.

`prompts.json` preserves all exact prompts, original generated output paths, reference hashes and output hashes. Individual `*.generation.json` records duplicate the record for each image. The image tool exposed neither a model identifier nor a seed. No CLI/API fallback or image postprocessing was used. The documentation images are byte-identical copies of the generated PNGs; original tool output is also preserved at its default location.

## Paired-angle review

A’s corner clock bay and rotated chimney arrangement, and C’s front entrance versus rear boiler/cistern yard, read as complementary opposing views, so both remain unchanged. The first B plate showed the same net-gallery wall from front and rear. A targeted imagegen edit produced **B-v2**: the right-hand view now shows the rear gable and previously unseen plain long service wall, with a canvas awning, rope reels and mending bench. The large net gallery is hidden on the far side, apart from its end peeking past the distant corner. The left street design, roof, hoist and gallery are retained visually. As with any generated edit, its pixels are not identical to the first plate; the original remains intact rather than being overwritten.

The B-v2 generation record identifies its exact edit prompt and the initial B plate’s hash. `prompts.json` retains both attempts and selects the corrected image for option B.

References:

1. `docs/concept/v0.72/art/guildhall-square.png`: approved city scale, warm outlined materials, joined town frontage.
2. `docs/concept/v0.7/art/4-opening/T7c-workshop-lane.png`: workshop craft, pale masonry, warm timber, clay tiles, sea-facing town atmosphere.

The candidate concepts are standalone buildings that could fit close to neighbouring frontages. They do not replace the approved guild hall, post office, shops or workshop. After a direction is chosen, resolve exact matching elevations and scale in an editable source, then adopt and build through the existing `pipeline/world-catalog.json` and `scripts/world-art.sh` workflow. No model has been registered or selected by this art study.

Gallery: [Three seaside-town building directions](../../../../../docs/concept/v0.72/seaside-buildings.md).
