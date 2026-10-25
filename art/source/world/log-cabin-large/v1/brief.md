# Asset brief: log-cabin-large

Status: accepted (2026-10-23); see [the review](../../../../../pipeline/reviews/2026-10-23-bigger-houses-textures-and-build-mode.md). The teal-roofed twin is [`log-cabin-large-teal`](../../log-cabin-large-teal/v1/brief.md).

- Purpose and player-visible role: Kindle Hollow's homes, grown from the 3-cell cabin because the owner found the houses a little too small. Placed as `home`, `row-north-a`, `row-north-b` and `row-south-a`, and offered in build mode as the Hollow House.
- Reference and the three visual qualities to match: the violet-roofed cabin in [reference/voxel-isometric.png](../../../../../reference/voxel-isometric.png), as in [`log-cabin`](../../log-cabin/v1/brief.md): chunky violet tiles with a lighter lip, log walls with dark chinking on a limestone foundation, an arched stone door with a round gable window.
- Source folder/version and authoring tool/version: `art/source/world/log-cabin-large/v1/model.blend`, Blender 5.2.2 LTS. Geometry from `Recipes.new(block, Recipes.LARGE).cabin()` in `pipeline/world_recipes.gd`, seeded, imported and then baked with `scripts/world-art.sh retexture`.
- Exact prompt or generator/export steps: `seed`, `init`, `build`, `compare` (lossless round trip), then `retexture` and `build`. The `LARGE` numbers: walls 4.52 × 4.44, eave 2.6, ridge 1.95 above it, ten tile rows of twelve, two windows on each long wall, a window each side of the door, a 0.74-wide door, a 1.3× chimney.
- Dimensions in world units and comparison to player: foundation 4.7 × 4.7; ridge about 4.6 high; the door is 0.86 wide with its arch topping out at about 1.9, against a character about 1.3 tall.
- Ground pivot and forward direction: ground origin at the centre of the footprint; the door and the round gable window face +Z (area-document facing `S`).
- Visible overhang versus solid logical footprint: the catalog footprint `[-2.35, -2.35, 4.7, 4.7]` blocks exactly five by five cells (`test/test_area.gd` proves it). The roof overhang, the doorstep and the chimney are decoration.
- Shared materials, textures and import requirements: the shared palette; pictures baked from `pipeline/texture-catalog.json` (lush set) with world-scale UVs; roof tiles use the `cells` mode.
- Variant names and parts that move or change state: none.
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/log-cabin-large/model.glb`, catalog id `log-cabin-large`, authority `blender`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build log-cabin-large`. Four placements in Kindle Hollow, two facings; the build-mode tests place more.
- Acceptance review/evidence and known limitations: [evidence/build-place.png](../../../../../evidence/build-place.png) and the town in [evidence/voxel-clearing.png](../../../../../evidence/voxel-clearing.png). Limits: same as the small cabin (box geometry, no porch); the 5-cell size is the owner's "about two tiles each side" taken literally; the mill and the plaster cottage were not enlarged.
