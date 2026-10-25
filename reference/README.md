# Art direction: the voxel-inspired village

[voxel-isometric.png](voxel-isometric.png) is the selected concept image. It was copied unchanged from Rootward's v0.6 comparison. Treat it as the target for the art; it is a generated reference picture, with no underlying meshes or animations. Original prompts and all three comparison images are preserved under [docs/concept/v0.6](../docs/concept/v0.6/).

## What to match

- Fixed diagonal orthographic view: visible roof, front and side faces, readable paths and water banks.
- A warm, slightly fantastical village: cream plaster, pale stone foundations, substantial timber beams, golden windows and lamps.
- Saturated violet cottage roofs and teal mill roofs, with individual chunky tiles and deliberate eaves.
- Full green tree crowns built from irregular clusters, with broad grass banks and readable stone paths. The current user direction excludes flowers and small decorative props.
- Turquoise stream, stone retaining walls, timber crossing and a visibly turning waterwheel.
- Clear silhouettes and a consistent scale. Reserve tiny details for focal objects; keep walkable cells and programmable objects legible.
- One small, expressive anime-inspired 2D player sprite, anchored by its feet in the 3D world. Other villagers are excluded.

The picture's UI and code are illustrative. The working program/API and the world's validated state decide behavior.

## Current working direction

The playable level is **Kindle Hollow**, a 64×48 valley built from this brief (see the [README](../README.md) and [area guide](../pipeline/AREAS.md)); the paragraph below describes the earlier single clearing it grew from.

The clearing now uses a 2D animated character in the 3D scene, smooth four-direction grid steps with held-key repeat and click-to-walk, three timber/plaster buildings, tiled roofs, larger leaf-cluster trees, cobbled paths, stone banks, rippling water and a turning mill. The original concept remains the target; the geometry is still an editable prototype rather than a finished recreation.

The player requested no other villagers or small doodads such as flowers. Flower boxes, flowers, crates, sacks, shrubs and scattered decorative props are removed. Main structural forms and interactive lamps, gate, bridge and mill remain.

The [active pipeline](../pipeline/README.md) records source prompts, import and scale conventions, character frames, texture recipes, movement rules and acceptance checks. Review the world at gameplay size before expanding the kit. Later comparisons can refine the sprite style and foliage/roof silhouettes without replacing the execution or movement contract.

## Current source decisions — 2026-10-23

Keep the approved painted adventurer's face, proportions, clothing and style. The user has accepted the clearing's current size, scale and style for main-project development. The selected eight-pose diagonal walk, neutral breathing idle and front blinks use one shared frame-skin template. SW mirrors SE and NW mirrors NE. Skins change appearance while preserving that motion contract; rejected bone/cutout experiments remain archived. See [characters](../pipeline/CHARACTERS.md) and [the handoff](../docs/PROJECT_HANDOFF.md).

House shells and static land now have selected Blender sources and exported GLBs; use [the visual editing guide](../pipeline/BLENDER.md). The violet-roofed log cabin and the hanging-lantern lamppost in this image were recreated and adopted the same way: [side-by-side with the concept](../evidence/cabin-lamppost-vs-concept.png). Existing varied tree crowns and mechanisms remain procedural tests. This source handoff preserves the reference composition without requiring a new 3D character.
