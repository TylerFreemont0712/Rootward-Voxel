# Town ground paints (2026-11-06)

Build-mode ground paints that suit Haverlund, so painted ground sits with the authored square.

| File | What it is |
| --- | --- |
| `paint.py` | Deterministic painter (Blender numpy; run once, it never overwrites a native). It reuses the masonry and noise routines of `../../sparks-lane/v1/textures.py`. |
| `native/town_flags.png`, `native/town_cobbles.png` | The square's own `lane-flags` and `lane-cobbles`, copied unchanged. |
| `native/town_setts.png`, `town_brick.png`, `town_gravel.png`, `town_bed.png` | New: granite setts (seed 4101), running-bond brick (4102), garden hoggin (4103) and planting-bed soil (4104), with features sized to survive the 128-pixel runtime pictures. |
| `library.json`, `generation.json` | The texture library and its hashes, built by `scripts/art.sh` as `town-ground-v1` into `assets/world/textures/{lush,solid}/`. |
| `texture-catalog-before.json` | The exact texture catalog before these ground-only additions (the `compatible_bake_catalog` ancestor), so adopted Blender bakes stay valid. |

Lawn uses the existing `grass` picture. How paving and kerbs meet is described in [GROUND](../../../../../pipeline/GROUND.md#town-ground).
