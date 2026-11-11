# Field tablet, wall screen and room touch-ups — 2026-10-27

Sparks & Machines now moves from "a terminal in every room" toward "a terminal in the first room, then something you carry". The loft keeps its desk computer for the first greeting. After it, Hotaru sends the traveller to **Nell’s field tablet**, a slate lying on the quilt with a cord and a brass plug. The workshop’s zone node is no longer a second computer: it is a **wall screen** with a brass-collared socket, and it only accepts the tablet.

## What changed

**The tablet is an item, not a menu.** `core/player_items.gd` owns the rule: an area’s top-level `pickups` entry names a known item, the placed object that shows it and the cell to stand on. `state.items` carries it through Undo, Reset, Continue and both rooms (`_share_journey_progress` merges it between floors); a program cannot take or claim one. A save from before items existed that had already greeted Hotaru is handed the tablet. In the world the slate is part of the bed from the first moment, but it becomes a pickup only after Hotaru’s waking conversation has told the traveller to pick it up. Until then the stairs are open and the tablet is scenery. Afterwards the stairs wait with the line "Nell’s slate is still on the bed." Lifting it plays a short lift animation and a four-page scene.

**The wall screen needs it.** A terminal in an area document may now name `requires` (an item), `prompt` (the F label), `idle` (the glass before a link) and `locked` (what it says without the item). `ZoneTerminals.connect_at` refuses a traveller who does not carry the required item, and a returned command still needs the saved link, as before. The workshop terminal keeps its id, so existing links stay. `ZoneTerminalDisplay` now lays its lettering on whichever model’s `terminal_screen` glass the area names; the desk computer and the wall screen share it. `ZoneConnectionPanel` calls such a terminal an **area node** and says to plug the tablet in.

**Dialogue.** The waking scene’s old hand-console ending is replaced by the slate on the quilt (a measurement, "the board by the bed", a flat joke about it not moving all night); the pickup scene follows the [dialogue rules](../../docs/concept/v0.7/07-dialogue.md): no button names, no moral, Nell’s way of handing things over. Nell’s note loses its post-script about the hand console. The scene narrator now says "The loft" in the loft, and loft scenes close with "Back to the loft". Saved story-log tokens for page 3 of the waking scene still point at the work-ticket line.

**Art.** All masters are editable Blender sources with guarded edit records.

| Asset | Change | Record |
|---|---|---|
| `field-tablet` (new) | Cream enamel slate, teal glass, brass corner caps, a coiled grey cord and a brass plug. Lies on the quilt. | [`field_tablet.py`](../../art/source/world/sparks-loft/v1/field_tablet.py) |
| `workshop-wall-screen` (new) | Teal plate, cream enamel housing, long glass named `terminal_screen`, jack panel with a brass-collared socket, two dials, a `connection_lamp`, a conduit rising to the ceiling. West wall, beside the corner. | [`wall_screen.py`](../../art/source/world/sparks-workshop/v1/wall_screen.py) |
| `workshop-tool-wall` | The rows of looped, unrecognisable hangers are gone. A rack of four graduated open-end spanners with the third missing (it is the one on the bench, and its place is marked by a chalk outline), a claw hammer resting on its pegs, two screwdrivers in a holder. The shelf and plants are unchanged. | [`tool_wall_and_mug.py`](../../art/source/world/sparks-workshop/v1/tool_wall_and_mug.py) |
| `workshop-tea-table` | The mug held a flat dark disc standing for tea. It is a hollow white mug. | same record |
| `loft-desk` | The desk mug had the same flat lid. It is hollow too. | [`desk_mug.py`](../../art/source/world/sparks-loft/v1/desk_mug.py) |

The wall screen sits on the west wall, between the corner post and the tool board, with its approach at cell (1, 2). The old computer on the long bench and the hand console are no longer placed; their masters and exports remain.

## Zoom

The wheel used to add 0.75 to the global **Camera zoom** setting. In a room with its own zoom (loft 12.5, workshop 15.5) the first notch jumped to wherever the setting was, usually zooming in from the room’s view when scrolling out, and the same setting was rewritten for the next room. A high-resolution wheel or touchpad, which sends many small events, moved the view far too quickly. In a room that authors `interior.zoom`, the wheel now multiplies the zoom by an even 0.92 per notch from where the view already is, scales a fine wheel’s step by the fraction it reports, understands a pinch, never rewrites the setting, and remembers the player’s choice across both rooms for the session within 0.55× to 1.4× of each room’s own zoom. Kindle Hollow, Village Morning and their houses are unchanged. The Camera zoom slider still drives outdoor views and no longer overrides a room.

## The rug shadow

At game zoom the workshop rug was clean, but zoomed out its weave showed a hatched dark kite and slivers. Toggling shadow casting piece by piece showed two causes working together: the rug cast shadow onto itself, and its lower layers sat level with the herringbone plank tops. Removing the rug’s shadow casting (a catalog flag, `casts_shadow: false`, applied by `WorldAssets.instantiate`) and lifting the two workshop rugs 0.02 in the area document removed the pattern at zoom 13, 20 and 24, and the rug’s fringe now shows. Raising the shadow bias or the normal bias, or shortening the shadow distance, did not remove it. The loft rug did not show the artefact and is unchanged. The player is still held above the rug.

## Reviewed

Native captures at the actual camera scale, in `evidence/sparks-workshop/tablet-and-wall-screen/`:

| View | 1600×1000 | 1280×720 |
|---|---|---|
| The slate lying on the bed at the start | [Loft](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/03-loft-before-note.png) | [Loft](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/03-loft-before-note.png) |
| Standing at the bed after Hotaru’s cue: the F badge on the slate | [Offered](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/08-tablet-offered.png) | [Offered](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/08-tablet-offered.png) |
| Hotaru’s question about the quilt | [Choices](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/11-waking-choices.png) | [Choices](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/11-waking-choices.png) |
| The scene after lifting it | [Scene](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/08b-tablet-scene.png) | [Scene](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/08b-tablet-scene.png) |
| The workshop’s area-node card | [Card](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/03b-zone-connection.png) | [Card](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/03b-zone-connection.png) |
| Connected: the lantern test beside Field Notes | [Connected](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/03c-connected-terminal.png) | [Connected](../../evidence/sparks-workshop/tablet-and-wall-screen/1280/03c-connected-terminal.png) |

1600×1000 close views: [tool wall](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/20-tool-wall.png), [wall screen](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/21-wall-screen.png), [empty mug](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/22-empty-mug.png), the rug [before](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/23-rug-before-zoom-7-13-20-24.png) and [after](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/24-rug-after-zoom-13-20-24.png), and the [workshop zoomed out](../../evidence/sparks-workshop/tablet-and-wall-screen/1600/25-workshop-zoomed-out.png).

Not built, and said so in the docs: a visible carried-items display and any use of the tablet outside the workshop. Its uses are the wall screen and, added in the [reach and markers revision](2026-10-27-reach-and-markers.md), working on a single lamp from beside it.

Checks: the complete `scripts/test.sh` passed. Focused suites grew as follows: Sparks journey 103 → 127 (the tablet from bed to carried, the stairs wait, legacy saves, Reset, wheel steps and limits, a pinch, click-to-pickup), zone terminals 25 → 46 (carried-item rule, pickup authoring defects, requirement refused and explained), area documents 151 → 152, workshop quests 74 → 75, world art 673 → 681 and handoff links 1130 → 1140.
