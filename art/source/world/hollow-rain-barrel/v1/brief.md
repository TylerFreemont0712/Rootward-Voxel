# Asset brief: hollow-rain-barrel

Status: authored for the village builder library.

- Purpose: A banded barrel with a copper downpipe, lid and brass garden tap.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-rain-barrel/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `garden.py::rain_barrel` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 0.79 × 0.91 × 1.52 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 0.95 × 0.85 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-rain-barrel/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-rain-barrel` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
