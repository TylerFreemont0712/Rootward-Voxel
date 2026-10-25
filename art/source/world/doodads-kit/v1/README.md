# Voxel doodads kit

Thirty-two small voxel props: furniture, household and farm things, garden and street dressing, and woodland and waterside pieces. They are **studio-only items on the build shelf's Doodads tab** (`content/build/catalog.json`, kind `prop`) and are not placed in any shipped area. The full list, sizes and footprints are in [the doodads review](../../../../../pipeline/reviews/2026-10-23-voxel-doodads.md); each prop has a `brief.md` in its own `art/source/world/<id>/v1/` folder.

## How a prop is made

Each model is a grid of 0.05 m voxels, authored by a one-time Blender script. Every material becomes one object named `<material>_geometry` that holds only its exposed faces, with flat shading. Objects carry a `part` property so they group in the Outliner.

| Script | Models |
| --- | --- |
| `author.py` | `flower-pot`, `hay-bale` (the first pair; it has its own copy of the helpers) |
| `farmyard.py` | `wooden-barrel`, `crate-stack`, `grain-sacks`, `woodpile` |
| `garden.py` | `window-planter`, `mossy-boulder`, `tree-stump`, `stream-reeds` |
| `street.py` | `park-bench`, `signpost`, `stone-well`, `cart-wheel` |
| `indoor.py` | `wooden-chair`, `dining-table`, `cottage-bed`, `bookshelf`, `storage-chest`, `hearth-stool` |
| `yard.py` | `watering-can`, `wooden-bucket`, `wheelbarrow`, `clay-jug`, `notice-board`, `milk-churn` |
| `outdoor.py` | `stepping-stones`, `rowboat-upturned`, `fallen-log`, `mushroom-cluster`, `market-stall`, `hanging-sign` |

`voxel_lib.py` holds the shared helpers (`author_models` and the voxel mesh builder) used by every script except `author.py`. Run a script once in Blender from the project root:

```sh
blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/<script>.py
```

Each script writes `<id>/v1/model.blend` and a `provenance.json`, and refuses to run if a source already exists, so it is a record and not the master. `farmyard.py` also accepts model ids after `--` to author only those (their saved sources must be removed first). After this handoff, open a `model.blend` in Blender to edit it, then build the runtime GLB:

```sh
scripts/world-art.sh build <id>
```

`catalog-<group>.json` beside the scripts is the catalog fragment each group proposed. The entries now live in `pipeline/world-catalog.json` with `status: candidate_unplaced`, and the shelf items in `content/build/catalog.json`; those two files are the sources of truth, so a fragment that differs from them is history.

## Review

`tools/asset_shot.gd` renders one model beside the painted character at the game's camera. `tools/doodad_tour.gd` opens the Doodads tab and places a yard of props through the real build controls. See [Build mode](../../../../../pipeline/BUILD.md).
