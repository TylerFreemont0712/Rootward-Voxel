# Pendulum & Pin — original clockmaker, v2

The user authorized the new clockmaker modeling pass after the strip/layout work, asking to stay close to the original concept and give the shop a functional door. The rejected v1 derived shop-house remains untouched as history. V2 imports no existing building or shop mesh.

Reference: [clockmaker concept](../../spindle-strip/v1/clockmaker-concept.png). The original architecture has an offset clock tower with a bell-shaped patinated copper cap and finial, a tall arched pendulum bay, a recessed oak-and-glass entrance, two curved display bays with modeled clocks, an enamel fascia, arched upper windows and flower boxes, a standing-seam roof, asymmetric curved dormer, chimney and rear service porch.

`author_original.py` records one-time modeling using the common mesh/material utilities and existing Haverlund paintings. It refuses the existing v2 master. `copper_finish.py` is a deliberate edit of that saved master, replacing the ceramic picture with sheet-copper materials and low-profile panels. `detail_finish.py` records modeled clock hands, side-window fills and pipe brackets. Provenance and before hashes are alongside them. These records are not runtime builders: **edit `model.blend` going forward**, then run `scripts/world-art.sh build haverlund-clockmaker`.

The model faces Blender −Y, with its ground pivot at the footprint center. In the square it stands at `(12.5,20)`, height 2, facing east into Spindle Walk. The functional left entrance beneath the tower is approached from `(17,17)`. The center glazed panel is fixed display joinery, and the rear service door is scenery. Only the recessed entrance opens a room link.

`door_leaf_clockmaker` and its glazing share the hinge and `swing: -100`; the existing door presenter operates them. `clock_hour_hand` and `clock_minute_hand` retain independent center pivots and follow the shared town clock. `clock_pendulum` is a separate modeled part for future control work; its swing/lesson is not implemented. The frontage lamps bind to the square's automatic light circuit.

The separate `shop-clockmaker` room remains the cleared shell with its existing doorway and two structural pendant fittings. No shopkeeper, stock inventory, programming challenge or replacement interior furniture is implied. Existing room memory survives. [Review](../../../../../pipeline/reviews/2026-11-03-original-clockmaker.md).
