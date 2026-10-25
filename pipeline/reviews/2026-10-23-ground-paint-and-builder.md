# Review: ground paint and compact builder — 2026-10-23

- Asset/area/source version: Kindle Hollow appearance block v1; `art/source/world/ground/v1/`; existing expansion-kit GLBs reused without source edits.
- Intended change and reference qualities: half-cell ground paint, continuous chunky pixel textures, ragged height-biased transitions, smaller searchable shelf, six new scenery items in the builder. Approved characters, camera and authored Rune Mill land retained.
- Build/check commands actually run and their results: `VOXEL_LAB_FRESH=1 scripts/art.sh` passed (offline character/icon/ground rebuild, 100 art and 42 skin checks); `scripts/test.sh` passed all 1,452 checks. Full suite counts are recorded below.
- Gameplay resolution/camera and renderer: Godot 4.7.2 Compatibility, Radeon 680M integrated GPU. Gameplay 1600×1000, zoom 13; builder 1280×720; ground GPU proofs use a 512×512 offscreen viewport inside a real window.
- Selected whole-scene/detail/movement evidence: [ground](../../evidence/ground-gameplay.png), [reference comparison](../../evidence/ground-blend-vs-reference.png), [Paint stroke](../../evidence/build-paint-stroke.png), [small shelf](../../evidence/build-compact-shelf.png), [tree shelf](../../evidence/build-new-trees.png), [Rune Mill](../../evidence/ground-rune-mill.png).
- In-game observations, including second use/rebuild: deterministic control maps and one texture per area; drag preview commits one edit on release, cancels without history, and undo/redo restore the full stroke. Save round trips, independently rebuilt rules for every path/walkability result on the pure fixture, non-top terrain geometry/material equality and six scenery lifecycles are checked. All 37 protected `.blend`, GLB and character PNG hashes match the starting snapshot. The windowed tour also commits Hearth House and Hearth Oak and verifies the model tree is drawn; see [placed scenery](../../evidence/build-new-scenery-placed.png).
- Performance: same area/focus/window before change, 245 ms build and 168 fps; final isolated run, 382 ms build and 168 fps (137 ms increase). Draw calls reduced from 421 to 385. Earlier concurrent authoring/review runs are excluded from the final comparison.
- Height-map acceptance: grass 0.8506, dirt_path 0.8234, cobble 0.8876, soil 0.8703, pebbles 0.8687, rock 0.8778. All six pass ≥0.55 correlation and exact opposite-edge checks. No lush height fell back; solid intentionally uses luminance from its own pictures.
- Known visual, behavior or pipeline defects: literal default-versus-all-`grass` equality is false because defaults contain light/dark tones. The GPU proof instead compares exact equivalent tones and uniform skin versus a single plane across half-cell and chunk boundaries (12 checks passed). Brook Mill's wheel is static decorative scenery, without quest bindings; its catalog footprint describes the shell. Captures/input checks are automated in windows; a human mouse/keyboard session is not claimed. No optional fringe sprites were needed. Export packaging is not a release gate exercised by this task.
- Decision: retain the reviewed implementation; all new scenery is studio catalog content and no new objects were placed in the shipped area.
- Next smallest proof needed: owner play review of brush feel and the new scenery placements.

## Final validation

`scripts/test.sh` passed, with the local WASI runtime executing outside the filesystem sandbox. All tests/reviews set `VOXEL_LAB_FRESH=1` and leave player saves alone.

| Suite | Checks passed |
| --- | ---: |
| World rules and Python/WASI | 73 |
| Area documents and five-quest arc | 90 |
| Build rules | 111 |
| Six builder scenery models | 62 |
| Ground data, geometry and history | 121 |
| Builder input and 40-card layout | 70 |
| Learning UI | 32 |
| App/session/save flow | 95 |
| Movement and routing | 30 |
| Painted art and idle | 100 |
| Shared frame skins | 42 |
| World art and area views | 124 |
| Authoring protection | 7 |
| Active pipelines and handoff links | 374 |
| Ground art hashes, edges and correlation | 121 |
| **Full-suite total** | **1,452** |

Separate windowed `tools/ground_shot.gd`: **12 GPU checks passed**, zero failures. `tools/area_shot.gd` reviewed Kindle Hollow and Rune Mill; `tools/build_tour.gd` reviewed compact cards, Paint and committed model placements. The offline `scripts/art.sh` rebuild passed. An initial sandboxed baseline run could not execute WASI and failed; the authorized host run passed, as did the final host suite. No failed check remains.

Implementation choices beyond the brief: expansion models are studio-only candidates; their existing source status/area placements were preserved. Dirt uses the same broad two-octave tone basis as grass. Warp amplitude was increased from the suggested 0.45 to 1.25 and height strength to 0.65 after side-by-side review. Equivalent-tone and single-plane pixel proofs replace the contradictory default-versus-uniform-grass equality. A preserved ancestor catalog proves ground-only additions do not require rewriting adopted Blender files.
