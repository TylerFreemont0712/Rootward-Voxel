# Asset brief: stream-reeds

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative clump of reeds and cattails for a stream edge. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab. It has no footprint, because reeds stand at the water's edge.
- Reference and the three visual qualities to match: the chunky voxel look of the kit, thin tall stalks with brown seed heads, and teal-green blades low on the stalks. Theme reference: `reference/voxel-isometric.png`.
- Source folder/version and authoring tool/version: `art/source/world/stream-reeds/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/garden.py`.
- Exact prompt or generator/export steps: the one-time `garden.py` run (refuses an existing source), then `scripts/world-art.sh build stream-reeds`.
- Dimensions in world units and comparison to player: six one-voxel stalks from 0.6 m to 1.0 m tall, a clump 0.55 m by 0.5 m. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of a small mud bed, base on z=0. No front face.
- Visible overhang versus solid logical footprint: no footprint (`null`). The blades reach about 0.15 m beyond the mud bed.
- Shared materials, textures and import requirements: flat colours only, no textures. Stalks `reed`, `reed_dark`; seed heads `seed`, `seed_light`; blades `blade`, `blade_dark` (palette teal-green); mud `soil`. The reed stalk and seed-head shades are new here; the rest are palette hexes.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Reeds`, `Seedheads`, `Soil`.
- Fields/commands exposed to player programs, or decorative only: decorative only. No collision and nothing exposed to player code.
- Active runtime output and catalog entry: `assets/world/stream-reeds/model.glb`; catalog id `stream-reeds`, authority `blender`, status `candidate_unplaced`, built and registered.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build stream-reeds`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews at yaw 0 and 180 in `.cache/doodads/garden/`; in-game review pending. Limits: one-voxel stalks are thin at gameplay size, and the blades read as small teal hooks rather than long leaves.
