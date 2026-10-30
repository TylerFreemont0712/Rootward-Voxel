# v0.7 concept art

Outputs of [the art prompt pack](../04-art-prompts.md) go here, one folder per phase. Everything here is a concept reference for the [Sparks & Machines journey](../05-scenario.md); nothing is a runtime asset, and the game never loads this folder.

| Folder | Phase | Ids |
|---|---|---|
| `1-style/` | Style lock | `T1`, `T6` |
| `2-hotaru/` | Hotaru | `H1`–`H4` |
| `3-cast/` | The apprentice and Nell | `C1`, `C2a`, `C2b` |
| `4-opening/` | Opening places | `T7a`, `T7b`, `T7c`, `P3`, `P1` |
| `5-town/` | The town | `T3`, `T4`, `T5`, `T2`, `P2` |
| `6-automatons/` | Automatons | `A1`–`A4` |
| `7-cast/` | The rest of the cast | `C3`–`C6` (portrait `a`, sprite `b`), `C7` |
| `8-interface/` | Interface | `U1`, `U2` |
| `9-future/` | Future places | `F1`–`F3` |

**The full pack is complete:** [browse the visual gallery](gallery.html), [open the 38-image index](INDEX.md), or read [current design decisions](DESIGN_DECISIONS.md).

## Naming

`<id>-<slug>.png` exactly as the pack lists it, for example `2-hotaru/H1-turnaround.png`. Up to two runners-up may sit beside it as `H1-turnaround.alt1.png` and `.alt2.png`. Never overwrite an image the user has approved; make a new version as `H1-turnaround.v2.png` and note why. Separate `.wheels.png` revisions apply the user’s rolling-base direction; `.circuit.png` records the festival lighting correction. The authoritative current choices are `selected_concepts` in [prompts.json](prompts.json).

## Recording

Add one entry to `prompts.json` for every saved image:

```json
{
  "id": "H1",
  "file": "2-hotaru/H1-turnaround.png",
  "date": "2026-10-27",
  "tool": "the image tool and model you used",
  "inputs": ["art/source/companions/hotaru/v3/concept/turnaround-sheet.png", "..."],
  "prompt": "the exact final prompt text, shared blocks included",
  "variant": "which of the generated variants was chosen, and why",
  "status": "draft | approved | rejected",
  "notes": "anything the reviewer should know"
}
```

Paths are relative to the project root for inputs and relative to this folder for `file`. Set `status` to `approved` only when the user says so.

## Review

The user superseded the pack's phase approval stops on 2026-10-26: “go with your best instinct, and go through all the remaining pieces of the art concept creation”. Continue through all remaining phases, selecting coherent concepts without further approval requests. Keep individual user approvals distinct from selections made under this delegated judgment. Everything remains concept art; runtime adoption is separate.

## Completed pack — 2026-10-26

All **38 requested concept images across nine phases** have current selections. The folder preserves **91 PNGs**, including alternatives, earlier approvals and one intermediate lineup study. Ground-going automatons use compact rolling wheel bases; Hotaru keeps her floating silhouette and tucked wheels.

| Phase | Review | Selections |
|---|---|---:|
| 1 · Style lock | [Review](1-style/REVIEW.md) | 2 |
| 2 · Hotaru | [Review](2-hotaru/REVIEW.md) | 4 |
| 3 · The apprentice and Nell | [Review](3-cast/REVIEW.md) | 4 |
| 4 · Opening places | [Review](4-opening/REVIEW.md) | 5 |
| 5 · The town | [Review](5-town/REVIEW.md) | 5 |
| 6 · Automatons | [Review](6-automatons/REVIEW.md) | 4 |
| 7 · The village cast | [Review](7-cast/REVIEW.md) | 9 |
| 8 · Interface | [Review](8-interface/REVIEW.md) | 2 |
| 9 · Future places | [Review](9-future/REVIEW.md) | 3 |

The six directly approved original images remain preserved with their approval records. Later wheel revisions and the remaining selections use the user's delegated art judgment; their individual statuses remain draft. The gallery uses the current selection map rather than treating historical approval as a newer locomotion decision.

Native pixels are preserved. Landscapes are 1536×1024, portraits 1024×1536, and square sprites/model studies may be the tool's native 1254×1254 despite a 1024×1024 request. Exact dimensions and alpha details are recorded per image. A few transparent images need low-alpha edge cleanup before adoption.

The pack has been visually reviewed and checked for PNG decoding, dimensions, transparency, image/reference hashes, prompt blocks, complete coverage and local links. [Validation results](validation.json) record the final inventory. The full game suite passed during Phase 1; it was not repeated for these concept-image and documentation changes. Gameplay-scale Godot review, source modelling and runtime adoption remain separate work through the existing project pipelines.
