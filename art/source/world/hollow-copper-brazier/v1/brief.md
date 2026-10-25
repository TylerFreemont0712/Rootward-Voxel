# Asset brief: hollow-copper-brazier

Status: authored for the village builder library.

- Purpose: An embossed copper bowl on three iron legs with split logs and amber fire.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-copper-brazier/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `village_magic.py::copper_brazier` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 0.80 × 0.80 × 1.20 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 0.85 × 0.85 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {"kind": "light", "on": "Light", "off": "Extinguish"}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-copper-brazier/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-copper-brazier` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
