# Asset brief: hollow-water-pump

Status: authored for the village builder library.

- Purpose: A green iron hand pump pours into a stone trough beneath a brass spout.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-water-pump/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `village_magic.py::water_pump` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 0.76 × 0.97 × 1.26 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 0.85 × 0.8 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {"kind": "pump", "on": "Start", "off": "Stop"}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-water-pump/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-water-pump` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
