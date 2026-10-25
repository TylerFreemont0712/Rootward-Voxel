# Fifty-object village builder library — 2026-10-24

Delivered **50 new objects**, individually authored and exported, in addition to the existing 32 Doodads. The studio builder now contains **95 entries / 82 props**, with ten new pieces each in Furniture, Workshop, Market, Garden and Village & Magic. Sixteen of the new objects have working, saved F/Python interactions. The approved boy, character templates, camera heading/elevation and existing models/textures were preserved.

The [complete index](../BUILDER_LIBRARY.md) lists all fifty, individual briefs, footprints and interactions. The [source guide](../../art/source/world/village-library/v1/README.md) documents the design kit and ordinary editing loop. This review records implementation and observed evidence; later user art acceptance remains a separate decision.

## Art and sources

Each object has a distinct construction function, an editable `art/source/world/hollow-<name>/v1/model.blend`, brief, provenance, world-catalog definition, builder card and audited GLB/manifest. They were initialized and integrated sequentially, one id at a time, through the existing Blender → `scripts/world-art.sh build <id>` → Godot audit. Runtime loading uses those checked exports; the one-time recipes are not a competing runtime generator.

Design follows the village reference: warm chunky timber, cream stone and crockery, aged brass, violet/teal cloth and roofs, small restrained crystal accents. Silhouettes distinguish craft roles: the anvil and vise, a loom's warp and shuttle, pottery turntables, a book press, market canopies, braced carts, a straw skep, hutch, coop, trellis and small shrine. New raster textures were unnecessary; existing lush pictures are packed into the new sources, with a limited shared set of flat cloth/clay/copper/leaf colors. No existing artwork was repainted.

The apothecary cabinet was refined after the first windowed inspection: the upper body became open shelves and the bottle groups moved forward for visibility. The existing new master was edited deliberately; before-edit masters, guarded edit scripts and hash journals remain in its source folder. Its source was exported again using the standard build, and the final furniture scene was rechecked.

All fifty exports have grounded pivots and explicit blocking footprints. They range from **186 to 2,676 triangles**, median **484**; the entire set totals **34,354 triangles**. Geometry batches by material and semantic part. The [catalog audit](../../evidence/builder-library-50/catalog-audit.json) records per-object source/runtime hashes, bounds, footprints, interactions and triangle counts. Every current manifest matches its saved source and output, and every original authoring dependency hash matches. A before/after SHA-256 comparison of **519 pre-existing art files** found **zero changes**.

## Gameplay-scale visual review

Godot 4.7.2, desktop Compatibility renderer, AMD Radeon 680M. Each of the fifty GLBs was rendered individually beside the approved boy at normal zoom **13** and detail zoom **5**, followed by five labelled group scenes at zoom 13. All five group scenes were inspected; the furniture page was refreshed after the cabinet refinements. Category pages show the actual runtime models and lighting.

| Category | Ten individually numbered models |
|---|---|
| Furniture | [Gameplay-scale scene](../../evidence/builder-library-50/furniture.png) |
| Workshop | [Gameplay-scale scene](../../evidence/builder-library-50/workshop.png) |
| Market | [Gameplay-scale scene](../../evidence/builder-library-50/market.png) |
| Garden | [Gameplay-scale scene](../../evidence/builder-library-50/garden.png) |
| Village & Magic | [Gameplay-scale scene](../../evidence/builder-library-50/village-magic.png) |

The actual game was reviewed at **1600×1000** and **1280×720**. The tour loads the full shelf, selects all five new categories, searches across categories, places all sixteen working pieces through the real ledger/controller, checks each actual F prompt and action, runs a real Python notebook proposal, applies and undoes it, then saves and Continues with all sixteen states preserved. Scratch saves leave the player's journey and shipped area unchanged.

| View | Evidence |
|---|---|
| Furniture shelf and model details | [1600×1000](../../evidence/builder-library-50/builder-furniture.png) |
| Village & Magic shelf | [1600×1000](../../evidence/builder-library-50/builder-village-magic.png), [1280×720](../../evidence/builder-library-50/builder-village-magic-1280.png) |
| Cross-category search | [Butter churn search](../../evidence/builder-library-50/builder-search.png) |
| Standing object's id, facing and real Python members | [Chest details at 1280×720](../../evidence/builder-library-50/builder-working-code-1280.png) |
| Python preview with committed state preserved | [Notebook](../../evidence/builder-library-50/python-preview.png), [1280×720](../../evidence/builder-library-50/python-preview-1280.png) |
| Pump droplets and open chest in the valley | [Pump](../../evidence/builder-library-50/hollow-water-pump.png), [chest](../../evidence/builder-library-50/hollow-wayfarers-chest.png) |
| All sixteen active after saved Continue | [Working yard](../../evidence/builder-library-50/working-yard.png) |

The category header scrolls independently and reveals the chosen category; search stays accessible. The standing Code section fits the compact window and uses the actual `prop-N` id. Short animations preserve actual gameplay frames: [bell swing](../../evidence/builder-library-50/bell.webp), [pump and droplets](../../evidence/builder-library-50/pump.webp), and [chest closing/opening](../../evidence/builder-library-50/chest.webp). Review tools and unselected individual/detail frames live under `.cache/builder-library-50/`; selected captures above travel with this project.

## Interaction contract

The sixteen working pieces are the forge, grinding wheel, potter's wheel, spinning wheel, alchemy bench, oven, candle stand, brazier, shard lantern, obelisk, rune stone, bell, lever, pump, chest and shrine. F offers the catalog's on/off verbs within 2.2 cells, with a clear approach; walls and other objects prevent reaching through. Existing conversation/house prompts retain their priority.

`world.prop(id)`, `world.props` and `zone.props` expose known interactive instances. `Prop` has `id`, `asset`, `name`, `zone`, `cell`, `active` and `set_active(bool)`. The existing atomic `set_field` protocol gains one explicitly typed field, `active`. Named districts follow discovery; a prop outside named districts is visible only while nearby. Code can act remotely on known objects, as with lamps.

Run is a proposal; its footprint ghost does not animate the committed model. Apply commits that validated proposal. Undo restores prior active state, and F clears stale proposals. Saving, moving and turning preserve active state; reset deactivates the pieces without removing construction. Legacy saves without a prop-state map default to inactive. Visual animation and glow never change walkability.

`core/prop_interactions.gd` owns manual reach/discovery checks; `core/lab_world.gd` validates writes and snapshots; `sandbox/world_harness.py` adapts the bounded WASI API. `art/prop_visual.gd` only presents state through authored `mechanism` pivots and `state_glow` / `state_flame` materials, duplicated per instance. Pump droplets are a local effect.

## Validation

`scripts/test.sh` passes, including **570 new library checks** and **16 real-game working-prop checks**. The library checks exercise all fifty registrations, source/runtime files, a second rotated placement, blocking collision, saved edit round trips, movement/deletion and undo; all sixteen models' pivot/material contracts; Boolean validation, unknown/hidden targets, extra fields, invalid atomic batches, static footprints, legacy saves and manual range/wall checks; API inference and actual Python/WASI execution. The integration test covers real builder details, F, preview/Apply/Undo, stale-preview invalidation, moving active visuals, save/Continue and reset.

Existing checks also pass: the five-quest teaching arc with real WASI reference solutions, house isolation, expanded-area routes, builder policies/reachability, ground painting, UI/session behavior, art/frame-skin contracts, GLB/source integrity and handoff links. The full run completed **19 suites / 3,271 checks**, exit 0; see the [verification record](../../evidence/builder-library-50/verification.json) and [catalog audit](../../evidence/builder-library-50/catalog-audit.json).

Windowed review commands:

```sh
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/builder_library_review.gd
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/builder_library_tour.gd
VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1280x720 -s res://tools/builder_library_tour.gd -- .cache/builder-library-50/tour-compact
```

## Limits

These are studio-only outdoor props. No indoor furniture editor, tabletop stacking, inventory, crafting economy, live farm animals, automatic mechanism scheduler or bell audio is implemented. The chest opens its lid and the bell swings; the pump emits visual water without changing terrain. All fifty retain fixed ground footprints. Nothing is auto-placed into the authored valley. Existing homes, residents, lesson coordinates, textures and approved character artwork remain intact. The game needs no Blender, network service or authoring provider at runtime.
