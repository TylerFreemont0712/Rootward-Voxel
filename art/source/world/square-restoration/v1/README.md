# Restore the pre-flat square

The user clarified the baseline is the layout immediately before the flat expansion: area v6 and adopted ground v3. The initial original-square draft was superseded by that answer. Ground v5 copies v3, keeps the original terraces, smaller garden, promenade and stair flights, removes ground faces below the mist, and preserves the existing local-light sections and power-conduit geometry. The original v1–v4 masters remain.

`restore_area.py` records the document composition with the existing `[16,0]` saved coordinate offset. `restore_ground.py` records the source copy and lower-face removal. These are historical edits, not regeneration tools for the selected masters. Current JSON owns placements, and `haverlund-square-ground/v5/model.blend` owns terrain artwork. `fit_shop_plot.py` subsequently recesses only the clockmaker footprint into the higher rear land, preserving the shop's visibility from the lane without repeating the flat expansion.

`shop_door.py` copies clockmaker v3 to v4, keeps the separate recessed residence door static, gives the central glazed leaf its own hinge, and adds a 0.16 m stone plinth. The square places the building at `(12.5,20)`, raised to 2.16 m. The active approach/return is `(16,21)`; the glazed door is flanked by the two clock displays. The room's return link and native review use that same entrance.

Atmosphere is three unlit quads, six triangles, configured through `interior.depth_fog`. Fixed local lights use layer 1 and atmosphere uses layer 2. The base hides the bottom and two low-opacity wisps soften its meeting with masonry. All layers follow the shared daylight value. This is a cheap surface mist, not volumetric fog.

The player's v7 sketch is preserved byte-for-byte in its original export and in `content/areas/archive/haverlund-square-v7-layout-sketch.json`. A save epoch archives retired edits without applying them across restored terrain. Current edits, archives and campaign progress survive Continue. Old feet on removed ground or new shop furniture recover to safe positions.

Build through `scripts/world-art.sh build haverlund-square-ground` and `scripts/world-art.sh build haverlund-clockmaker`. See the [review](../../../../../pipeline/reviews/2026-11-04-square-restoration-and-clockshop.md) for final validation and captures.
