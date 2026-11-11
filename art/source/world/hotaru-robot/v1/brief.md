# Hotaru, robot companion — 2026-10-26

**Study only.** This source is not registered in `pipeline/world-catalog.json` and the game does not use it. The user asked that the existing game stay unchanged and that the v0.7 concept develop as its own scenario, with final art from a separate image-generation pass ([prompt pack](../../../../../docs/concept/v0.7/04-art-prompts.md)). Register it, or a cuter successor, only when that scenario is built.

Stage 0 of the [robot companion design](../../../../../docs/concept/v0.7/03-robot-companion.md): a lantern-shaped robot replaces the fairy orb, with the same following behaviour. Cream enamel body with two teal bands, a teal brimmed dome cap, brass collar and foot ring, a folding two-blade brass rotor with a red knob, short stub arms with teal hands, one round spark window in a brass rim and a tape slot under it. Folded legs show only in working mode (a later stage).

About 0.34 m tall with legs folded (one metre per grid cell). The pivot is the ground under her feet in working mode; she faces Godot +Z.

Changing parts, found by name rather than node path: the `spark_glass` window and `spark_eye` meshes (separate materials), and the `rotor`, `legs`, `arm_left` and `arm_right` pivots. No collision, footprint or commands.

`author.py` is the one-time authoring record and refuses an existing master. `model.blend` is the editable authority: edit it in Blender and export with `scripts/world-art.sh build hotaru-robot`. Concept renders come from `art/source/companions/hotaru/v3/concept/render_turnaround.py`.
