# Asset brief: wooden-barrel

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative farmyard doodad for the world. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the warm oak of the carts and crates in `reference/voxel-isometric.png`; a chunky barrel rather than a building; a readable silhouette with a slight belly, iron hoops and a lid.
- Source folder/version and authoring tool/version: `art/source/world/wooden-barrel/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/farmyard.py` with the other farmyard ids.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/farmyard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build wooden-barrel`.
- Dimensions in world units and comparison to player: 0.45 m across the belly, 0.5 m deep including the front bung, 0.5 m tall to the lid. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the barrel's centre, base on z = 0. The bung on the front (Blender -Y, Godot +Z) is the only front detail.
- Visible overhang versus solid logical footprint: the proposed footprint is the whole barrel, `[-0.225, -0.25, 0.45, 0.5]`. Nothing overhangs it. Nothing is blocked until a placement is made.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`). Iron from the palette (`iron`); `iron_light` (`5f6c6e`) is new and defined in `farmyard.py`.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber` (staves, lid, bung) and `Iron` (hoops). Eight staves, three hoops.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/wooden-barrel/model.glb` and its `manifest.json`; catalog id `wooden-barrel`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build wooden-barrel`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews (front-right, front-left and back-right, plus gameplay scale). At gameplay zoom the staves are dense, so the barrel reads mainly by its hoops and lid. Checked in Godot at gameplay size: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md).
