# Asset brief: watering-can

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit (flat colours, timber and iron), a galvanised can read by its spout and rose, and a carrying handle that holds at close range.
- Source folder/version and authoring tool/version: `art/source/world/watering-can/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build watering-can`.
- Dimensions in world units and comparison to player: 0.25 m across the body, 0.5 m from the back of the handle to the rose, 0.35 m tall to the top of the handle. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the middle of the bounding box. The body axis sits 0.125 m behind it, toward the handle. The spout faces -Y (Godot +Z).
- Visible overhang versus solid logical footprint: no blocking footprint is proposed (`null`). The spout and rose overhang the body.
- Shared materials, textures and import requirements: flat colours, no textures. Galvanised iron in `galv`, `galv_light` and `galv_dark`, using the palette's stone tones (`stone`, `stone_light`, `stone_dark`). Iron (`iron`, `iron_light`) is from the kit; `iron_dark` is new to this group.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Metal` (body, spout, rose) and `Iron` (foot ring, handle, rose holes).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/watering-can/model.glb` and its `manifest.json` once built; catalog id `watering-can`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build watering-can`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). At gameplay zoom (ortho 13) the can reads as a grey lump with a spout; the rose holes do not survive.
