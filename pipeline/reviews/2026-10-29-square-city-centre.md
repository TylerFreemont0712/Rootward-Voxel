# Rootward Square as a town centre — 2026-10-29

After the first v3 pass the user asked for:

- **Shops:** replace the three low-quality shop buildings of the old one-piece west terrace.
- **Rootwell:** make it 30–40 % bigger, with real presence.
- **Parks:** the walls between the north buildings guarded nothing, and a tree behind a gate made no sense. They should become walled grass parks.
- **Pillars:** whole glowing power pillars instead of thin gold slits down the wall pilasters.
- **Scene changes:** the whole stair width should trigger them, the apprentice should keep walking through them, the stairs should carry the power grid, and shop doors should open on the way in.
- **Design:** the square should be laid out like a real city centre: more shops and street furniture, proper bench placement and more lighting. Characters come later.

## Result

- **Shops:**
  - `square-west-terrace` is retired. In its place stand three separate shop-houses from one shopfront recipe in the seaside house kit: `haverlund-bakery` (Morning Loaf), `haverlund-greengrocer` and `haverlund-bookshop` (Finch & Sons). Each has painted joinery, gold fascia lettering, a lit display window, a striped awning, a hanging sign and its wares set out.
  - `haverlund-cafe` (the Harbour Cup) takes the corner of Lantern Row, with parasol tables.
  - A news kiosk stands at the arrival, and a coffee cart stands on the promenade.
  - The market now has two rows of stalls back to back, with their stock between them.
- **The Rootwell:** placed at 1.35 scale on a wider ring of setts (`rootwell-plaza`), with blocks scaled to match. Its inspections and lamp stands moved round it and all stay reachable.
- **Parks:** the yard walls and gates are gone. Between the bank and the guild hall, and between the hall and the post office, are two pocket parks: a lawn, a tree at the back, two benches facing each other, and low walls with a gap in front to walk in. The east garden is four lawns with a tree each either side of the path.
- **Power pillars:**
  - The carved pilasters are removed from both grounds (`pillars_revision.py`). 38 `town-power-pillar` placements stand on the square's walls and 17 on the lane surround's.
  - After the first gameplay review they still read as stone with a slit. `pillar_glow_revision.py` made each one a single glass shaft, 1.12 m across, wrapping round its sides, with slim brass rails and hoops. A new shader sends pulses of light up the column.
- **Scene changes:**
  - Room links can span several cells, each cell with its own arrival. The lane's town steps (both cells) and the square's street (all five cells) now cross.
  - With `walk_through`, the apprentice walks out under the fade, walks in on the far side, and carries on `enter` cells.
  - The workshop's street doors are split into hinged leaves. They swing open as the apprentice goes through and close behind. A room-picture plane shows beyond them, so the doorway never opens onto nothing.
  - Recorded frames: floor to lane arrives at (11,12), lane to square at (3,9), square to lane at (13,24).
- **Stairs and power:**
  - The parallel power-grid pass already runs conduits down Spindle Steps, the town steps, Hill Street and the Harbour Steps.
  - This pass adds conduits climbing the Rootwell's four flights to the drum (`art/source/world/rootwell/v1/conduits_revision.py`), and bridges across the plaza ring to the square's channels.
- **City-centre layout:** the techniques used are listed in the [square-hub README](../../art/source/world/square-hub/v1/README.md#how-the-square-is-laid-out-as-a-town-centre).
  - Active edges on every built side.
  - Eight planter-benches in pairs round the Rootwell, each facing it with planting at its back. They replace four loose benches.
  - Benches face views, paths or each other, never the middle of a walk.
  - Walks along the conduits stay clear.
  - Light at two heights: banner lamps, plus 16 low lit bollards along the walks to the hall, the promenade and the market. Festoon lights hang over the market aisle and the café front.
  - A fingerpost at the foot of Spindle Steps, two poster columns and a bicycle rack.
  - The guild hall's parvis and the paving south of the Rootwell are left open for gatherings, characters and later building.
- **New masters,** all adopted, audited and built: the four shops and sixteen pieces of street furniture (see [world assets](../WORLD_ASSETS.md#rootward-square-as-a-town-centre--2026-10-29)).
- **Inspections:** new ones for the café, kiosk, fountain, a pocket park, the fingerpost, a poster column and the coffee cart. 31 in all; the room limit for inspections is now 64.
- **Document:** 460 placements and 139 blocks. 2,654 walkable cells, all connected; all three exits and every inspection, lamp stand and the screen are reachable.

## Checks

- `test/test_square.gd`, 165 checks:
  - the new shops in place and the terrace gone;
  - every placement catalogued;
  - the Rootwell at 1.35;
  - all eight planter-benches facing it;
  - lit bollards, festoons and the fingerpost present;
  - the power pillar's glass at least a metre across with its shader;
  - the walk-through arrival continuing to (3,7);
  - the return to the lane continuing to (12,24).
- `test/test_lane.gd`, 152 checks:
  - the town steps' two cells and their own arrivals;
  - a sideways step not crossing;
  - malformed wide links refused;
  - the walk on after each change.

  It found a real fault: a non-text `doors` value crashed validation instead of being refused. It is now refused.
- `test/test_rootwell.gd`, 35 checks: the conduits climb all four flights with the grid shader. The model now measures 7.56 m across because of the conduits' 3 cm lips at the foot of each flight.
- The full `scripts/test.sh` suite passes with `VOXEL_LAB_FRESH=1`, including the world-art audit and the authoring and handoff checks.

## Not done / to tweak

- **Pillar length:** the pillars hang 14 m whatever the wall's height. Where a wall is shorter the rest is buried. At the far overview zoom one pillar end shows below the cut edge of the land under the Harbour Steps; at gameplay zoom it does not.
- **Lights by day:** festoon bulbs and bollard bands glow by their material only. There are no new real lights, to keep frame time down, so they read mainly as fittings in daylight.
- **The bicycle** stands beside the rack, not locked into a hoop.
- **No characters yet,** as asked. The coffee cart, kiosk and stalls are unattended.
- **Weight:** 930–2,160 draw calls at gameplay zoom, 130–168 fps at 1600×900 on this machine. The town overview is about 5,000 draw calls and 74 fps. It has not been measured on the user's laptop.

## Evidence

- Overview: [whole square](../../evidence/square-city-centre-2026-10-29/overview.png), review zoom.
- At gameplay zoom:
  - [the Rootwell and its seats](../../evidence/square-city-centre-2026-10-29/rootwell.png);
  - [a seating corner close up](../../evidence/square-city-centre-2026-10-29/seats-sw.png);
  - [the market](../../evidence/square-city-centre-2026-10-29/market.png);
  - [the café corner](../../evidence/square-city-centre-2026-10-29/cafe.png);
  - [the arrival and fingerpost](../../evidence/square-city-centre-2026-10-29/arrival.png);
  - [the promenade, coffee cart and pillars](../../evidence/square-city-centre-2026-10-29/promenade.png);
  - [the civic side and pocket parks](../../evidence/square-city-centre-2026-10-29/north.png);
  - [the Harbour Steps corner](../../evidence/square-city-centre-2026-10-29/harbour.png).
- Scene changes:
  - [through the workshop doors](../../evidence/square-city-centre-2026-10-29/transition-workshop-doors.png) and [down the town steps](../../evidence/square-city-centre-2026-10-29/transition-town-steps.png);
  - the doors open [on the lane](../../evidence/square-city-centre-2026-10-29/doors-open-lane.png) and [inside the workshop](../../evidence/square-city-centre-2026-10-29/doors-open-floor.png).
