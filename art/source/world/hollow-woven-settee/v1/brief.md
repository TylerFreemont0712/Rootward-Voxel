# Asset brief: hollow-woven-settee

Status: authored for the village builder library.

- Purpose: A two-seat timber settle with woven teal upholstery and cream pillows.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-woven-settee/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `furniture.py::woven_settee` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 1.62 × 0.83 × 1.16 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 1.6 × 0.8 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-woven-settee/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-woven-settee` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
