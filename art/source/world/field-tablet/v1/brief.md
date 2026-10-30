# Nell’s field tablet — 2026-10-27

The slate the traveller carries between the loft and the workshop. Source/version: `v1/model.blend`; this saved master owns future shape and material edits. Authoring record: [`field_tablet.py`](../../sparks-loft/v1/field_tablet.py), which refuses an existing master. Review: [tablet and wall screen](../../../../../pipeline/reviews/2026-10-27-tablet-and-wall-screen.md).

It is cream enamel with a teal glass surround, a dark unlit screen with three faint lines, four brass corner caps and a brass indicator. Twelve inches by eight, a little over half an inch thick. A grey cord leaves the right edge, coils twice on whatever the slate rests on and ends in a brass-collared plug. The model rests on its bottom face; the origin is the centre of that face. The local front faces Blender −Y / Godot +Z.

Placement and the pickup belong to `content/areas/workshop-loft.json` (`assets`: `bed-tablet`, `pickups`: `tablet`). The model has no collision and no command. Once carried, the game hides this object; the tablet has no held-in-hand model yet.

Edit the existing master, then run `scripts/world-art.sh build field-tablet` and review it in Godot at gameplay scale. Never rerun the one-time authoring record over an existing master.
