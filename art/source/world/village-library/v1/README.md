# Village library v1 — authoring records

The 50-object [library guide](../../../../../pipeline/BUILDER_LIBRARY.md) is the human-facing index. This folder records the original deliberate scripted Blender authoring; the individual `art/source/world/hollow-<name>/v1/model.blend` files are now authoritative editable masters.

## Organization

| File | Responsibility |
|---|---|
| `library.json` | Fifty ordered, named designs: identity, recipe, category, footprint, blurb and interaction. Ten designs per category. |
| `furniture.py` | Ten cottage furniture designs, including writing/map desks, dressers, bed and seating. |
| `workshop.py` | Ten craft tools, benches and workshop mechanisms. |
| `market.py` | Ten counters, carts and household wares. |
| `garden.py` | Ten farmyard/garden forms, shelters and growing/drying equipment. |
| `village_magic.py` | Ten village fixtures and restrained magical mechanisms. |
| `modeling.py` | Small faceted geometry helpers and shared materials; batches by semantic part/material. Packs existing lush textures with continuous world-scale face UVs. |
| `author.py` | One-time Blender entry for exactly one design. Refuses an existing master, checks ground/size, writes the master, brief and original dependency hashes. |
| `integrate.py` | Initial registration, standard world-art build/audit, then builder registration, sequentially per id. Refuses conflicting catalog entries and missing registered masters. |

Each design has its own construction function and geometry; these are not fifty recolors. Rounded things use low-sided facets alongside chunky rectangular timber. Geometry stays editable in Blender and moving pieces retain an authored `mechanism` empty as pivot. `state_glow` and `state_flame` material roles are reserved for committed visual state.

## After handoff

For an existing object, edit its saved `.blend`, then run `scripts/world-art.sh build <id>`. Do not rerun an author to repair a missing adopted source; restore the source. Never use `author.py` to regenerate one of the existing fifty. The initialization kit is an authoring record rather than a competing runtime generation path. All fifty supplied masters and checked runtime exports are present.

The original delivery used `python3 art/source/world/village-library/v1/integrate.py <one-id>` one object at a time. That invokes installed Blender only to initialize a new source and delegates export/promotion to the established `scripts/world-art.sh build` command. Its `--all` option processes the same list sequentially and preserves existing source files; rebuilding a normal asset needs only world-art. This kit is not loaded by the game.

Original `provenance.json` files pin the exact author/helper/category/index hashes used at creation. Subsequent intentional master edits have separate journals; the original provenance is retained. The apothecary cabinet includes guarded shelf/bottle refinement scripts, before-edit sources and hash journals beside its master. The exported manifest pins the current source.

See the [visual review](../../../../../pipeline/reviews/2026-10-24-builder-library.md) for gameplay-scale captures, tests and interaction limits. The project plays from supplied assets without Blender or network access.
