# Rootward Square v3: the town's hub

The square rebuilt from scratch as the central hub of Haverlund, and the town round Spindle Lane so the lane no longer floats. The square is everything placed on top of one base ground model, never one big set. Each building, railing bay, pier, lamp, prop and background house is its own model, placed by `content/areas/haverlund-square.json`, so any of them can later be moved, replaced or built over.

## Layout (72 × 64 cells; the old square was 36 × 32)

- **South-west, the arrival:** the street down from Spindle Lane, two flights from level 2. Its whole five-cell width is the way back up. A café corner sits below it.
- **North-west, Hill Street:** open, climbing out of the north edge for a later area. The bank stands on its corner.
- **North-east, Lantern Row:** open, leaving the east edge along the hillside.
- **South-east, the Harbour Steps:** open, three flights between parapets down to the lower town.
- **West side:** three separate shop-houses (Morning Loaf, the greengrocer, Finch & Sons) and the fruit market hall, with the hill and its houses behind them.
- **North side:** the bank, the guild hall, the post office and the Harbour Cup café on the corner. Between the bank and the hall, and between the hall and the post office, are two small walled grass parks.
- **Middle:** the Rootwell, placed 35 % larger than its model, on a wider ring of setts. Conduit bridges join its steps to the square's channels.
- **Elsewhere:** the market lies between the shops and the Rootwell. There is a lawned garden on the east and the building yard in the south-east.
- **South and east edges:** stone balustrades over the lower town, 10 m down. Their glowing power pillars hang down the walls.

2,654 walkable cells, all connected. The Rootwell's inspections, lamps and the service screen keep their ids, now round the larger Rootwell.

## How the square is laid out as a town centre

The layout follows the habits of real public squares, not an even scatter of props:

- **Active edges.** Shops, the market hall, the café and the civic buildings face the square on every side that has buildings. The shop wares, the market stalls and the café tables spill out in front of them, where people walk.
- **Seats with something behind them, facing something worth watching.**
  - Eight planter-benches stand in pairs round the Rootwell, 12.4 m out, each facing it.
  - Promenade and overlook benches face the view, their backs to the square.
  - Garden and park benches face their paths or each other.
  - No bench stands loose in the middle of a walk.
- **Clear desire lines.** The conduits run from the Rootwell to the four ways out, the market and the civic doors. Seats and stalls stand beside them, never across them.
- **Light at two heights.** Banner lamps ring the Rootwell and line the edges. Low lit bollards mark the walks to the guild hall, the promenade and the market. Festoon lights hang along the market aisle and the café front.
- **Wayfinding.** A fingerpost at the foot of Spindle Steps points to Hill Street, Lantern Row, the Harbour Steps and back up to the lane. Poster columns stand at the arrival side and by Lantern Row.
- **Small trade.** A news kiosk at the arrival, a coffee cart on the promenade by the benches, and two rows of market stalls back to back with their stock between them.
- **Room left open.** The parvis in front of the guild hall and the paving south of the Rootwell stay clear, for gatherings, characters and later building.

## Records

| File | What it does |
|---|---|
| `plan.py` | The layout as plain data: cells, levels and stairs, buildings and their blocks, dressing, railing runs, background houses, trees, zones, lamps and inspections. A dressing block is one half-size `(hx, hy)` or several `(dx, dy, hx, hy)`, such as a festoon's two posts. |
| `author_area.py` | Writes the area document from the plan. It expands each railing run into bays with one pier or post at every joint. The document is the master once written; regenerate only with `--force` while the plan is still the working record. Version 2 is archived as `content/areas/archive/haverlund-square-v2.json`. |
| `author_ground.py` | The base ground `haverlund-square-ground`: paving, levels, dressed retaining walls with copings, kerbs, stairs, the Harbour Steps' parapets, the Rootwell's setts and the town's land past every edge. |
| `author_pieces.py` | The modular edge pieces: `town-balustrade` (3 m and 1.5 m), `town-balustrade-pier`, `town-railing` (2 m and 1 m), `town-railing-stair` (one stair cell, raked), `town-railing-post`, `town-garden-wall` (3 m and 1.5 m), `town-garden-pier` and `town-garden-gate`. |
| `author_buildings.py` | `haverlund-post-office`, `haverlund-fruit-market` and `haverlund-bank` (Haverlund Savings). |
| `author_shops.py` | The shop-houses that replaced the one-piece west terrace: `haverlund-bakery` (Morning Loaf), `haverlund-greengrocer`, `haverlund-bookshop` (Finch & Sons) and `haverlund-cafe` (the Harbour Cup). |
| `author_street.py` | The first street furniture: `town-power-pillar`, `rootwell-plaza`, `town-kiosk`, `town-fountain`, `town-bollard`, `town-bin`, `town-parasol-table`, `town-lawn` and `town-tree-grate`. |
| `author_square_life.py` | The second set: `town-festoon`, `town-signpost`, `town-planter-bench`, `town-bollard-light`, `town-poster-column`, `town-coffee-cart` and `town-bike-rack`. |
| `pillars_revision.py`, `pillar_glow_revision.py` | Source edits for the power pillars. The first removed the carved pilasters from the square and lane-surround grounds; their positions are in `pillars-*.json` and the area documents place `town-power-pillar` there. The second made each pillar one full-width glass column. |
| `door_leaves_revision.py` | Splits the workshop's street doors (`lane-workshop`, `workshop-shop-doors`) into hinged leaves the game swings open. |
| `lane_pillars.py` | Places the lane's 17 power pillars from `pillars-haverlund-lane-surround.json`. |
| `lane_plan.py`, `author_lane_ground.py`, `dress_lane.py` | The town round Spindle Lane: the ground model `haverlund-lane-surround` (built with the same drawing tools; it never draws the lane set's own cells), the background houses and trees, and a balustrade along the tram bed's drop. The lane document is version 4, with v3 archived. |

Each Blender authoring record refuses to overwrite an adopted master and takes `-- --draft DIR` for review drafts. Each revision record refuses to run twice and keeps the file it changed as `model.pre-*.blend`. After adoption, each `model.blend` is the editable authority; build with `scripts/world-art.sh build <id>`. The Rootwell's step conduits are recorded beside it in `art/source/world/rootwell/v1/conduits_revision.py`.

## Railings and walls

Railings only stand where there is a drop or an open edge:
- the arrival street's south side, as level, raked and level runs;
- the hill's coping where it overlooks the street and the gaps between buildings;
- Hill Street's open side.

Balustrades run along the square's south and east edges over the lower town. Low garden walls enclose the two pocket parks, each with a gap in its front wall to walk in.

Every run has exactly one pier or post at each bay joint and run end, so nothing doubles up at a corner. A raked railing rises one cell over one stair cell, its handrail following the nosing line. Bays are scaled by at most a few per cent to fit their run.

## Background

- **Square:** 56 background houses (the five modular seaside houses, each with its own look) and 16 trees round it. Seven more trees stand inside the square: one in a grate, four in the garden and one in each park.
- **Lane:** 31 houses and 10 trees.
- Houses only glimpsed are placed with `look: {seed, plain: true}`, which hides their dressing.
- Houses toward the camera stand on the lower town 8–10 m down, set back so their roofs stay below the line of sight to anything walkable.

See the [first review](../../../../../pipeline/reviews/2026-10-29-square-hub-v3.md) and the [city-centre pass](../../../../../pipeline/reviews/2026-10-29-square-city-centre.md).

## Later revisions (2026-10-30)

Deliberate, backed-up edits of adopted models, each starting from its own `model.pre-*.blend`:

- `doorway_dark_revision.py -- <id>`: removes the workshop's inside-door picture quad (`workshop-shop-doors`) and makes the lane's (`lane-workshop`) flat black.
- `coplanar_revision.py -- <id> [<id> ...]`: lifts layers that shared a plane with what they sat on (the fountain's water; stone, timber, shutter and paint on eleven building models) by a few millimetres so they stop flickering. Rerunning starts from `model.pre-coplanar.blend`. `test/test_coplanar.gd` keeps it so.

See the [review](../../../../../pipeline/reviews/2026-10-30-doorways-transitions-and-flicker.md).
