# Square and lane texture pass (2026-11-06)

One-time records of the fixes to the problems the user circled in five night screenshots of Rootward Square and Spindle Lane. The saved masters and area documents are the authority afterwards; never rerun these over them.

| Record | What it did |
| --- | --- |
| `ground_v9.py` | `haverlund-square-ground` v8 → **v9**. Spindle Steps (the lane flight) used to stop on a 2 m block above the terrace. Ten more 0.2 m steps now carry it down to the floor (x 3.5–5.5, y 5.45–10.55), and the conduit follows the treads and risers. The bare limestone flags with blocky grass patches on the high ground (behind the rear wall at z 4, west of the steps at z 6, on the parapet above the arrival lawn at z 3) are now lawn, keeping the path at the head of the steps. `v9/texture-pass.json` records counts. |
| `revise_area.py` | Square area v9 → **v10**. The two new step cells are blocked, and a second walk-through link (`uphill-steps`) across the flight's foot climbs to the lane like `uphill` does. Trees line the high gardens as room scenery. The north end of the walk gets trees and a bench as layout props, and the layout scope grows to cover it. The layout epoch is unchanged, so saved studio edits still apply. |
| `lane_surround_v2.py` | `haverlund-lane-surround` v1 → **v2**. A stepped stone parapet with coping replaces the town steps' east handrail beyond the lane's north gate, which read as a zig-zag rail from the game camera. |

Engine and document changes made with them:
- `art/depth_mist.gdshader` gains an optional edge haze (`interior.depth_fog.edge`), and the night mist is a moonlit haze instead of near-black.
- The power column, pillar and grid shaders no longer cut their glass off at `light_floor`. Below it they stay whole but unlit, and the mist covers them.
- Spindle Lane has depth fog and edge haze. The ten houses and eight trees of the lower town at z -8, and their window lights, were removed (they only showed as roofs through the mist).

Review: [2026-11-06 texture pass and lane fog](../../../../../pipeline/reviews/2026-11-06-texture-pass-and-lane-fog.md).
