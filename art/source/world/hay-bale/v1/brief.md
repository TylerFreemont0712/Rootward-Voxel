# Asset brief: hay-bale

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative doodad for the farm side of the world. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the existing kit (flat colours, no smooth shading), a warm golden bale that reads as straw at a glance, and simple timber-and-twine character rather than a painted texture.
- Source folder/version and authoring tool/version: `art/source/world/hay-bale/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/author.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/author.py` (one-time; refuses an existing source), then `scripts/world-art.sh build hay-bale`.
- Dimensions in world units and comparison to player: 0.9 m long, 0.5 m deep, 0.5 m tall. Loose straws stand a little beyond that. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the bale. The long axis runs along X. The front face is -Y in Blender, which is +Z in Godot.
- Visible overhang versus solid logical footprint: the proposed footprint is the bale's floor, `[-0.45, -0.25, 0.9, 0.5]`. Loose straws on top and on the grass overhang it. Nothing is blocked by the catalog yet.
- Shared materials, textures and import requirements: flat colours only. Straw (`hay`, `hay_light`, `hay_dark`, `hay_pale`) and twine (`twine`) are new and defined in the author script.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Straw` and `Twine`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/hay-bale/model.glb` and its `manifest.json`; catalog id `hay-bale`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build hay-bale`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md). Limits: the straw runs are a fixed random pattern, and the loose straws are single voxels rather than thin sticks.
