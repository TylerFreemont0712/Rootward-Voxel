# Asset brief: hanging-sign

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: an inn-style hanging sign for a street or a doorway. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: a timber post with an iron bracket arm reaching out, and a small board hanging from the arm with a violet rim and a cream face, in flat voxel colours.
- Source folder/version and authoring tool/version: `art/source/world/hanging-sign/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/outdoor.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/outdoor.py` (one-time; refuses an existing source), then `scripts/world-art.sh build hanging-sign`.
- Dimensions in world units and comparison to player: about 1.4 m tall, 0.5 m by 0.6 m in plan; the post is 0.15 m square. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the foot of the post, not the centre of the bounds. The iron arm reaches out from the post and the board hangs from it in front.
- Visible overhang versus solid logical footprint: the post, `[-0.075, -0.075, 0.15, 0.15]`. The arm and board overhang it.
- Shared materials, textures and import requirements: flat colours only, no textures. Materials and the new colours (`cut`, `twine`, `iron_light`, `apple`, `apple_light` where used) are defined in `outdoor.py`, not in `art/world_palette.gd`.
- Variant names and parts that move or change state: none. Objects are grouped by the `part` property (see `PART` in `outdoor.py`).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/hanging-sign/model.glb` and its `manifest.json`; catalog id `hanging-sign`, authority `blender`, status `candidate_unplaced`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build hanging-sign`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: reviewed in Godot at gameplay size: see [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md). The board is a plain cream face: it carries no lettering.
