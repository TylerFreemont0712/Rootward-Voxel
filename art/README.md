# Art source entry points

Read [the active pipeline](../pipeline/README.md) before changing sources or runtime selections.

- `source/adventurer/v1/`: original accepted painted design and prompt, preserved.
- `source/adventurer/v2-isometric/`: original whole-body character in four authored diagonal views; selected animation's unchanged keys.
- `source/adventurer/v3-smooth/`: accepted prototype in-betweens with exact-key/base/model/backend provenance; sixteen display frames per direction. Correct alternating-foot poses remain an art gate.
- `sprite_actor.gd`: selected AnimatedSprite3D, projected facing, phase-preserving playback, stop settling, fixed idle and shadow.
- `source/world/<id>/<version>/model.blend`: human-editable world source after adoption. See [Blender](../pipeline/BLENDER.md).
- `world_assets.gd`: loads catalog-selected GLBs; rules/collision remain in `core/`. `mechanism_builder.gd` uses the adopted `lamppost` for post lamps and finds its `lamp_glass` mesh.
- `world_palette.gd`, `surface_materials.gd`, `water.gdshader`: shared colours, surfaces and engine water. `world_textures.gd` reads `pipeline/texture-catalog.json` (which painted picture each palette colour wears); `build_grid.gdshader` is build mode's ground grid.
- `adventurer.gd`: older 3D fallback; not the selected character design.

`cutout_rig.gd`, `cutout_skin.gd`, `rigs/chibi_v1/` and `source/characters/adventurer-cutout/` are the **inactive, visually rejected cutout experiment**. Do not re-enable them because code checks passed. Original painted character fidelity takes priority over outfit swapping.

`scripts/art.sh` builds accepted character assets locally. `scripts/world-art.sh build <id>` exports adopted world sources without overwriting them. Source generation/interpolation is an explicit versioned authoring stage, not a runtime service.
