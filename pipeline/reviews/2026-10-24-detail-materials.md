# Detail materials — 2026-10-24

Implemented fifteen individually generated paintings in the established warm village style, thirty runtime pictures across lush/solid, per-part finish controls on 88 existing models, four Land floor paints and six per-house room controls. [Material index and usage](../MATERIALS.md).

## Art and source review

The built-in image-generation tool authored each material separately against the existing texture/concept references. Native outputs, exact prompts, reference hashes and provenance are preserved in `art/source/world/textures/v2-detail/`. Tool model/seed were unavailable. `scripts/art.sh` packages deterministic 128px RGB pictures with matching edge pixels and lossless mipmapped imports. Existing texture recipes retain their values and bake compatibility; additions do not retexture adopted masters.

Inspected both [lush](../../evidence/detail-materials/library-lush.png) and [solid](../../evidence/detail-materials/library-solid.png) boards with every picture repeating 2×2. Pattern scale and color fit the village; wallpaper/linen stay quieter than decorative tile/patchwork. Boundary pixels match, and no conspicuous repeat gaps were observed in these views. This is visual review, not a claim of mathematically periodic painted motifs.

Inspected real Godot gameplay at 1600×1000 and 1280×720, with additional 1280×720 UI scale 1.5 review:

- [House materials](../../evidence/detail-materials/house-materials.png): imported log house, painted walls, slate roof, live turntable and per-part selectors. Cedar and [copper](../../evidence/detail-materials/copper-roof.png) roof variants were also inspected.
- [Floor paints](../../evidence/detail-materials/floor-paints.png): real Floors tray and appearance patches. Existing ragged ground blending still applies. All four floor pictures were also inspected on full interior floors.
- [Cottage](../../evidence/detail-materials/cottage-parquet.png): parquet, limewash, timber, brick and linen/patchwork.
- [Workshop](../../evidence/detail-materials/workshop-limestone.png): limestone, brick, riverstone and leather. `loft-west` is an older house id mapped to this workshop template.
- [Loft](../../evidence/detail-materials/loft-tiles.png): teal tile, wallpaper and patchwork.
- [Mill](../../evidence/detail-materials/mill-terracotta.png): terracotta, limewash and brick.
- Room controls at [1280×720](../../evidence/detail-materials/room-controls-1280.png) and [UI scale 1.5](../../evidence/detail-materials/room-controls-large.png): readable swatches, scrolling choices and accessible Undo/Redo/Done.

The approved camera orientation/scale and boy artwork remain unchanged. Materials add surface detail; room furniture geometry and footprints remain the authored baseline. Local triplanar overrides follow rotating models and do not mutate imported shared materials. Semantic flame/glow/glass bindings are excluded.

## Checks

- `scripts/art.sh`: all fifteen detail textures built in both styles, existing character/skin/portrait builds pass.
- `scripts/test.sh`: **23 suites, 4,625 checks passed**, including real Python/WASI, lessons, movement, building by code, dialogue, source guards, old bake handoffs and ground art.
- After adding the material guide and selected evidence, the focused handoff/link check passed **856 checks**; both new material suites and the art build also passed again.
- New material suite: **1,007 checks** for exact source/output hashes, 128px opacity, matching edge pixels, lossless mipmapped imports, audited/disjoint/non-glow bindings, unsupported edits, undo/redo, JSON history, movement preservation, legacy rooms and actual GLB instance isolation.
- New gameplay integration: **30 checks** through actual selectors, four floor paints, active chest finishing, saved outdoor Continue, room state/furniture preservation, undo/redo, Original, Continue indoors and two isolated homes. Windowed flow additionally visits the other three templates (**36 checks**).
- All **879** pre-existing `.png`, `.blend` and `.glb` files checked before/after: **zero changed**. Selected evidence hashes and counts are in [verification.json](../../evidence/detail-materials/verification.json).

## Limits

Finishes are cosmetic builder edits, with no new player Python commands. Supported parts are defined by existing model material groups; one part can cover multiple mesh pieces. There is no per-face painter, new geometry detail, indoor furniture placement, terrain reshaping, normal map or displacement system. Materials are available after placing/selecting a supported object; trees and lesson mechanisms keep their original appearance. Playing requires supplied runtime assets only.
