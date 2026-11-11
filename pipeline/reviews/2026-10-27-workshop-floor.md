# Connected workshop and furniture review — 2026-10-27

The downstairs room is playable from the Sparks loft. It follows the selected [T7b workshop](../../docs/concept/v0.7/art/4-opening/T7b-workshop-floor.png) and [P3 props](../../docs/concept/v0.7/art/4-opening/P3-workshop-props.png): honey herringbone parquet, timber and plaster walls, repair bench and tools, parts drawers, central assembly table, full stairs, stove, plaid armchair, tea, a single job ticket and green street doors. Twenty new editable Blender masters make twenty-six placements with the existing tape reader, robot and harbour picture. The [source pack](../../art/source/world/sparks-workshop/v1/README.md) contains exact painting prompts and the guarded authoring/edit history.

The traveller keeps the approved loft size, clothes, face and animation. Downstairs workbenches, tables, seating and storage are reduced by 15%; their attached props, mounting positions and collision footprints move with them. The room shell and stairs keep their dimensions. The resulting space holds a useful service trolley and a food cupboard beneath a wall clock. Its labelled enamel tin has an open hinged lid, a scored loaf and cut slices on a used board: Nell's opening “bread in the tin” now points to a real place. F opens the bread inspection, and the post-greeting pinned hint mentions it.

The three unwanted white machine/crate coverings are removed. The umbrella crock has an annular rim, inner wall and recessed floor; the two flowerpots sit above the stone step. The plaid throw clears the chair's arms and back, and the small cushion rests above its seat. The stove grille has a closed arch, bottom rail and intersecting bars; its flue still reaches the ceiling after scaling. The floor rugs use painted woven material. The side door fades when it would obscure the traveller.

The area document owns all blocking furniture, the six inspections, stair heights and reciprocal room links. The loft hatch lowers the sprite through its existing treads; the downstairs flight has thirteen ascending supports and a landing. Walking, click picking and route travel use those heights. The camera keeps its approved heading/elevation. There is no lateral step through the stair rails.

Each floor saves its position, objects and program memory separately. The Python page, greeting and read dialogue progress are shared. A pending proposal is discarded before travel. Continue resumes the active floor, old loft-only saves remain valid, and a remembered position obstructed by the rearranged furniture recovers without dropping program memory. Hotaru stays upstairs while asleep and appears at the downstairs assembly bench when awake. Repeated attempts at the latched street doors reuse one visible message.

Validation: `scripts/test.sh`, plus windowed `test/test_workshop.gd` at both review sizes. Checks cover real WASI execution, proposal cancellation, actual stair ascent/descent and elevated picking, room save/restore and memory isolation, bread inspection and HUD continuity, a ray through the hollow crock, removal of all three covering materials, furniture scale and repeated feedback. The [validation record](../../art/source/world/sparks-workshop/v1/validation.json) contains exact counts and hashes. The staircase also has an [identical rebuild proof](../../art/source/world/sparks-workshop/v1/rebuild-proof.json). Sources were deliberately edited with preserved before copies; the existing loft models and paintings were retained.

Native gameplay captures:

| View | 1600×1000 | 1280×720 |
|---|---|---|
| Furnished room | [Room](../../evidence/sparks-workshop/1600/02-workshop.png) | [Room](../../evidence/sparks-workshop/1280/02-workshop.png) |
| Bread cupboard | [In the room](../../evidence/sparks-workshop/1600/06-bread-cupboard.png) | [In the room](../../evidence/sparks-workshop/1280/06-bread-cupboard.png) |
| Bread inspection | [Paper card](../../evidence/sparks-workshop/1600/07-bread-note.png) | [Paper card](../../evidence/sparks-workshop/1280/07-bread-note.png) |
| Job board | [Ticket](../../evidence/sparks-workshop/1600/03-job-board.png) | [Ticket](../../evidence/sparks-workshop/1280/03-job-board.png) |
| Upper landing | [Arrival](../../evidence/sparks-workshop/1600/01-upper-landing.png) | [Arrival](../../evidence/sparks-workshop/1280/01-upper-landing.png) |
| Stair ascent | [Raised sprite](../../evidence/sparks-workshop/1600/04-stair-ascent.png) | [Raised sprite](../../evidence/sparks-workshop/1280/04-stair-ascent.png) |
| Door cutaway | [Visible traveller](../../evidence/sparks-workshop/1600/05-street-door-cutaway.png) | [Visible traveller](../../evidence/sparks-workshop/1280/05-street-door-cutaway.png) |

The street is not yet enterable. Nell's arrival, free companion following and later repair lessons remain proposed; this room pass adds exploration and continuity rather than claiming those scenes are implemented.
