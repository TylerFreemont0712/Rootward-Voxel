# Asset brief: signpost

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative street doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the signboard by the path in the concept image. A chunky timber post, two readable arrow boards, and iron fittings at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/signpost/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/street.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/street.py` (one-time for all four street ids; it refuses existing sources), then `scripts/world-art.sh build signpost`.
- Dimensions in world units and comparison to player: post 1.3 m tall and 0.1 m square. The cream board (0.9 to 1.25 m) points +X and the violet board (0.55 to 0.9 m) points -X. Each board is about 0.8 m long, and the whole sign spans about 1.05 m. The character is about 1.45 m tall.
- Ground pivot and forward direction: ground origin at the centre of the post's iron shoe. The boards face Blender -Y (Godot +Z).
- Visible overhang versus solid logical footprint: footprint `[-0.1, -0.1, 0.2, 0.2]`, the iron shoe. The boards overhang it sideways by about 0.5 m and 0.55 m at height. Their iron straps stand 0.05 m in front of it.
- Shared materials, textures and import requirements: flat colours, no textures. From the shared palette: `wood` and `wood_light`, `iron`, `cream`, `plaster_shade`, `roof` and `roof_dark` (the violet board). `iron_light` and `iron_dark` are new and defined in `street.py`.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Timber`, `Iron`, `Cream` (board edge and face) and `Violet`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/signpost/model.glb` after build; catalog id `signpost`, status `candidate_unplaced`, in `catalog-street.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build signpost`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews only, in `.cache/doodads/street/`. Not yet reviewed in Godot. At ortho 13 the boards read as two shapes, but the post and iron fittings are small.
