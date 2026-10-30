# Rootward Square v3, the hub, and the town round Spindle Lane — 2026-10-29

The user asked to rebuild the square from scratch as the central hub of the city, where many quests will gather. The requirements:

- **Layout:** the apprentice comes down from the south-west, and open spaces lead north-east, south-east and north-west to later areas.
- **Background:** background houses make the town large, and both the square and Spindle Lane stop looking like floating islands.
- **Buildings:** a new fruit market and post office, plus one more building that makes sense (a bank was chosen over a clock tower, because the guild hall already carries the square's clock). The new Rootwell is used.
- **Size:** much bigger. Mid-pass the user asked about the 96-cell limit and to make the area bigger still.
- **Structure:** modular rather than one giant site: the main ground first, with buildings and things placed on top, ready for building through code later.
- **Railings:** natural ones.

## Result

- **`haverlund-square` version 3, 72 × 64** (the old one was 36 × 32), with 2,806 walkable cells, all connected. The full layout and records are in the [square-hub pack](../../art/source/world/square-hub/v1/README.md); version 2 is archived.
- **Modular:** the area document stands every piece on the base ground `haverlund-square-ground`: buildings, lamps, props, robots, 93 railing and wall pieces, 56 background houses and 18 trees. 324 placements in all.
  - The ground carries land only: paving, levels, dressed retaining walls with copings and pilasters, kerbs, stairs, the Harbour Steps' parapets, and the Rootwell's setts and brass channels.
  - Moving or replacing any building or railing is a one-line document edit. Nothing about the layout is baked into a mesh.
- **New buildings,** each its own model in the house kit's materials:
  - `haverlund-post-office`: two storeys and an attic. Red doors under a fanlight, striped counter awnings, a gold POST OFFICE fascia, an enamel envelope sign on a bracket, a balcony, a parcel bench and an envelope weathervane.
  - `haverlund-fruit-market`: an open hall on green cast-iron columns under a FRUIT MARKET board and striped awnings, with arched gable ends, tiered stalls of fruit, a hanging scale and a chalkboard reading PEACHES TOMORROW, probably.
  - `haverlund-bank` (Haverlund Savings): rusticated ashlar and barred arched windows, a pediment on two columns over panelled doors, pilasters, dentils, a roof balustrade and a copper-domed lantern.
- **Exits:**
  - **Hill Street** climbs out of the north edge, with its own flight and a railing on its open side.
  - **Lantern Row** leaves the east edge along the hillside, with its front gardens' walls and gates.
  - **The Harbour Steps** go down three flights between stone parapets to the lower town.
  - Each has a discovery zone.
- **Railings:**
  - Railings only where there is a drop or an open edge: the arrival street's open side as a level, raked and level run following the flights; the hill's coping where it overlooks the street and the gaps between buildings; and Hill Street's open side.
  - Stone balustrades on the south and east edges over the lower town.
  - Garden walls with gates closing the yards between the north buildings.
  - Every joint has exactly one pier or post, so nothing doubles up at a corner. A raked bay rises one cell over one stair cell, its handrail on the nosing line.
- **Spindle Lane** (document version 4) now stands in the same town:
  - `haverlund-lane-surround` covers the set's cut faces with dressed walls down to a lower town, a back lane and the hill behind the workshop row, and the town steps continuing north. It never draws the lane's own cells.
  - 31 houses and 10 trees stand round it, and a stone balustrade runs along the tram bed's drop.
  - The town steps now arrive at the square's new street (1, 8).
- **Background houses:**
  - Each house has its own look (seed or curated palette). Houses that are only glimpsed are `plain`, with no dressing.
  - Those toward the camera stand 8–10 m down and set back, so their roofs stay below the line of sight to anything walkable.
- **Kept:**
  - The beacon inspections (now on the Rootwell's real faces), the shop, stall and robot inspections, the three lamps, the service screen and scratch page, Pip's, Trowel's and the porter's rounds, banners, smoke and gulls.
  - New inspections: the fruit market and the bank.
  - Retired models stay in the catalog as `retained_previous_concept`.
- **Limits raised:**
  - Area side: 96 → 160 cells. 96 was a guard written into `AreaDef`, with no engine reason behind it.
  - Model envelope: ±64 → ±128 units, a self-imposed audit bound in `world_art.gd`.
  - Room assets may carry a `look`; `AreaDef` checks its shape and `HouseVariants.look` presents it.

## Not done / to tweak

- **Exits** end at the area edge; nothing beyond them is walkable yet.
- **Building interiors:** none are enterable.
- **Building through code** is planned for later. The separation into pieces is ready for it; no player API places or moves them yet.
- **Paths** were not written for the new robot rounds; Pip, Trowel and the porter got simple paths.
- **Story text** still calls it "the beacon in the middle"; the dialogue was not revised.
- **Weight:** about 1,700 draw calls at gameplay zoom, 120–165 fps at 1600×1000 on this machine. The town overview is about 5,200 draw calls and 62 fps. It has not been measured on the user's laptop.
- **Mesh rules:** the square's ground mesh does not decide walking. The cells and blocks in the document do.

## Evidence

- [Square overview](../../evidence/square-hub/2026-10-29/square-overview.png) and [Spindle Lane overview](../../evidence/square-hub/2026-10-29/lane-overview.png) (review zoom)
- Square at gameplay zoom:
  - [arrival street](../../evidence/square-hub/2026-10-29/square-arrival.png)
  - [Rootwell](../../evidence/square-hub/2026-10-29/square-rootwell.png)
  - [market](../../evidence/square-hub/2026-10-29/square-market.png)
  - [north buildings](../../evidence/square-hub/2026-10-29/square-north.png)
  - [Hill Street](../../evidence/square-hub/2026-10-29/square-nw-hill-street.png)
  - [Lantern Row](../../evidence/square-hub/2026-10-29/square-ne-lantern-row.png)
  - [Harbour Steps](../../evidence/square-hub/2026-10-29/square-se-harbour-steps.png)
- [Spindle Lane's tram edge](../../evidence/square-hub/2026-10-29/lane-tram-edge.png)
- The new buildings: [post office](../../evidence/square-hub/2026-10-29/haverlund-post-office.png), [fruit market](../../evidence/square-hub/2026-10-29/haverlund-fruit-market.png), [bank](../../evidence/square-hub/2026-10-29/haverlund-bank.png)

## Validation

- `scripts/world-art.sh build` passed for every new master. Triangles:

  | Master | Triangles |
  |---|---|
  | Square ground | 142,340 |
  | Lane surround | 76,612 |
  | Post office | 29,385 |
  | Fruit market | 70,655 |
  | Bank | 42,152 |
  | Edge pieces | 160–1,904 each |

  Headless import passed.
- `test/test_square.gd` (rewritten for v3): **137 checks passed**. They cover:
  - the walkable graph and the three exits;
  - real travel from the lane;
  - descending both flights;
  - robot rounds clear of every block;
  - houses beyond all four edges;
  - the ground reaching past every edge;
  - the screen's scope, WASI preview/Apply and Continue;
  - the walk back to the lane.
- `test/test_lane.gd`: 146 checks passed. `test/test_rootwell.gd`: 33 passed, now expecting the Rootwell in the square only.
- Full `scripts/test.sh` (with `VOXEL_LAB_FRESH=1`) **passed, exit 0**. Log: `.cache/square-hub/full-test.log`.
- Fixed during review:
  - Awnings floated twice their height (a kit bug).
  - The market board was hidden by its eave.
  - Houses overlapped the bank and post office.
  - A chimney's smoke was above the allowed height.
  - Grass and flag ground made a chequerboard; it now uses organic garden patches.

No commit was made.
