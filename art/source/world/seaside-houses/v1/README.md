# Modular seaside houses

Standalone background houses for dressing the seaside town one finished house at a time, instead of modelling each street as one set. They follow the [five background-house concepts](../../../../../docs/concept/v0.72/background-houses.md) and are painted with the [seaside house texture pack](../../../../../docs/concept/v0.72/house-textures.md).

| Master | Concept | What it is |
|---|---|---|
| `seaside-rosewash-house` | F | A compact two-storey family home with a loft: limestone ground floor with a plank door, lantern and shuttered window; an oak bressummer on carved brackets carrying a jettied rose-limewashed upper floor; a steep pan-tiled gable roof with bargeboards, an off-centre front dormer, a small back dormer and an attic vent; a brick chimney. Behind: a tiled porch over the kitchen door, closed to the east with a framed board wall and to the west by a little gate; a log store; a washing line on a T-pole. |
| `seaside-lantern-row-house` | D | A tall, narrow lodging house of four storeys and an attic: a limestone ground floor with an arched plank door, three limewashed floors in an oak frame with two shuttered windows each, plain side walls with one small window a floor, a steep street-facing gable with a shuttered attic window, a dormer on the side slope and a brick chimney. Behind: a low pantry lean-to, the kitchen door and washing from the top floor. |
| `seaside-saltwind-house` | E | A broad three-storey apartment house of three bays: dressed limestone ground floor, ochre limewash above with quoins, string courses and a cornice, worn patches showing brick; a panelled front door with a fanlight under a stone hood on consoles; a low hipped deep-teal roof with terracotta hips and two chimneys. Behind: an arched plank kitchen door and a terracotta-roofed laundry alcove with a stone wash trough, baskets, a barrel and washing; a second line on an upper window. |

| `seaside-shingle-court-cottage` | G | A low, wide courtyard cottage: one storey of limestone under a broad roof with two dormers to each slope, a tiled hood over the front door, shuttered windows with flower boxes, attic lights in both gables and a stone chimney. Optional: a tall plank courtyard gate between piers under a little tiled pergola with climbing roses. Behind: a covered kitchen stoop with a work table, pots and washing. |
| `seaside-eaveside-terrace` | H | Two joined homes as one cluster. West: three limewashed storeys and an attic under a steep street-facing terracotta gable, oak floor beams, quoins and an arched door. East: two ochre storeys under a hipped deep-teal roof with terracotta hips and a dormer, a door under a terracotta hood and a bench. Behind: a wash house with its own door, a stone sink and a washing line on posts. Each home paints its own plaster, roof, ridge tiles and shutters. |

None is placed in any area. All appear in the title's **Asset Showcase (Dev)**. None carries paving: sidewalks and yards are separate pieces, so each house stands straight on whatever ground it is placed on.

## Records

- `house_kit.py`: the shared, reusable kit. Textured walls with lined openings, quoins, bands, dressed surrounds, casement windows (painted pane with lace curtains, sash and bars, braced board shutters open or drawn, flower boxes), plank and panelled doors (arched, fanlight, stone hood), pan-tiled roofs (gable, hip, lean-to, dormer) built as stepped courses whose painted tile band matches each step, scalloped eave mouths, ridge, hip and verge caps, gutters and downpipes, chimneys, lanterns and yard dressing (pots, barrels, climbers, laundry, log stores, baskets, crates).
- The kit also builds the [Rootwell](../../rootwell/v1/README.md). Its material lookup takes a record's own full material name first (the Rootwell's `lamp_glass`), then a surface slot, then a house colour.
- `author_houses.py` (E, F) and `author_houses_dgh.py` (D, G, H): guarded one-time authoring. Each refuses an existing master. `-- --draft DIR` writes review drafts outside `art/source`.
- A gable that faces the street (D and H's west home) is built with the kit's ridge-along-X roof inside `parts.turned(-90)`, a frame turned a quarter so the gable built at +X becomes the front. Paintings are mapped before the turn, so they follow the pieces.

While the design was being settled on 2026-10-29, before the user's review, the masters were re-authored from these records twice more: to remove the paving apron at the user's request, and to gather the plain colours into one palette material (same geometry, a third of the draw calls). From now on each `model.blend` is the editable authority: open it, edit it, and export with `scripts/world-art.sh build <id>`. A further house type should get its own recipe in a new authoring record that imports this kit.

## Conventions the game relies on

- **One material per surface family**: `seaside_plaster`, `seaside_roof`, `seaside_ridge`, `seaside_stone`, `seaside_timber`, `seaside_shutter`. A joined building's second home has its own slots ending `_2` (H: `seaside_plaster_2`, `seaside_roof_2`, `seaside_ridge_2`, `seaside_shutter_2`); stone and timber are shared. Each starts with its authored painting from `assets/world/textures/seaside-houses/detail/` (512-pixel builds of the pack, made by `scripts/art.sh`). `HouseVariants` swaps a family's painting per placed house. Keep these names when editing; rename one only with its `variants.surfaces` entry in `pipeline/world-catalog.json`.
- **Optional dressing** is one object per group named `detail_<name>` (window boxes, planters, vines, yard, wood store, laundry, Shingle Court's garden gate). **Alternatives** are `alt_<group>_<option>` (chimney brick/stone, shutters open/drawn, Saltwind's front door oak/painted); the first option listed in the catalog is the authored one. Glass in a group sits in `<name>_glass`. The catalog's `variants` block lists them all and `test/test_house_variants.gd` checks they exist.
- Every plain colour (ironwork, sashes, pots, leaves, blossom, linen, rope…) is a 16-pixel cell of `house-palette.png`, written by the kit, so all plain-coloured parts share one material, `house_paint`. Glass panes use the lane's painted window picture; lantern glass is `house_lamp_glass`; chimneys may use `house_brick`. Everything else is static and joined by material. A house is 26–36 surfaces in all, alternatives included.
- Paint repeats are fixed in world units so painted tiles, blocks and boards keep one size on every house: plaster 2.0, roof 1.75 (seven pan tiles; a course is 0.38 along the slope), stone 1.9, timber 1.6, boards 0.8, brick 0.75.

## Size

| | Walls | Height | Triangles |
|---|---|---|---|
| Rosewash | 5.4 × 4.6 (upper floor oversails the front by 0.16) | eave 5.55, ridge 8.1, chimney 9.6 | 36,126 |
| Saltwind | 8.6 × 6.0 | eave 8.95, ridge 10.6, chimneys 12.3 | 48,610 |
| Lantern Row | 4.0 × 5.6 | eave 11.0, ridge 13.6, chimney 15.1 | 43,406 |
| Shingle Court | 8.0 × 5.0 (gate 2.3 further east) | eave 2.8, ridge 5.3, chimney 6.7 | 33,992 |
| Eaveside pair | 4.0 × 5.2 and 4.6 × 4.4, joined | eaves 8.2 and 5.5, ridge 10.6, chimney 12.1 | 64,712 |

Ground pivot at the footprint centre, front toward Blender −Y (Godot +Z). See the [review](../../../../../pipeline/reviews/2026-10-29-modular-background-houses.md).
