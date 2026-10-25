# Asset brief: hollow-weather-vane

Status: authored for the village builder library.

- Purpose: A brass sun-and-rooster vane above four compass arms on a stone foot.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-weather-vane/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `village_magic.py::weather_vane` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 0.81 × 0.73 × 2.20 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 0.7 × 0.7 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-weather-vane/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-weather-vane` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
