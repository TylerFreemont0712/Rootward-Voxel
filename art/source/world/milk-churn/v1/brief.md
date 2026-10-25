# Asset brief: milk-churn

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative yard doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel kit, a tall galvanised churn with two iron bands, a flared lid and a small arched handle on the lid.
- Source folder/version and authoring tool/version: `art/source/world/milk-churn/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/yard.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/yard.py` (one-time; refuses an existing source), then `scripts/world-art.sh build milk-churn`.
- Dimensions in world units and comparison to player: 0.4 m across the body, 0.5 m across the bands, and 0.8 m tall to the top of the lid handle. The character is about 1.45 m tall.
- Ground pivot and forward direction: origin on the ground at the body axis. No front face.
- Visible overhang versus solid logical footprint: the proposed footprint is the body, `[-0.2, -0.2, 0.4, 0.4]`, a walker-blocking circle approximated as a square. The bands and lid rim overhang it by 0.03 to 0.05 m.
- Shared materials, textures and import requirements: flat colours, no textures. Galvanised iron from the palette's stone tones (`galv`, `galv_light`, `galv_dark`), and iron from the kit (`iron`, `iron_light`) with `iron_dark` for the foot. The foot and bands are iron; the body and lid are galvanised.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Metal` and `Iron`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/milk-churn/model.glb` and its `manifest.json` once built; catalog id `milk-churn`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build milk-churn`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: close-up previews in `.cache/doodads/yard/` (not committed). The lid handle merges into the lid at gameplay zoom, and the two bands read as dark stripes.
