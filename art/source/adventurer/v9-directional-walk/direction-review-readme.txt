# Approved directional sheets

These user-approved sheets are selected for the runtime v9 walk and neutral idle through `pipeline/art-catalog.json`. Immutable source snapshots and provenance are under `art/source/adventurer/v9-directional-walk/`.

| Sheet | Facing |
| --- | --- |
| `SE.png` | Toward the viewer and screen right |
| `SW.png` | Each corrected SE pose mirrored horizontally |
| `NE.png` | Away from the viewer and screen right |
| `NW.png` | Each approved NE pose mirrored horizontally |

Each sheet has a 3×3 layout, read left-to-right and top-to-bottom. Cells 1–8 are the walk; cell 9 is neutral idle. Mirroring happens within each cell, preserving the 1–9 order.

The SE pose-8 leg correction is preserved under `art/source/adventurer/v8-se-pose-8/`. Earlier sources and the old SW candidate remain preserved. The SE blink changes only the neutral pose's eyes and is mirrored exactly for SW. NE/NW only use the gentle breathing motion.

Painted sources were generated with built-in imagegen from the approved adventurer and Supernova Files' CC0 isometric pose template. Originals, source history and prompts remain under `art/source/`; `sources.json` identifies the selection. See [the character pipeline](../../../pipeline/CHARACTERS.md) and [runtime review](../../../pipeline/reviews/2026-10-23-approved-directional-walk.md).
