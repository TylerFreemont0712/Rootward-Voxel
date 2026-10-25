# Asset brief: clay-jug

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit, a glazed terracotta jug with a wide belly, a narrow neck and a lip, and one loop handle.
- Source folder/version and authoring tool/version: `art/source/world/clay-jug/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build clay-jug`.
- Dimensions in world units and comparison to player: 0.45 m across the belly, 0.5 m tall, and 0.55 m across with the handle. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the middle of the bounding box. The body axis sits 0.05 m toward -X, because the handle is on the +X side. No front face.
- Visible overhang versus solid logical footprint: no blocking footprint is proposed (`null`). The handle overhangs the belly.
- Shared materials, textures and import requirements: flat colours, no textures. Terracotta (`clay`, `clay_light`, `clay_dark`) is new to this group. The cream glaze uses palette colours (`cream`, `plaster`, `plaster_shade`).
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Clay` and `Cream`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/clay-jug/model.glb` and its `manifest.json` once built; catalog id `clay-jug`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build clay-jug`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). At gameplay zoom the glaze reads almost white, close to the notice paper's tone, and the handle is a small bump.
