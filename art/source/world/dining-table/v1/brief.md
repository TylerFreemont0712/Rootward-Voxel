# Asset brief: dining-table

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area. Interiors are not placeable yet, so an indoor piece can only be set down outdoors for now.

- Purpose and player-visible role: decorative indoor furniture, a square timber dining table. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the village kit (warm oak and wood in flat colours), a plain table with a plank top, and a silhouette that reads from the isometric camera at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/dining-table/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/indoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/indoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build dining-table`.
- Dimensions in world units and comparison to player: 0.8 m square top, 0.75 m high. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the footprint, base on z = 0. The front faces -Y (Godot +Z). The table has no front face of its own.
- Visible overhang versus solid logical footprint: the proposed footprint is the top, `[-0.4, -0.4, 0.8, 0.8]`. The legs sit inside it, so nothing overhangs.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`). No new colours.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/dining-table/model.glb` and its `manifest.json` once built. Catalog id `dining-table`, authority `blender`, status `candidate_unplaced`, in `art/source/world/doodads-kit/v1/catalog-indoor.json`. Not yet registered in `pipeline/world-catalog.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build dining-table`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews from the game camera at front, front-left and back-right, at 3.0 and 13 ortho scale. Not yet checked in Godot. The apron is one voxel thick, so it reads as a shadow line at gameplay zoom.
