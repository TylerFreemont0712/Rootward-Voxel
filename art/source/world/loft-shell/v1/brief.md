# Workshop loft shell — 2026-10-27

The room shell of the Sparks & Machines journey's first room: the attic loft above Nell's workshop, after `docs/concept/v0.7/art/4-opening/T7a-workshop-loft.wheels.png`. A thick plank floor with a cut front edge, a stair hatch with brass-capped newel posts, plaster walls in a timber frame with plank wainscot, two broad braces and roof rafters on the west wall, and a north gable with the round porthole window and a tall dormer window.

Size and pivot: 12 by 10 cells to match `content/areas/workshop-loft.json`; origin at the centre of cell (0, 0) on the floor; Blender +X is logical x and +Y is logical y (Godot −Z). Only the west and north walls exist; the camera looks in from the south-east.

The area document owns the exit (`[3, 1]`), walls and collision. The hatch's newel posts stand where `HouseInstances.frame_posts` places the doorway's collision, and the hand rails' collision is the two blocking `furniture` entries in the area document. No footprint, no finishes, no commands.

`author.py` is the original one-time authoring record and refuses an existing master. `model.blend` is the editable authority. The furnished revision uses bespoke painted oak, plaster and window surfaces from [the loft source pack](../../sparks-loft/v1/README.md); use `scripts/world-art.sh build loft-shell` after editing it. Generic `retexture` would replace these bespoke materials and is no longer the finish workflow for this room. The first adopted master is preserved as `model.pre-furnishing.blend`; `furnishing-revision.json` and the source-pack edit records describe the deliberate changes.
