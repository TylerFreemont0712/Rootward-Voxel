# Asset brief: mossy-boulder

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative rounded stone with moss on top, for a clearing or a path edge. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the kit, a grey stone with a few lit facets, and a moss cap that reads green at gameplay size. Theme reference: `reference/voxel-isometric.png`.
- Source folder/version and authoring tool/version: `art/source/world/mossy-boulder/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/garden.py`.
- Exact prompt or generator/export steps: the one-time `garden.py` run (refuses an existing source), then `scripts/world-art.sh build mossy-boulder`. The shape is an ellipsoid mask with seeded lumpy and per-cell noise, cut flat at z=0.
- Dimensions in world units and comparison to player: 0.8 m across and 0.6 m of stone, 0.65 m with the moss cap. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the base, base on z=0. The stone has no front face; its lit facets are on the upper +X, -Y side.
- Visible overhang versus solid logical footprint: the proposed footprint is `[-0.35, -0.35, 0.7, 0.7]`. The widest belly reaches 0.4 m from the pivot, so it overhangs the footprint by 0.05 m, and the moss cap sits on top.
- Shared materials, textures and import requirements: flat colours only, no textures. Stone `stone`, `stone_light`, `stone_dark` (shadowed underside); moss `moss`, `moss_light`, `moss_dark`. All are palette hexes (moss uses the palette's grass shades).
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Stone`, `Moss`.
- Fields/commands exposed to player programs, or decorative only: decorative only. No collision is added and nothing is exposed to player code. The footprint is proposed for a later placement review.
- Active runtime output and catalog entry: `assets/world/mossy-boulder/model.glb`; catalog id `mossy-boulder`, authority `blender`, status `candidate_unplaced`, built and registered.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build mossy-boulder`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews at yaw 0 and 180 in `.cache/doodads/garden/`; in-game review pending. Limits: the moss patches are one voxel thick and the top shows some stepped texture from the noise.
