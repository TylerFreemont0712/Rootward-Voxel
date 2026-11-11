# Clockmaker: two concept refinement passes

The user requested another pass or two because the new shop differed too much from the original image and had errors/inconsistencies. This revision edits the retained custom v2 master into v3, preserving earlier sources, the approved player/camera, the collision footprint and saved room behavior.

## What changed

The first pass corrects the rigid silhouette: a rounded bell cap with ribs and a stepped cornice replaces the pyramidal tower roof, a curved fitted dormer replaces the detached box, and the metal roof meets actual tower/dormer cutouts. Pipework is attached to the walls. Upper-front openings now align with their casements, and the tower slit is opened through the masonry.

The second pass corrects the facade. Shallow arched upper windows replace dark panels and oversized blue bars; bowed displays have clear glazing and full frames. Mantel clocks stand in cases on ledges, and pocket watches hang from supports. The fascia has deeper cornices, pilasters and serif lettering. The rear service door and windows now match their wall openings instead of leaving a blank hole elsewhere. Duplicate planting and detached old pipes are removed. The working left entrance retains its hinge and glazed leaf.

The existing patinated copper painting and warmer oak are exported with their intended color factors. A final game-view tone check reduces copper glare and uses neutral low-opacity glazing so display faces retain their warm colors. Lamps and clear panes are isolated so the power system cannot override the window material. One emitting mesh controls all three shop lamps. The actual Godot review caught oversized ink on nested clock details and roof panels; authored per-mesh ink exclusions preserve modeled rims without the dark overlaps. Small display clocks use readable quarter marks. The source details and corrective steps are recorded in [v3's handoff](../../art/source/world/haverlund-clockmaker/v3/README.md).

The left entrance remains active; the central and rear secondary doors are scenery. Clock hands still follow town time. The pendulum is modeled but has no programming lesson or swing yet. The separate room stays cleared, and saved room memory is retained. Apothecary modeling and interior furnishing remain deferred.

## Review and validation

- Original concept compared directly against the retained v2 preview and both refinement renders, including rear views.
- Final imported model: **65 checks passed**, covering exported color factors, transparent glazing, isolated fixture glass, authored ink exclusions, hinge motion, town-time hands, reachable doorway, unchanged collision and saved-position recovery.
- Native Godot 4.7.2 / Compatibility at 1600×1000: **18 checks passed**, including visible door opening/closing, entry, Continue inside the room, return to the matching facade and independent room memory. Day/evening views reviewed.
- Square lights: **68 fittings, zero meshes above eight affecting point lights**.
- Full `scripts/test.sh` passed, including 969 world-view checks, source/workflow guards, 1,592 handoff checks and 121 ground-art checks. Final readability/export refinements also passed the 65-check model test, native door/save review, lighting audit and all 969 world-view checks. The updated handoff/link audit passes 1,595 checks.
- Final normal world-art audit: **31 meshes / 64,357 triangles**. This is a more detailed hero asset than v2; authored ink exclusions avoid extra hulls over its fine roof/dial work. No whole-game frame-rate gain is claimed.
- `git diff --check`: passed.

[Before](../../evidence/clockmaker/model-front.png) · [First structure pass](../../evidence/clockmaker-refinement/pass1-front.png) · [Refined front](../../evidence/clockmaker-refinement/refined-front.png) · [Refined rear](../../evidence/clockmaker-refinement/refined-rear.png) · [Actual game view](../../evidence/clockmaker-refinement/game/00-full-building.png) · [Evening view](../../evidence/clockmaker-refinement/game/05-evening-frontage.png).

A candidate material-slot error was caught in the source renders and corrected before delivery. The corrected candidate's geometry was checked against the prior candidate; only material assignments differed. The live Blender bridge was unavailable, so local Blender source edits/renders and the normal Godot build/import path were used. Acceptance remains with the user in Finished.
