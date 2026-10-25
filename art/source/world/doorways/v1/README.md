# Steps and doors — 2026-10-25

The recorded source edits open the **existing** ten adopted building masters. Each original is retained as `model.pre-doorways.blend`; historical building-polish records still refer to that preserved version. `doorways.json` records the current source hash and the later review-backup chain. Normal future edits use each saved `model.blend` and `scripts/world-art.sh build <id>`.

`edit_sources.py` separates the original leaves onto a ground-pivot `DoorHinge`, carves a real opening, adds a recessed vestibule and centers two low treads. Catalog `entrance.steps` records their exact local reaches, width and height; rendering uses these values for character support, while `core/house_instances.gd` uses only integer approaches and directed crossings for travel. The terrain builder’s four-tread recipe supplies terrain stair heights.

The Godot review revealed inward shell normals, unreliable Boolean results on the loft’s intersecting tile batch, and Blender material suffixes introduced while loading backup geometry. `review_corrections.py`, `final_fit.py`, `restore_bindings.py` and `door_detail.py` record the deliberate corrections, retaining each preceding source. The final loft keeps its original continuous tile cover, moves the complete oriel to the front corner, shortens its cap and removes duplicate gable infill. Three larger houses receive centered oak leaves with straps and knockers. Canonical material identities retain saved per-part finishes.

These are one-time authoring records, guarded against adopted revisions. They are not an alternative rebuild pipeline. No art service or Blender is needed to play.

The final aperture authority is the saved result of `clip_apertures.py`: it restores only affected mesh data from the original backup, splits existing faces on the opening boundaries and removes the faces inside. This supersedes the intermediate Boolean cuts, which produced closing planes or extruded fragments in intersecting batches. The exported-geometry regression checks both doorway visibility and the outer approach bounds. All intermediate sources remain preserved for review.
