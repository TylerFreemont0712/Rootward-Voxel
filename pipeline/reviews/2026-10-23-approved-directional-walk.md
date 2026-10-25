# Approved directional walk and idle — 2026-10-23

This supersedes the character selection in [the earlier painted/Blender review](2026-10-23-painted-and-blender.md). The Blender world selections are unchanged.

The user approved the corrected SE pose 8 and the four directional sheets, requested SE mirrored as SW, and requested these sheets replace the existing runtime animation. The selected version is now **v9-directional-walk**.

## Implemented behavior

- Eight approved poses per direction at 16 FPS: a half-second loop across two grid steps.
- SW mirrors each corrected SE cell; NW mirrors each approved NE cell. Pose order is preserved.
- Source pixels are retained through integer registration. No new interpolation or character redesign is selected.
- Turns and held input retain animation phase. Stops select neutral pose 9 in the current direction.
- Idle breathes on a 3.6-second cycle, by at most 0.6% vertically in front views and 0.4% in rear views, anchored at the feet.
- Front views blink for 120 ms, with starts 6–7 idle seconds apart. SW's eye-patched blink is an exact mirror of SE.
- Rear views only breathe. Walking cancels breathing/blinking immediately.

The source snapshots, generated blink input, prompt, eye compositing record, atlas and hashes are under `art/source/adventurer/v9-directional-walk/`. The normal offline build remains `scripts/art.sh`. Old sources, the previous SW candidate and the inactive cutout experiment are preserved.

## Verification

`scripts/art.sh` passed the source/import/frame build and 100 painted-art/idle checks. `scripts/test.sh` passed **233 checks**:

| Checks | Count |
| --- | ---: |
| World rules and actual Python/WASI | 53 |
| App preview/apply, movement, undo and stale results | 24 |
| Grid routing and movement | 25 |
| Painted source identity, mirrored cells/blink, frame layout, idle timing and phase | 100 |
| World art and projected facing | 26 |
| Authored-source replacement guards | 5 |

Godot 4.7.2 rendered the actual scene at 1600×1000. The live held-key review observed SE/NE/NW/SW and verified each key followed its logical axis, producing 40 captures. A separate four-actor recording used the selected runtime resources: 64 walking frames at 32 FPS, and 128 idle frames at 16 FPS over eight simulation seconds. Both front-facing actors visibly reached their closed-eye frame. The rear actors retained their back-facing neutral artwork.

Reviewed the actual gameplay image and the eight-frame playback strips: corrected leg phases remain distinct, feet retain their baseline, idle retains facing, and the front blink is brief. Breathing remains intentionally very slight. The recordings use enlarged study actors to make the short blink inspectable, alongside a separate capture at normal gameplay size.

## Evidence and limits

[Gameplay](../../evidence/voxel-clearing.png) · [Walk recording](../../evidence/painted-walk.gif) · [Idle recording](../../evidence/painted-idle.gif) · [Blink still](../../evidence/painted-idle.png) · [Direction study](../../evidence/painted-directions.png)

The approved paintings still have small drawing differences between poses; integer registration preserves them. This is a reviewed prototype animation, rather than a claim of production polish or a general character system. Clothing/held-item layers, another character and additional areas remain deferred. No world rules, sandbox boundaries or Blender assets changed.
