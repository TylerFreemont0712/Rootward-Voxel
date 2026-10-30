# Loft tape reader — 2026-10-27

New bespoke T7a furnishing for the Sparks & Machines loft. Source/version: `v1/model.blend`; this saved master owns future shape and material edits. Shared authoring/provenance: [the loft pack](../../sparks-loft/v1/README.md), including source paintings and exact prompts.

Native Godot bounds: 0.745 m wide × 0.715 m high × 0.590 m deep. Blender is Z-up; glTF performs the normal Godot conversion. The local front faces Blender −Y / Godot +Z. The postcard origin is its picture centre; other prop origins are the support/floor origin. The cable uses a floor-relative wall-connection origin.

Placements, turns, support heights and blocking rectangles belong to `content/areas/workshop-loft.json`. Decorative overhang and drawn detail do not grant collision or an interaction. This is room furnishing, not a builder-shelf item.

Materials use supported glTF nodes and embedded painted surfaces. The catalog selects fine sepia outlines. Semantic `spark_glass`, `rotor`, `tape_spool` and `paper_feed` pieces remain separate where relevant; static pieces batch by material and retain component names in mesh extras. Runtime state changes duplicate/override per-instance materials.

Edit the existing master, then run `scripts/world-art.sh build loft-tape-machine` and review it in Godot at gameplay scale. Never rerun the one-time authoring record over an existing master.
