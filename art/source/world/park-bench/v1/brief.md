# Asset brief: park-bench

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative street doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the timber bench beside the paths in the concept image. Warm oak slats, dark iron ends, and a clear seat, back and legs at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/park-bench/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/street.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/street.py` (one-time for all four street ids; it refuses existing sources), then `scripts/world-art.sh build park-bench`.
- Dimensions in world units and comparison to player: 0.9 m long, 0.4 m seat depth (0.5 m with the feet), seat top at 0.45 m, backrest top at 0.9 m. The character is about 1.45 m tall. Voxels are 0.05 m.
- Ground pivot and forward direction: ground origin at the centre of the seat. The seat faces Blender -Y (Godot +Z), and the backrest is on the +Y side.
- Visible overhang versus solid logical footprint: footprint `[-0.45, -0.2, 0.9, 0.4]`, which holds the seat, backrest and frames. The feet stick out 0.05 m past it front and back at ground level. The backrest and armrests stand inside it.
- Shared materials, textures and import requirements: flat colours, no textures. Timber `oak` and `oak_light` and iron `iron` are from the shared palette. `iron_light` and `iron_dark` are new and defined in `street.py`.
- Variant names and parts that move or change state: none. Objects group by the `part` property: `Timber` (slats) and `Iron` (frames, armrests, bearer, feet).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/park-bench/model.glb` after build; catalog id `park-bench`, status `candidate_unplaced`, in `catalog-street.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build park-bench`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews only, in `.cache/doodads/street/` (front, back, side, and an ortho-13 gameplay view). Not yet reviewed in Godot. The silhouette holds at gameplay size.
