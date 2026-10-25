# Asset brief: wooden-bucket

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit (flat colours, timber and iron), a staved timber bucket with iron hoops, and a little water showing at the top.
- Source folder/version and authoring tool/version: `art/source/world/wooden-bucket/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build wooden-bucket`.
- Dimensions in world units and comparison to player: 0.3 m across and 0.35 m tall to the rim. The rope bail rises to about 0.45 m. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the centre of the bucket, which is also the body axis. No front face.
- Visible overhang versus solid logical footprint: no blocking footprint is proposed (`null`). The bail overhangs the rim.
- Shared materials, textures and import requirements: flat colours, no textures. Timber from the palette (`oak`, `oak_light`, `wood`, `wood_dark`), iron hoops (`iron`, `iron_light`, `iron_dark`), water from the palette (`water`, `water_light`, `water_dark`), and a twine bail (`twine` from the kit, `twine_light` and `twine_dark` new to this group).
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber`, `Iron`, `Water` and `Rope`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/wooden-bucket/model.glb` and its `manifest.json` once built; catalog id `wooden-bucket`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build wooden-bucket`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). The bail reads as a flat block on the rim close up, and the water is a small patch inside the rim.
