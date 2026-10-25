# Asset brief: stepping-stones

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative stepping stones for a muddy crossing or a garden path. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: flat grey limestone slabs with moss on the back rim, set in a gravel bed so the group reads as one piece, low enough to walk over.
- Source folder/version and authoring tool/version: `art/source/world/stepping-stones/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/outdoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/outdoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build stepping-stones`.
- Dimensions in world units and comparison to player: about 1.6 m long, 0.4 m across and 0.15 m tall: three flat stones in a line. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the middle of the line of stones. The line runs along X.
- Visible overhang versus solid logical footprint: none: the catalog gives it no footprint, so it never blocks movement. The placement body is a small square at the pivot.
- Shared materials, textures and import requirements: flat colours only, no textures. Materials and the new colours (`cut`, `twine`, `iron_light`, `apple`, `apple_light` where used) are defined in `outdoor.py`, not in `art/world_palette.gd`.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property (see `PART` in `outdoor.py`).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/stepping-stones/model.glb` and its `manifest.json`; catalog id `stepping-stones`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build stepping-stones`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: reviewed in Godot at gameplay size: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md). Gravel runs between the stones so every voxel attaches to the model. The group is long for its placement body, so it can overlap a nearby small prop.
