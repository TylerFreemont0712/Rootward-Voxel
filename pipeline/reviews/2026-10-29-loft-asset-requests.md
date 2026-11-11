# Loft asset requests — 2026-10-29

- `loft-luggage`: removed both spare shoes from the adopted Blender master, preserving the suitcase, folded clothes and scarf. Rebuilt with `scripts/world-art.sh build loft-luggage`; the audited export has 8 meshes and 2,832 triangles. [Gameplay-scale Godot view](../../evidence/asset-requests-2026-10-29/luggage.png).
- `loft-wardrobe`: added two different small posters to the closed door panels: a travel landscape and a botanical print. The adopted master retains the wardrobe and its original materials. Rebuilt with `scripts/world-art.sh build loft-wardrobe`; the audited export has 26 meshes and 2,949 triangles. [Godot close-up](../../evidence/asset-requests-2026-10-29/wardrobe.png) and [gameplay-scale view](../../evidence/asset-requests-2026-10-29/wardrobe-gameplay.png); the posters are small at normal scale.

Both use the normal catalog, source and runtime paths; room placement and collision are unchanged. The full `scripts/test.sh` suite passed, including world-art and authoring guards. The asset requests await user review in the Finished queue.
