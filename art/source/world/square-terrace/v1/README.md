# Spindle Walk terrace (2026-11-05)

One-time records of the upper-terrace rearrangement. The saved masters and the area document are the authority afterwards; never rerun these over them.

| Record | What it did |
| --- | --- |
| `terrace_ground.py` | Copied `haverlund-square-ground` v7 to **v8**. Re-cut every old terrace floor face (z 2) into one paving scheme (flags, with cobbled walks along the landing and down the promenade spine) in 4 m sections, paving the ragged lawn strips along the outer edge. Ran the city conduit (city-power-grid v2 channel) from the lane steps along the landing and up the spine, with feeds to the clockmaker and apothecary doors and the four walk lamps, plus service plates at the joints. Removed the free-standing pit cheek behind the clockmaker, closed the rear wall behind its plot, and plugged three voids where the sky showed through (under the lane steps, north of them at x 3.5, and the corner beside the upper flight). `v8/terrace.json` records counts, routes and hashes. |
| `revise_area.py` | Area v8 → **v9**, layout epoch 9. Set the bakery, The Pantry and Finch & Thread one cell back against the terrace wall (doors, inspections and window lamps moved with them), placed Thyme & Tonic with its door link, window light and inspection, retired the walled lawns of the old court, opened the rear shelf as walkable terrace with a walled physic garden (3 m opening on the fountain's axis), and dressed the walk's outer edge with lamps, benches facing the view and trees in grates. Garden walls, benches, trees and planters are layout-studio props, so build mode can move them. Sets `interior.stair_steps: 5` (see below). |
| `../../haverlund-apothecary/v2/author_original.py`, `slate_tint.py` | The original apothecary model and its green slate tint. |

`interior.stair_steps` tells the walking surface how many steps the authored ground cuts each level into. The square's Blender flights have five 0.2 m steps; the procedural default is four. Before this, feet and contact shadows sank up to 10 cm into the treads on Spindle Steps and the hill stairs. Contact shadows now also rest on the highest tread beneath them (`WalkingSurface.contact_lift`).

Review: [2026-11-05 Spindle terrace and apothecary](../../../../../pipeline/reviews/2026-11-05-spindle-terrace-and-apothecary.md).
