# Asset brief: bookshelf

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area. Interiors are not placeable yet, so an indoor piece can only be set down outdoors for now.

- Purpose and player-visible role: decorative indoor furniture, a tall open timber bookcase. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the village kit (warm oak and wood in flat colours), a tall shelf with rows of violet, teal and cream book spines, and a silhouette that reads from the isometric camera at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/bookshelf/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/indoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/indoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build bookshelf`.
- Dimensions in world units and comparison to player: 0.5 m wide, 0.3 m deep, 1.0 m tall. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the footprint, base on z = 0. The open front faces -Y (Godot +Z), so the book spines face the viewer; the closed back is at +Y.
- Visible overhang versus solid logical footprint: the proposed footprint is the whole cabinet, `[-0.25, -0.15, 0.5, 0.3]`. Nothing overhangs it.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`), book spines from the shared palette (`roof`, `roof_light`, `teal`, `teal_light`, `plaster`, `cream`). No new colours.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber` (sides, shelves and back), `Books` (violet and teal spines) and `Linen` (cream spines).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/bookshelf/model.glb` and its `manifest.json` once built. Catalog id `bookshelf`, authority `blender`, status `candidate_unplaced`, in `art/source/world/doodads-kit/v1/catalog-indoor.json`. Not yet registered in `pipeline/world-catalog.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build bookshelf`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews from the game camera at front, front-left and back-right, at 3.0 and 13 ortho scale. Not yet checked in Godot. The books are one voxel wide, so they read as colour bands at gameplay zoom.
