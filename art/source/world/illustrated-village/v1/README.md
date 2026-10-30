# Illustrated village authoring record

The reference is `reference/voxel-isometric.png`. The user requested a closer,
semi-drawn voxel style after approving the square lamp study.

Editable masters are separate:

- `art/source/world/painted-cottage/v1/model.blend`
- `art/source/world/painted-oak/v1/model.blend`
- `art/source/world/painted-garden-fence/v1/model.blend`

`author.py` is protected one-time authoring. The cottage retains the adopted
reference cottage geometry and hinge; it changes the surface treatment.
`refine_pass02.py` records deliberate edits of the first saved cottage/tree
masters, preserving each as `model.pass-01.blend`. The tree’s initial crown had
flat terraces; the current master uses individually offset, bevelled leaf clumps.
Current revision hashes are recorded in each `pass-02.json`.

These scripts are design history, not the asset build. Open the current master
to edit it, then use `scripts/world-art.sh build <id>`. The four illustrated
assets, including `square-lamppost`, are selected in the world catalog.
