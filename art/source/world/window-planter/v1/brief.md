# Asset brief: window-planter

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative timber flower box for a sill or a garden edge. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the chunky voxel look of the kit (warm timber in flat colours), a plain box rather than furniture, and a readable row of small blossoms at gameplay size. Theme reference: `reference/voxel-isometric.png`.
- Source folder/version and authoring tool/version: `art/source/world/window-planter/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/garden.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/garden.py` (one-time; refuses an existing source), then `scripts/world-art.sh build window-planter`.
- Dimensions in world units and comparison to player: 0.8 m long, 0.25 m deep and 0.25 m tall box; the blossoms reach 0.55 m. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the box's centre, base on z=0. The flower side faces Blender -Y (Godot +Z). Five voxels of depth leave the box 0.025 m toward -Y (its front) of centre.
- Visible overhang versus solid logical footprint: the proposed footprint is the box body, `[-0.4, -0.15, 0.8, 0.25]`. The blossoms and leaves rise above it; two ivy trails hang 0.05 m past the front edge.
- Shared materials, textures and import requirements: flat colours only, no textures. Timber `wood`, `wood_light`, `wood_dark`; soil `soil`, `soil_dark`; leaves `leaf`, `leaf_light`, `leaf_dark`; blossoms `petal_violet`, `petal_cream`, `petal_mauve`, `centre`. All are palette hexes except `centre`, which is new here and matches the flower pot.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Timber`, `Soil`, `Plants`, `Blossoms`.
- Fields/commands exposed to player programs, or decorative only: decorative only. No gameplay effect, no collision change, no commands.
- Active runtime output and catalog entry: `assets/world/window-planter/model.glb`; catalog id `window-planter`, authority `blender`, status `candidate_unplaced`, built and registered.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build window-planter`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews at yaw 0 and 180 in `.cache/doodads/garden/`; in-game review pending. Limits: the violet and mauve blossoms are close in tone at distance.
