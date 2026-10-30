# Background houses and three-colour material pack — 2026-10-29

The user requested five further house concepts in varying sizes to make the town beyond the playable area feel inhabited, then added a dedicated texture folder with 2–3 colour choices. This pass delivers five residential concept plates and fifteen native material paintings, three colours in each of five surface families.

## Houses

[Five-house gallery](../../docs/concept/v0.72/background-houses.md).

D Lantern Row is a tall narrow four-storey lodging house with attic; E Saltwind is a broad three-storey apartment house under a low hipped roof; F Rosewash is a compact two-storey home with loft; G Shingle Court is a low wide cottage with loft; H Eaveside is one joined three-/two-storey terrace asset. Two complementary front/right and rear/left views show street and service elevations, complete roof forms and foundations. The plates fit their own canvases and are not one common scale.

The first D/H attempts lacked the taller floor counts. Targeted second passes add a full floor to D and to H’s taller half; both initial attempts are preserved. The selected plates are copied unchanged into the docs gallery. The earlier A–C seaside concepts and approved square reference remain unchanged.

All native images, exact prompts, reference/output hashes and generation attempts are under `art/source/world/seaside-background-houses/v1/`. The pictures are unselected model references, with no new building masters, placements or collision. Exact dimensions and facade consistency remain a modelling/adoption step.

## Materials

[Texture gallery and palette combinations](../../docs/concept/v0.72/house-textures.md).

- Plaster: cream, ochre, rose.
- Curved roof tile: terracotta, deep teal, slate grey.
- Masonry: pale limestone, honey sandstone, cool grey.
- Timber: honey oak, dark chestnut, weathered driftwood.
- Painted boards: teal, sage, dusty blue.

The fifteen opaque 1254-square native albedo maps have their own `textures/` folder, organised by surface. Additional colours were painted with imagegen edits of their family’s base map, preserving material pattern and wear. Individual records and a combined library/provenance file pin exact prompts and hashes. Three suggested palette combinations are recorded for authoring. No normal or displacement maps are supplied; roughness is scalar metadata.

The existing `scripts/art.sh` detail-texture build now accepts an optional `output_root`, restricted to `assets/world/textures/`. The new selected building library writes thirty 128-square lossless mipmapped maps and a manifest into **`assets/world/textures/seaside-houses/{lush,solid}/`**. Existing entries retain their default paths and pixels. No second build pipeline was introduced. New procedural recipes, finish-menu capabilities and bindings to house models are not added by this pack.

The normalizer retains its established method: lush uses Lanczos to 128; solid uses 64 then nearest to 128; opposite boundary pixels are paired. The originals remain untouched. Practical 2×2 repeats were reviewed in native Godot, without conspicuous gaps at this scale; this is not a claim that generated native motifs are mathematically periodic.

## Visible review

`tools/seaside_house_textures_review.gd` displays all fifteen actual built maps in both styles at 2×2 repetition, with colour names and five family columns. The 1600×1000 board provides the repeat/contrast check. No new house is rendered in the game, since this pass authors concepts rather than geometry.

- [Lush repeat board](../../evidence/seaside-house-textures/2026-10-29/lush.png)
- [Solid repeat board](../../evidence/seaside-house-textures/2026-10-29/solid.png)

## Validation

- `scripts/art.sh`: passed, including 100 painted-art and 111 shared-skin checks.
- `test_seaside_house_textures.gd`: **224 checks passed**; source/generation hashes, three colours per family, contrast after normalization, dedicated output paths, periodic boundary pixels and pinned imports.
- Native Godot repeat boards: both styles passed visual review.
- Full `scripts/test.sh`: passed after the material-build extension, including 224 new material checks and 1,337 pipeline/handoff checks.
- Preservation/link audit passed: 22 generation records, five unchanged gallery copies, all prior concepts and 88 existing texture outputs. Art catalog differs only by the appended library entry.
- `git diff --check`: passed.

All image creation/colour edits used built-in imagegen. Its model identifier and seed were not exposed. No existing Blender master or world selection was replaced; supplied game assets remain usable offline. No commit, push or publication was made.
