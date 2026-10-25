# Asset brief: cart-wheel

Status: candidate. On the studio build shelf's Doodads tab (`content/build/catalog.json`, kind `prop`) and registered in `pipeline/world-catalog.json`; not placed in any shipped area.

- Purpose and player-visible role: decorative street doodad. It is not placed in any shipped area; the studio can place it from the build shelf's Doodads tab.
- Reference and the three visual qualities to match: the wagon and its wheels in the concept image. Its iron rim, timber spokes and hub must read at gameplay size.
- Source folder/version and authoring tool/version: `art/source/world/cart-wheel/v1/model.blend`, Blender 5.2.2 LTS, generated once by `art/source/world/doodads-kit/v1/street.py`.
- Exact prompt or generator/export steps: `blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/street.py` (one-time for all four street ids; it refuses existing sources), then `scripts/world-art.sh build cart-wheel`.
- Dimensions in world units and comparison to player: 1.0 m across and 1.0 m tall, standing on its rim. The rim is 0.1 m thick, and the hub caps reach 0.2 m. The character is about 1.45 m tall.
- Ground pivot and forward direction: ground origin at the bottom of the rim, where the wheel touches the ground. Its plane is XZ and it faces Blender -Y (Godot +Z).
- Visible overhang versus solid logical footprint: footprint `[-0.5, -0.05, 1.0, 0.1]`, a strip the wheel's width and thickness. The hub caps overhang it by 0.05 m front and back at about 0.5 m height. Nothing else projects past it.
- Shared materials, textures and import requirements: flat colours, no textures. From the shared palette: `iron`, `oak` (spokes) and `wood` (hub). `iron_light` and `iron_dark` are new and defined in `street.py`.
- Variant names and parts that move or change state: none. The wheel does not turn. Objects group by the `part` property: `Iron` (rim, cap) and `Timber` (spokes, hub).
- Fields/commands exposed to player programs, or decorative only: decorative only.
- Active runtime output and catalog entry: `assets/world/cart-wheel/model.glb` after build; catalog id `cart-wheel`, status `candidate_unplaced`, in `catalog-street.json`.
- Build command and second-placement/rebuild check: `scripts/world-art.sh build cart-wheel`. Placed through build mode in `test/test_build_mode.gd` and `tools/doodad_tour.gd`, which also exercise move, delete and save.
- Acceptance review/evidence and known limitations: Blender previews only, in `.cache/doodads/street/`. Not yet reviewed in Godot. Reads as a wheel at gameplay size, but the spokes are small there.
