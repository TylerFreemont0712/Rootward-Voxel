# Asset brief: wheelbarrow

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit, a timber tray with an iron rim and a hay load, a single wheel at the front on an iron axle, and two handles at the back.
- Source folder/version and authoring tool/version: `art/source/world/wheelbarrow/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build wheelbarrow`.
- Dimensions in world units and comparison to player: 0.45 m wide, 0.9 m long and 0.5 m tall. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the middle of the bounding box. The tray centre sits 0.125 m toward the handles. The wheel is at -Y (front) and the handles are at +Y (back).
- Visible overhang versus solid logical footprint: the proposed footprint is the whole barrow, `[-0.225, -0.45, 0.45, 0.9]`, because a walker would be blocked by the wheel and the handle grips. Nothing overhangs it. A placement needs a deliberate layout review.
- Shared materials, textures and import requirements: flat colours, no textures. Timber from the palette (`wood`, `wood_light`, `wood_dark`, `oak`, `oak_light`), iron from the kit (`iron`, `iron_light`, `iron_dark`). The hay load (`hay`, `hay_light`, `hay_dark`) is new to this group.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Timber`, `Iron` and `Hay`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/wheelbarrow/model.glb` and its `manifest.json` once built; catalog id `wheelbarrow`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build wheelbarrow`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). At gameplay zoom the hay load reads as a pale block and the spokes merge into the tyre.
