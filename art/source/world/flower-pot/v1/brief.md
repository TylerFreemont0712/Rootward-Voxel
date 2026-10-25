# Asset brief: flower-pot

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative doodad for the world. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the existing kit (warm terracotta, limestone and timber in flat colours), a small clay pot rather than a building, and a readable flower clump at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/flower-pot/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/author.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python art/source/world/doodads-kit/v1/author.py` (one-time; refuses an existing source), then `scripts/world-art.sh build flower-pot`.
- Dimensions in world units and comparison to player: 0.6 m across the rim, 0.45 m tall to the rim, about 0.9 m to the top of the flowers. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the pot. The pot is round-ish and has no front face.
- Visible overhang versus solid logical footprint: the proposed footprint is the pot, `[-0.3, -0.3, 0.6, 0.6]`. The four blossoms and their leaves overhang it. Nothing is blocked by the catalog yet; a placement needs a deliberate layout review.
- Shared materials, textures and import requirements: flat colours only, no textures. Clay (`clay`, `clay_light`, `clay_dark`), soil from the shared palette (`soil`), leaves from the shared palette (`leaf`, `leaf_light`, `leaf_dark`), and petals and a centre (`petal_*`, `centre`). Clay and petal colours are new and defined in the author script.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property: `Pot`, `Soil`, `Plants`.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/flower-pot/model.glb` and its `manifest.json`; catalog id `flower-pot`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build flower-pot`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md). Limits: at gameplay zoom the blossoms are small, and gold and cream petals are close in tone.
