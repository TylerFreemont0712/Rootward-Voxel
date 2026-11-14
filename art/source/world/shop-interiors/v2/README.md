# Market shops, second pass (2026-11-12)

The user found Morning Loaf, The Pantry and Finch & Thread "very bare bones" and asked for detailed, lavish interiors with new pieces of furniture, each shop distinct, the shop windows outside dressed with features of their own, and no low-quality assets. This pack is that pass. The [review](../../../../../pipeline/reviews/2026-11-12-market-shops.md) shows the result in the running game.

## What is here

| File | What it records |
| --- | --- |
| `interior_kit.py` | Shared helpers, imported by the records below. It adds:<ul><li>a palette atlas, so a piece of forty colours still exports a handful of materials;</li><li>painted surfaces;</li><li>turned (`lathe`), swept (`tube`, `torus`) and draped (`sheet`) forms;</li><li>panels, legs, cornices and room-shell builders;</li><li>lettering in the game's Cinzel and Alegreya faces;</li><li>`attach()`, for deliberate edits of saved masters.</li></ul> |
| `goods.py` | Small goods: bread and pastry, fruit and vegetables, flowers, cloth. |
| `author_bakery.py` | Morning Loaf: its room shell (v2) and fourteen pieces. |
| `author_greengrocer.py` | The Pantry: its room shell (v2) and fifteen pieces. |
| `author_tailor.py` | Finch & Thread: its room shell (v2) and sixteen pieces. |
| `revise_fronts.py` | A deliberate edit of the three storefront masters, from v2 to v3. |
| `register.py` | The `pipeline/world-catalog.json` entries for everything above. |
| `layout_rooms.py` | The one-time layout of room documents version 4, with v3 kept in `content/areas/archive/`. |
| `textures/` | Pictures packed into the masters. Each authoring run re-paints them identically:<ul><li>`shops-palette.png`;</li><li>painted metro tile, marble, regency stripe, rug and gingham;</li><li>256-pixel reductions of the native detail paintings.</li></ul> |

Every authoring record refuses an existing master. The one exception is a re-run with `--redo` when the master is still byte-identical to what that record saved, so human edits are never overwritten. Once you change a master in Blender, it is the authority: rebuild it with `scripts/world-art.sh build <id>`.

## The shops

| | Morning Loaf (Ada Kettering) | The Pantry (Teo Vasko, minded by Tessa) | Finch & Thread (Gret Finch) |
|---|---|---|---|
| Colours | Oxblood joinery, white metro tile with an oxblood glazed border, limewash, terracotta floor, copper and brass | Bottle-green painted boards, sage sprig paper, limestone flags, oak, zinc and wicker | Navy panelling with gilt lines, rose regency stripe, herringbone oak, a knotted rug, wine and teal velvet |
| New pieces | `bakery-bread-wall`, `-cake-table`, `-proving-cabinet`, `-mixer`, `-cooling-rack`, `-cafe-table`, `-dresser`, `-pretzel-stand`, `-gift-stand`, `-pendant` | `greengrocer-bin-wall`, `-barrels`, `-dairy`, `-barrow`, `-flower-stand`, `-squash-pallet`, `-crate-stack`, `-basket-table`, `-platform-scale`, `-basket-stack`, `-pendant` | `tailor-dress-form-gown`, `-dress-form-suit`, `-fitting-room`, `-order-rail`, `-hat-stand`, `-counter`, `-settee`, `-pressing`, `-rug`, `-chandelier` |
| New versions of existing ids | `bakery-shell`, `-oven`, `-counter`, `-proving-table`, `-flour-sacks` | `greengrocer-shell`, `-produce-stand`, `-counter`, `-jar-shelves`, `-sack-row` | `tailor-shell`, `-cloth-shelves`, `-spool-wall`, `-cutting-table`, `-dress-form`, `-sewing-table`, `-mirror` |
| Storefront (v3) | <ul><li>Cream and oxblood awning</li><li>Bracket sign with a gilt pretzel</li><li>Geranium window boxes</li><li>Stepped windows: wedding cake, tarts, a pretzel garland, baguettes</li></ul> | <ul><li>Green and cream awning</li><li>A ledge of crates under the big window</li><li>Hanging baskets, a bucket of sunflowers</li><li>Windows: raked crates, jam jars, onion strings</li></ul> | <ul><li>Scalloped navy valance with gilt fringe</li><li>Bracket sign with gilt shears</li><li>Topiary in navy tubs</li><li>Windows: velvet backdrops, the gown, a tailcoat and top hat</li></ul> |

Every window has real glass and gold-leaf lettering on it. The joinery now carries the shop's own colour, and the door inside the room matches it.

## Conventions kept

- **Room shells:** the cutaway is still 12 × 12 and the shop's door is still at x 6, hinged on `door_leaf_<shop>`. The square's door links and the save's room ids are therefore unchanged.
- **Fixture ids:** the lamps a save or quest can hold keep their ids: `shop-pendant-1` and `-2`, `oven-fire` and `sewing-lamp`. The bakery and the tailor gain `shop-pendant-3` and `-4`. Fixtures keep lamp glass as one mesh, so the game's fixture binding finds it.
- **Outlines:** pieces are outlined (`illustrated_edges`). Small parts use the palette's `_fine` materials, and metal and glass carry no ink hull.
- **Shadows:** pendants, chandeliers and the rug are `casts_shadow: false`.
- **Pavement:** nothing on a storefront stands more than 0.25 m in front of the wall, because the pavement cells in front are the door approach.
- **Layering:** surfaces stacked on each other stand at least 4 mm apart. `test_coplanar` holds the storefronts to its existing allowance. All but one interior piece pass the same check at a stricter 0.05 m²; the bakery shell keeps 0.06 m², behind the station clock's face.
- **Retired piece:** `bakery-bread-rack` (v1) is now `retained_previous_concept`, superseded by the bread wall. All v1 masters and the v2 storefronts stay on disk.

No runtime dependency on Blender. The fonts are the game's own (`ui/fonts/`, OFL; see CREDITS.md).
