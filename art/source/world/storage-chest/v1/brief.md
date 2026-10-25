# Asset brief: storage-chest

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area. Interiors are not placeable yet, so an indoor piece can only be set down outdoors for now.

- Purpose and player-visible role: decorative indoor furniture, a wooden storage chest. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the village kit (warm oak in flat colours), a chest with iron corner straps, a dark lid band and a small iron latch, and a silhouette that reads from the isometric camera at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/storage-chest/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/indoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/indoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build storage-chest`.
- Dimensions in world units and comparison to player: 0.6 m long, 0.4 m deep, 0.4 m high. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the footprint, base on z = 0. The front, with the latch, faces -Y (Godot +Z). The long axis runs along X.
- Visible overhang versus solid logical footprint: the proposed footprint is the body, `[-0.3, -0.2, 0.6, 0.4]`. The latch sits flush on the front, so nothing overhangs it.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`). Iron from the shared palette (`iron`). `iron_light` (`#5f6c6e`) is new to this kit and is defined in `indoor.py`, not in the palette yet.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber` and `Iron`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/storage-chest/model.glb` and its `manifest.json` once built. Catalog id `storage-chest`, authority `blender`, status `candidate_unplaced`, in `art/source/world/doodads-kit/v1/catalog-indoor.json`. Not yet registered in `pipeline/world-catalog.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build storage-chest`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews from the game camera at front, front-left and back-right, at 3.0 and 13 ortho scale. Not yet checked in Godot. The iron straps are dark and close in tone to the lid band at gameplay zoom.
