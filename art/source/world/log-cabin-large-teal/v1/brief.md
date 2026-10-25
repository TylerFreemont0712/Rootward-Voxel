# Asset brief: log-cabin-large-teal

Status: accepted (2026-10-23); see [the review](../../../../../pipeline/reviews/2026-10-23-bigger-houses-textures-and-build-mode.md).

- Purpose and player-visible role: the miller's house, the 5-cell house under a teal roof to tie it to the mill. Placed as `miller-house` and offered in build mode as the Millwright's House.
- Reference and the three visual qualities to match: as [`log-cabin-large`](../../log-cabin-large/v1/brief.md), with the concept's teal mill roof (`teal`, `teal_light`, `teal_dark` tiles) instead of violet.
- Source folder/version and authoring tool/version: `art/source/world/log-cabin-large-teal/v1/model.blend`, Blender 5.2.2 LTS, from `Recipes.LARGE.merged({"roof": "teal"})`; baked with `retexture`.
- Exact prompt or generator/export steps: as the violet house.
- Dimensions in world units and comparison to player: identical to `log-cabin-large`.
- Ground pivot and forward direction: door and gable window face +Z.
- Visible overhang versus solid logical footprint: footprint `[-2.35, -2.35, 4.7, 4.7]`, five by five cells.
- Shared materials, textures and import requirements: as the violet house, with the `roof_tile_teal` picture.
- Variant names and parts that move or change state: none. Fields/commands exposed to player programs: decorative only.
- Active runtime output and catalog entry: `assets/world/log-cabin-large-teal/model.glb`, catalog id `log-cabin-large-teal`, authority `blender`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build log-cabin-large-teal`.
- Acceptance review/evidence and known limitations: the mill yard in the review's captures. Same limits as the violet house.
