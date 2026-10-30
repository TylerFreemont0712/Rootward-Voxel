# Rootward Square source pack

Haverlund’s next walkable area down the hill from Spindle Lane. The selected [day square](../../../../../docs/concept/v0.7/art/5-town/T3-rootward-square-day.wheels.png) and [Rootwell sheet](../../../../../docs/concept/v0.7/art/5-town/T5-rootwell-sheet.png) guide its low centrepiece, blue civic roof, plaster shopfronts, brass paving and everyday street furniture. It shares the lane’s packed paintings and fine sepia outlines. No generated image or external service is needed to play.

| Editable master | Contents |
|---|---|
| `haverlund-square-set` | Cobble square and flagged shop apron; soil and limestone cut edges; harbour garden and rail; two four-tread hill flights and a landing; stone cheeks following the steps; rain channels and open grates; brass branches and circular setts; service poles with supported wires; rear wall and scattered flowers. Authored in area coordinates. |
| `square-rootwell` | Low circular limestone steps, brass rim, teal inner collar, transparent glass bell, curling live root, amber heart, oversized low-reading dial, four connected valve wheels, fine glass highlights. |
| `square-town-hall` | Cream plaster and timber framing, blue tiled roof, clock tower, glazed windows in real openings, double doors, front steps and flower boxes. Exterior only. |
| `square-bakery` | Ochre Morning Loaf shop with bread trays, striped awning and chimney. |
| `square-bookshop` | Salmon Finch & Sons shop with books in outside trays and a rose-striped awning. |
| `square-grocer` | Pale blue shop with fruit trays and a green-striped awning. |
| `square-market-stall` | Cloth canopy supported by four poles, counter, produce bins, storage crates and hanging scales. |
| `square-cafe-table` | Round wooden table, two iron chairs, open cup with tea below its rim, saucer and marked newspaper. |
| `square-delivery-robot` | Squat cream-and-teal postal worker on two wheels, brass-rimmed spark window, parcel basket. Static scenery in this slice. |
| `square-node` | Freestanding enamel service screen with real `terminal_screen`, brass socket and `connection_lamp`. Same slate connection contract as the workshop. |

The area reuses the lane’s adopted benches, planters, trees, cypress, lamps, notice board, handcart, bicycle, pump, post box and Hotaru. Their masters are preserved.

`author.py` refuses existing masters. `author_initial_set.py` preserves the exact first-set record before its shared disc helper was corrected; its hash is pinned in the set’s provenance. After initial authorship, each individual `model.blend` is the authority. Subsequent deliberate edits retain backups and hash records:

- `roof_gables_revision.py`: align the hall and shop gables with their actual roof ridges.
- `stair_cheeks_revision.py`: replace over-high plain stair walls with coursed stone that follows the flights.
- `rootwell_glass_revision.py`: warmer amber, legible glass silhouette and finer reflections, inner root curl.
- `open_lane_gate.py`: swing open the adopted lane’s two iron gate leaves; its previous master remains `model.pre-square-gate.blend`.

Build a selected source with `scripts/world-art.sh build <id>`, then import in Godot. Builds audit the GLB and verify that export has not changed the source. Never rerun a maker over an adopted master.

**Superseded 2026-10-29.** The square was rebuilt after the Guildhall Square concept from the [v2 source pack](../v2/README.md). Of these masters, `square-node`, `square-cafe-table`, `square-market-stall` and `square-delivery-robot` are still placed; `haverlund-square-set`, `square-rootwell`, `square-town-hall`, `square-bakery`, `square-bookshop` and `square-grocer` are kept as `retained_previous_concept`. The first square's document is archived at `content/areas/archive/haverlund-square-v1.json`.

`content/areas/haverlund-square.json` owns placements, collision, levels, stairs, inspections, lamps, terminal and reciprocal travel. The meshes do not grant traversal or programming scope. The [review](../../../../../pipeline/reviews/2026-10-29-stairs-and-square.md) records visible results and limitations.
