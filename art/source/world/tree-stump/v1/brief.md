# Asset brief: tree-stump

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative cut stump for a clearing or a woodland edge. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the kit, warm bark sides with vertical ridges, and a pale cut top with growth rings. Theme reference: `reference/voxel-isometric.png`.
- Source folder/version and authoring tool/version: `art/source/world/tree-stump/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/garden.py`.
- Exact prompt or generator/export steps: the one-time `garden.py` run (refuses an existing source), then `scripts/world-art.sh build tree-stump`.
- Dimensions in world units and comparison to player: 0.5 m across and 0.4 m tall to the cut, 0.45 m with the moss cap; the root flare widens the base to 0.6 m. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the stump, base on z=0. The moss cap sits on the front-right edge (Blender +X, -Y, the side facing the default camera).
- Visible overhang versus solid logical footprint: the proposed footprint is `[-0.25, -0.25, 0.5, 0.5]`, the trunk. The root flare overhangs it by 0.05 m, and the moss cap sits on the rim above it.
- Shared materials, textures and import requirements: flat colours only, no textures. Bark `wood`, `wood_light`, `wood_dark`; cut top `cut_pale`, `cut_ring`, `cut_heart`; moss `moss`, `moss_light`, `moss_dark`. All are palette hexes.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Timber`, `Cut`, `Moss`.
- Fields/commands exposed to player programs, or decorative only: decorative only. No collision change and nothing exposed to player code.
- Active runtime output and catalog entry: `assets/world/tree-stump/model.glb`; catalog id `tree-stump`, authority `blender`, status `candidate_unplaced`, built and registered.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build tree-stump`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews at yaw 0 and 180 in `.cache/doodads/garden/`; in-game review pending. Limits: the rings are one voxel apart, so at distance they read as a pale disc with a ring.
