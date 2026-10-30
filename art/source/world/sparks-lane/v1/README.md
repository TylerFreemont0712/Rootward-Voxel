# Spindle Lane source pack

The street outside Nell's workshop, after the selected [T7c workshop lane](../../../../../docs/concept/v0.7/art/4-opening/T7c-workshop-lane.wheels.png) and [P1 street props](../../../../../docs/concept/v0.7/art/4-opening/P1-street-props.png). It is the first outdoor scene of Sparks & Machines: one 24×28 terrace above the town, reached through the workshop's green street doors, with a painted harbour behind it.

Twenty new editable Blender masters:

| Master | What it is |
|---|---|
| `haverlund-lane-set` | The scene itself, in area coordinates: the cobbled lane and flagged pavements on level 1, the tram halt a level below, the limestone retaining wall with ivy, a brass spout and the SPINDLE LANE plate, four-tread halt steps, the tram cutting with its tall round arch in a solid hillside, the track, buffer stop and the overhead wire on scrolled posts, the balustrade and the shut iron gate at the head of 212 steps, Bram's white picket fence and garden, three telegraph poles with insulators and their wires, the green with its raised tree bed, an allotment, hedges, pots, chalk squares, a coir mat, a hanging basket and Pepper asleep on the east wall. |
| `lane-workshop` | Nell's workshop from the street, matching its rooms: a plastered workshop floor with heavy framing over a limestone plinth, the green doors a third of the way from the south corner under a glazed transom, the shop window over a panelled stall riser, the gear sign; the loft as a jettied, close-studded upper floor with shuttered windows and the round window in its south gable; a clay roof with its ridge north–south, a chimney, a woodshed, a chopping block and a water butt. |
| `lane-nell-house` | The landlady's house next door: dressed stone, gable to the lane, a plum panelled door under a stone hood with a fanlight and a brass hand knocker, teal shutters, lavender in the window boxes, a climbing rose and a stone chimney. Its south wall is the workshop's party wall. |
| `lane-cottage` | Bram's salmon plaster cottage: limestone quoins, green shutters and door, a striped awning, an oculus, milk bottles and the paper on the step. |
| `lane-lamp` | The street lamp: a lantern on an iron post over a limestone pedestal. Its glass is a separate mesh with the material `lamp_glass`; the gate lamp is a room lamp fixture that the game lights. |
| `lane-post-box`, `lane-notice-board`, `lane-bench`, `lane-telescope`, `lane-bicycle`, `lane-crates`, `lane-planter`, `lane-handcart`, `lane-pump`, `lane-shed` | Street furniture and the neighbours' things. The crates are the workshop's scrap waiting for collection; the pump stands over a hollow stone trough. |
| `lane-laundry` | A washing line whose five cloths are separate objects `cloth_0`…`cloth_4` with their origins on the line; the game sways them. |
| `lane-tram-shelter` | The halt's tiled shelter with its bench, a lantern, pots, the enamel stop disc and the framed timetable. |
| `lane-tram` | Hill tram No. 7, along +X with its headlamp at the buffer end: two sprung four-wheeled trucks on the lane's 1.1 gauge, lifeguard trays, a panelled teal and cream body lined in gold with HAVERLUND TRAMWAYS, windows with drop-lights, a clerestory, destination boxes, folding platform doors and a trolley pole whose shoe meets the wire at 3.75. The game drives its round trip. |
| `lane-tree`, `lane-cypress` | A blossom tree (a flared trunk in the project's bark picture, forking boughs and twigs, a lumpy crown lit lighter on top, clustered blossom, fallen petals) and a cypress (bark trunk, layered feathery tufts), presentation only. |

## Records

- `lane_kit.py`: the shared palette, painted surfaces and helpers: batched bevelled blocks with cube-projected UVs, stone courses, clay roofs with their ridge along either axis, wall slabs with real openings (`wall`), panes that carry one whole picture (`pane`, `disc_pane`), windows set into those openings, lettering converted to mesh, wires. It reuses the loft pack's primitives.
- `textures.py`: paints `lane-cobbles.png`, `lane-flags.png`, `lane-ashlar.png` and the glass pictures `lane-glass.png` (sky and drawn curtains), `lane-glass-shop.png` (a warm room of shelves) and `lane-glass-tram.png` (seat backs), and tints the loft's `cream-plaster.png` into `salmon-plaster.png` (seamless, deterministic numpy). `lane-grass-lush.png` is the project's own lush grass, `assets/world/textures/lush/grass.png`, at its density of 32 art pixels per cell, laid out over eight cells through a slow wrapped warp with the ground's light and dark grass tints, so it does not repeat. `lane-grass.png` is the first pass's painted grass, kept as a record and no longer used. The script refuses to repaint an existing picture.
- `author_set.py`, `author_buildings.py`, `author_props.py`: guarded one-time authoring. Each refuses an existing master.
- `backdrop/`: the harbour backdrop's composite, the two img2img passes and their [prompts and hashes](backdrop/prompts.json).

While the layout was being settled on 2026-10-28, before adoption, the unadopted masters were regenerated from these records: first while it was built, then once more for the second pass after the user's first play-through (the workshop rebuilt to match its rooms, Nell's house, real window openings, the borrowed grass, the wider halt and the detailed tram). From adoption onward each `model.blend` is the editable authority: open it, edit it, and export with `scripts/world-art.sh build <id>`. Never regenerate an adopted master.

`content/areas/haverlund-lane.json` owns every placement, blocking footprint, level, stair, link, inspection, the street's light and backdrop (`interior.outdoor`) and its small motions (`interior.life`: three chimneys' smoke, the swaying washing, the tram's timetable, three gulls). Static meshes never decide traversal.

The [Spindle Lane review](../../../../../pipeline/reviews/2026-10-28-spindle-lane.md) links the gameplay captures.
