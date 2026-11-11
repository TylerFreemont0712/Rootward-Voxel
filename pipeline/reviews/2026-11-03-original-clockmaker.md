# Original Pendulum & Pin clockmaker

After authorizing the flat upper layout, the user asked to start the clockmaker as a unique asset, closely following the generated concept, with a working door. This explicitly supersedes the earlier deferral of clockmaker modeling. The apothecary and interior furnishing remain deferred.

## Delivered

An independently modeled v2 replaces the rejected reused shop-house on the first western plot. No existing building mesh was imported. The concept's offset clock tower, copper cap/finial, tall arched pendulum bay, recessed left entrance, curved clock display bays, enamel sign, arched upper windows, flower boxes, sheet roof, curved dormer and rear service porch define the asset. Existing Haverlund paintings and low-level mesh utilities maintain the game's style; they do not determine its floor plan or silhouette. The prior v1 master remains.

The recessed oak leaf and glazing rotate around their own shared hinge. The actual campaign room link opens the separate clockmaker room and returns to the matching facade. The former strip planter is moved aside from this approach. The central glazed panel is fixed display joinery and the rear door is scenery; only the recessed left entrance is active.

Both exported clock hands have real visible geometry and follow the town clock. The long pendulum is a separate semantic mesh for future work, with no programming lesson or swing implemented. The shop's actual lamps join the square circuit, bringing the square to 68 logical fixtures. The existing blank interior remains cleared; no furniture, quest, inventory or shopkeeper was added.

## Source and performance

The selected source is [v2/model.blend](../../art/source/world/haverlund-clockmaker/v2/model.blend), built normally into `assets/world/haverlund-clockmaker/model.glb`. The original authoring record and deliberate saved-master refinements are in [the source handoff](../../art/source/world/haverlund-clockmaker/v2/README.md). Normal build audit: **25 meshes / 32,684 triangles**, with packed materials, explicit footprint and semantic pivots. The complete square light check reports zero meshes above eight affecting point lights. Geometry, collision and room links remain separate.

## Validation

- Original asset, footprint, reachable entry, actual hinge motion, visible hands, shared time, retained empty room and old-save recovery: **20 checks passed** on the final model.
- Native Godot 4.7.2 / Compatibility, 1600×1000: **18 checks passed**, including entry with a visibly swinging door, Continue inside the cleared shop, return beside its own facade, door closing and room-memory retention. Day and evening views reviewed at the approved camera scale.
- The layout's native mouse/save review also passes **28 checks** with the shop placed.
- Full `scripts/test.sh`: **passed**, including gameplay, UI, sandbox, all 969 world-view checks, source/workflow guards, 1,592 handoff checks and 121 ground-art checks. Following the final model refinement, the 20-check model test, 68-fitting light audit, world-view test and native door/save review were rerun successfully; final native views use the latest import.
- `git diff --check`: passed.

[Concept](../../art/source/world/spindle-strip/v1/clockmaker-concept.png) · [Full model preview](../../evidence/clockmaker/model-front.png) · [On the strip](../../evidence/clockmaker/01-original-shop-on-strip.png) · [Recessed entrance](../../evidence/clockmaker/02-recessed-door.png) · [Cleared room](../../evidence/clockmaker/03-cleared-room.png) · [Evening frontage](../../evidence/clockmaker/05-evening-frontage.png).

The final model awaits the user's acceptance in the Finished queue. Further material/detail refinement and interior design can follow that review; apothecary geometry remains a separate request.
