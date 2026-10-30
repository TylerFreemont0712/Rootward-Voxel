# Postal worker removal — 2026-10-29

The obsolete `square-delivery-robot` model was removed through its dependency-bound asset request. The square porter uses another Pip model; its short route was reconstructed after the original was removed during the pass. Pip is a reusable robot model. The earlier archived square's postal-worker placement and obsolete art-catalog and test entries were removed. The similarly named lane notice-board is a different, retained model; its inspection identifier is `lane-notices` to distinguish it from the separate asset requested for deletion.

The lane and square focused tests and full `scripts/test.sh` suite pass. [Godot gameplay-scale square view](../../evidence/asset-removal-2026-10-29/square-porter.png) shows the replacement in the square. The rest of the deletion queue remains open.
