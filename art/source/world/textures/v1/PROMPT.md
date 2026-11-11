# Texture pack brief: Rootward Voxel, world materials v1

Status: delivered and in use (2026-10-23). The pack this brief asked for is in `assets/world/textures/`, and the game reads it through `pipeline/texture-catalog.json` (see [world assets](../../../../../pipeline/WORLD_ASSETS.md)). The brief is kept as the record of what was asked; hand it to whoever or whatever makes the next set.

## Paste-ready prompt

You are making a seamless, hand-painted texture pack for a chunky, voxel-inspired fantasy village game (Godot 4, fixed orthographic isometric camera, about 70 screen pixels per world unit). The target look is the concept image at `/home/joejin/personal-project/Voxel-Rootward/reference/voxel-isometric.png`: warm, saturated, pixel-art-inspired painting, clear shapes, no photorealism. The textures wrap simple box-shaped models, so they must read at 20 to 70 pixels on screen and survive mip-mapping.

Make TWO sets of the same materials:

- **solid**: clean and bold. At most 16 colours per texture, flat even light, big readable shapes, very little noise. For large surfaces and for reading at a distance.
- **lush**: richer and more organic. 24 to 48 colours. Subtle moss, lichen, dew sparkle, weathering and warm/cool colour drift. Still calm enough not to shimmer when small, and no single feature so distinctive that the tiling shows.

Rules for every image:

1. Seamlessly tileable in both directions. Check by shifting it half a tile each way and looking at the seams.
2. A flat, straight-on view of the surface. No perspective, no 3D objects, no border, no vignette, no text, no watermark.
3. Colour only. No baked shadows or specular shine. Light it softly from straight above; the game supplies sun and shadow. Keep highlights within +12 % of the base value and shadows within -15 %.
4. Crisp pixel-art edges, no blur, no film grain. One "pixel" of detail is about 1/32 of the tile.
5. Stay close to the hex colours listed for each material (variations of about 10 % lightness or hue are fine), so the pack matches the game's palette.
6. Do not paint flowers, crates, barrels, sacks, people or other loose props. The project excludes them for now.
7. Make a 1024×1024 master, then a 128×128 final (area-average downscale, no sharpening). Non-tiling items are marked. sRGB, no alpha unless stated.

Negative prompt, if your tool takes one: photo, photorealistic, 3D render, perspective, vignette, border, frame, text, watermark, signature, characters, flowers, crates, barrels, sacks, strong cast shadows, specular highlights, blur, noise grain.

Prompt pattern for each file (fill the braces from the list below):
`seamless tileable texture, flat top-down view, hand-painted pixel-art style, chunky shapes, crisp edges, {material description}, {solid: clean flat bold shapes, few colours | lush: rich organic detail, subtle moss and weathering, colour drift}, palette {hex colours}, soft even light from above, no shadows, no text, no border`

## Where the files go

Repository root: `/home/joejin/personal-project/Voxel-Rootward/`

| What | Path |
| --- | --- |
| 1024 px masters | `art/source/world/textures/v1/raw/<name>_solid_1024.png` and `<name>_lush_1024.png` |
| The exact prompt, tool, model and seed used for each image, plus manual edits | `art/source/world/textures/v1/prompts.md` |
| One image showing every final side by side | `art/source/world/textures/v1/contact-sheet.png` |
| 128 px finals, solid set | `assets/world/textures/solid/<name>.png` |
| 128 px finals, lush set | `assets/world/textures/lush/<name>.png` |

Use exactly the names below (lowercase, underscores). Do not create `.import` files; Godot makes them and I will set the import options (nearest filtering, mip-maps, repeat). Do not touch `art/source/world/*/v1/model.blend`, any `assets/world/<asset>/` folder, `art/source/adventurer/` or `assets/characters/`.

## Materials

"Tile" means how much world the repeating image covers. 1 unit is one grid cell and is about as wide as the player's character is tall.

### Ground (tile 1 unit)

| name | colours | paint |
| --- | --- | --- |
| `grass` | #638b41, light #83a852, dark #4e763b | Short grass as chunky blocky clusters. No flowers. Lush adds blades, clover leaves and a few dew glints. |
| `dirt_path` | #a97b4a, light #c19a62, dark #86603a | Packed earth with small pebbles and soft patches. No ruts or directional marks. |
| `cobble` | #d2c7a4, #b6b298, #827a61, mortar #5e5848 | Pale rounded cobblestones, about 4 by 4 per tile, dark gaps. Lush: moss in the gaps, worn pale edges. |
| `soil` | #755846, light #96745b, dark #584b48 | Dark tilled earth for banks and cut edges. Lush: fine roots, a few stones. |
| `rock` | #929a9a, light #bcc2ae, dark #626f73 | Craggy grey stone face. Lush: lichen patches, moss in cracks. |
| `pebbles` | #b6b298, #d2c7a4, #827a61 | Small river-shore pebbles packed together. |

### Water (tile 1 unit)

| name | colours | paint |
| --- | --- | --- |
| `water` | #5baca9, light #9bd1c2, dark #3a878c | Calm stream seen from above: soft chunky ripples and faint light bands. Keep the contrast low, a shader animates it. |
| `water_foam` | white on black, no colour | Grayscale foam bubbles and streaks for the water's edge. Used as a mask. |

### Housing (tile 1 unit unless stated)

| name | colours | paint |
| --- | --- | --- |
| `log_wood` | oak #b07a45, light #c59458, dark #765039, gap #49382f | Five horizontal logs per tile, each with a pale rounded top strip and a darker underside, grain running along the log, butt joints staggered. Lush: knots, a hint of moss low down. |
| `plank_wood` | #a47b51, dark #765039 | Four planks per tile with nail dots, for doors, fences and decks. Grain runs along the planks. |
| `timber_dark` | #765039, dark #49382f | Vertical-grained dark beam wood for posts and frames. |
| `plaster` | #e8ddbd, shade #d3c6a4 | Cream lime plaster with gentle trowel patches. Lush: hairline cracks and faint stains. |
| `stone_block_warm` | #c8bb99, light #d4c9ad, mortar #6b6251 | Warm limestone blocks, 3 by 2 per tile, dark mortar, a light top edge on each block. |
| `stone_block_grey` | #929a9a, light #bcc2ae, dark #626f73 | Grey field-stone blocks for walls and banks. |
| `roof_tile_violet` | #66509a, light #8271b1, dark #493c71 | Overlapping chunky slate tiles, 3 rows by 3 per tile, alternate rows offset, each tile with a lighter lower lip. Lush: a few faded or uneven tiles. |
| `roof_tile_teal` | #347b85, light #4c939b, dark #255560 | The same layout in teal, for the mill. |

### Fittings and nature (tile 0.5 unit unless stated)

| name | colours | paint |
| --- | --- | --- |
| `iron` | #394446, light #5a6a6e | Dark blue-grey hammered iron with a faint row of rivets. Lush: slight rust at the edges. |
| `brass` | #e3b16a, dark #a8763a | Warm hammered brass. |
| `leaf` | #4d7e35, light #7ca946, dark #2e5835 | Chunky overlapping leaf clumps for tree crowns (tile 1 unit). Lush: lighter sun-touched clumps, a few yellow leaves. |
| `bark` | #765039, dark #49382f | Vertical ridged bark for trunks (tile 1 unit). |
| `lantern_glass` | #7a6648 | NOT tiling, 128×128. Smoked amber glass with a soft inner gradient and a faint sheen. |
| `lantern_glass_lit` | centre #ffe6a5, edge #f0b45a | NOT tiling, 128×128. A glowing pane: white-hot centre fading to orange at the edges. Solid set: three flat bands. |
| `window_glass` | #526f7a | NOT tiling, 128×128. Dark blue-grey glass with a gentle diagonal sheen. |
| `window_glow` | #f0b45a, corners #b8742c | NOT tiling, 128×128. A lit window, warm amber, softly darker toward the corners. |

## When the images arrive

Tell me. I will then (1) make the game's surfaces load these files instead of the code-drawn patterns, starting with the generated ground and trees, (2) give the cabin and lamppost world-scale UVs so a tile means the same size on a 0.17 wide post as on a 2.4 long wall, deliberately and with your say-so because both are your editable Blender sources, (3) review at gameplay size against the concept and record it under `pipeline/reviews/`.
