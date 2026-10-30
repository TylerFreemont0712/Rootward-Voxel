# Integrated city conduits

This is the record of a deliberate edit to the adopted `haverlund-square-ground`, `haverlund-lane-set` and `haverlund-lane-surround` masters. The masters remain the editable authority. `rework.py` refuses an already-revised master; it is a one-time source-edit record, not a replacement generator. Each master keeps its exact preceding version as `model.pre-grid-inlay.blend`.

The old tagged flat strips are removed. The new channels have a 38 cm recessed bed, two 36 mm bronze frame rails and 164 mm inset glass, with service fittings at the branches. Planar paving is split around the channel mouth with UV interpolation; its textures and surrounding layout stay intact. Ground surveys sample the authored Blender geometry and the actual house steps. `seat_stair_glass.py` seats glass on the full tread width at beveled seams. `join_gate.py` wraps the six-centimeter lane/set boundary step.

Routes follow the Rootwell feeds, market and civic streets, the three exits, centered Spindle Steps and tram steps. The lane's house feeds cross their authored thresholds and the tram platform is supplied along its length. The lane surround carries the same route down the town steps beyond the gate; the square's streets continue beyond the playable rectangle instead of stopping at its boundary.

Existing tall pilasters are separated from the stone batch without changing any vertex positions. Their original stone material supplies the texture to the cosmetic carved-light shader. The revision reuses 38 square and 17 lane-surround pilasters. There are no separate vertical stripes down the walls. Area documents, collisions, levels and saves are unchanged.

Build edits with `scripts/world-art.sh build <id>`. Source-adjacent `grid-inlay-audit.json` files record surveyed route endpoints, lengths, risers, paving cuts and reused pilasters. Godot applies the conduit/pillar shaders from their semantic metadata; no Blender or authoring script runs in gameplay.
