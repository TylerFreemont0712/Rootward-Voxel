# Woodland and building candidates

Six finished standalone models, **not placed in an area**. Open [the combined PNG](../../../../../evidence/scenery-candidates.png) for the actual Godot results, with the original player at gameplay scale.

| Asset ID | Design | Proposed blocking footprint |
| --- | --- | --- |
| `hearth-oak` | Bent old trunk, exposed roots, broad irregular green crown | Trunk radius 0.5 m; crown overhang is decorative |
| `ridge-cedar` | Tall blue-green crown, layered bough pads, fluted bark | Trunk radius 0.36 m |
| `river-willow` | Arched limbs, hanging leaf curtains, mossy roots | Trunk radius 0.5 m |
| `hearth-house` | Violet roof, cream plaster, stone-arched door, porch, east dormer | 5×5 cells: one extra cell on every side of the original 3×3 house |
| `lantern-loft` | Two storeys, teal gambrel roof, balcony, octagonal oriel and brass finial | 7×7 cells: two extra cells on every side |
| `brook-mill` | Larger stone-and-timber mill, open-spoked wheel, trestle sluice, hoist and roof monitor | 6×5 cell shell; wheel and launder extend east |

Each editable source is `art/source/world/<id>/v1/model.blend`, with a brief and provenance beside it. Each exported candidate is `assets/world/<id>/model.glb`, with the normal audited export manifest. [This manifest](manifest.json) lists dimensions and hashes for the whole set. All are new IDs; existing adopted sources remain owned by their current workflow.

Use `scripts/world-art.sh build <id>` after editing a saved source. The catalog's candidate status documents the handoff; registration alone places nothing. The historical `author.py`, `refine.py` and `finish_roof.py` record initial authorship and visual corrections; their overwrite guards deliberately refuse reuse after handoff.

The supplied GLBs contain all required textures. Materials reuse the new texture pack for plaster, masonry, timber, bark and windows, while roof tiles and leaf patches use the shared colour family. There are no runtime authoring dependencies.

The mill keeps a separate `waterwheel_pivot` with a local X axle. It is ready for a deliberate future adapter, but is static here. No river/water shader, mechanism behavior, collision update, enterable building, area placement or save change is included.

Render again locally:

```sh
godot --path . --resolution 1200x1000 -s res://tools/expansion_kit_review.gd -- .cache/world-expansion-v1/renders
/usr/bin/python3 art/source/world/expansion-kit/v1/make_sheet.py
```

All panels use the normal orthographic camera size 13 and the unchanged 1.45 m painted actor. The board keeps one image scale across the six assets. Roofs, crowns and approach decorations extend beyond their proposed blocking footprints.
