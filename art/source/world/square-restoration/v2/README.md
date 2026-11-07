# The clockmaker's court (2026-11-05)

`pave_court.py` copies ground v6 to `haverlund-square-ground/v7/model.blend` (v6 is untouched) and, in the blocked rear shelf behind Spindle Walk (x 9.5–15.5, y 14.5–54.5, floor at z 2), removes the clockmaker plot's pit walls and floors and every ground face in that rectangle (the grass patches among them), then lays one continuous flagged floor. Nothing the player can walk on changes. `v7/court.json` records the hashes and counts.

The dressing is area-owned: `content/areas/haverlund-square.json` (`interior.assets`, ids `court-*`) places a limestone garden wall along the promenade edge (x = 15.45) with piers and two gates, four raised lawns with trees and cypresses, a fountain, a bench and planters. They are presentation only; the rear shelf stays blocked, so no collision or reachability changes. The script is a one-time record; edit the saved master or the placements from here.

Review: [2026-11-05 purge and polish](../../../../../pipeline/reviews/2026-11-05-purge-and-polish.md).
