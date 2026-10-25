# Ground paint and blending

Generated land has a continuous ground skin, a 2×2 appearance grid per logical cell and the Land menu (the Paint tool) in [build mode](BUILD.md). Walking, quests and programmable commands still use the original cell terrain. Rune Mill's adopted `clearing-ground` model keeps its original surface; Paint is available only for generated land (`ground: {}`).

**Land → Floors** adds `herringbone_oak`, `terracotta_tile`, `encaustic_tile` and `limestone_flags` from the fifteen-picture [detail library](MATERIALS.md). Their atlas pictures append to the original six without changing previous indices. They use the existing luminance height fallback and appearance-paint rules. Interior floors use the same recipes through the separate room finish panel.

## Area format

`paint` is optional. Omitting it derives the whole surface from `terrain`, with `roughen: 0.4`. A block contains:

```json
{
  "version": 1,
  "palette": ["grass", "grass_light", "grass_dark", "dirt", "dirt_light", "dirt_dark", "path", "path_light", "path_dark", "soil", "pebbles"],
  "roughen": 0.4,
  "rows": ["…exactly twice the area width, repeated twice the area height…"]
}
```

The example row is illustrative, not a valid map. Real rows use `.` for the default, or a lowercase base-36 digit (`0`–`9`, `a`–`z`) indexing 1–36 unique palette IDs. Rows are north-up, exactly like terrain. `roughen` is a finite number in 0–1. Unknown IDs, malformed sizes and invalid digits reject the document. Water/rock overrides produce validator warnings and are ignored.

Palette entries must have `ground: true` in `pipeline/texture-catalog.json`. `AreaStore` supplies that list to the pure parser and ledger. Pure callers can supply it as the fourth `AreaDef.parse` argument or seventh `BuildLedger` argument; otherwise the schema's standard palette is used. The shipped families are grass, dirt, cobble (`path`), soil, pebbles and rock face. Painting rock-face texture on grass changes its appearance, never its terrain.

Sub-tile `[sx, sy]` is centred at logical `(sx / 2 - 0.25, sy / 2 - 0.25)`. Sub-tile zero is the southwest quarter of cell zero. North-up row index is `2 * height - 1 - sy`.

## Derived defaults

`core/ground_paint.gd` is pure: no files, nodes or textures. Cell grass/path/cobble selects grass/dirt/path families. The previous two-octave value noise now samples the sub-tile centres, so light/dark tones drift across broad patches instead of alternating cells. Dirt uses the same broad patch basis as grass.

Within one sub-tile of a different terrain family, a symmetric hash of the sorted boundary endpoints chooses a neighbor with probability `0.5 * roughen`. It never roughens a sub-tile adjacent to water, rock or the map edge, including diagonal neighbors. Explicit paint wins. The hash is independent of material order. There is no RNG state.

`GroundPaint.control(area)` produces one palette-index byte per sub-tile, indexed south-up (`sy * 2 * width + sx`). A deterministic multi-source breadth-first dilation fills water/rock texels from nearest ground; those cells have no surface mesh. Equal-distance ties follow traversal order.

## Rendering

`art/ground_skin.gd` creates one flat mesh per 16×16-cell chunk, only over ground cells (not stairs), at world height 0.02 above each cell's land level. An R8 level map (one texel per cell) lets the shader draw a dark pixel contour along every edge that drops to lower ground and a soft shadow at the foot of a cliff; on all-flat land it changes nothing. Shaping the land rebuilds the chunk meshes and level map ([shaping the land](BUILD.md#shaping-the-land)). All chunks share one material and an R8 nearest-filtered control texture. Soil sides, banks, rocks, walls, fences and water retain exactly their prior geometry/materials. The skin receives light/shadows and casts none. The build grid is above it at 0.045. Missing pictures report an error and leave the legacy top slabs available as a fallback.

The texture-array atlas is cached per active texture set and combines continuous world-space albedos with height in alpha. The shader snaps decisions to 32 art pixels per world unit, reads the four neighboring control texels with `texelFetch`, then picks the picture with the highest bilinear weight plus height bias. A periodic procedural two-channel 64×64 noise texture warps the border. Pictures never rotate or mirror between sub-tiles. Nearest sampling with mipmaps keeps the painted grid crisp at gameplay scale.

Current tunables in `art/ground.gdshader`: `height_strength = 0.65`, `warp_amplitude = 1.25` sub-tile units, noise sampling scale 0.21. The stronger warp was selected after comparing the six reference pairs. There are no fringe sprites or additional draw passes.

A committed edit updates different control pixels and calls `ImageTexture.update`; the ground meshes and other scenery are retained. Live strokes update just their newly visited sub-tiles. Cancellation restores the committed control data. A texture-set change rebinds the cached atlas; authored heights belong to lush, while solid uses its own luminance fallback.

## Painting and history

The saved edit is `{op: "paint", material: "dirt", cells: [[sx, sy], ...]}`. Empty material restores the derived default. A drag deduplicates its sub-tiles, fills gaps between pointer events and commits once on release. Water/rock are filtered out; malformed or out-of-map saved coordinates reject the entire stroke. Undo/redo reapply the edit list over the untouched area document. A paint-only change reuses `LabWorld` and its route cache, without a reachability flood. Paint has no allowance limit.

Press B, then 4. Choose a material from Grass/Dirt/Stone/Soil/Floors, or Eraser. Brush sizes cover 1, 2×2 or 4×4 sub-tiles; `[` and `]` change size. Alt-click, I then click, or Pick samples the effective material. Right-click/Esc cancels the active proposal. Release commits and saves through the game's normal debounce.

## Art source and rebuilding

The original base pictures are reused unchanged. Built-in `image_gen.imagegen` authored six candidate heights and six comparison references. Sources, exact prompts, tool disclosure and hashes are in `art/source/world/ground/v1/`. Model/seed are not exposed by that tool. Native generator output is preserved under `native/`, normalized 1024 masters under `raw/`, rejected/accepted height candidates under `height-candidates/`, and reference-only 512 swatches under `reference/`.

`scripts/art.sh` invokes `pipeline/normalize_ground.py` using `${ART_PYTHON:-/usr/bin/python3}` (Pillow and NumPy, authoring only). It samples heights to 32×32 with nearest colors, joins opposite edge pairs, quantizes to at most eight gray levels, enlarges with nearest to 1024, then BOX averages to opaque sRGB 128×128. References use a 64×64 detail grid and 512 outputs. No surface shapes are procedurally repainted. The build verifies previously approved native hashes and refuses a modified native source; new paintings need a versioned handoff.

Each height must have matching edges and Pearson correlation ≥0.55 with periodic one-pixel-blurred albedo luminance. All six v1 heights passed (0.823–0.888), and selected outputs live in `assets/world/ground/height/`. If no height exists, the atlas computes a periodic 3×3 luminance box blur and stretches its contrast to 0–1 at load. References never load in the game. Warp noise and control maps are always generated deterministically in code.

To add a ground material, register a ground picture/tint/tile entry in the texture catalog and a shared palette color. Existing atlas pictures require no shader change; an additional picture needs a layer in `GroundSkin.PICTURES`. Area documents may name it in their paint palette; the UI discovers catalog ground entries. Extend the family tabs if introducing another family. Keep the runtime palette below 64 entries (the default 14 plus at most 36 authored entries currently fit). Then run the art build, checks and windowed reviews.

## Checks and review

`scripts/test.sh` includes pure ground/document/history/rule tests, independent art hash/correlation checks, six scenery-asset lifecycle checks and build input with a 40-card fake tray. `tools/ground_shot.gd` requires a window and tests actual GPU pixels for derived versus explicit equivalent tones and uniform ground versus a single plane, both within a cell and across 16-cell chunks.

The prompt's literal default-versus-all-`grass` image equality conflicts with derived light/dark tone variation. The tool reports that difference and tests exact tone equivalence plus uniform surface continuity separately. See the [review record](reviews/2026-10-23-ground-paint-and-builder.md), [six-pair comparison](../evidence/ground-blend-vs-reference.png) and [Paint capture](../evidence/build-paint-stroke.png).
