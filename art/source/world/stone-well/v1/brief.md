# Asset brief: stone-well

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative street doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the kit, cut limestone, warm timber and a violet roof. The well reads as a well from above at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/stone-well/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/street.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/street.py` (one-time for all four street ids; it refuses existing sources), then `scripts/world-art.sh build stone-well`.
- Dimensions in world units and comparison to player: ring 0.9 m across and 0.6 m tall. The frame and hood rise to 1.45 m. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the ring. The two uprights stand on the ring at x = -0.35 m and x = +0.35 m, with the crossbeam between them and the bucket hanging at the centre. The well has no front face.
- Visible overhang versus solid logical footprint: footprint `[-0.45, -0.45, 0.9, 0.9]`, which is the ring. The hood's eave reaches the ring's outer edge, so nothing projects past it. The water, bucket and rope sit inside.
- Shared materials, textures and import requirements: flat colours, no textures. From the shared palette: `stone_warm`, `plaster` (coping), `wood` and `wood_light`, `iron`, `roof`, `roof_light` and `roof_dark`, and `leather_light` (rope). `stone_warm_dark`, `well_water` (the dark surface) and `iron_light` are new and defined in `street.py`.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Stone`, `Timber`, `Iron`, `Violet`, `Rope` and `Water`.
- Fields/commands exposed to player programs, or decorative only: decorative only. The bucket is static and does not move.
- Active runtime output and catalog entry: `assets/world/stone-well/model.glb` after build; catalog id `stone-well`, status `candidate_unplaced`, in `catalog-street.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build stone-well`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews only, in `.cache/doodads/street/`. Not yet reviewed in Godot. The hood and ring read clearly at gameplay size. The bucket is only a few voxels wide.
