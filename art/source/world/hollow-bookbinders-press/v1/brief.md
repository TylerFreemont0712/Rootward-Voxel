# Asset brief: hollow-bookbinders-press

Status: authored for the village builder library.

- Purpose: Twin screw uprights squeeze a brass-cornered book between timber platens.
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/hollow-bookbinders-press/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `workshop.py::bookbinders_press` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately 1.15 × 0.79 × 1.66 metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: 1.15 × 0.8 metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/hollow-bookbinders-press/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build hollow-bookbinders-press` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
