# World assets, houses and materials

Use this for props, trees, buildings, bridge parts and surfaces. The world uses ordinary 3D geometry with a voxel-inspired appearance; making an object programmable does not require a voxel-volume engine.

The fifteen reusable textures and saved builder finishes are documented in [Materials](MATERIALS.md). `world-catalog.json` binds audited material names on 90 models to supported parts. Instance overrides give each building or furnishing its own finish while retaining its geometry, collision and working parts.

## Requests, delivery and deletion

The title’s Asset Showcase (Dev) offers Request update, Request new, Delete, a request browser and an independent Finished filter. Read [asset-requests/README.md](../asset-requests/README.md) for the agent lifecycle. Each request retains user notes, selected reference assets, catalog/source/runtime/manifest paths, area/content usage and source-pack links. `finish` requires a current normal build manifest and a review, and stores the delivered hashes. Changed results cannot be accepted. Deletion removes exclusive source/runtime directories and the catalog entry after rechecking a dependency-bound plan; referenced/shared assets become removal requests to resolve first. The queue does not replace the existing builders or make Blender/AI a gameplay dependency.

## Choose and record the source

The [Sparks foliage pass](reviews/2026-10-30-plant-style.md) replaces rounded plant placeholders in 35 existing masters with pointed leaves, branching sprigs and petalled flowers. Each source retains its pre-edit backup and `plant-style.json`; the [source pack](../art/source/world/plant-style/v1/README.md) records the edit and preservation audit. Edit these saved masters and use the normal world build. The packed four/five-row house palettes and non-botanical uses of their colours are preserved.

The six square robots now select individual `robot-<name>/v2/model.blend` masters. Their [source contract](../art/source/world/sparks-robot-refinement/v1/README.md) records detailed native revisions and packed enamel bakes. Pip's latest approved design omits the bag and carries parcels in real front cubbies. Catalog `spark_blink` adds `RobotBlink` to instances: only eye meshes tagged `blink_eyes` compress briefly. `WorldAssetMeta` reads Blender custom fields from Godot's imported `extras`; drive-wheel nodes retain local-X pivots and an authored `wheel_radius` used by `LaneStage`. These are presentation details, never movement/collision rules. Original v1 models and concept/movement PNGs remain intact. [Model gallery](../docs/concept/v0.72/robot-model-refinement.md).

The [Sparks loft furniture pack](../art/source/world/sparks-loft/v1/README.md) supplies fourteen bespoke room models with packed painted surfaces and fine sepia outlines. They are selected only by `workshop-loft.json`; its furniture rectangles own collision. The existing shell is deliberately refined with its prior master preserved. Reader and Hotaru keep their semantic moving/window parts. Edit the saved masters and use the regular world build; generic retexturing would replace their bespoke finish.



`world-catalog.json` may select area-specific presentation variants through `areas.<id>.presentation.assets`, and a `post_lamp`. `WorldView` resolves these for normal models and proposal ghosts; core data continues to use the original asset’s collision and door contract. A variant must therefore keep those contracts compatible. The new standalone models are also available on the studio shelf with their own catalog entries.

`illustrated_edges` adds a rendering-only back-face hull with welded-position normals and a thin sepia shader. It leaves original mesh/material resources intact, follows each mesh’s own transform, scales line width with the viewport, and casts no shadow. Light panes and transparent/emissive effects are excluded. The retained Rootward cutaway is separate. `painted_glow` preserves the square lamp’s authored amber gradient when lit; the ordinary lamp metadata still controls Preview/Apply/Undo, halos and pooled lights.

Outline and house-material caches hold weak references, so shared resources survive while live instances need them and release after leaving a district. Incremental area preparation holds strong resources only through construction; `WorldAssets.finish_area()` releases preparation references and prunes expired cache entries. Static authored placements apply their house appearance before outlining and discard hidden `detail_*` / `alt_*` branches, preserving semantic lamp emitters. The showcase and editable buildings retain complete variants for later changes. This changes runtime instances only; adopted GLBs/Blender sources, visible geometry, light bindings and area collision remain authoritative. [Memory/desktop review](reviews/2026-11-05-memory-and-desktop-graphics.md).

The building pass deliberately edits the eight current shells and lamp, preserving source backups. It adds two adopted shop masters. Use their saved Blender sources and the normal build; historical source-edit scripts are not replacement seeders.



`pipeline/world-catalog.json` records per-asset authority. Use procedural Godot geometry for a changing prototype test; once adopted, edit the `.blend` and export its GLB. The old maker remains a seed/reference, not a second master to regenerate over human changes. The game uses selected GLBs without Blender running or installed.

## Make one asset deliberately

1. Copy [the asset brief](templates/asset-brief.md). State the ID, purpose, source/version, dimensions, pivot, forward direction, visible overhang, blocking footprint, shared materials, variants and moving parts.
2. Establish its silhouette beside the existing player and house at the normal camera. One cell is one world unit. Keep chunky, warm fantasy forms: substantial timber, cream plaster, pale foundations, violet/teal roof tiles and warm windows.
3. If testing a shape in code, follow the existing `_make_house` and `_make_tree` recipes, or `pipeline/world_recipes.gd` (the cabin and lamppost: plain functions that take a `block` callable, so they do not grow the runtime view). Review it with `tools/asset_shot.gd -- <id> <png> recipe` at zoom 13 (gameplay) and closer, beside the character. Static decorative blocks batch by material; moving/stateful parts remain identifiable. Placements and footprints live in the area document (`content/areas/<id>.json`); lesson mechanisms are built in `art/mechanism_builder.gd`, and library prop states are presented by `art/prop_visual.gd`.
4. When the test is ready for visual editing, seed/init one new version through the documented handoff. For a model authored directly in Blender, a code seed is optional: save the versioned `.blend`, register it in the catalog and use `build`.
5. Export and review the result in Godot. Test a second instance/variant and one source rebuild before calling the asset reusable. A catalog entry alone does not place a new object: add a `buildings` entry (asset, position, facing, scale) to an area document, and its solid footprint comes from the catalog. For a builder prop, register its `kind: prop` item in `content/build/catalog.json`; the player's saved edits provide placements.

## A stateful model keeps its changing part separate

A model that the game must change keeps that part as its own mesh with its own material, found by **material name**, never by node path. The lamppost's lantern glass is `lamp_glass`: `MechanismBuilder` finds it, swaps in the lit material when the lamp is lit (and back to the model's own when it is dark), and puts the halo and light where the glass is, so the lantern may move in Blender without a code change. A model without that mesh is reported, not silently replaced.



## Shape, collision and behavior are separate

A tree crown can cover several cells while only its trunk blocks movement. A roof overhang does not become an invisible wall. A decorative bench does not automatically gain sitting behavior, and a modeled door does not become enterable.

For any new player-program capability, define its field/command, type, permitted target/range, occupancy/support validation, feedback and meaningful tests in pure rules. Keep NodePaths, meshes and bones out of the player API. An accepted state transition drives the visual result.

Blender changes to a footprint, entrance, bank, path or connection require a matching layout/rule review. Current catalog footprints document the intended contract; `core/` still owns actual traversal. Do not assume an edited mesh has updated pathfinding.

## Detail priorities

| Asset | First forms | Later detail |
|---|---|---|
| Bench | Seat/back/legs, readable approach, ground pivot | Plank seams and softened edges; sitting needs a separate interaction. |
| Tree | Trunk/branches and an irregular full crown | Chunky leaf clusters and a few values; keep trunk and canopy bounds distinct. |
| House | Foundation, walls, roof pitch/eaves, door approach | Tiles, beams, recesses, windows and chimney courses. |
| Gate/bridge | Exact passage, connection dimensions and moving/removable sections | Posts, braces, planks and state feedback. |
| Lamppost | Post, arm, lantern with its own glass, pedestal; the arm points +Z | A chain and hook, a planter and shrub if requested. |
| Flowers, if later requested | One readable clump | Compare small meshes or planes at gameplay size before adding detail. |



## Materials and textures

Generated ground uses [the ground skin](GROUND.md): a mipmapped texture array, R8 half-cell control map and height-biased hard pixel borders. `ground: true` marks paintable catalog entries; `pebbles` and `rock_face` reuse existing pictures. Six authored heights and six reference sheets have prompts/hashes under `art/source/world/ground/v1/`; `scripts/art.sh` rebuilds selected heights. Other procedural surfaces keep triplanar materials; adopted Blender land stays unchanged.

Ground-only catalog additions preserve the exact prior catalog as `compatible_bake_catalog`. The handoff guard verifies its hash against recorded bakes and checks every prior picture/tint/tile/set is unchanged, ignoring only the new `ground` flag. Changed baked recipes still fail validation. No adopted source was rewritten for ground paint.

**Painted pictures.** The delivered texture pack (`assets/world/textures/{solid,lush}/`, 24 materials each; sources, prompts and hashes in `art/source/world/textures/v1/`) is wired in through **`pipeline/texture-catalog.json`**: each shared palette id maps to a picture with a world `tile` size, a brightness `tint`, a `mode` (`world`: repeats every `tile` units; `face`: one pane per face for glass and glow; `cells`: each face shows one painted cell of an n×n picture, for roof tiles) and optional `emission`. `art/world_textures.gd` reads it. Procedural geometry (ground, trees, fences, walls, decks, the wheel) gets world-space triplanar materials from `art/surface_materials.gd`, so a tile is the same size everywhere and lines up across every block; the `lush` set is selected by the catalog's `set`. Keep triplanar sharpness low (4): Godot weights projections by instance scale and a high value turns thin slabs black.

**Baking into a Blender source.** `scripts/world-art.sh retexture <id>` (`pipeline/blender_retexture.py`) rewrites an adopted source's materials and UVs from the catalog (planar world-scale UVs per face, so a 0.2 log course shows one row of the log picture) and never touches geometry. It keeps `model.pre-retexture.blend` beside the source, writes `retexture.json` with the catalog's hash, and is followed by `build`. `test/test_pipeline_handoff.py` fails if a baked asset's hash differs from the catalog, so a catalog edit cannot silently leave a model on old pictures. Run `compare` (the unedited round-trip proof) **before** `retexture`: afterwards the model deliberately differs from its seed. Done for the cottage, mill-house, clearing-ground, log-cabin, log-cabin-large, log-cabin-large-teal and lamppost; the unselected `tree` reference is not baked.


The seed kit uses `art/world_palette.gd` for colours; any palette id without a painted picture falls back to a deterministic 64×64 mipmapped recipe in `art/surface_materials.gd`. Adopted models carry their exported material/texture data; changes to a seed recipe or to the texture catalog do not silently recolor an artist-owned `.blend` (use `retexture`).

Keep a small coherent material set. Authoring textures should have a versioned source, prompt/tool/manual-edit record, intended resolution, tiling/UV scale, alpha use and pinned import choices. Review stretching, seams, distant shimmer and color beside the existing kit. Texture resolution does not define world size.

Use materials that survive glTF or deliberately bake/recreate the required surface. Animated water and other Godot ShaderMaterials remain engine effects. Keep independently moving parts separate with meaningful pivots. The initial building shells group geometry by role/material for editing; they are not yet a general modular-building/interior system.

## Extending the library

Extend the current catalog with validated permitted rotations, variants and interactive-part definitions as concrete assets need them. Move instance IDs/placements/initial state into a shared area document when proving a second area. Validate unknown IDs, bounds, footprint rotation, overlap, support and approaches. A future editor should consume those same definitions rather than maintain a separate map truth.

Use [review](REVIEW.md) and [area authoring](AREAS.md). Keep the prototype standalone and runnable at every handoff.

## Explicit building collision envelopes

A building asset may define `collision_rects`, up to sixteen `[min_x, min_y, width, height]` rectangles in its local S-facing **logical** frame (front is negative y). `AreaDef` validates and rotates/scales them into plain rectangles; `LabWorld` uses them instead of the default whole placement rectangle for standing and passages. They are separate from roofs/visual overhangs and do not come from runtime mesh bounds. The Concept Cottage uses three rectangles to cover its low log/foundation edges while preserving a central entry recess and its existing placement footprint/doorstep. See the doorway review and `test/test_doorway_boundaries.gd`.




## Rootward Square as a town centre — 2026-10-29

A second pass on the hub ([square-hub pack](../art/source/world/square-hub/v1/README.md)).

- **Shops instead of the terrace:** `haverlund-bakery`, `haverlund-greengrocer`, `haverlund-tailor` and `haverlund-cafe` are separate shop-houses, built from one shopfront recipe in the seaside house kit (`author_shops.py`). `square-west-terrace` is now `retained_previous_concept`.
- **Street furniture:** two records, `author_street.py` and `author_square_life.py`, add sixteen small masters:
  - `town-power-pillar`, `rootwell-plaza`, `town-kiosk`, `town-fountain`, `town-bollard`, `town-bin`, `town-parasol-table`, `town-lawn`, `town-tree-grate`;
  - `town-festoon`, `town-signpost`, `town-planter-bench`, `town-bollard-light`, `town-poster-column`, `town-coffee-cart`, `town-bike-rack`.
- **Power pillars:** the retaining walls' carved pilasters are gone from both grounds. Each is now a placed `town-power-pillar`: one glass shaft 1.12 m across, wrapping round its sides, held by slim brass rails and hoops. Its glass carries the `power_column` extra, and `WorldAssets.light_power` gives it `art/power_column.gdshader`, where pulses of light climb the column. The older `power_pillar` carved shader stays for any model that still uses it.
- **The Rootwell:** it is placed at 1.35 scale. A deliberate source edit (`art/source/world/rootwell/v1/conduits_revision.py`) runs `power_grid` conduits up its four flights to the drum. `rootwell-plaza` carries them across the wider ring to the square's channels.
- **Doors that open:** `lane-workshop` and `workshop-shop-doors` have hinged `door_leaf*` parts with a `swing` extra. `scenes/door_swing.gd` swings them when a room link names them in `doors`; see [Areas](AREAS.md#walking-through-a-scene-change).
- **Lit parts that are not lamps:** festoon bulbs and the bollard bands use their own emissive `festoon_glass`, so they are always lit and the game never treats them as lamps to tend.

See the [review](reviews/2026-10-29-square-city-centre.md).

## Rootward Square v3 and the town round Spindle Lane — 2026-10-29

The square was rebuilt from scratch as the town's hub, made of separate pieces on one base ground ([square-hub pack](../art/source/world/square-hub/v1/README.md)).

- **New masters:**
  - `haverlund-square-ground`;
  - the buildings `haverlund-post-office`, `haverlund-fruit-market` and `haverlund-bank`;
  - eleven modular edge pieces: `town-balustrade(-short)`, `town-balustrade-pier`, `town-railing(-short)`, `town-railing-stair`, `town-railing-post`, `town-garden-wall(-short)`, `town-garden-pier` and `town-garden-gate`;
  - `haverlund-lane-surround`, which joins Spindle Lane into the town without touching its set.
- **Placement:** the area documents lay railings and walls out bay by bay, with one pier or post per joint, and place the five modular seaside houses with per-placement looks.
- **Retired:** `guildhall-square-set`, `square-beacon` and `square-post-office` are now `retained_previous_concept`.
- **Size limits:** the model envelope is ±128 units and areas may be up to 160 cells a side.

See the [review](reviews/2026-10-29-square-hub-v3.md).

## The Rootwell — 2026-10-29

The square's headpiece, `rootwell-beacon`, is a new editable master after the approved [Rootwell paintings](../docs/concept/v0.72/rootwell-beacon.md), built with the seaside house kit plus its own verdigris, brass, amber glass and root materials ([source pack](../art/source/world/rootwell/v1/README.md)). It was first catalogued `showcase_only`; it now stands at the centre of Rootward Square (`integrated_sparks_square`), and `square-beacon` is retired. Parts that story may move later are separate nodes on their own axes, listed in the catalog's `story_parts`: the gauge needle, the maintenance door, six valve wheels, the root and the chamber light. The light is an inward-facing shell, so the root stands against it from any side. See the [review](reviews/2026-10-29-rootwell-headpiece.md).

## Modular seaside houses — 2026-10-29

Background houses are now standalone, reusable models rather than parts of a set. The [seaside house pack](../art/source/world/seaside-houses/v1/README.md) adds five editable masters after the v0.72 concepts: `seaside-lantern-row-house` (D), `seaside-saltwind-house` (E), `seaside-rosewash-house` (F), `seaside-shingle-court-cottage` (G) and `seaside-eaveside-terrace` (H, two joined homes), painted with the seaside texture pack and built from one shared kit (`house_kit.py`). Each is catalogued `showcase_only`: it appears in Asset Showcase (Dev) and is placed in no area. Neither carries paving; streets and yards are separate pieces.

A catalog entry's `variants` block names what a placement may vary: each surface family's painting (`seaside_<family>` materials, plus `_2` slots for a joined building's second home; three colours each from `assets/world/textures/seaside-houses/detail/`), optional dressing (`detail_<name>` nodes) and alternatives (`alt_<group>_<option>`). `HouseVariants` (art/house_variants.gd) applies a look to one instance without touching the shared imported materials, picks a deterministic look from a seed, or recolours with one of the library's three curated palettes. `WorldAssets.instantiate(id, cache, variant)` always shows one complete look, the authored one by default; assets without `variants` are unaffected. In the showcase, **Look**, **Shuffle** and **Street of three** present them. Variety is presentation only: footprint, collision and doors stay those of the model. Area placements do not yet carry a variant. See the [review](reviews/2026-10-29-modular-background-houses.md).

## Guildhall Square — 2026-10-29

The square was rebuilt after the selected Guildhall Square concept. The [v2 source pack](../art/source/world/sparks-square/v2/README.md) registers sixteen new editable masters: `guildhall-square-set` (the square and the town round it in area coordinates), `square-beacon`, `square-guildhall`, `square-post-office`, `square-west-terrace`, `square-banner-lamp`, `square-flower-stall`, `square-fruit-stall`, `square-tree-planter`, `square-timber-store` and the robots `robot-pip`, `robot-trowel`, `robot-wick`, `robot-heron`, `robot-tender` and `robot-tally`. They reuse the lane pack's palette and painted surfaces. A robot's wheels are separate `wheel*` nodes on their axles; a banner lamp's banner is `cloth_banner` and its lantern `lamp_glass`. The audit's ±64-unit bound applies to the set too, so its far ground stops at x 62. The first square's set, Rootwell, town hall and shopfronts are kept as `retained_previous_concept`. See the [review](reviews/2026-10-29-guildhall-square.md).

## Downhill square (first pass) — 2026-10-29

The [square source pack](../art/source/world/sparks-square/v1/README.md) registers ten new editable masters: `haverlund-square-set`, `square-rootwell`, `square-town-hall`, three shopfronts (`square-bakery`, `square-bookshop`, `square-grocer`), `square-market-stall`, `square-cafe-table`, `square-delivery-robot` and `square-node`. The source pack borrows the lane’s packed painted materials and preserves its fine outline system. Glass and reflections stay clear of silhouette hulls. The service pedestal’s glass and indicator remain named separately. The Rootwell’s wheel/dial presentation is scenery until its future quest gives it rules; model geometry grants no capability. Existing lane props are reused without reauthoring. The gate is a deliberate backed-up edit of `haverlund-lane-set`; export it with the usual world build.

The 2026-10-29 loft request pass removed the shoes beside `loft-luggage` and added two small posters to `loft-wardrobe`'s closed door. Both are edits to their adopted masters and normal audited exports; see the [review](reviews/2026-10-29-loft-asset-requests.md).

The old `square-delivery-robot` was deleted at the user's request; the square porter uses another `robot-pip` instance. The distinct `lane-notice-board` remains in use. See the [removal review](reviews/2026-10-29-postal-worker-removal.md).

Robot names such as Pip identify reusable models; multiple instances can appear in the world. A distinctive named robot can have its own modified appearance.



The [city power grid](reviews/2026-10-29-city-power-grid.md) updates `haverlund-square-ground` and `haverlund-lane-set` in their adopted Blender masters. Tagged strips use `art/power_grid.gdshader` for a cosmetic moving amber pulse; they do not add power gameplay or collision. Lower-town paving replaces scattered grass patches, and Spindle Lane uses ground strips in place of its overhead wire and poles.

The [integrated conduit revision](reviews/2026-10-29-integrated-power-conduits.md) supersedes the flat strips: the square, lane and lane surround use recessed framed panes, surveyed stairs and threshold feeds. Existing pilasters receive a stone-based glowing carving; separate wall stripes are removed. The editable source record is under `art/source/world/city-power-grid/v2/`.

## City clock and public lobby — 2026-11-02

The adopted `square-guildhall` master has deliberate, preserved-source revisions in `art/source/world/civic-cycle/v1/`: the obstructing outside counter/contents and static open leaves are removed, two panelled oak leaves have common `door_leaf` / `swing` metadata, and the two original clock hands are separated on the dial centre. `CityInstruments` rotates those hands from the saved shared clock. The façade, arch, stairs, paint, lanterns and windows remain authored geometry.

The same source pack creates three new saved masters: `city-hall-shell`, `city-hall-help-desk` and `city-hall-job-desk`. These use the existing painted limestone/oak civic palette, with a 28×22 cutaway lobby, tall windows, inlaid runner and separate enquiries/public-works counters. Approved shelf, bench, plant, pendant, board and door assets furnish the room through area placements. Subsequent edits use their saved masters and `scripts/world-art.sh build`, not initial authoring.

`rootwell-beacon` retains its original moving needle at the original pivot/calibration (1.3). Its old low-side red patch is moved to 9–10 and additional green (0–8) and amber (8–9) sectors sit behind the needle. The game displays actual pressure through 15 on the loading instrument, while the physical face ends at 10 and flutters above that stop. Backups and source hashes are beside both revised masters. The review records native resolution checks and full pipeline validation.

The square’s `town-festoon` / `town-bollard-light` bulbs now participate in mapped fixtures through their existing `festoon_glass`, superseding the earlier always-lit presentation. All placed banner/lane street lamps, the hall’s built-in entrance lanterns, loft desk/bedside lamps, shop and Rootwell lanterns, surrounding house lanterns and civic pendants likewise have logical state and slate access. The 148 logical fittings use local approaches or district service screens; hidden optional lantern geometry does not emit detached halos. `lamp_glass` and `festoon_glass` remain authored material names; no mesh path determines gameplay. Conduit and power-column shaders use a shared presentation supply multiplier fed by the trusted city state.

## Square renewal — 2026-11-03

The [source record](../art/source/world/square-renewal/v1/README.md) describes preserved-version storefront revisions, the new clockmaker/apothecary, reusable shop shell, clock display and retaining-wall module. The bakery, food shop and clothier keep their original IDs for compatibility; `haverlund-tailor` now presents Finch & Thread. Existing modular town barriers now have catalog footprints and studio shelf entries. One straight retaining-wall bay is modular; specialized terrain walls and stair cheeks remain part of the spatially sectioned ground source.

Square ground sections use local bounds (4 m near the playable town, 16 m far away), preserving existing UVs and finishes. Repeated immutable railing/wall bays share local 8 m MultiMeshes in the view; placement roots and pure collision remain independent. Flat painted ground tops skip redundant silhouette hulls. The renderer caches the world catalog until its modification time changes instead of reparsing it for every placement.

Every ordinary lamp now owns a fixed `FixtureLight`; mapped fittings retain theirs and no longer receive duplicate camera-selected lights. Main square lamps use 7 m range/1.65 energy. The square has 66 logical fittings, down from 115; small path-light models and their fittings are removed. Actual light, glass and halos follow committed state and supply loss. Most local lights remain shadowless to bound rendering cost; the authored directional shadow system remains. Day/night relays remain editable through the existing slate. New shop lamps ship with dusk relays. See the [measured review](reviews/2026-11-03-square-lighting-and-shops.md).

## Spindle Walk layout and concept-only replacements — 2026-11-03

The user rejected the temporary clockmaker/apothecary reskins. They are now unplaced retained concepts; two original imagegen design sheets and exact prompts live in [spindle-strip/v1](../art/source/world/spindle-strip/v1/README.md). These PNGs are references, with no runtime selection. New building models and interior furniture will be authored after review. The five existing shop rooms are cleared of loose furniture/stock.

`haverlund-square-ground/v3/model.blend` deliberately revises the landing, park and promenade from preserved v2, with local 4 m sections and the existing packed materials. Its normal audited build remains authoritative. Source records in the same pack describe the terrain cut, masonry finish and frontage alignment. Existing market buildings, Rootwell and the fixed real-light system retain their preceding asset versions.

For tightly nested authored details, a mesh may set Blender custom property **`illustrated_edges = false`**. The imported extras suppress the expanded ink hull on that mesh only; modeled rims and the rest of the asset retain their appearance. Use this for fine clockwork or roof plates where an extra silhouette would overlap adjacent surfaces. Lamp glass, ordinary glazing and opaque backing panes must remain separate meshes when a fixture uses a material override.

## Market shops, second pass — 2026-11-12

Morning Loaf, The Pantry and Finch & Thread are furnished again, at the clockmaker's level of detail or above, from the [shop-interiors v2 source pack](../art/source/world/shop-interiors/v2/README.md).

- **Masters:** 48 masters (31 new ids, 17 new versions) and three storefronts at v3. The storefronts have:
  - deepened, dressed windows behind real glass, with gilt lettering;
  - each shop's own joinery colour;
  - an awning or valance, window boxes or crates, hanging baskets and bracket signs.
- **Shared kit:** the pieces share `interior_kit.py`. Plain colours are cells of one palette atlas, with `_fine` materials for small parts that must not grow an ink outline. Painted surfaces are either reductions of the detail library or deterministic paintings (metro tile, marble, regency stripe, rug, gingham).
- **Kit helpers:**
  - turned, swept and draped forms;
  - an `attach()` for deliberate edits of saved masters;
  - `--redo`, which is refused unless the master is byte-identical to the record's own output.
- **Fixtures:** keep one lamp-glass mesh each. Pendants, chandeliers and the rug set `casts_shadow: false`.

Room documents are version 4 (v3 archived). See the [review](reviews/2026-11-12-market-shops.md).
