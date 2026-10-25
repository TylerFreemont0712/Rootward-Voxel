# Rootward world textures v1 — exact prompts and authoring record

24 named materials, each with solid and lush treatments. Generated as an asset handoff; integration and UV changes remain with the user.

Tool: built-in `image_gen.imagegen`. **Model identifier and random seed are not exposed by this tool.** No seed was supplied and no model name has been inferred. Exact prompts, generated-source hashes, dimensions and processing are recorded per image.

## Shared processing

The generator may return a different native size from the requested 1024. Surface paintings are sampled with nearest colour sampling to the brief’s meaningful-detail grid of 32×32 to preserve crisp pixel shapes. Glass panes and the foam mask use BOX sampling for their intended smooth colour/coverage bands. Tiling materials receive a periodic opposite-edge join, then all images are median-cut quantized without dithering (solid ≤8, within the brief’s ≤16 budget; lush 24–48; the solid lit pane uses 3). The grid is enlarged with nearest-neighbour to the 1024 master. The final is an exact 8×8 BOX area-average of that master, without sharpening. Four glass/glow panes receive no edge join. Foam is grayscale; all outputs are opaque sRGB RGB PNGs.

Plank paintings use origin-aligned nearest samples (floor(i * native_dimension / 32)), preserving quarter-tile seams and nail dots that centre-of-cell sampling could miss. No joints, dots or other geometry are drawn by the normalization step.

Native generator outputs are preserved under `native/`; `raw/` contains the selected 1024 px masters. First-pass warm-stone, unlit-lantern and plank candidates were regenerated to correct course count, muted glass colour and seam readability; the exact selected prompts are below. Generated originals were kept, with SHA-256 hashes. No Blender, model, character or runtime-material source was edited.

Opposite-edge joins use a three-texel cosine taper: weight(i) = (1 + cos(pi*i/3))/2, i=0,1,2. Each opposite pair is moved toward its shared mean with that weight, first vertically and then horizontally. Texture shapes come from the generated painting; no procedural surface patterns are substituted.

The named palette anchor colours and intended world tile sizes are in `PROMPT.md`. The contact sheet labels tile sizes; pane textures are marked non-tiling.

## Validation

All 48 masters are 1024×1024 and all 48 finals are 128×128. Palette budgets, exact final area averages, opaque sRGB output, grayscale foam and matching opposite tiling edges were checked. Every one of the 213 protected model/asset/character/import files retained its starting hash. No `.import` files were created. Visual contact-sheet and half-tile-offset repeat reviews supplement the edge checks.

## grass — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/grass_solid_generated.png` (1254×1254); SHA-256 `748cf530de10261337b95bd1fd20804fcf076b08159e095a0c8022ab21aeadfe`
- Master: `art/source/world/textures/v1/raw/grass_solid_1024.png`; SHA-256 `639296cc9bbcd9420c127bdef6ea729cc60ce4688d1cce445c2535706e7626c3`
- Final: `assets/world/textures/solid/grass.png`; 8 colours; SHA-256 `274d51205c9d788464c058b949deb26bcfd05e3584d1ac0b4308f6c9f2e5e0b3`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: grass
Variant: solid.
Palette anchors: #638b41, #83a852, #4e763b.
Surface: Short grass in chunky blocky clusters, no flowers.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## grass — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/grass_lush_generated.png` (1254×1254); SHA-256 `a963d3f07d8dfe2f3ccc46728b76b5db9ca9912a41c51756e20f9958c7a1e3d7`
- Master: `art/source/world/textures/v1/raw/grass_lush_1024.png`; SHA-256 `1be19c5819e948f20775d30e07771e54b601efb14c97f5cb46b1f84eb2463ba9`
- Final: `assets/world/textures/lush/grass.png`; 48 colours; SHA-256 `2104ee35892b34656d8f9d6ac7a8d8a29d1b0d135a9cf35abe56378035036d17`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: grass
Variant: lush.
Palette anchors: #638b41, #83a852, #4e763b.
Surface: Short grass in chunky blocky clusters, no flowers.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. More varied short blades and clover leaves, restrained pale dew-colour flecks; no glossy highlights.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## dirt_path — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/dirt_path_solid_generated.png` (1254×1254); SHA-256 `99daaed62cfa0e707cf5502995632e62e1bab489a7c541d9fbdf2bcb6b2a5483`
- Master: `art/source/world/textures/v1/raw/dirt_path_solid_1024.png`; SHA-256 `6769e2d384e77cba89c79ec9ef1c529025fb971406c0685a797802ac02f4379f`
- Final: `assets/world/textures/solid/dirt_path.png`; 8 colours; SHA-256 `87f3dd6e162464dff49ca94aaeb8849145547eff547659682324e9d49407703d`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: dirt_path
Variant: solid.
Palette anchors: #a97b4a, #c19a62, #86603a.
Surface: Packed warm earth, small scattered pebbles and broad soft patches; no ruts or directional tracks.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## dirt_path — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/dirt_path_lush_generated.png` (1254×1254); SHA-256 `311efed09c8a945339c5d1b59b1a4f8e1c5e74cc4a1d9c6b4f3688378a9f36d5`
- Master: `art/source/world/textures/v1/raw/dirt_path_lush_1024.png`; SHA-256 `7010cd2638a02489b4a070509903521549967adc2996ec623c00e37a30ce131b`
- Final: `assets/world/textures/lush/dirt_path.png`; 48 colours; SHA-256 `defadf9d4a7132f3ce52d92c239055bc1578a5fc33b31cbfc64890a3d902a73e`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: dirt_path
Variant: lush.
Palette anchors: #a97b4a, #c19a62, #86603a.
Surface: Packed warm earth, small scattered pebbles and broad soft patches; no ruts or directional tracks.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Slight warm/cool earth drift, a few more pebbles, sparse compacted patches; calm organic variation.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## cobble — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/cobble_solid_generated.png` (1254×1254); SHA-256 `dee31f17ef3650298692a6b01bcc17371b3489e987d57cd8476ff14f68a21395`
- Master: `art/source/world/textures/v1/raw/cobble_solid_1024.png`; SHA-256 `d9d7d9d9e4c50de6246eed4ab2f1df0e75c9aafbab90da35a205a77936eb5276`
- Final: `assets/world/textures/solid/cobble.png`; 8 colours; SHA-256 `efcbee44df96fec65882a24bc2a331019a3329303478478b8f885384b8870bbd`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: cobble
Variant: solid.
Palette anchors: #d2c7a4, #b6b298, #827a61, #5e5848.
Surface: Pale rounded chunky cobblestones, approximately four stones across by four down, with narrow dark mortar gaps.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## cobble — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/cobble_lush_generated.png` (1254×1254); SHA-256 `79a88199d928d3d32a13a481da6366f19ae99ad0ae92a93b7f3012ee99812619`
- Master: `art/source/world/textures/v1/raw/cobble_lush_1024.png`; SHA-256 `3fdb74044c639608b6765465d74d30663aa8ce92d110c7ab13a2297564cd04c9`
- Final: `assets/world/textures/lush/cobble.png`; 48 colours; SHA-256 `a4b1603324cb79d70aa8d9838279a283518302bd081c84f2c10382651fce64e8`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: cobble
Variant: lush.
Palette anchors: #d2c7a4, #b6b298, #827a61, #5e5848.
Surface: Pale rounded chunky cobblestones, approximately four stones across by four down, with narrow dark mortar gaps.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Subtle muted moss only in a few gaps and worn pale stone edges; retain four-by-four scale.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## soil — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/soil_solid_generated.png` (1254×1254); SHA-256 `c1ffe5b2c639f95bf7d5ef70f78a306b66eb54b55f81cf8173c70cd69f07f0a5`
- Master: `art/source/world/textures/v1/raw/soil_solid_1024.png`; SHA-256 `40766707f86f0b3b0442e6027180c3dfcb10becaa0317334a1292a9a7b675f52`
- Final: `assets/world/textures/solid/soil.png`; 8 colours; SHA-256 `dd08c0e59f95433759affff1004eab652efeac2783617a390e7134617e289dfc`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: soil
Variant: solid.
Palette anchors: #755846, #96745b, #584b48.
Surface: Dark tilled earth for banks and cut edges; broad irregular earth clods, evenly distributed.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## soil — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/soil_lush_generated.png` (1254×1254); SHA-256 `3f7f068b25481572d19b302e01faf87adeea8e688672a3d5117745e3e8ee875c`
- Master: `art/source/world/textures/v1/raw/soil_lush_1024.png`; SHA-256 `93aec6878710baca5d4e0bd1051d790259b9fc50545979b59c73689f97d8f045`
- Final: `assets/world/textures/lush/soil.png`; 48 colours; SHA-256 `fd7cda737b6a2cb470156fc70d36297972fa4edc8600f5ddde8bd41ccbb7f243`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: soil
Variant: lush.
Palette anchors: #755846, #96745b, #584b48.
Surface: Dark tilled earth for banks and cut edges; broad irregular earth clods, evenly distributed.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Sparse fine roots and a few small stones, softly varied warm/cool soil patches.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## rock — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/rock_solid_generated.png` (1254×1254); SHA-256 `be11a52e427e5cf66c15b00eaac30e30a3cc8db3cfef238e484d6fdac650a873`
- Master: `art/source/world/textures/v1/raw/rock_solid_1024.png`; SHA-256 `2c3ce4b94bddb05df972d792cbbe255e04bddc991c428683d5d8755bf12cf669`
- Final: `assets/world/textures/solid/rock.png`; 8 colours; SHA-256 `320311dcdebfbff1c10a323860afb9ddb68a24b6400fd79cf882c731a4b827e4`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: rock
Variant: solid.
Palette anchors: #929a9a, #bcc2ae, #626f73.
Surface: Craggy grey stone face, a few broad angular fracture planes and cracks; no directional lighting.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## rock — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/rock_lush_generated.png` (1254×1254); SHA-256 `d08890f86aaa94473f19f3875072af70647181cc9b678481cc70e8f888ff8ddc`
- Master: `art/source/world/textures/v1/raw/rock_lush_1024.png`; SHA-256 `a3e1139cca1919e808f6211a76bb0f41cc175f83be4fb96dc1edfcc99ca17876`
- Final: `assets/world/textures/lush/rock.png`; 48 colours; SHA-256 `d28b0d134a715c3ba6c2726e30dd8e65371740ab211a283a39596d1caf3fb241`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: rock
Variant: lush.
Palette anchors: #929a9a, #bcc2ae, #626f73.
Surface: Craggy grey stone face, a few broad angular fracture planes and cracks; no directional lighting.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Muted lichen patches and restrained moss in a few cracks; broad calm variation.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## pebbles — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/pebbles_solid_generated.png` (1254×1254); SHA-256 `722714b7aebbade2b283c6f9ca1445bc52b87a0931cc3dd1fa6c293af34cdacc`
- Master: `art/source/world/textures/v1/raw/pebbles_solid_1024.png`; SHA-256 `3c548e4ff747f8e0d848e7c106caf629e604225246f5346e821d88441dc88215`
- Final: `assets/world/textures/solid/pebbles.png`; 8 colours; SHA-256 `3086cd68566ebbaaa2f04d5d82aa09ae47a97e77ad29e2739509ea0cf5e044eb`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: pebbles
Variant: solid.
Palette anchors: #b6b298, #d2c7a4, #827a61.
Surface: Small rounded river-shore pebbles packed together; many smaller stones than cobble, no large boulders.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## pebbles — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/pebbles_lush_generated.png` (1254×1254); SHA-256 `60198fc04f2d823e102042f84328fafdc934e0a8bcc74ed4911740098d9606d9`
- Master: `art/source/world/textures/v1/raw/pebbles_lush_1024.png`; SHA-256 `096386d02f08c674d36e42e123b03f0e30f9fa24e5830e2f451d88bd90595780`
- Final: `assets/world/textures/lush/pebbles.png`; 48 colours; SHA-256 `c4720b0f536df5e794a0fcaeab93e651f075cfe4e40d77f1992e4e515c74e89c`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: pebbles
Variant: lush.
Palette anchors: #b6b298, #d2c7a4, #827a61.
Surface: Small rounded river-shore pebbles packed together; many smaller stones than cobble, no large boulders.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. More organically varied pebble sizes, restrained warm/cool drift and slightly worn matte edges.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## water — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/water_solid_generated.png` (1254×1254); SHA-256 `28cf65887f8a608b29dd69a514a7858b5d3856e6ddf965559d88dd70defa308d`
- Master: `art/source/world/textures/v1/raw/water_solid_1024.png`; SHA-256 `d08218f8465a1809eb8752a07a91b4e4ffadf5d6003ff6364fc8f9691635033e`
- Final: `assets/world/textures/solid/water.png`; 8 colours; SHA-256 `12ae8ff71f5a5d62262550ca6e4a0fd5f5c822b00c9f8b1b494fea499c4e03f7`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: water
Variant: solid.
Palette anchors: #5baca9, #9bd1c2, #3a878c.
Surface: Calm turquoise stream from directly above, soft chunky ripples and faint short light-colour bands. Very low contrast; animation will come from a shader.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## water — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/water_lush_generated.png` (1254×1254); SHA-256 `f27d5a47dd36daf50f61e88ce45f000f338f77381d71a5ae87c532d6688b58e8`
- Master: `art/source/world/textures/v1/raw/water_lush_1024.png`; SHA-256 `5b7b65e351a16f0cbb844032ebbaa6ac31d075ddbbd549af81793b1c1a976d66`
- Final: `assets/world/textures/lush/water.png`; 48 colours; SHA-256 `c43d176f5e0fd330f9e7b94af9746d4200370121f7e6bcedc0d8db0c19b88a19`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: water
Variant: lush.
Palette anchors: #5baca9, #9bd1c2, #3a878c.
Surface: Calm turquoise stream from directly above, soft chunky ripples and faint short light-colour bands. Very low contrast; animation will come from a shader.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Richer but quiet variation in the turquoise ripples, occasional small pale matte bands. No reflected scenery or specular glints.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## water_foam — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/water_foam_solid_generated.png` (1254×1254); SHA-256 `118e6b7c39b32c6a4481b4f5c3abc652329b4437d51c8121921a0c157f3cde8e`
- Master: `art/source/world/textures/v1/raw/water_foam_solid_1024.png`; SHA-256 `f6737dd9e365ce413ba93d1f154058e64bda53d8f5cfed038ebb7e278e1fa192`
- Final: `assets/world/textures/solid/water_foam.png`; 8 colours; SHA-256 `54ddee041b032801622c0bc42de69e5a5e63dd3c752b0b2673c350b633c9c670`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: water_foam
Variant: solid.
Palette anchors: #000000, #ffffff.
Surface: GRAYSCALE ONLY. White foam bubbles and short broken foam streaks on a solid black background, a water-edge mask. No blue or other colour.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## water_foam — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/water_foam_lush_generated.png` (1254×1254); SHA-256 `f46be5ceb70e97fdc680a839cb221e0ca0c456247c37c332abe3f3d5b2640fa7`
- Master: `art/source/world/textures/v1/raw/water_foam_lush_1024.png`; SHA-256 `9ab24b8ac2a41dd60177de0b90047bb8e1d42b2b2953a2acb028dd2589229ab3`
- Final: `assets/world/textures/lush/water_foam.png`; 48 colours; SHA-256 `774e3e0bed41cd8569c325b34b739813538c7bd370b44e0eab6580454ca84429`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: water_foam
Variant: lush.
Palette anchors: #000000, #ffffff.
Surface: GRAYSCALE ONLY. White foam bubbles and short broken foam streaks on a solid black background, a water-edge mask. No blue or other colour.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. More organic small bubble groupings and broken foam filaments, with a few intermediate grey values; plenty of calm black negative space.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## log_wood — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/log_wood_solid_generated.png` (1254×1254); SHA-256 `c5b2b496b1b9242f6847718749fa56805fe3bc7bd2eb983f0d135128b217c3c2`
- Master: `art/source/world/textures/v1/raw/log_wood_solid_1024.png`; SHA-256 `ab07b7651c51709e64df66b7e939d78c161e7d39a9bf69c7e5a11a8c91da473a`
- Final: `assets/world/textures/solid/log_wood.png`; 8 colours; SHA-256 `61274716f654ebdd00f848f0f6549639af68643826f2b790bf3253d4fe80d2bd`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: log_wood
Variant: solid.
Palette anchors: #b07a45, #c59458, #765039, #49382f.
Surface: Exactly FIVE horizontal logs filling the tile, narrow dark gaps, staggered butt joints. Long subtle horizontal grain. A pale top-colour strip and darker underside-colour strip are painted albedo bands, not cast shadows.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## log_wood — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/log_wood_lush_generated.png` (1254×1254); SHA-256 `154aa4c12b03a38cacd17b59efc4fe958fabf820709143c96d83a8fc2ce3c019`
- Master: `art/source/world/textures/v1/raw/log_wood_lush_1024.png`; SHA-256 `788f13d9998a9265b37abf77ce505b3165c9ab42d1934c1cd6536afb8cf8e3c3`
- Final: `assets/world/textures/lush/log_wood.png`; 48 colours; SHA-256 `cc305bf45530dcdbc58525a22c5ca628e3312c1cdd6fbaea75f6d8c625b28fbb`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: log_wood
Variant: lush.
Palette anchors: #b07a45, #c59458, #765039, #49382f.
Surface: Exactly FIVE horizontal logs filling the tile, narrow dark gaps, staggered butt joints. Long subtle horizontal grain. A pale top-colour strip and darker underside-colour strip are painted albedo bands, not cast shadows.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. A few restrained knots and a hint of muted moss near some joints; keep exactly five horizontal logs and their broad shapes.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## plank_wood — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/plank_wood_solid_generated.png` (1254×1254); SHA-256 `f22c6ebfafda1335ec26f755927fcfde63dbe41540bd8d671fc6fbd2ed4e2e34`
- Master: `art/source/world/textures/v1/raw/plank_wood_solid_1024.png`; SHA-256 `94c7a0b00e53001d2b77a3ca65f57478611cbebefa51ac03a54a9b411228f0c0`
- Final: `assets/world/textures/solid/plank_wood.png`; 8 colours; SHA-256 `ada16b4e84d5b494253fd572627c2013e16775e436931cfaaca2c87beace3aba`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: plank_wood
Variant: solid.
Palette anchors: #a47b51, #765039.
Surface: Exactly FOUR vertical wooden planks across the tile. Narrow seams, small simple nail dots and lengthwise vertical grain for doors, fences and decks.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
CRITICAL SMALL-SCALE CONSTRUCTION: draw FOUR equal-width VERTICAL planks. Think of a 32-by-32 logical pixel tile: each board is 8 logical pixels wide. The continuous straight dark-brown gaps at columns 0, 8, 16 and 24 must be ONE FULL LOGICAL PIXEL wide (about 32 actual pixels in a 1024 master), not hairline seams. Keep these four vertical joints obvious from top to bottom; the edge joint wraps. Boards are large calm flat brown masses; grain is only a few broad sparse vertical ribbons. Nail dots are one logical pixel, in the same dark brown palette, near the top and bottom of each board. Preserve these major seams and dots when viewed at 32x32 pixels. No micro-grain, no diagonal or cross-hatched grain, no extra boards, no perspective. Broad readable 4-board structure is more important than decorative grain.
```

## plank_wood — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/plank_wood_lush_generated.png` (1254×1254); SHA-256 `c53b6427d72862375638683b1e4cf4fa1fddbacfd7cc826faa8561bd1257e19d`
- Master: `art/source/world/textures/v1/raw/plank_wood_lush_1024.png`; SHA-256 `076bd5a8955b670280920ff03aaa0c75642b394c4f01f4fea3adaf77b35815ca`
- Final: `assets/world/textures/lush/plank_wood.png`; 48 colours; SHA-256 `db7a9baa7f51971cbfb8d83f4705ad47cd33994e86956d303ea597991e1a0c45`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: plank_wood
Variant: lush.
Palette anchors: #a47b51, #765039.
Surface: Exactly FOUR vertical wooden planks across the tile. Narrow seams, small simple nail dots and lengthwise vertical grain for doors, fences and decks.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Richer warm grain, a few subtle knots, slight matte edge weathering; retain four vertical planks.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
CRITICAL SMALL-SCALE CONSTRUCTION: draw FOUR equal-width VERTICAL planks. Think of a 32-by-32 logical pixel tile: each board is 8 logical pixels wide. The continuous straight dark-brown gaps at columns 0, 8, 16 and 24 must be ONE FULL LOGICAL PIXEL wide (about 32 actual pixels in a 1024 master), not hairline seams. Keep these four vertical joints obvious from top to bottom; the edge joint wraps. Boards are large calm flat brown masses; grain is only a few broad sparse vertical ribbons. Nail dots are one logical pixel, in the same dark brown palette, near the top and bottom of each board. Preserve these major seams and dots when viewed at 32x32 pixels. No micro-grain, no diagonal or cross-hatched grain, no extra boards, no perspective. Broad readable 4-board structure is more important than decorative grain.
```

## timber_dark — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/timber_dark_solid_generated.png` (1254×1254); SHA-256 `7113130b6982d6e19810ee78f67971f867027b189d69e4dcfd51e12c7f5d2807`
- Master: `art/source/world/textures/v1/raw/timber_dark_solid_1024.png`; SHA-256 `a8029cb075e929a9b40e4bff7a18a1d58ba6963d27217da7d5480e36676d445d`
- Final: `assets/world/textures/solid/timber_dark.png`; 8 colours; SHA-256 `3ebaeb65232ded22c4eac46dd4e80e14fc4868cec2d17d8a7c8f4959769be101`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: timber_dark
Variant: solid.
Palette anchors: #765039, #49382f.
Surface: Dark timber for posts and structural frames. Long straight VERTICAL wood grain, broad readable stripes and only sparse small knots.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## timber_dark — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/timber_dark_lush_generated.png` (1254×1254); SHA-256 `febf272c2518f9a9bbe4828f566ab95e74dcf9677f683244cf5a797e007556a3`
- Master: `art/source/world/textures/v1/raw/timber_dark_lush_1024.png`; SHA-256 `72e55fc874255d035c5466f835d10cb6546eac08061aba0fd7632e01e439b15a`
- Final: `assets/world/textures/lush/timber_dark.png`; 48 colours; SHA-256 `615c8712aca3402e39ac837e65857409bce53ced3a016a29f8a9df8066ca0cf0`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: timber_dark
Variant: lush.
Palette anchors: #765039, #49382f.
Surface: Dark timber for posts and structural frames. Long straight VERTICAL wood grain, broad readable stripes and only sparse small knots.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Subtle worn grain and a little irregular warm-brown weathering, still dark and low contrast.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## plaster — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/plaster_solid_generated.png` (1254×1254); SHA-256 `a0ca04a68c6b042ed30290b3ec8983dc92908cd012e9db7369d86ff36d852334`
- Master: `art/source/world/textures/v1/raw/plaster_solid_1024.png`; SHA-256 `527a3815d0f3ebeafccd70e5cf82995991390d62b0f81f766757e1788389347f`
- Final: `assets/world/textures/solid/plaster.png`; 8 colours; SHA-256 `d6fc7536288862e58547bb0b837fd952ae136e6343ce0b20adaebd4f43b616e1`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: plaster
Variant: solid.
Palette anchors: #e8ddbd, #d3c6a4.
Surface: Cream lime plaster with broad very gentle flat trowel patches; no bricks, framing or objects.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## plaster — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/plaster_lush_generated.png` (1254×1254); SHA-256 `34da09d57bee5722b5c91d57110a6cf824f94fee28a190a4aa5e4bcc6719b1e9`
- Master: `art/source/world/textures/v1/raw/plaster_lush_1024.png`; SHA-256 `40d1b9b9fe564c7bfa8c661f32d271601ab9b6740de6dcf4b01c762a87766c5a`
- Final: `assets/world/textures/lush/plaster.png`; 48 colours; SHA-256 `05c56477ec7daa39997955bf152b509188bdeee5819983fe9ab5cbe822595273`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: plaster
Variant: lush.
Palette anchors: #e8ddbd, #d3c6a4.
Surface: Cream lime plaster with broad very gentle flat trowel patches; no bricks, framing or objects.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Sparse hairline cracks and faint pale stains; still mostly calm cream plaster.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## stone_block_warm — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/stone_block_warm_solid_generated.png` (1254×1254); SHA-256 `098219ab735c95f7db2affb639f4709c171a1883e8c180430dc8c4bb2d8f100e`
- Master: `art/source/world/textures/v1/raw/stone_block_warm_solid_1024.png`; SHA-256 `73a1fe05a571d474f45939c8cfa2f3094af53f2d58a39f2dc317e337e7306651`
- Final: `assets/world/textures/solid/stone_block_warm.png`; 8 colours; SHA-256 `234871a225354087981bd18985063097b5115be6897ddd5dfacc9b6cb3b906b3`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: stone_block_warm
Variant: solid.
Palette anchors: #c8bb99, #d4c9ad, #6b6251.
Surface: Warm limestone wall made of SIX LARGE TALL blocks in exactly TWO horizontal courses. Each course contains exactly THREE blocks across the square. Each block is roughly ONE THIRD of the image width and ONE HALF of the image height: taller than it is wide. There are TWO ROWS TOTAL, not four or five brick courses. Stagger the second row by half a block, allowing clipped half-blocks on opposite edges to wrap seamlessly. Dark mortar lines are about 1/32 tile wide and clear at small size. Very calm pale stone faces and a thin pale albedo top edge. No other subdivisions, small stones or extra courses.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
COUNT CHECK: exactly one horizontal internal mortar joint at y=50 percent, with periodic mortar at the top/bottom. THREE blocks per row, TWO rows total. Do not draw four rows. This is a repeat unit, not a photograph of an entire wall.
```

## stone_block_warm — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/stone_block_warm_lush_generated.png` (1254×1254); SHA-256 `3f8b2e3b69b05d2403cbd42c5bb2688d33a6131e9d0493189603c4523de08cc7`
- Master: `art/source/world/textures/v1/raw/stone_block_warm_lush_1024.png`; SHA-256 `abbe7536c3bd09a6472674e25ed8ae4d8ad694c6fd0a45a4cbb07c91a834eaeb`
- Final: `assets/world/textures/lush/stone_block_warm.png`; 48 colours; SHA-256 `fb38168aa7edd4906a6a1aeecddba9364b5ca0120ebd809ebb8a6136877cfb20`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: stone_block_warm
Variant: lush.
Palette anchors: #c8bb99, #d4c9ad, #6b6251.
Surface: Warm limestone wall made of SIX LARGE TALL blocks in exactly TWO horizontal courses. Each course contains exactly THREE blocks across the square. Each block is roughly ONE THIRD of the image width and ONE HALF of the image height: taller than it is wide. There are TWO ROWS TOTAL, not four or five brick courses. Stagger the second row by half a block, allowing clipped half-blocks on opposite edges to wrap seamlessly. Dark mortar lines are about 1/32 tile wide and clear at small size. Very calm pale stone faces and a thin pale albedo top edge. No other subdivisions, small stones or extra courses.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Quietly weathered pale stone, sparse fine chips and tiny muted moss traces in a few mortar joints; preserve three-by-two scale.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
COUNT CHECK: exactly one horizontal internal mortar joint at y=50 percent, with periodic mortar at the top/bottom. THREE blocks per row, TWO rows total. Do not draw four rows. This is a repeat unit, not a photograph of an entire wall.
```

## stone_block_grey — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/stone_block_grey_solid_generated.png` (1254×1254); SHA-256 `004334eeded1cafbef2a27432c48b027d00e8f1aabd707420e9d6dc0941f4389`
- Master: `art/source/world/textures/v1/raw/stone_block_grey_solid_1024.png`; SHA-256 `066fff4f55aa10767959b68b9e5e6514729113046b7906eb12863bc7db7726d7`
- Final: `assets/world/textures/solid/stone_block_grey.png`; 8 colours; SHA-256 `c9efe8be7aeb4e4669a71db1462a72c87fa81a3de927c9c5306bbab445c1283c`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: stone_block_grey
Variant: solid.
Palette anchors: #929a9a, #bcc2ae, #626f73.
Surface: Grey field-stone blocks for walls and banks, broad chunky roughly rectangular stones in staggered courses and narrow gaps.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## stone_block_grey — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/stone_block_grey_lush_generated.png` (1254×1254); SHA-256 `4d10b2688264755f4e3a4cc91ca23e5266ad7314084e00f102eba53d261c22e7`
- Master: `art/source/world/textures/v1/raw/stone_block_grey_lush_1024.png`; SHA-256 `c2108d4f1927508d7f7a25e818c263ebb463312af44d8fb6c5868280cc5318d0`
- Final: `assets/world/textures/lush/stone_block_grey.png`; 48 colours; SHA-256 `9b549ddee7ea0ddd416314f2cc6ac1bb72e9378d6fccafda2b5415a400fdf4a9`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: stone_block_grey
Variant: lush.
Palette anchors: #929a9a, #bcc2ae, #626f73.
Surface: Grey field-stone blocks for walls and banks, broad chunky roughly rectangular stones in staggered courses and narrow gaps.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Restrained grey-green lichen and weathered edges, muted colour drift between stones; no deep shadows.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## roof_tile_violet — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/roof_tile_violet_solid_generated.png` (1254×1254); SHA-256 `1352c2dfaa1b52962b14679cb44a614bf1ea21e86ec427e120b76ac4138d0ab3`
- Master: `art/source/world/textures/v1/raw/roof_tile_violet_solid_1024.png`; SHA-256 `7eaf0131a4c06669201fe81bab9adfdaaaaa0b75fee080f06d1d750e3a6a853c`
- Final: `assets/world/textures/solid/roof_tile_violet.png`; 8 colours; SHA-256 `e83fc690579c29259323e50a502e5562f3b916dadaecfe7fbb8256d8e90323a5`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: roof_tile_violet
Variant: solid.
Palette anchors: #66509a, #8271b1, #493c71.
Surface: Overlapping chunky violet slate roof tiles, THREE rows by THREE tiles across the repeat. Alternate rows offset. Each tile has a thin lighter lower-colour lip. Flat orthographic surface pattern, no roof, no perspective.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## roof_tile_violet — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/roof_tile_violet_lush_generated.png` (1254×1254); SHA-256 `c7cdb39505db4d664093b4d3971c7b86a47bddc515379ce8181d841cde1d2344`
- Master: `art/source/world/textures/v1/raw/roof_tile_violet_lush_1024.png`; SHA-256 `c0cfb4c0c7b9ec3f69f0d11abef4683fc6f57b1406ea7822e4f8ff8eb3b6ac87`
- Final: `assets/world/textures/lush/roof_tile_violet.png`; 48 colours; SHA-256 `025659d37be7ce1de10629433561197204cead96bd30f0c326c20f07d36562dc`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: roof_tile_violet
Variant: lush.
Palette anchors: #66509a, #8271b1, #493c71.
Surface: Overlapping chunky violet slate roof tiles, THREE rows by THREE tiles across the repeat. Alternate rows offset. Each tile has a thin lighter lower-colour lip. Flat orthographic surface pattern, no roof, no perspective.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. A few subtly faded or slightly uneven violet tiles, tiny matte weathering marks, no spectacular chips or moss blanket; retain three-by-three tile layout.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## roof_tile_teal — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/roof_tile_teal_solid_generated.png` (1254×1254); SHA-256 `325aa66771e5c6e8b65a90acf13685549e2117c4073ba97781447d50ac39c24b`
- Master: `art/source/world/textures/v1/raw/roof_tile_teal_solid_1024.png`; SHA-256 `d72fd6ae1ac909e86d46e4d2a30c126088dbb0de23fcf7e04c270341995a31f4`
- Final: `assets/world/textures/solid/roof_tile_teal.png`; 8 colours; SHA-256 `16be7e175048bfcd28264bcb2c593bcbc6163cc8468bdd59ba385cd3f688a2ad`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: roof_tile_teal
Variant: solid.
Palette anchors: #347b85, #4c939b, #255560.
Surface: Overlapping chunky teal slate roof tiles, THREE rows by THREE tiles across the repeat. Alternate rows offset. Each tile has a thin lighter lower-colour lip. SAME layout and scale as the violet roof texture. Flat surface, no roof or perspective.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## roof_tile_teal — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/roof_tile_teal_lush_generated.png` (1254×1254); SHA-256 `14c6dec411d0429e4bc2bd3522f781f31a282299ad5bf46f4e1cd8aa9b8b93aa`
- Master: `art/source/world/textures/v1/raw/roof_tile_teal_lush_1024.png`; SHA-256 `cf47fa50c29b08dae32ce8eae27ba26a5dbf485b55f28b8c502950245d0aaf02`
- Final: `assets/world/textures/lush/roof_tile_teal.png`; 48 colours; SHA-256 `842c09da8a0a5feab318831e441edab2e919692af3f3979477c60572895f3f70`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: roof_tile_teal
Variant: lush.
Palette anchors: #347b85, #4c939b, #255560.
Surface: Overlapping chunky teal slate roof tiles, THREE rows by THREE tiles across the repeat. Alternate rows offset. Each tile has a thin lighter lower-colour lip. SAME layout and scale as the violet roof texture. Flat surface, no roof or perspective.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. A few subtly faded or slightly uneven teal tiles, tiny matte weathering marks; retain three-by-three tile layout.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## iron — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/iron_solid_generated.png` (1254×1254); SHA-256 `040d144383e3396ecde473f1369c75dcf447b668a4fe95e69b9acfe8bd1dae0c`
- Master: `art/source/world/textures/v1/raw/iron_solid_1024.png`; SHA-256 `243f4283424a1bae7603a6da8da58ca0a86c9c0fbab6db86fcccbdeb53755675`
- Final: `assets/world/textures/solid/iron.png`; 8 colours; SHA-256 `d48882bb18419b73530dbc6c3f0fa7add6d40a193a528b13ba597b5d3c85ba2c`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: iron
Variant: solid.
Palette anchors: #394446, #5a6a6e.
Surface: Dark blue-grey hammered iron, broad faint matte hammer marks and one restrained repeating row of tiny rivet dots. No panel border, no metallic reflections.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 0.5 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## iron — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/iron_lush_generated.png` (1254×1254); SHA-256 `7271eb335cbacadb0dbe4028dd3d5a2cae8a14fd4d48892a494d790267b92eb6`
- Master: `art/source/world/textures/v1/raw/iron_lush_1024.png`; SHA-256 `3899a3681e1897da302f63417a4c077e04f8a0fd93f6d732af9110e0ede57682`
- Final: `assets/world/textures/lush/iron.png`; 48 colours; SHA-256 `bdeb24aa30209245c04c5538ba12f166b930e85e06f2d75d4f32dc3e934c6c8d`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: iron
Variant: lush.
Palette anchors: #394446, #5a6a6e.
Surface: Dark blue-grey hammered iron, broad faint matte hammer marks and one restrained repeating row of tiny rivet dots. No panel border, no metallic reflections.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Slight muted rusty-brown discoloration by some rivets, subtle warm/cool patina, never glossy; no outer border.
SEAMLESS REPEAT: This covers 0.5 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## brass — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/brass_solid_generated.png` (1254×1254); SHA-256 `2a228983b648917c537b66ba6908f550a9e11ee7622430bf88dd493e1bbee2f9`
- Master: `art/source/world/textures/v1/raw/brass_solid_1024.png`; SHA-256 `7636be9b270a7bc1cc6010dcce67b4480211f99845ccf72fad3eb9e6f7caf0df`
- Final: `assets/world/textures/solid/brass.png`; 8 colours; SHA-256 `61167db2f7f33603c1089c9c78bcffc7b5e43e01fc5de117a4e86d96795a0ba5`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: brass
Variant: solid.
Palette anchors: #e3b16a, #a8763a.
Surface: Warm hammered brass surface, broad quiet matte irregular hammer marks; no object, engraved symbol or shiny metallic highlight.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 0.5 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## brass — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/brass_lush_generated.png` (1254×1254); SHA-256 `40094d42ff282d5b9e578d096509e0591d6dff9b7dee00cf529b1ec3587c929a`
- Master: `art/source/world/textures/v1/raw/brass_lush_1024.png`; SHA-256 `e43fb19ce8ba6ed5631dd5122831c81dfc48c24ec213710d0eb276c69b583404`
- Final: `assets/world/textures/lush/brass.png`; 48 colours; SHA-256 `c2d7d631ed5da5e7d16baab216c6db0604559e5d66d44b0b637648e19d01021a`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: brass
Variant: lush.
Palette anchors: #e3b16a, #a8763a.
Surface: Warm hammered brass surface, broad quiet matte irregular hammer marks; no object, engraved symbol or shiny metallic highlight.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Restrained warm-brown patina and gentle colour drift, slightly more irregular hammer marks; no gloss or bright reflection.
SEAMLESS REPEAT: This covers 0.5 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## leaf — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/leaf_solid_generated.png` (1254×1254); SHA-256 `87dff758eda61958dc1579594e962d8e648bc68a6dac0451c9188b8d7f8e3fdf`
- Master: `art/source/world/textures/v1/raw/leaf_solid_1024.png`; SHA-256 `cf858947e689eac637e449379b1fa12dba86b7b54eca085297a950d822a736d3`
- Final: `assets/world/textures/solid/leaf.png`; 8 colours; SHA-256 `1b0076fd44d63d9410b16351fdba58fdc387da8c2cc7c6a041aa5180d56b19a1`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: leaf
Variant: solid.
Palette anchors: #4d7e35, #7ca946, #2e5835.
Surface: Chunky overlapping leaf clumps for voxel tree crowns, broad rounded angular clusters covering the tile, no branches, sky, fruit or flowers.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## leaf — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/leaf_lush_generated.png` (1254×1254); SHA-256 `2eb61c6840401a36d184583bc1e1fe04a01181c8ae23507caa54b26441b4da11`
- Master: `art/source/world/textures/v1/raw/leaf_lush_1024.png`; SHA-256 `7a3c60e6f77af29a9b085f8aa81842af6afb22927fbcfc7af04df9fa9c7cf463`
- Final: `assets/world/textures/lush/leaf.png`; 48 colours; SHA-256 `b21a1c51b52391e15bc2ec83734dab34e6894ce24b14e8b907a9143f80a4720a`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: leaf
Variant: lush.
Palette anchors: #4d7e35, #7ca946, #2e5835.
Surface: Chunky overlapping leaf clumps for voxel tree crowns, broad rounded angular clusters covering the tile, no branches, sky, fruit or flowers.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. More organic small leaf clumps and a few yellow-green leaves; lighter-colour clumps are flat albedo, never lighting or shine.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## bark — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/bark_solid_generated.png` (1254×1254); SHA-256 `c8ae98bd5bc38e06b24e7b5bea746dd39e4893d6ef6efc66b8afd057714b92cc`
- Master: `art/source/world/textures/v1/raw/bark_solid_1024.png`; SHA-256 `3e6f8df1ae277254e9be4088d51f0f3f080b9f7396cdd4f9b3bf7fb61f46d12f`
- Final: `assets/world/textures/solid/bark.png`; 8 colours; SHA-256 `43ef38210794b1f79a9fcc723209492d418cebb730164986c46a779768e6a115`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: bark
Variant: solid.
Palette anchors: #765039, #49382f.
Surface: Tree trunk bark with broad VERTICAL ridges and sparse broken vertical cracks, low contrast, no trunk object or silhouette.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## bark — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/bark_lush_generated.png` (1254×1254); SHA-256 `d9baa1c3d491f571430e59f8cc4351b9071aaedcfed705acb0362b4c286e27e8`
- Master: `art/source/world/textures/v1/raw/bark_lush_1024.png`; SHA-256 `2fd837d8c9ef2b2ca151f711cf9e7163b81131f1303ec582fcbb5fca0044a9a0`
- Final: `assets/world/textures/lush/bark.png`; 48 colours; SHA-256 `0ee0111de872d7453d666cb08766d7c677e8cba7c51213b6d1a25e6381198783`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: bark
Variant: lush.
Palette anchors: #765039, #49382f.
Surface: Tree trunk bark with broad VERTICAL ridges and sparse broken vertical cracks, low contrast, no trunk object or silhouette.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Richer irregular bark ridges, sparse subtle lichen and worn brown patches; retain vertical flow.
SEAMLESS REPEAT: This covers 1 world unit(s). It must tile perfectly on all four edges with continuous shapes crossing each edge and no visible repeat boundary. No central medallion or central lighting hotspot. Imagine a 3x3 repetition and avoid seams.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## lantern_glass — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/lantern_glass_solid_generated.png` (1254×1254); SHA-256 `2103b665375209dbb15b478ef491bc57b3999e446812299f27ebf94d2db03931`
- Master: `art/source/world/textures/v1/raw/lantern_glass_solid_1024.png`; SHA-256 `2b84b1af90e4825e82536460ad52dd0cd3dcbd136cc77374b07d659e4d08fb77`
- Final: `assets/world/textures/solid/lantern_glass.png`; 8 colours; SHA-256 `8cc5aa7377f65e405aa08a5b9da79d996cf805e54d16c032369f5e8c71b67844`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: lantern_glass
Variant: solid.
Palette anchors: #7a6648.
Surface: NON-TILING UNLIT smoked-brown glass colour swatch, filling the entire square. Overall colour MUST be the DARK MUTED BROWN #7a6648, not gold or orange. No transmitted light, no emission, no bright centre and no depicted object. Only an extremely gentle variation, about #706047 to #86704d, can describe a faint inner matte colour sheen.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
Critical: this is the UNLIT pane. It must be dark brown, visually distinct from the separately authored bright lantern_glass_lit texture. Do not paint a light or hot spot. No image frame or bevel.
```

## lantern_glass — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/lantern_glass_lush_generated.png` (1254×1254); SHA-256 `c71785f3ce2910375b95de2829f0ae0bc84eeccd88bed0193c2aa2784245ef44`
- Master: `art/source/world/textures/v1/raw/lantern_glass_lush_1024.png`; SHA-256 `d7af18524fe3b60a38e2618124b98cc086634274ec9eca7246b339d6583292fb`
- Final: `assets/world/textures/lush/lantern_glass.png`; 48 colours; SHA-256 `117656e2dc1d1ad812c35d29c1e3b971c126b745f7d7be7aff3b8e9e990c22e3`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: lantern_glass
Variant: lush.
Palette anchors: #7a6648.
Surface: NON-TILING UNLIT smoked-brown glass colour swatch, filling the entire square. Overall colour MUST be the DARK MUTED BROWN #7a6648, not gold or orange. No transmitted light, no emission, no bright centre and no depicted object. Only an extremely gentle variation, about #706047 to #86704d, can describe a faint inner matte colour sheen.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Slightly richer but still DARK MUTED BROWN drift around #7a6648. No light shining through it, no golden glow. Soft flat tonal variations in the narrow range #706047 to #86704d.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
Critical: this is the UNLIT pane. It must be dark brown, visually distinct from the separately authored bright lantern_glass_lit texture. Do not paint a light or hot spot. No image frame or bevel.
```

## lantern_glass_lit — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/lantern_glass_lit_solid_generated.png` (1254×1254); SHA-256 `ade070533978f24f368814473b02005dee2e2abea0f0c7cfcf4c22e387b22ee7`
- Master: `art/source/world/textures/v1/raw/lantern_glass_lit_solid_1024.png`; SHA-256 `cb6493800ebaaaea0c2ecb7bcdbd422fd1932569877c1fed26412f751a0b0928`
- Final: `assets/world/textures/solid/lantern_glass_lit.png`; 3 colours; SHA-256 `f5836b25bf469e19f1cd1f24daa1ca5203e384185c2af8184be3706a53bce114`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: lantern_glass_lit
Variant: solid.
Palette anchors: #ffe6a5, #f0b45a.
Surface: NON-TILING flat glowing lantern glass pane filling the full square. Pale warm cream centre and honey-orange outer area. In the SOLID version use EXACTLY THREE FLAT COLOUR BANDS, no continuous gradient, no visible flame, frame or lantern object.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## lantern_glass_lit — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/lantern_glass_lit_lush_generated.png` (1254×1254); SHA-256 `13e2f570a20835b292bf8e4de5454d0247ecc230266ff8a591665fd0ebcaf670`
- Master: `art/source/world/textures/v1/raw/lantern_glass_lit_lush_1024.png`; SHA-256 `809ec9a4659675ed48cfbe1eb2ad5039985588a6febb70034a1e7e03d8f9db82`
- Final: `assets/world/textures/lush/lantern_glass_lit.png`; 48 colours; SHA-256 `9364bdee048b51223cf600195e17e64e03cb226defbd695a2c5c6d55ad6ce3b9`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: lantern_glass_lit
Variant: lush.
Palette anchors: #ffe6a5, #f0b45a.
Surface: NON-TILING flat glowing lantern glass pane filling the full square. Pale warm cream centre and honey-orange outer area. In the SOLID version use EXACTLY THREE FLAT COLOUR BANDS, no continuous gradient, no visible flame, frame or lantern object.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Use a softly stepped richer warm cream-to-orange glow gradient, still pixel-art and albedo-only, no white lens flare or hard bright hotspot.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## window_glass — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/window_glass_solid_generated.png` (1254×1254); SHA-256 `e2119ee72043e5f2effb799681c7dadf9d9deaf265ceccd33609bf87c4af342b`
- Master: `art/source/world/textures/v1/raw/window_glass_solid_1024.png`; SHA-256 `d55061a2f1501d1143a1b7e0ae0c762a1b7c9db8fcd1894606d82a51107a2221`
- Final: `assets/world/textures/solid/window_glass.png`; 8 colours; SHA-256 `19397f1d318f7b64981b6fbf2d640f609a6756e109f5e030a58ea8c692c5c4d3`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: window_glass
Variant: solid.
Palette anchors: #526f7a.
Surface: NON-TILING flat dark blue-grey window glass pane filling the full square with a very gentle diagonal colour sheen. No window frame, mullions, scenery or reflection.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## window_glass — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/window_glass_lush_generated.png` (1254×1254); SHA-256 `9b40efe24af67094f41ce0091e1241535caef0a7cf679a76c86ce94a85b5e3e2`
- Master: `art/source/world/textures/v1/raw/window_glass_lush_1024.png`; SHA-256 `4080a50f5bf9d547429b7c165a643b581624b05afbba8bcaa5ba127a18ebc272`
- Final: `assets/world/textures/lush/window_glass.png`; 48 colours; SHA-256 `976b17cdafc5aba3b6ddafe75c719601f3a67eae42bf7d2a4ab2cd1d2207bcc1`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: window_glass
Variant: lush.
Palette anchors: #526f7a.
Surface: NON-TILING flat dark blue-grey window glass pane filling the full square with a very gentle diagonal colour sheen. No window frame, mullions, scenery or reflection.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. A richer very subtle stepped blue-grey diagonal colour drift, matte and quiet, no scratches or glints.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## window_glow — solid

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/window_glow_solid_generated.png` (1254×1254); SHA-256 `c767f199d3e3749e1c667dcf6c5fce215708817309599e50e1808e946057b2bd`
- Master: `art/source/world/textures/v1/raw/window_glow_solid_1024.png`; SHA-256 `01ba9d2976558a2ee1a9acf8b6536a52f46b9628c4b5e65f7f8ab4e868fb0f49`
- Final: `assets/world/textures/solid/window_glow.png`; 8 colours; SHA-256 `debfb0d819db4a55ffa0625f06b3fa46efc40cb7bcc6af665a9177e3e948ae6b`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: window_glow
Variant: solid.
Palette anchors: #f0b45a, #b8742c.
Surface: NON-TILING flat lit window pane filling the full square, warm amber centre and softly darker amber corners. No frame, mullions, candles, silhouettes or scene.
SOLID treatment: clean, bold, flat, even colour masses. MAXIMUM 16 colours in the entire texture; mostly 4-8. Very little detail.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```

## window_glow — lush

- Tool: built-in image_gen.imagegen
- Model: Not exposed by the built-in tool
- Seed: Not exposed by the built-in tool; no caller seed parameter
- Generated source: `art/source/world/textures/v1/native/window_glow_lush_generated.png` (1254×1254); SHA-256 `8efd9bfa7c776e565cce644a9faf7df4a630e924912101776920e71f49ed42d6`
- Master: `art/source/world/textures/v1/raw/window_glow_lush_1024.png`; SHA-256 `c4bc0032d648e3b3b86b19a3f61c681d44d297a47deb690759735ab02a3c096f`
- Final: `assets/world/textures/lush/window_glow.png`; 48 colours; SHA-256 `a22ec9420ebe01ee2df8fa6d5fb44d20a2a16294301c0dd1580a0d168e5684a6`
- Manual/processing edits: shared normalization above; no additional repainting.

```text
Use case: stylized-concept
Asset type: one production COLOUR/ALBEDO texture for Rootward Voxel, a warm saturated chunky voxel-inspired fantasy village. Flat straight-on surface, hand-painted pixel-art-inspired look. The game is isometric but THIS TEXTURE HAS NO PERSPECTIVE. Must read at 20-70 screen pixels per tile. Produce a square 1024x1024 master, opaque sRGB with no alpha.
Material ID: window_glow
Variant: lush.
Palette anchors: #f0b45a, #b8742c.
Surface: NON-TILING flat lit window pane filling the full square, warm amber centre and softly darker amber corners. No frame, mullions, candles, silhouettes or scene.
LUSH treatment: same material, layout and palette, richer organic finish with 24-48 colours, restrained extra detail, no busy focal mark. Richer softly stepped warm amber colour gradient with darker copper corners, no lens flare or pinpoint highlights.
This is NON-TILING: a single flat pane, with edge-to-centre colour as specified. No outline, frame, rim or pictured object.
Global constraints: Big crisp block-pixel shapes; smallest meaningful detail about 1/32 of the full tile. No subpixel grain, no brush noise, no blur, no gradients except the explicitly non-tiling glass panes. Even soft frontal/above light; colour only, no ambient occlusion, no baked cast shadows and no specular reflections. Relative to each local palette anchor, highlights within +12 percent and darker variations within -15 percent; the named dark mortar/seams remain material colours. Stay near the supplied palette within about 10 percent hue/lightness. Fill the whole image with the material. No photo, photorealism, 3D render, perspective, vignette, outer border, frame, text, labels, watermark, signature, people, characters, flowers, crates, barrels, sacks, props, strong shadows, specular highlights, blur or noise grain. Exactly one texture, not a contact sheet.
```
