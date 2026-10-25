# Village detail paintings, v2-detail

Fifteen individual paintings generated one at a time with built-in `image_gen.imagegen` on 2026-10-24. The tool did not expose a model identifier or seed. `library.json` preserves every exact prompt, design, scale, role and reference list. `generation.json` records returned file paths and hashes. `native/` holds exact copies of the returned 1254×1254 PNGs.

References were the existing v1 contact sheet, approved lush plank texture and village concept. Their hashes are recorded. The library extends cream/oak, teal/violet and pale stone without replacing previous pictures. Originals and references remain preserved.

`pipeline/art-catalog.json` selects this source. **`scripts/art.sh`** invokes `pipeline/detail_texture_builder.gd`, verifies design/native/reference hashes and packages derived RGB textures:

- Lush: Lanczos reduction to 128×128.
- Solid: Lanczos reduction to 64×64, nearest enlargement to 128×128.
- Opposite edge pixel pairs averaged, columns then rows, for a periodic pixel boundary.
- Lossless imports, mipmaps and no automatic 3D compression; nearest sampling with mipmaps in game.

This deterministic packaging leaves native paintings untouched. Equal boundary pixels alone do not prove structural seamlessness: inspect the 2×2 runtime boards and game views. No normal maps, displacement or lighting bakes are supplied.

Outputs: `assets/world/textures/{lush,solid}/<id>.png` and `assets/world/textures/detail-library.json`. Shared recipes, scales, roughness and copper's metallic value live in `pipeline/texture-catalog.json`. Both runtime styles were reviewed in Godot. Adopted Blender sources remain authoritative; game finishes are a saved appearance layer.

See [materials and controls](../../../../../pipeline/MATERIALS.md) and [the review](../../../../../pipeline/reviews/2026-10-24-detail-materials.md).
