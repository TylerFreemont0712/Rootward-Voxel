# Asset brief: mushroom-cluster

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: a clump of spotted mushrooms for a woodland floor. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: six cream and violet mushrooms on a short cut stump, in flat voxel colours.
- Source folder/version and authoring tool/version: `art/source/world/mushroom-cluster/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/outdoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/outdoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build mushroom-cluster`.
- Dimensions in world units and comparison to player: about 0.5 m across and 0.3 m tall: six mushrooms on a short stump. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the stump.
- Visible overhang versus solid logical footprint: none: the catalog gives it no footprint, so it never blocks movement. The placement body is a small square at the pivot.
- Shared materials, textures and import requirements: flat colours only, no textures. Materials and the new colours (`cut`, `twine`, `iron_light`, `apple`, `apple_light` where used) are defined in `outdoor.py`, not in `art/world_palette.gd`.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property (see `PART` in `outdoor.py`).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/mushroom-cluster/model.glb` and its `manifest.json`; catalog id `mushroom-cluster`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build mushroom-cluster`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: reviewed in Godot at gameplay size: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md). Small at gameplay size: the caps read as a pale cluster with violet specks.
