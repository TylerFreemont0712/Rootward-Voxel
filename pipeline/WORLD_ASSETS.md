# World assets, houses and materials

Use this for props, trees, buildings, bridge parts and surfaces. The world uses ordinary 3D geometry with a voxel-inspired appearance; making an object programmable does not require a voxel-volume engine.

The fifteen reusable textures and saved builder finishes are documented in [Materials](MATERIALS.md). `world-catalog.json` binds audited material names on 90 models to supported parts. Instance overrides give each building or furnishing its own finish while retaining its geometry, collision and working parts.

## Choose and record the source

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
