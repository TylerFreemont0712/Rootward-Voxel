# Voxel doodads: three batches — 2026-10-23

Status: thirty-two candidates, now offered on the **studio build shelf's Doodads tab**. None is placed in a shipped area, and no area document references them. All thirty-two are registered in `pipeline/world-catalog.json` with `status: candidate_unplaced`, which means unplaced in the shipped valley, as it does for the six scenery candidates. The batches are: the flower pot and hay bale, twelve farm, garden and street props, and eighteen indoor, yard and outdoor props.

This was a test of how well the project's voxel workflow works for a new prop authored from scratch. The sources were written as a Blender script by Haiku 5.5 at the project owner's request, with no hand modelling.

- [Flower pot brief](../../art/source/world/flower-pot/v1/brief.md) · [hay bale brief](../../art/source/world/hay-bale/v1/brief.md) · [kit README and authoring script](../../art/source/world/doodads-kit/v1/README.md)
- Evidence: [flower pot, close](../../evidence/doodads-flower-pot-close.png) · [hay bale, close](../../evidence/doodads-hay-bale-close.png) · [flower pot, gameplay zoom](../../evidence/doodads-flower-pot-gameplay.png) · [hay bale, gameplay zoom](../../evidence/doodads-hay-bale-gameplay.png)

## What was made

- **Flower pot** (`flower-pot`): a stepped terracotta pot on a soil bed, a two-voxel rim with chamfered corners, a pottery band, and four plus-shaped blossoms (violet, mauve, cream, gold) on one-voxel stems with leaves. 0.6 m across, 0.45 m to the rim, about 0.9 m to the top of the flowers. 1,768 triangles.
- **Hay bale** (`hay-bale`): a square bale 0.9 m long by 0.5 m by 0.5 m with rounded long edges, straw runs along its length, three one-voxel twine wraps, a darker base, loose straws on top, one poking from the front, and a few on the grass. 1,920 triangles.

## How it was made

- `art/source/world/doodads-kit/v1/author.py` builds each model as a voxel grid in Blender. Each material becomes one object holding only its exposed faces, with flat shading and no shared faces between voxels. It is a one-time record: it refuses to run over a saved source.
- Sources: `art/source/world/<id>/v1/model.blend` with `provenance.json`. Runtime: `assets/world/<id>/model.glb` and `manifest.json`, built with `scripts/world-art.sh build <id>`.
- Shared palette colours were used for soil and leaves. Clay, petal, centre and straw colours are new and defined in the author script. They are not yet in `art/world_palette.gd`.

## Iteration

1. **First pass at 0.1 m voxels.** The pot was readable, but the blossoms were clumped and their stems hidden, and the straw noise and pale protrusions looked like stray blocks. The project owner said the blocks were too big and asked for more detail.
2. **Second pass at 0.05 m voxels** (this review). The shapes were rewritten at the finer grid, not just subdivided: a rim with a shadow band and chamfered corners, four blossoms spaced so their stems show, straw runs of varied length, one-voxel twine, and loose straws. The close captures were checked against the earlier pass.

## Assortment: twelve more props

Three agents each authored one group in parallel, using the shared helper `art/source/world/doodads-kit/v1/voxel_lib.py`. Each group has its own script (`farmyard.py`, `garden.py`, `street.py`), its own catalog fragment, and its own folders. The lead merged the fragments into `pipeline/world-catalog.json`, built each one, and reviewed them in Godot at gameplay zoom (camera ortho 13, beside the painted character). Per-group sheets are in evidence: [farmyard](../../evidence/doodads-kit-farmyard-sheet.png) · [garden](../../evidence/doodads-kit-garden-sheet.png) · [street](../../evidence/doodads-kit-street-sheet.png).

| Id | Group | Size (m) | Proposed footprint `[x, y, w, h]` |
| --- | --- | --- | --- |
| `wooden-barrel` | farmyard | about 0.5 tall, 0.45 across | `[-0.225, -0.25, 0.45, 0.5]` |
| `crate-stack` | farmyard | about 0.5 tall, 0.45 square | `[-0.225, -0.225, 0.45, 0.45]` |
| `grain-sacks` | farmyard | about 0.7 tall, 0.95 wide (reworked) | `[-0.475, -0.225, 0.95, 0.45]` |
| `woodpile` | farmyard | 0.9 long, 0.4 deep, 0.45 tall (reworked) | `[-0.45, -0.2, 0.9, 0.4]` |
| `window-planter` | garden | 0.8 long, 0.55 tall | `[-0.4, -0.15, 0.8, 0.25]` |
| `mossy-boulder` | garden | about 0.65 tall, 0.8 across | `[-0.35, -0.35, 0.7, 0.7]` |
| `tree-stump` | garden | about 0.45 tall, 0.6 across | `[-0.25, -0.25, 0.5, 0.5]` |
| `stream-reeds` | garden | about 1.0 tall, six stalks | none (stands at the water's edge) |
| `park-bench` | street | 0.9 long, 0.9 tall | `[-0.45, -0.2, 0.9, 0.4]` |
| `signpost` | street | 1.3 post, boards about 1.05 wide | `[-0.1, -0.1, 0.2, 0.2]` |
| `stone-well` | street | 0.9 across, 1.45 tall | `[-0.45, -0.45, 0.9, 0.9]` |
| `cart-wheel` | street | 1.0 across, 0.1 thick, upright | `[-0.5, -0.05, 1.0, 0.1]` |

Each folder under `art/source/world/<id>/v1/` has `model.blend`, `provenance.json` and a `brief.md`. The flower pot and hay bale briefs are the template.

## Rework: grain sacks and woodpile

- **Woodpile** was square-section logs, which read as crates. It is now round logs, 0.25 m across, lying with their cut ends to the front, in four ground logs and three nested above. The rings and bark shading read at gameplay size.
- **Grain sacks** were rebuilt twice, first with narrower and taller sacks and fewer folds, then with fuller sacks and a warmer burlap colour. They still read as a lumpy stone cluster at gameplay size. Another pass needs a different approach, not more tweaks to this profile.
- The sources were re-authored with `farmyard.py -- grain-sacks woodpile`, which takes model ids after `--` and leaves the other saved sources alone. Their briefs were rewritten. The earlier briefs were lost when the folders were removed, and the rewrites replace them.

## Batch three: eighteen indoor, yard and outdoor props

Three more agents each wrote one group script, using `voxel_lib.py`. The lead merged their fragments into the catalog, built each one, and reviewed them in Godot at camera ortho 13. Review grids: [indoor](../../evidence/doodads-batch3-indoor-grid.png) · [yard](../../evidence/doodads-batch3-yard-grid.png) · [outdoor](../../evidence/doodads-batch3-outdoor-grid.png). Indoor pieces are for interiors, which cannot be placed yet.

| Id | Group | Size (m) | Proposed footprint `[x, y, w, h]` |
| --- | --- | --- | --- |
| `wooden-chair` | indoor | 0.9 tall, 0.45 square | `[-0.225, -0.225, 0.45, 0.45]` |
| `dining-table` | indoor | 0.75 tall, 0.8 square | `[-0.4, -0.4, 0.8, 0.8]` |
| `cottage-bed` | indoor | 0.5 tall, 1.1 by 0.7 | `[-0.55, -0.35, 1.1, 0.7]` |
| `bookshelf` | indoor | 1.0 tall, 0.5 by 0.3 | `[-0.25, -0.15, 0.5, 0.3]` |
| `storage-chest` | indoor | 0.4 tall, 0.6 by 0.4 | `[-0.3, -0.2, 0.6, 0.4]` |
| `hearth-stool` | indoor | 0.45 tall, 0.35 across | `[-0.175, -0.175, 0.35, 0.35]` |
| `watering-can` | yard | about 0.35 tall | none |
| `wooden-bucket` | yard | 0.45 tall, 0.3 across | none |
| `wheelbarrow` | yard | 0.5 tall, 0.9 long | `[-0.225, -0.45, 0.45, 0.9]` |
| `clay-jug` | yard | 0.5 tall, 0.55 wide | none |
| `notice-board` | yard | 1.2 tall, 0.8 wide | `[-0.4, -0.1, 0.8, 0.2]` |
| `milk-churn` | yard | 0.8 tall, 0.5 across | `[-0.2, -0.2, 0.4, 0.4]` |
| `stepping-stones` | outdoor | 0.15 tall, 1.6 long, in gravel | none |
| `rowboat-upturned` | outdoor | 0.4 tall, 1.6 long (2.15 with oars) | `[-0.8, -0.3, 1.6, 0.6]` |
| `fallen-log` | outdoor | 0.45 tall, 1.2 long | `[-0.6, -0.2, 1.2, 0.4]` |
| `mushroom-cluster` | outdoor | 0.3 tall, 0.5 across | none |
| `market-stall` | outdoor | 1.4 tall, 1.6 wide | `[-0.75, -0.45, 1.5, 0.9]` |
| `hanging-sign` | outdoor | 1.4 tall, post 0.15 square | `[-0.075, -0.075, 0.15, 0.15]` |

Two footprints are the body, not the overhangs: the rowboat's oars and the market stall's canopy overhang them. The hanging sign's footprint is its post, since the arm and board overhang it. Its pivot is the post foot, not the bounds centre.

## Build menu

The owner then asked for every doodad to go into the build menu under a new tab. Build mode knew only buildings and trees, so doodads became a third item kind, `prop`:

- **Document and rules.** An optional `props` list in the area document holds `{id, asset, at, facing, scale}`. `AreaDef` reads it (a prop's `rect` is its catalog footprint, or a small square when it has none; `solid` marks the ones with a footprint), `LabWorld` blocks the solid ones, and `AreaBuild` gains `check_prop`, quarter-cell snapping, picking, removal and the `add`, `move` and `remove` edits. Buildings and trees now keep clear of props.
- **History.** `BuildLedger` places, moves, removes, undoes, redoes and saves props. Ids are `prop-N` and are never reused. A removal edit records its asset so the history can still say what it took away.
- **Interface.** The shelf's tabs come from the catalog, so adding a `doodads` category added the tab. Props are drawn by the same path as buildings, picked by ray, highlighted and carried like buildings, with no door arrow. Cards show "blocks the way" or "a decoration you can walk past".
- **Data.** `content/build/catalog.json` gains the Doodads category and thirty-two `prop` items, all `audience: studio`.

Captures from `tools/doodad_tour.gd`, in a window at gameplay size: [the Doodads tab](../../evidence/doodads-build-menu-tab.png), [a yard of twenty placed props](../../evidence/doodads-build-menu-yard.png) and [the delete hover on a barrel](../../evidence/doodads-build-menu-delete.png).

Behaviour to know about:

- **Indoor pieces go outdoors.** Chairs, tables, the bed, the bookshelf, the chest and the stool can only be set down in the valley, because room furniture editing does not exist yet.
- **A solid prop blocks movement; the cut-off check applies to it.** A prop without a footprint (the watering can, bucket, clay jug, mushrooms, stepping stones, reeds) is walked over.
- **Picking behind trees.** The pointer picks by ray, so a small prop behind a tall tree's pick box is hard to select until the camera is moved. Trees already behave this way.
- **Some props are small at the game's camera.** The watering can, clay jug, hearth stool and mushroom cluster are the smallest, and the watering can, clay jug and grain sacks read weakly there; see the limits below.

## Validation

- `scripts/world-art.sh build` for all thirty-two: each candidate audited and promoted (finite bounds, materials and triangle counts recorded). Triangle counts run from about 850 (grain sacks) to about 6,300 (stone well).
- Gameplay review in Godot at camera ortho 13, with the character for scale. The benches, signpost, well, cart wheel, window planter, boulder, stump, barrel and crate stack read as intended. The grain sacks and reeds are weaker; see below.
- `scripts/world-art.sh build flower-pot` and `build hay-bale`: both candidates audited and promoted (finite bounds, materials and triangle count recorded). Source hashes unchanged during export.
- Renders with `tools/asset_shot.gd` at gameplay zoom and a close framing, beside the painted character. Note that asset_shot clamps zoom to 7–24, so the "close" captures are at zoom 7 rather than tighter.
- Full `scripts/test.sh` with `VOXEL_LAB_FRESH=1`, after the build menu change: **one failure, outside the doodad work**. Every Godot suite passed: build rules (236, up from 111 with the prop rules and a catalog check per prop item), build mode (87, up from 70 with a Doodads flow through the real input path), world art (271), area (109), places and village (84), house travel (21), builder scenery (62), ground (121), interface (32), app (95), movement (30), painted art (100), frame skins (66) and authoring guards (7). The pipeline handoff test then stopped on `README.md -> pipeline/reviews/2026-10-23-village-expansion.md`: that review, which the village notes and `art/source/characters/village-v1.md` also link to, does not exist yet. It belongs to the village work and I did not write or change it.
- `test.sh` stops at the first failure, so I ran the handoff test on an in-memory copy that tolerates only that one link: 497 checks passed. The last suite, ground art, passed 121 checks when run directly.
- The build-rules checks had assumed the valley's original seven buildings. They now take that baseline from the area document, so they follow the valley as it grows. Six checks changed.
- Window review with `tools/doodad_tour.gd` at 1600 by 1000: the Doodads tab shows every card with a picture of its model, a ghost and a yard of twenty props place through the real controls, and the move and delete hovers highlight a prop with its footprint tile and name it in the bubble.
## Limits and open choices

- **On the studio shelf, not in the shipped valley.** All thirty-two are studio-only shelf items. Placing one in the shipped area document still needs an entry in a `props` list and a deliberate layout review. Offering one to villagers means setting its `audience` to `player` and giving the `player` policy a limit for kind `prop`.
- **Weaker at gameplay size.** The grain sacks still read as a lumpy stone cluster after two rework passes, so they need a different design. The stream reeds are thin, and their blades read as small teal hooks. The signpost boards and the cart-wheel spokes blur at ortho 13. In batch three, the watering can and the clay jug read as small blobs, and the mushroom cluster is small. These are open rework items, not blockers for the catalog.
- **Palette drift.** `iron_light` is defined separately in several group scripts, with slightly different hexes (`5f6c6e` in `indoor.py` and `farmyard.py`, `5a6667` in `street.py`). Pick one value in the shared palette before any of these go into the game.
- **Cream book spines** use the plaster material, so `PART` places them in the linen part rather than the books part. `PART` is per material, so the fix needs a separate material.
- **Gameplay scale.** At the gameplay camera the blossoms are small, and the gold and cream petals are close in tone. If the pot is placed, check that the flowers read at size 13.
- **Footprints are proposals.** Pot `[-0.3, -0.3, 0.6, 0.6]`, bale `[-0.45, -0.25, 0.9, 0.5]`. Blossoms and loose straws overhang them. Nothing blocks movement until a placement is made.
- **The shared "no flowers or small props" rule** in `pipeline/WORLD_ASSETS.md` and `pipeline/README.md` still applies to placed content. These two are candidate-only exceptions, made at the owner's request.
- **Voxel vs. the rest of the kit.** The existing buildings and trees are smooth-shaded. These props are flat-shaded voxel blocks on purpose. Whether to keep that look in the world is a visual call for the owner.
