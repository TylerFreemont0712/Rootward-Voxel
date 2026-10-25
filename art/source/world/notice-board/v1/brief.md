# Asset brief: notice-board

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit, a timber board on two posts with a cream notice, and a violet tiled cap, matching the reference's notice boards.
- Source folder/version and authoring tool/version: `art/source/world/notice-board/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build notice-board`.
- Dimensions in world units and comparison to player: 0.8 m wide board, 0.5 m tall board on 1.0 m posts, 1.2 m tall with the cap, and 0.9 m wide with the cap overhang. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the middle of the bounding box. The posts sit 0 to 0.1 m behind it and the board faces -Y (Godot +Z).
- Visible overhang versus solid logical footprint: the proposed footprint is the posts and board line, `[-0.4, -0.1, 0.8, 0.2]`. The violet cap overhangs it by about 0.05 m at each side.
- Shared materials, textures and import requirements: flat colours, no textures. Timber from the palette (`wood`, `wood_dark`, `oak`, `oak_light`), the notice (`cream`, `plaster`, `plaster_shade`), teal pins (`teal`) and the violet roof (`roof`, `roof_light`, `roof_dark`). All are palette colours.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber`, `Cream`, `Pins` and `Roof`.
- Fields/commands exposed to player programs, or decorative only: decorative only. The notice text is plain dark bars, not readable words, so no script can read it.
- Active runtime output and catalog entry: `assets/world/notice-board/model.glb` and its `manifest.json` once built; catalog id `notice-board`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build notice-board`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). The cap reads as striped slabs, and the text lines are plain bars.
