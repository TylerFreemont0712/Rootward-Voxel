# Task: natural ground blending with 2×2 sub-tiles, a Paint tool in build mode, and a smaller build shelf

You are working in `/home/joejin/personal-project/Voxel-Rootward/` (Godot 4.7.2, typed GDScript, GL Compatibility renderer, isometric orthographic camera). You have image generation; use it only where section 4 says. Do the work in the phases below and run `scripts/test.sh` at the end of each phase.

**Read first, in this order:** `AGENTS.md`; `pipeline/README.md`; `pipeline/WORLD_ASSETS.md` (the "Materials and textures" part); `pipeline/BUILD.md`; `art/terrain_builder.gd`; `art/surface_materials.gd`; `art/world_textures.gd`; `pipeline/texture-catalog.json`; `art/source/world/textures/v1/prompts.md` (how the shipped pictures were made and normalised); `core/area_def.gd`; `core/area_build.gd`; `core/build_ledger.gd`; `scenes/clearing_view.gd`; `app/build_mode.gd`; `ui/build_hud.gd`; `ui/build_card.gd`; `reference/voxel-isometric.png` (look at how the paths meet the grass).

## 1. Goal

Today every ground cell is one flat box wearing one painted picture, so grass, dirt and cobble meet in straight lines on the cell grid and the land looks tiled. Make the ground look natural:

1. **Sub-tiles.** A ground cell can be painted at half-cell resolution: 2×2 sub-tiles of 0.5 unit each, so authors can fine-tune the land instead of one-cell-one-texture.
2. **Blending.** Where two materials meet (grass and dirt, dirt and cobble, grass and cobble, soil and pebbles...), the border is ragged and organic, drawn in the same chunky pixel-art style as the textures, not a straight line and not a blurry fade.
3. **A Paint tool in the new build menu** (`pipeline/BUILD.md`) so the owner, and later players, can paint the ground, with undo and saves like every other build edit.
4. **A smaller shelf.** The owner finds the build menu's item cards too big and plans to add many more assets. Shrink them and make the shelf scale (section 5).

Style target: crisp pixel art on the textures' own grid (32×32 art pixels per world unit; the pictures are 128 px, so one art pixel is 4 texels). Warm, saturated, no photographic gradients, no blur. No flowers, crates, barrels, sacks or people (the project excludes them).

## 2. Project rules (non-negotiable)

- Do not edit or depend on the sibling `../Rootward` repo. Do not commit, push or release. Keep it playable offline.
- Rules stay at **cell** resolution in `core/`. Painting changes only how the ground looks: it never changes walkability, a quest, a path or `terrain`. Paint applies only to ground cells (grass, path, cobble); water and rock are ignored.
- The area document is the source of truth; the player's edits are a saved layer over it (`BuildLedger`), never a rewrite of it.
- Do not regenerate or edit any adopted `.blend` (Rune Mill's land is the Blender asset `clearing-ground`; leave it exactly as it is: only areas whose `ground` is `{}` use `TerrainBuilder`).
- Another assistant works in this folder (candidate assets under `art/source/world/expansion-kit/`). Leave those alone, and re-read any shared file immediately before editing it (`scenes/clearing_view.gd`, `pipeline/world-catalog.json`, docs, `scripts/test.sh`).
- Set `VOXEL_LAB_FRESH=1` for every test and review. Run `godot --headless --editor --path . --import --quit` after adding a `class_name` file. A headless run has no renderer, so anything visual must be reviewed in a window (`scripts/play.sh`, `tools/area_shot.gd`, `tools/build_tour.gd`).
- Report results accurately: say exactly which checks ran, which passed, and what you could not verify.

## 3. Method

### Phase 1: data and rules (pure code, tests first)

**Document format.** Add an optional `paint` block to the area document (`content/areas/kindle-hollow.json`). Validate it in `AreaDef`:

```json
"paint": {
  "version": 1,
  "palette": ["grass", "grass_light", "grass_dark", "dirt", "dirt_light", "dirt_dark", "path", "path_light", "path_dark", "soil", "pebbles"],
  "roughen": 0.4,
  "rows": ["....a...", "...1111."]
}
```

- `palette`: up to 36 palette ids, each a material in `pipeline/texture-catalog.json` whose picture is a ground picture. Existing ids already cover grass, dirt, soil and cobble (`path` is the cobble). Add palette ids and catalog entries for `pebbles` and (if used) `rock_face`; the pictures already exist in `assets/world/textures/`.
- `rows`: exactly `2 × height` strings of `2 × width` characters, **north-up like `terrain`**; `.` means no override, otherwise one base-36 digit indexing `palette`. One character is one sub-tile.
- `roughen`: 0 to 1, how much the automatic border roughening below applies.
- Absent block = all defaults. Reject unknown palette ids, wrong row counts and bad characters with a clear message. Paint on a water or rock cell is ignored (and reported by the validator as a warning, not an error).

**Derived default** (what a cell looks like with no override), in a new pure helper `core/ground_paint.gd` (`GroundPaint`):
- Cell terrain gives a family: grass, dirt (the `PATH` terrain), cobble.
- Tone variants inside a family (`grass`, `grass_light`, `grass_dark`, likewise dirt and cobble) come from the existing two-octave value noise in `TerrainBuilder` (`_noise`), now sampled **per sub-tile**, so tone drifts in broad soft patches. Never alternate per cell (that makes a checkerboard).
- **Border roughening:** within one sub-tile of a boundary between two different families (grass↔dirt, dirt↔cobble, grass↔cobble), flip a sub-tile to the neighbour's material with probability about `0.5 × roughen`, using a symmetric deterministic hash of the sub-tile coordinates so the result is identical every build. Never roughen next to water or rock. Authored overrides always win.

**Edits.** Add a `paint` op to `core/area_build.gd` and `core/build_ledger.gd`: `{op: "paint", material: "dirt", cells: [[sx, sy], ...]}` (`material: ""` restores the derived default). `AreaBuild.apply` writes it into `paint.rows` (creating the block if needed). A paint-only edit changes no rules, so `BuildLedger` must **skip the reachability flood** for it (fast path) and `describe` it as "Painted dirt". Undo and redo already work by popping and re-applying the edit list. Store strokes compactly (a whole drag is one edit).

**Pure tests first** (`test/test_ground.gd`, add it to `scripts/test.sh`): document validation (good, wrong sizes, bad characters, unknown palette id, water cell ignored); the derived default is deterministic and never produces a checkerboard (assert that tone changes are spatially correlated); roughening never touches cells beside water or rock and is symmetric; `apply` and undo/redo round-trip; a paint-only edit leaves `LabWorld` results unchanged (walkability, `find_path`, every `test_area` check unchanged); saved edits survive a JSON round trip.

### Phase 2: rendering (the blending itself)

Replace the per-cell top slabs with a **ground skin**: one flat mesh per 16×16-cell chunk, covering only ground cells, with a spatial shader that does the blending per art pixel. Keep the soil blocks that form each cell's sides, and keep banks, rocks, walls, fences and water exactly as they are.

**Control map.** A single `R8` image of `2×width` by `2×height` texels (128×96 for Kindle Hollow): one texel per sub-tile holding its palette index (derived default plus overrides). Build it with a pure, testable function `GroundPaint.control(area) -> PackedByteArray`. Fill the texels of water and rock cells by dilating from the nearest ground sub-tile, so a bank never bleeds a foreign material in. Sample it with **nearest** filtering and read it with `texelFetch`. An edit updates only the changed texels and calls `ImageTexture.update`.

**Picture atlas.** One `Texture2DArray` built at load from the catalog's ground pictures for the active set (`WorldTextures.active_set()`; rebuild if the set changes): layers are the pictures (grass, dirt_path, cobble, soil, pebbles, rock), **RGB = albedo, A = height**, nearest filtering with mipmaps. A palette entry is `{layer, tint}`, taken from its catalog entry (`texture` and `tint`), passed to the shader as uniform arrays.

**Height channel.** Use an authored height map (`assets/world/ground/height/<picture>.png`, see section 4) when it exists; otherwise compute one at atlas build time from the albedo luminance (one pixel of blur, contrast stretched to 0–1, tileable). Raised parts (stone, grass clumps) are high; recessed parts (mortar, bare soil between tufts) are low.

**The blend** (the heart of it). Per fragment, in world space so it is continuous across chunks:

```glsl
// ground = world xz (x east, z = -y north). ART = 32.0 art pixels per unit, SUB = 2.0 sub-tiles per cell.
vec2 g    = floor(ground * ART) / ART;                       // snap: one decision per art pixel
vec2 warp = (texture(warp_noise, g * 0.21).rg - 0.5) * 0.45; // raggedness, in sub-tile units
vec2 p    = vec2(g.x, -g.y) * SUB + (0.5 * SUB - 0.5) + warp; // sub-tile space; centres at integers
ivec2 i = ivec2(floor(p));  vec2 f = fract(p);
float best = -1.0;  vec3 colour = vec3(0.0);
for (int k = 0; k < 4; k++) {                                // the four nearest sub-tile centres
    ivec2 c = clamp(i + ivec2(k & 1, k >> 1), ivec2(0), size - 1);
    float w = ((k & 1) == 1 ? f.x : 1.0 - f.x) * ((k >> 1) == 1 ? f.y : 1.0 - f.y);
    int idx = int(texelFetch(control, c, 0).r * 255.0 + 0.5);
    vec4 s  = texture(ground_albedo, vec3((g + 0.5 / ART) / tile, layer_of[idx]));
    float score = w + (s.a - 0.5) * HEIGHT_STRENGTH;         // weight biased by the picture's height
    if (score > best) { best = score; colour = s.rgb * tint_of[idx].rgb; }
}
ALBEDO = colour;   // hard pick = crisp pixel border; optional blend_band uniform for a 1-pixel dither
```

Use a tileable procedural value-noise texture (about 64×64, two channels) for `warp_noise`, generated in code: do **not** use image generation for noise. Start with `HEIGHT_STRENGTH` about 0.5 and the warp amplitude above, then tune by eye against the reference sheets of section 4. The result should be: borders sit where the paint puts them (on the half-cell lines) but wander about a sub-tile, grass pokes into the mortar gaps of cobble, dirt shows between grass clumps, and every border pixel sits on the textures' own pixel grid.

Rules for the blend:
- **Never rotate or mirror a picture per sub-tile**: the pictures are seamless only against their own orientation, so it would draw seams every 0.5 unit. Variety comes from tone variants, paint and the roughening, not from orientation.
- Sample the pictures in continuous world space (`g / tile`, the catalog's `tile`), nearest filter with mipmaps, like the existing materials.
- Compatibility-renderer safe: `sampler2DArray`, `texelFetch` and uniform arrays are fine; nothing that needs Forward+. Use `render_mode diffuse_burley` like `art/water.gdshader` so lamps and the sun light it. The skin **receives** shadows and does not cast them.
- The skin sits at y of about 0.02 (where the thin grass and dirt slabs were). The old cobble slab stood about 0.03 higher; losing that step is acceptable. The build-mode grid at y 0.045 must stay above the skin.
- `art/terrain_builder.gd`: stop emitting the top slabs for GRASS, PATH and COBBLE cells (`_cell`, `_paving`, `_grass_material` are replaced by the derived default), keep everything else. `scenes/clearing_view.gd` `setup()` builds the skin where it calls `TerrainBuilder.build`, and `sync_edits` updates the control texture for a paint edit **without rebuilding anything else**. Keep a fallback: if the skin cannot be built, report the error and draw the old slabs.

### Phase 3: art with image generation

See section 4.

### Phase 4: the build menu

See section 5.

### Phase 5: tests, docs, review

See sections 6 and 7.

## 4. Image generation: what to make, and what not to

Use the same workflow as the shipped texture pack (`art/source/world/textures/v1/prompts.md`): generate a 1024×1024 master, sample with **nearest** colour sampling to the 32×32 art-pixel grid, enlarge with nearest, then box-average to 128×128; opaque sRGB; record the exact prompt, tool, hashes and every manual edit in `art/source/world/ground/v1/prompts.md` and `manifest.json`; keep generated originals under `art/source/world/ground/v1/native/` and masters under `raw/`. Do not create `.import` files.

**Do NOT use image generation for:** the warp noise (procedural, exact and tileable), the control map, or the base pictures (they are done; reuse them).

**A. Height maps (recommended, 6 of them: grass, dirt_path, cobble, soil, pebbles, rock).** Output `assets/world/ground/height/<picture>.png`, 128×128 grayscale, tileable. Give the image tool the existing albedo `assets/world/textures/lush/<picture>.png` as its input image if it accepts one. Prompt:

> Use case: texture-edit. Convert the attached top-down pixel-art ground texture into a grayscale height map of the same surface, pixel for pixel in the same place. Raised parts are bright (stones, grass clumps, pebbles), recessed parts are dark (mortar gaps, bare earth between tufts, cracks). Keep the same 32×32 chunky pixel grid and hard pixel edges, at most 8 gray levels, no shading, no shadows, no new shapes, no outline, no border, seamless tileable on all four edges. Output exactly one 1024×1024 image.

Verify each: opposite edges match; Pearson correlation between the blurred albedo luminance and the height map is at least 0.55 (it must line up with the picture); otherwise discard it and use the luminance fallback for that picture, and say so in the report.

**B. Transition reference sheets (for judging only; do not ship or load them).** Six pixel-art swatches, 512×512 each, top-down, showing how the two materials should meet: grass↔dirt, grass↔cobble, dirt↔cobble, grass↔soil, dirt↔pebbles, cobble↔pebbles. Prompt for each:

> Use case: stylized-concept. A top-down, hand-painted chunky pixel-art ground patch where {A} meets {B} along a wandering, ragged, natural border: {A} on one side, {B} on the other, a few pixels of each poking into the other, no straight lines, no soft gradient, crisp hard pixels on a 32×32 grid per tile, same warm saturated palette as the attached textures {attach the two albedos}. No shadows, no perspective, no border, no text, no flowers, no props. Exactly one image.

Save under `art/source/world/ground/v1/reference/`. After the shader works, render the same pairs with it (a 16×16 test area) and compare side by side; tune `HEIGHT_STRENGTH`, the warp amplitude and `roughen` until it looks as natural as the references. Put the comparison in `evidence/ground-blend-vs-reference.png`.

**C. Edge fringe sprites (optional; only if the blend alone looks too clean after phase 2).** Small cut-outs placed along borders: `fringe_grass_over_dirt`, `fringe_grass_over_cobble`, `fringe_dirt_crumbs_on_grass`, `fringe_pebbles_on_dirt`. Each sheet is 8 sprites of 32×32 px in a 4×2 grid (hard alpha, at most 12 colours, silhouettes no larger than half a cell, drawn flat on the ground), made on a flat magenta background and chroma-keyed with nearest sampling. Place them deterministically from the control map as one `MultiMesh` of flat quads per chunk, only where two families meet; never on water or rock. Output to `assets/world/ground/fringe/`. If you add them, add a test that placement is deterministic and stays off water.

## 5. The build menu (`ui/build_hud.gd`, `ui/build_card.gd`, `app/build_mode.gd`)

**Add a Paint tool next to Place, Move and Delete.** Toolbar button with a new `brush` glyph (add it to `ui/glyph.gd`), key `4`; add `Tool.PAINT` to `BuildMode`.
- Choosing Paint swaps the shelf from items to a **Ground** palette: one swatch per palette entry (a small picture of the ground texture, tinted), grouped by family tabs (Grass, Dirt, Stone, Soil), plus an **Eraser** (restores the derived default) and an **eyedropper** (hold Alt, or press `I`, and click to pick what is under the pointer).
- **Brush sizes:** 1 sub-tile, 2×2 (one cell), 4×4. Keys `[` and `]` change it.
- The grid overlay switches to the **half-cell grid** while painting, and the brush footprint is drawn as translucent tiles (reuse `BuildOverlay`'s tile pool): the swatch's tint where it will paint, red over water, rock and the map edge.
- **Dragging paints.** Hold the left button and drag; the control texture updates live as you go; releasing commits **one** `paint` edit through the ledger (one undo step), and `edited` fires so the game saves. Right-click or Esc cancels a stroke in progress.
- A paint edit toasts "Painted dirt" and obeys undo/redo exactly like the others. The `player` policy needs a paint allowance only if you choose to add one; default: unlimited, since it affects nothing but looks.

**Make the shelf smaller and scalable** (the owner plans many more assets):
- Shrink the item cards from about 158×176 to about **104×124** (picture frame about 80 px, a smaller font, the size chip moved into the tooltip and the info panel). The tab bar, panel and info panel shrink with them. Keep readability at the 1280×720 test size.
- Lay cards out in a **wrapping grid inside a vertical scroll area** (replace the single-row horizontal scroller), with the dock's height capped at about 36% of the window so it never hides the valley. Several rows must fit as the catalog grows; a scroll bar appears only when needed.
- Add a **search field** (a `LineEdit` in the dock's header, `Ctrl+F` focuses it, Esc clears it) that filters by title, blurb and category across all tabs; and keep the category tabs.
- Draw thumbnails **lazily**: only the visible category first, the rest in the background; pictures already drawn are cached in memory (and keep the headless guard in `ThumbnailStudio`).
- Cards honour the `ui_scale` setting and the mouse wheel scrolls the grid. Keep `Tab` to hide the shelf, and keep the cursor bubble, toasts and info panel working.
- Update `test/test_build_mode.gd` (it currently asserts seven cards) so it checks the new layout with a **larger fake catalog** of about 40 items: the grid wraps, the dock stays under its height cap, search narrows the list, and choosing a card still works.

## 6. Tests and acceptance

- `scripts/test.sh` passes: every existing suite unchanged in result (`test_area`, `test_movement`, `test_lab`, `test_build`, `test_app` must still pass without edits to their expectations except where a test hard-coded the old slab geometry or the card count), plus the new `test_ground.gd`.
- **Visual review in a window** (not headless) with `tools/area_shot.gd` at gameplay zoom and a new `tools/ground_shot.gd`: (a) no straight cell-aligned border between grass and path at the default; (b) each border wanders by about one sub-tile; (c) cobble shows grass in its mortar gaps; (d) no visible seam at any sub-tile or chunk edge inside one material: **prove it with a pixel test**: render a 6×6 all-grass area once with the derived default and once with every sub-tile overridden to `grass` and assert the images are identical; (e) the river banks, rocks, walls, fences and Rune Mill look exactly as before.
- **Performance:** at 1600×1000 the area shot reports at least 110 fps on the integrated GPU (it was about 160 before) and the area builds in at most 150 ms longer than before. Report the measured numbers.
- **Build mode:** the shelf tests above; a `tools/build_tour.gd` frame of the Paint tool with a stroke in progress and one of the smaller shelf; both copied to `evidence/`.
- **Rules unchanged:** a test that paints a whole cell and asserts `LabWorld.is_walkable` and every `find_path` result are identical before and after.

## 7. Docs and report

Add `pipeline/GROUND.md` (document format, the derived default, the control map, the blend and its tunables, how to add a ground material, how to regenerate height maps) and link it from `pipeline/README.md` and `pipeline/BUILD.md`. Update `pipeline/AREAS.md` (the `paint` block), `pipeline/WORLD_ASSETS.md`, `pipeline/UI.md` (the Paint tool and the smaller shelf), `docs/PROJECT_HANDOFF.md`, and write a review record in `pipeline/reviews/` using `pipeline/templates/review-record.md`. In your final message report: what you built per phase; the exact test counts; the measured fps and build time; which height maps passed the correlation check and which fell back; what you could not verify (for example anything needing a real mouse session); and any decision you made that the owner did not specify.
