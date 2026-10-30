# City power grid — 2026-10-29

Superseded by the [integrated conduit revision](2026-10-29-integrated-power-conduits.md).

The existing `haverlund-square-ground` and `haverlund-lane-set` Blender masters were edited and rebuilt through `scripts/world-art.sh build`. The square retains the Rootwell ring and existing channels, adds branches to the civic fronts, market, arrival and exit streets, strips down retaining walls and a tread-following strip on the Harbour Steps. Scattered grass polygons on the lower town's ground were changed to paving; intentional gardens and upper greenery remain.

Spindle Lane's overhead wires and pole hardware were removed, with the hanging flower basket moved to the workshop. Glowing strips run along the lane, branch toward buildings and the tram stop, and descend its retaining wall. `art/power_grid.gdshader` supplies a repeating moving amber pulse to the tagged meshes and original square brass in Godot. It is presentation only; the area documents and gameplay rules are unchanged.

Reviewed in Godot at 1600×1000 and zoom 13: [square](../../evidence/power-grid-2026-10-29/square.png), [Harbour Steps](../../evidence/power-grid-2026-10-29/harbour.png), [Spindle Lane](../../evidence/power-grid-2026-10-29/lane.png). The full `scripts/test.sh` run passed; it began before a final removal of three obsolete pole bases, and the focused lane test passed again after that rebuild. The photographs are stills; the shader itself animates in-game.
