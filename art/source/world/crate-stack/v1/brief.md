# Asset brief: crate-stack

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative farmyard doodad for the world. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the timber crates beside the cart in `reference/voxel-isometric.png`; two stacked boxes, not a building; plank slats and dark corner posts that read at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/crate-stack/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/farmyard.py` with the other farmyard ids.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/farmyard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build crate-stack`.
- Dimensions in world units and comparison to player: 0.45 m square and 0.5 m tall (two 0.25 m crates). The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the base crate, base on z = 0. The front (Blender -Y, Godot +Z) carries the plank seams.
- Visible overhang versus solid logical footprint: the proposed footprint is the base crate, `[-0.225, -0.225, 0.45, 0.45]`. The top crate is 0.35 m square and shifted one voxel to +X, so it sits inside the footprint and leaves a visible ledge on the -X side. Nothing overhangs.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber from the shared palette (`oak`, `oak_light`, `wood`, `wood_dark`). No new colours.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber` only.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/crate-stack/model.glb` and its `manifest.json`; catalog id `crate-stack`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build crate-stack`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews (front-right, front-left and back-right, plus gameplay scale). The crates have no iron fittings; the first draft's hasp read as a stray block and was removed. Checked in Godot at gameplay size: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md).
