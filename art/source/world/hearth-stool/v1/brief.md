# Asset brief: hearth-stool

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area. Interiors are not placeable yet, so an indoor piece can only be set down outdoors for now.

- Purpose and player-visible role: decorative indoor furniture, a small round three-legged stool. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the village kit (warm timber in flat colours), a round stool with a pale seat cushion, and a silhouette that reads from the isometric camera at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/hearth-stool/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/indoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/indoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build hearth-stool`.
- Dimensions in world units and comparison to player: 0.35 m across, 0.45 m high. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the seat, base on z = 0. The stool is round and has no front face.
- Visible overhang versus solid logical footprint: the proposed footprint is the seat, `[-0.175, -0.175, 0.35, 0.35]`. The legs sit inside it, so nothing overhangs.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`) and the cushion from the shared palette (`plaster`, `plaster_shade`, `cream`). No new colours.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber` (legs and seat) and `Linen` (cushion).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/hearth-stool/model.glb` and its `manifest.json` once built. Catalog id `hearth-stool`, authority `blender`, status `candidate_unplaced`, in `art/source/world/doodads-kit/v1/catalog-indoor.json`. Not yet registered in `pipeline/world-catalog.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build hearth-stool`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews from the game camera at front, front-left and back-right, at 3.0 and 13 ortho scale. Not yet checked in Godot. The stool is the smallest piece, so its three legs are only two voxels wide and read as a dark base at gameplay zoom.
