# Build mode with real freedom — proposal (2026-11-05)

**Status: slices 1–4 implemented as first versions on 2026-11-06 (see the end).** The user asked for build mode to depend much less on premade assets. They want ground textures that suit the theme, Sims-style walls that connect themselves, objects that code can control being movable, and most simple objects codeable. Only the square's basic ground should stay fixed: levels, stair placement and the loading boundaries.

## What exists today

| Piece | Today | Where |
| --- | --- | --- |
| Ground paint | 10 painted pictures on half-cells, appearance only | `art/ground_skin.gd`, `core/ground_paint.gd`, [GROUND](../../../pipeline/GROUND.md) |
| Objects | Place, move, turn and delete *props* from a scoped shelf (14 garden/barrier pieces in the square) | `core/area_build.gd`, `core/build_ledger.gd`, [BUILD](../../../pipeline/BUILD.md) |
| Walls | Fixed-length modular bays (garden wall, railing, balustrade) placed one at a time as props; terrain walls are baked into the Blender ground | `town-*` masters |
| Authored scenery | `interior.assets` (lamps, trees in grates, buildings, stalls) cannot be moved by build mode | area document |
| Code | Props whose catalog entry declares an `interaction` (light, hinge, lever, spin_x/y, bell, pump) appear as `world.prop(...)`. Everything placed is readable as `world.doodads`. Code-build can only `rotate`. | `core/prop_interactions.gd`, `core/code_build.gd` |

## Proposed split: the frame and the layout

- **Frame (authored, fixed):** levels, stairs, loading links, building plots with interiors, and the ground's height shape. It stays in the area document and the ground master.
- **Layout (everything else, editable):** paving and lawns, walls and fences, lamps, benches, trees, stalls and decorations. It's stored as today's edit layer over the document, and the shipped layout is just the first edit set. Moving an authored lamp is then the same kind of edit as moving a bench.

## Slices (each one playable and reviewed before the next)

1. **Everything non-structural movable.** Give `interior.assets` entries a `movable` flag (default true for lamps, trees, benches, stalls and planters; false for buildings, the Rootwell and the ground). A moved lamp keeps its id, power and Python handle, so programs keep working. The reachability rule still protects doors and links.
2. **Wall tool (Sims-style).** Drag along cell edges to draw a wall run. It snaps to edges, runs straight or turns at corners, and needs no premade lengths. It's stored as `walls: [{from, to, style, height}]`. Pure rules in `core/`: walls block movement on the edges they cover; a door or gate is a gap with an optional leaf; drawing must leave everything needed reachable. The renderer generates the geometry, auto-picking an end pier, corner pier, T-junction post or straight panel at each joint, in a few styles (limestone garden wall, iron railing, balustrade, clipped hedge) and heights (low 1 m, garden 1.6 m, full 3 m). Delete or split a run with the existing tools.
3. **Theme ground set.** Grow the paint palette into families that join properly: limestone flags, setts, cobbles, herringbone brick, gravel, lawn, planting bed, plus kerbs and edging drawn automatically where two families meet. They're made through the existing `scripts/art.sh` texture pipeline in the painted Haverlund style.
4. **Codeable simple objects.** Add capability tags to the catalog for most simple pieces: `light`, `open`, `turn`, `colour`, `ring`, `flow`. Any placed piece with a capability gets a Python handle through the same validated commands as lamps (`world.prop("bench-3").turn("E")`, `world.prop("fountain").flow(True)`). Code-build grows from `rotate` to `move` within reach, with the same placement rules as the mouse. The notebook keeps its plain-word errors.

## Decisions (answered 2026-11-06)

1. **Walls sit on cell edges**, Sims-style.
2. **Designer first.** The player gains control later in the story, not total control: their own apartment or house becomes customisable first, then a small area they look after.
3. **Conduit re-routing** to a moved lamp would be nice, but isn't needed yet. Power stays invisible for now.
4. **Order 1 → 2 → 3 → 4** is accepted.

Status (2026-11-06): **all four slices are implemented as first versions**. Details are in [BUILD](../../../pipeline/BUILD.md#freedom-in-the-layout-2026-11-06) and the [review](../../../pipeline/reviews/2026-11-06-build-freedom.md).

1. Done. Authored scenery is movable (the square's layout now covers the whole square). Lamps keep their ids, programs and lights, and collision moves with them. Scenery is never deleted.
2. Done. Garden wall, balustrade and iron railing, drawn along cell edges by drag or two clicks, with piers joining corners and T-junctions. Height variants and hedges are not built.
3. Done. Seven Town paints: the square's own flags and cobbles, setts, brick, gravel, bed and lawn. Paving has straight edges, and planted or loose ground gets kerbs.
4. Partly done. Code reads all doodads, scenery included, and can `move_to` and `face` them under the mouse's rules. Studio policy grants this. On/off capabilities for simple objects need mechanism pivots authored into the models and are not built.
