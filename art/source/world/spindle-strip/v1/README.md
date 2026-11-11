# Spindle Walk — layout and original shop concepts

This replaces the user's rejected first strip pass (two reused food-shop shells and an empty lawn). Their annotated 2026-11-03 revision asks for an extended arrival/loading area, a small park left of the stairs, a real shopping promenade facing the square, capacity for more shops, original building concepts, and cleared shop interiors before a later rebuild.

## Current implementation

- `content/areas/haverlund-square.json` version 6 owns the larger high landing, the moved five-cell lane boundary at `(0,12)`, the left-hand Spindle Garden, the long promenade and all physical dressing/barriers. Spindle Lane's reciprocal arrivals move to `(1,11)` and `(1,13)`, default `(1,12)`.
- `content/development/spindle-strip-plan.json` records four future shop frontages along the western side, facing east into the promenade and toward the square. The first two are the clockmaker and apothecary. The central path sits far enough west to keep the character visible past the existing market roofs under the approved fixed camera. The new building plots are unbuilt, with level paved courts; no invisible plot collision is added.
- `haverlund-square-ground/v3/model.blend` is a copied, deliberately edited adopted master. v2 and archived area v5 remain intact. `ground_revision.py`, `finish_masonry.py`, and `frontage_alignment.py` record the bounded source edits. Current saved `.blend` and area documents own later changes; do not regenerate them from these historical scripts. Export with `scripts/world-art.sh build haverlund-square-ground`.
- All five `shop-*.json` interiors have their loose furniture, stock, counters and descriptions removed. Only the shell, doorway and structural light fittings remain. Room IDs, programs/memory and safe exits survive, including a Continue already inside the retired clockmaker/apothecary rooms.
- The temporary clockmaker/apothecary exterior reskins are unplaced and marked `retained_previous_concept`. Their files are preserved. Original replacements have not been modeled or installed.

## Proposed building concepts

Both images were generated using the **built-in image_gen tool** and copied into this project. Exact final prompts: [concept-prompts.json](concept-prompts.json). Generator/proposal status and image hashes: [concept-provenance.json](concept-provenance.json). These are reference images for user review, not runtime assets or accepted model designs.

- [Clockmaker](clockmaker-concept.png): offset clock turret, glazed pendulum bay, sheltered entrance and a native watch/clock display frontage. Front and rear views on one concept sheet.
- [Apothecary](apothecary-concept.png): a lower asymmetrical building with a curved glazed shopfront, herb glasshouse wing, slate-green roof and a small service side. Front and rear views on one concept sheet.

Future models should be authored from these concepts after review, rather than copying another shop's house shell. Their final footprints, doors and rear walls should fit the current frontage plan; the concept drawings are not measured construction plans. Interior assets, trading and programming challenges remain deferred at the user's request.
