# World assets, houses and materials

Use this for props, trees, buildings, bridge parts and surfaces. The world uses ordinary 3D geometry with a voxel-inspired appearance; making an object programmable does not require a voxel-volume engine.

The fifteen reusable textures and saved builder finishes are documented in [Materials](MATERIALS.md). `world-catalog.json` binds audited material names on 90 models to supported parts. Instance overrides give each building or furnishing its own finish while retaining its geometry, collision and working parts.

## Requests, delivery and deletion

The title’s Asset Showcase (Dev) offers Request update, Request new, Delete, a request browser and an independent Finished filter. Read [asset-requests/README.md](../asset-requests/README.md) for the agent lifecycle. Each request retains user notes, selected reference assets, catalog/source/runtime/manifest paths, area/content usage and source-pack links. `finish` requires a current normal build manifest and a review, and stores the delivered hashes. Changed results cannot be accepted. Deletion removes exclusive source/runtime directories and the catalog entry after rechecking a dependency-bound plan; referenced/shared assets become removal requests to resolve first. The queue does not replace the existing builders or make Blender/AI a gameplay dependency.

## Choose and record the source

The [Sparks foliage pass](reviews/2026-10-30-plant-style.md) replaces rounded plant placeholders in 35 existing masters with pointed leaves, branching sprigs and petalled flowers. Each source retains its pre-edit backup and `plant-style.json`; the [source pack](../art/source/world/plant-style/v1/README.md) records the edit and preservation audit. Edit these saved masters and use the normal world build. The packed four/five-row house palettes and non-botanical uses of their colours are preserved.

The six square robots now select individual `robot-<name>/v2/model.blend` masters. Their [source contract](../art/source/world/sparks-robot-refinement/v1/README.md) records detailed native revisions and packed enamel bakes. Pip's latest approved design omits the bag and carries parcels in real front cubbies. Catalog `spark_blink` adds `RobotBlink` to instances: only eye meshes tagged `blink_eyes` compress briefly. `WorldAssetMeta` reads Blender custom fields from Godot's imported `extras`; drive-wheel nodes retain local-X pivots and an authored `wheel_radius` used by `WorkshopLaneStage`. These are presentation details, never movement/collision rules. Original v1 models and concept/movement PNGs remain intact. [Model gallery](../docs/concept/v0.72/robot-model-refinement.md).

The [Sparks loft furniture pack](../art/source/world/sparks-loft/v1/README.md) supplies fourteen bespoke room models with packed painted surfaces and fine sepia outlines. They are selected only by `workshop-loft.json`; its furniture rectangles own collision. The existing shell is deliberately refined with its prior master preserved. Reader and Hotaru keep their semantic moving/window parts. Edit the saved masters and use the regular world build; generic retexturing would replace their bespoke finish.

The [illustrated village study](reviews/2026-10-26-illustrated-village.md) adds `square-lamppost`, `painted-cottage`, `painted-oak` and `painted-garden-fence`, each with its own adopted Blender source and audited GLB. The cottage is a deliberate finish edit of the existing reference reconstruction; the original master is preserved. The oak and fence are new geometry. Guarded authoring/review records live under `art/source/world/illustrated-village/v1/`; future edits use each asset’s saved `model.blend`.

`world-catalog.json` may select area-specific presentation variants through `areas.<id>.presentation.assets`, and a `post_lamp`. `ClearingView` resolves these for normal models and proposal ghosts; core data continues to use the original asset’s collision and door contract. A variant must therefore keep those contracts compatible. The current cottage shares the exact footprint, collision rectangles and entrance; both oak variants use the same 0.5 m trunk radius. The new standalone models are also available on the studio shelf with their own catalog entries.

`illustrated_edges` adds a rendering-only back-face hull with welded-position normals and a thin sepia shader. It leaves original mesh/material resources intact, follows each mesh’s own transform, scales line width with the viewport, and casts no shadow. Light panes and transparent/emissive effects are excluded. The retained Rootward cutaway is separate. `painted_glow` preserves the square lamp’s authored amber gradient when lit; the ordinary lamp metadata still controls Preview/Apply/Undo, halos and pooled lights.

The [building pass](BUILDINGS.md) deliberately edits the eight current shells and lamp, preserving source backups. It adds two adopted shop masters. Use their saved Blender sources and the normal build; historical source-edit scripts are not replacement seeders.

The selected house shells and static clearing land now come from editable Blender sources. Open [the Blender guide](BLENDER.md) for exact paths, visual editing steps and the protected export commands. The initial cottage, mill-house, clearing-ground and tree have completed an unedited export/reimport check, and so have the concept-matched **log-cabin** and **lamppost** ([review](reviews/2026-10-23-log-cabin-and-lamppost.md)). Test trees and the beacon, gate, bridge and wheel mechanisms remain procedural until their own handoff is reviewed.

`pipeline/world-catalog.json` records per-asset authority. Use procedural Godot geometry for a changing prototype test; once adopted, edit the `.blend` and export its GLB. The old maker remains a seed/reference, not a second master to regenerate over human changes. The game uses selected GLBs without Blender running or installed.

## Make one asset deliberately

1. Copy [the asset brief](templates/asset-brief.md). State the ID, purpose, source/version, dimensions, pivot, forward direction, visible overhang, blocking footprint, shared materials, variants and moving parts.
2. Establish its silhouette beside the existing player and house at the normal camera. One cell is one world unit. Keep chunky, warm fantasy forms: substantial timber, cream plaster, pale foundations, violet/teal roof tiles and warm windows.
3. If testing a shape in code, follow the existing `_make_house` and `_make_tree` recipes, or `pipeline/world_recipes.gd` (the cabin and lamppost: plain functions that take a `block` callable, so they do not grow the runtime view). Review it with `tools/asset_shot.gd -- <id> <png> recipe` at zoom 13 (gameplay) and closer, beside the character. Static decorative blocks batch by material; moving/stateful parts remain identifiable. Placements and footprints live in the area document (`content/areas/<id>.json`); lesson mechanisms are built in `art/mechanism_builder.gd`, and library prop states are presented by `art/prop_visual.gd`.
4. When the test is ready for visual editing, seed/init one new version through the documented handoff. For a model authored directly in Blender, a code seed is optional: save the versioned `.blend`, register it in the catalog and use `build`.
5. Export and review the result in Godot. Test a second instance/variant and one source rebuild before calling the asset reusable. A catalog entry alone does not place a new object: add a `buildings` entry (asset, position, facing, scale) to an area document, and its solid footprint comes from the catalog. For a builder prop, register its `kind: prop` item in `content/build/catalog.json`; the player's saved edits provide placements.

## A stateful model keeps its changing part separate

A model that the game must change keeps that part as its own mesh with its own material, found by **material name**, never by node path. The lamppost's lantern glass is `lamp_glass`: `MechanismBuilder` finds it, swaps in the lit material when the lamp is lit (and back to the model's own when it is dark), and puts the halo and light where the glass is, so the lantern may move in Blender without a code change. A model without that mesh is reported, not silently replaced.

The fifty-object [builder library](BUILDER_LIBRARY.md) extends this contract. Its moving pieces parent their animated geometry to a semantic `mechanism` pivot; `state_glow` and `state_flame` identify emissive and flame meshes. `PropVisual` presents a validated Boolean state without supplying collision rules. Each instance duplicates changing materials so toggling one does not recolor its neighbor. Edit the existing `hollow-*/v1/model.blend` and use the same `scripts/world-art.sh build <id>` command.

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

Five painted village residents are implemented through the shared character pipeline. The builder offers the original 32 [doodads](reviews/2026-10-23-voxel-doodads.md) plus the 50-object [village library](BUILDER_LIBRARY.md), organized into five additional categories. These 82 props are studio shelf items; none is auto-placed in the shipped valley.

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

A building asset may define `collision_rects`, up to sixteen `[min_x, min_y, width, height]` rectangles in its local S-facing **logical** frame (front is negative y). `AreaDef` validates and rotates/scales them into plain rectangles; `LabWorld` uses them instead of the default whole placement rectangle for standing and passages. They are separate from roofs/visual overhangs and do not come from runtime mesh bounds. The Concept Cottage uses three rectangles to cover its low log/foundation edges while preserving a central entry recess and its existing placement footprint/doorstep. See [the doorway review](reviews/2026-10-25-doorway-and-test-window.md) and `test/test_doorway_boundaries.gd`.


The Concept Cottage entrance now sets `approach_cells: 1` in the world catalog. `AreaDef` records the derived door offset and closed-leaf collision; `AreaBuild` uses the same landing for ghosts, ground protection and reachability. Rotation/scale and grid rounding can also require an extra clearance cell for another model. The selected GLBs and source geometry are unchanged. [Landing review](reviews/2026-10-26-compact-desktop-and-room.md).

## Village Morning landmarks

The [Rootward Square review](reviews/2026-10-26-rootward-square.md) records the new adopted `rootward-tree` and `morning-town-hall` masters. Their initial authorship and deliberate saved-source revisions are under `art/source/world/village-landmarks/v1/`; subsequent edits use each asset’s `model.blend` and `scripts/world-art.sh build <id>`. The wide civic bench derives from the existing park bench with its human height retained; the original master is untouched. The tree’s catalog radius includes exposed roots; its canopy does not block walking. Its named light/wisp anchors supply only cosmetic rendering. The town hall’s doors and stairs use the common entrance contract, and its interior is a separately saved authored room. All pictures reuse the existing painted library and are packed in the GLBs.

Rootward’s [trunk cutaway](reviews/2026-10-26-rootward-trunk-cutaway.md) is rendering-only. `RootwardPresence` reads each imported node’s Blender `extras.part` role, hides `Crown`/`Boughs` and fades affected upper surfaces in tree-local coordinates. It creates per-instance overrides without changing the saved `.blend`, GLB, source materials, map or collision. Lower lantern anchors keep their halos/local lights; hidden upper lanterns do not get independent halos.

The reusable `zone-terminal` computer is selected in the loft. The workshop’s zone node is the wall-mounted `workshop-wall-screen`, and `field-tablet` is the carried slate it accepts ([review](reviews/2026-10-27-tablet-and-wall-screen.md)). Both terminal models keep a `terminal_screen` glass and a `connection_lamp` as independent presentation parts; native lettering and status are presentation, while `AreaDef.terminals` owns gameplay scope and `AreaDef.pickups` owns where an item can be taken. The previous typewriter source is retained ([zone terminal review](reviews/2026-10-27-zone-terminals.md)). A catalog entry may set `casts_shadow: false`, which `WorldAssets.instantiate` applies to every mesh of the model (the workshop rug).


## Rootward Square as a town centre — 2026-10-29

A second pass on the hub ([square-hub pack](../art/source/world/square-hub/v1/README.md)).

- **Shops instead of the terrace:** `haverlund-bakery`, `haverlund-greengrocer`, `haverlund-bookshop` and `haverlund-cafe` are separate shop-houses, built from one shopfront recipe in the seaside house kit (`author_shops.py`). `square-west-terrace` is now `retained_previous_concept`.
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

A later [asset deletion pass](reviews/2026-10-29-asset-deletion-pass.md) removes 29 requested legacy props from the builder shelf and retired Village Morning placements. The historical village library retains its original index as an authorship record; 42 of its models remain on the current shelf. Earlier counts in this document describe the original handoff.

The [city power grid](reviews/2026-10-29-city-power-grid.md) updates `haverlund-square-ground` and `haverlund-lane-set` in their adopted Blender masters. Tagged strips use `art/power_grid.gdshader` for a cosmetic moving amber pulse; they do not add power gameplay or collision. Lower-town paving replaces scattered grass patches, and Spindle Lane uses ground strips in place of its overhead wire and poles.

The [integrated conduit revision](reviews/2026-10-29-integrated-power-conduits.md) supersedes the flat strips: the square, lane and lane surround use recessed framed panes, surveyed stairs and threshold feeds. Existing pilasters receive a stone-based glowing carving; separate wall stripes are removed. The editable source record is under `art/source/world/city-power-grid/v2/`.
