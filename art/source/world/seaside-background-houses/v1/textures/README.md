# Seaside house materials

Fifteen native opaque **1254×1254 albedo PNGs**, organised by surface, with three colours per family:

| Folder | Colours | Suggested repeat width |
| --- | --- | --- |
| `plaster/` | Cream, ochre, rose limewash | 1.5 world units |
| `roof/` | Terracotta, deep teal, slate-grey ceramic | 1.2 |
| `stone/` | Pale limestone, honey sandstone, cool grey | 1.5 |
| `timber/` | Honey oak, dark chestnut, driftwood | 1.0 |
| `shutter/` | Teal, sage, dusty blue painted boards | 0.8 |

All five first surfaces were painted by built-in imagegen using the new house concepts as style references. Each additional colour is an imagegen edit of its family’s first map, preserving the pattern and changing the palette. Native files and their exact generation records are immutable source. No Python/image-editor recolouring was used. The tool exposed no model identifier or seed.

`library.json` contains every exact prompt, colour, repeat width, roughness and three recommended full-house palette combinations. `generation.json` pins the library hash and all source/reference hashes; individual `.generation.json` files preserve each call and original tool output path.

## Normal build

```sh
scripts/art.sh
godot --headless --path . -s res://test/test_seaside_house_textures.gd
```

The selected entry is in `pipeline/art-catalog.json` under `building_texture_libraries`, with `output_root: res://assets/world/textures/seaside-houses`. The existing detail-texture builder supplies thirty RGB PNGs in that folder’s `lush/` and `solid/` subfolders plus `manifest.json`. Existing libraries retain their default output folder and pixels. The optional output root is restricted to `assets/world/textures/`.

Lush normalises to 128 with Lanczos; solid normalises to 64 and enlarges to 128 with nearest filtering. Opposite boundary pixels are paired and imports are lossless with mipmaps. Native paintings are retained for higher-detail modelling. These are base-colour maps, with scalar roughness/metallic metadata; no normal/displacement maps or material `.tres` files are supplied.

The library is ready for material authoring using explicit texture paths. New procedural recipes, finish-menu choices, model material bindings and house adoption remain future integration. Avoid changing old assets merely to expose this pack.

## Review

```sh
godot --path . --resolution 1600x1000 -s res://tools/seaside_house_textures_review.gd
```

The native Godot board repeats each actual built map 2×2 in both styles, saved under `evidence/seaside-house-textures/2026-10-29/`. It shows practical repetition and palette contrast without modifying any placed model. [Texture gallery](../../../../../../docs/concept/v0.72/house-textures.md).
