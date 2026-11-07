# Clockmaker v3 — concept refinement

This is a deliberate refinement of the saved v2 building after the user found it too far from the original concept and reported errors/inconsistencies. V1 and v2 remain unchanged. No preset building or shop mesh is imported.

The selected authority is **`model.blend`**. Edit it going forward and build through `scripts/world-art.sh build haverlund-clockmaker`. The scripts record bounded source edits, not runtime builders or replacements for the Blender master.

## First pass: structure and silhouette

`refine_structure.py` reads the retained v2 source and establishes v3. It replaces only the old roof geometry, fits a curved copper roof around the clock tower/dormer, adds the rounded bell cap and curved dormer hood, corrects upper-front opening offsets, opens the tower's previously blocked side slit, and anchors replacement rainwater pipes. Existing main walls, footprint, clock pivots and functional entrance are retained. [First-pass view](../../../../../evidence/clockmaker-refinement/pass1-front.png).

## Second pass: facade and materials

`refine_frontage.py` edits the saved first-pass master. It aligns the rear wall openings with the existing service door/windows; replaces flat front panels with arched casements and bowed glazed displays; gives mantel clocks cases/feet and pocket watches explicit hanging supports; adds modeled cornices, pilasters, serif lettering, a glazed central secondary door, a porch pendant and coherent planting. The working left leaf is rebuilt around its unchanged hinge with an actual glazed opening. The clock hands keep their names/pivots; the pendulum remains a separate future mechanism.

`finalize_material_roles.py` separates clear panes from bulb geometry. `export_finish.py` uses Blender 5's supported RGBA Mix/Multiply nodes, preserving copper/oak color factors in glTF, and joins the three lamp bulbs into one isolated mesh for the existing logical fixture. `runtime_detail_finish.py` records the actual Godot-scale review: authored roof/fine dial parts opt out of expanded ink through `illustrated_edges: false`; modeled rims remain. It also fixes physical dial/case clearance and uses one double-sided glass skin per pane. `drain_finish.py` connects the tower-side pipe to the higher tower cornice, rather than a removed lower-roof corner. `tone_finish.py` records the final game-view correction to matte aged copper and neutral low-opacity glass, avoiding a cyan cast on the display clocks. `readability_finish.py` retains quarter marks on small display clocks instead of dense ticks that alias at gameplay scale.

A material-slot assignment mistake in the second candidate was caught before delivery. Reapplying the bounded edit records to a scratch candidate recovered only material assignments; transforms, vertices and polygons were verified identical. The correction log is in `.cache/clockmaker-refinement/material-verification.log`; the discarded candidate is not selected. The saved master and normal build manifest are authoritative.

## Materials and behavior

Copper uses the existing approved detail-library `copper_patina` painting, sampled in a patina-dominant region. Oak uses the existing seaside house painting. Original images are untouched; selected images are packed in the Blender source/GLB. DejaVu Serif lettering is converted to geometry; no font is required by the game. Lamp emitters, ordinary glazing and opaque backing panes have separate meshes so power changes cannot recolor the windows.

Placement, collision footprint, `(17,17)` approach, `shop-clockmaker` link, room memory and shared town clock are unchanged. The recessed left entrance remains the active door; central/rear secondary doors remain scenery. The separate interior remains cleared for later design. Neither a shopkeeper nor a programming quest is added.

[Original concept](../../spindle-strip/v1/clockmaker-concept.png) · [Refined front](../../../../../evidence/clockmaker-refinement/refined-front.png) · [Refined rear](../../../../../evidence/clockmaker-refinement/refined-rear.png) · [Review](../../../../../pipeline/reviews/2026-11-03-clockmaker-refinement.md).
