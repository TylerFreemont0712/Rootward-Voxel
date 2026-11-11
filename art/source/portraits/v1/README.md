# Village dialogue portraits v1

Five separately painted high-definition **1024×1536 RGBA** portraits, generated with the built-in `image_gen.imagegen` tool. These are the selected UI portraits for the user's classic single-speaker visual novel direction, displayed at the smaller scale and raised position documented in [the conversation guide](../../../../pipeline/DIALOGUE.md).

| Person | Source | Identity |
|---|---|---|
| Mira | [mira.png](mira.png) | Espresso bob, brass clips, plum coat, ochre scarf and sage cuffs. |
| Rowan | [rowan.png](rowan.png) | Silver hair/beard, teal waistcoat, cream shirt and rust scarf. |
| Bram | [bram.png](bram.png) | Dark curls, warm brown skin, copper vest, burgundy sleeves and leather apron. |
| Tessa | [tessa.png](tessa.png) | Strawberry braid, moss cap, russet jacket and sage scarf. |
| Nell | [nell.png](nell.png) | Silver braided bun, round brass spectacles, teal/gold shawl and violet tunic. |

The original neutral sprite for each resident is the identity reference, and [classic concept A](../../ui/village-dialogue-concepts/v1/a-classic-portrait-stage.png) is the illustration-style reference. The new paintings were copied from generated outputs without editing their pixels. They contain real alpha; underlying RGB colors in fully transparent pixels are not a painted runtime backdrop. The output tool's inline preview may show those colors differently from Godot's alpha compositing.

[Exact prompts](prompts.json) · [Generation record, source hashes and reference hashes](generation.json). Built-in mode was used; model identifier and seed were not exposed. Original generated files remain at the paths recorded in `generation.json`.

`pipeline/art-catalog.json` selects the source hashes and outputs; `scripts/art.sh` includes `pipeline/portrait_builder.gd`, preserves source pixels and builds `assets/portraits/*.png` plus the manifest. Import uses lossless RGBA, linear UI filtering, transparent-edge repair and no mipmaps. Do not resize/repaint existing masters in place; use a new version and preserve its prompt/provenance. No walking sprite, character template or skin motion setting was changed.

[In-game review](../../../../pipeline/reviews/2026-10-24-village-dialogue.md)
