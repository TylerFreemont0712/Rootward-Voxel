# Asset brief: hollow-herb-drying-rack

Status: authored for the village builder library.

- Purpose: Tied bundles of sage and lavender hang from a braced rack above wicker baskets.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-herb-drying-rack/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `garden.py::herb_drying_rack` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 1.30 × 0.61 × 1.50 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 1.3 × 0.65 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-herb-drying-rack/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-herb-drying-rack` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
