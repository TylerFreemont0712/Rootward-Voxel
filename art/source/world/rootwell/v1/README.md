# The Rootwell

The town's central power beacon and the headpiece of Guildhall Square, modelled after the approved [Rootwell paintings](../../../../../docs/concept/v0.72/rootwell-beacon.md) (front and rear three-quarter). The editable master is [`rootwell-beacon/v1/model.blend`](../../rootwell-beacon/v1/model.blend); the game loads `assets/world/rootwell-beacon/model.glb`. It is catalogued `showcase_only`: the playable square still shows the older `square-beacon` until the square layout pass places this one.

## What is there

- **Base:** three shallow octagonal steps and a terrace of dressed limestone blocks, each block mitred at the corners and painted with a whole block from the seaside limestone picture. A few grass tufts sit in the step corners.
- **Drum:** a proud plinth course, six courses of ashlar, a moulded lip and top paving. Ivy hangs over the lip at the four corners seen front and back, and flowers grow in soil pockets at every corner.
- **South-east (public face, toward the game camera):** a teal riveted panel framed in brass, holding a 1 m pressure gauge.
  - The gauge has an enamel face, ticks, numerals 0–10, a red low band and PRESSURE.
  - The needle sits just past the first mark. A bright scratch on the bezel near 6.4 marks where it used to rest.
  - A brass ROOTWELL plaque sits above the gauge.
  - Below it, a brass manifold sends a brass main and two iron pipes down the steps to capped stubs at the ground.
- **South:** a notice board under a tiled hood, carrying a tide table, a Thursday guild meeting notice and LOST: ADMIRAL with a drawing of the tortoise. In front stands a slatted bench with scrolled brass ends.
- **East:** a teal plank maintenance door under a tiled hood, with brass strap hinges, a ring and a polished keyhole. BACK AT 4 is chalked on the paving in front.
- **North-west (service face):**
  - A louvred vent plate in a recess between two copper risers, each riser with a valve wheel.
  - A relief valve on one riser, and two capped stubs at the foot.
- **Terrace:** stone planters with clipped trees either side of the gauge; timber planters elsewhere, two with tall evergreens.
- **Chamber:**
  - A teal riveted base band with brass rings and four pipes out to valve stands with handwheels.
  - Bowed amber glass with brass retainers and glazing ribs.
  - The living root: a four-strand twisted trunk, roots over the floor into the throat, and five boughs forking to fine twigs.
- **Crown:**
  - Eight teal columns with brass bases, collars and capitals, joined by tie rings, with a lantern on each side.
  - A brass entablature with a riveted teal band and brass balls.
  - A ribbed verdigris dome, and a studded cupola with a flared cap and two finials.

## Parts for later story

These are their own nodes, each with its origin on its own axis (Godot axes):

| Node | Moves by |
|---|---|
| `gauge_needle` | turning about its local Z; −27° per unit of pressure; authored at 1.3 |
| `maintenance_door` | swinging about its local Y; the origin is on the hinge line at the threshold |
| `valve_wheel_e`, `_n`, `_w`, `_s` | spinning about their vertical axles on the drum top |
| `valve_wheel_service_w`, `_n` | spinning about the axles facing out of the service face |
| `root` | the living root (lit, so it keeps its drawn outline) |
| `root_light` | the chamber's light: an inward-facing shell just inside the glass. Only its far half draws, so the root always stands against it, as in the paintings |

The bell glass is `rootwell_bell_glass`, translucent amber and double-sided. The lantern glass keeps the project's `lamp_glass` contract. No part grants a capability: placements, collision and interactions belong to the area document.

## Records

- `author_rootwell.py` is the guarded one-time authoring record. It refuses an existing master; `-- --draft DIR` writes a review draft outside `art/source`. It uses the [seaside house kit](../../seaside-houses/v1/README.md) for stone, tiles, timber, boards, plain colours and hoods.
- `verdigris.png` is written by the record. It recolours the library's copper-patina painting (`textures/v2-detail/native/copper_patina.png`) to the paintings' teal at 512 pixels, keeping its mottle.
- `light-gradient.png` is also written by the record: the chamber light from amber at the throat to near-white behind the trunk to gold under the crown.
- `provenance.json` beside the master records the concept and texture hashes.

## Size

7.5 m across the steps' flats and 8.1 m across their corners; 9.5 m to the finial. The drum is 4 m across, the glass bell 2.6 m across at its widest. 123,571 triangles in 21 meshes.

See the [review](../../../../../pipeline/reviews/2026-10-29-rootwell-headpiece.md).
