# Review: frame rate cap and lighter anti-aliasing — 2026-10-25

- Asset/area/source version: no art, area or Blender source changed. `app/game.gd` caps the frame rate and lowers the world viewport's MSAA; new tool `tools/perf_probe.gd`.
- Intended change and reference qualities: the owner noticed the computer working hard to run the game and asked for performance work while keeping the graphics (shadows included). 60 Hz is enough for this game.
- Cause found: on the owner's laptop (Radeon 680M driving a 2560×1440, 165 Hz panel) vsync let the game try to draw 165 frames a second. It reached about 127, with the GPU busy for the whole of every frame. The world was drawn with 4× MSAA at 2221×1250 (fullscreen, interface 80%); MSAA alone was two thirds of the GPU time. Scripts were cheap (median 0.8 ms per frame while walking), so CPU-side work was not the cause.
- Change: the game draws at most 60 frames a second (`Game.FRAME_RATE`), matching its 60 Hz movement, and 30 while another window has focus (`BACKGROUND_FRAME_RATE`). Headless runs are not capped, so tests keep their speed. The world viewport uses 2× MSAA instead of 4×. Shadows, lights, materials, the camera and all art are unchanged. The small turntable, character and thumbnail viewports keep 4×.
- Build/check commands actually run and their results: `scripts/test.sh` passed every suite (exit 0, including the handoff link check); `tools/perf_probe.gd` fullscreen with `ab`; a windowed check that focus out/in moves the cap 60 → 30 → 60 (measured 60.0, 30.0, 60.0 fps).
- Gameplay resolution/camera and renderer: Godot 4.7.2 Compatibility, Radeon 680M (Mesa radeonsi), fullscreen 2560×1440, interface scale 0.8, play zoom 13.
- Visual check: the same frame at 4×, 2× and no MSAA, cropped and enlarged around the apprentice, a resident, a lamp post and a tree. 2× could not be told from 4×; no MSAA showed slightly jagged lamp-post and roof edges, so it was not chosen. FXAA is not available in the Compatibility renderer.
- Measurements (`tools/perf_probe.gd`, standing at the start of a new game):

| | Before | After |
|---|---|---|
| Frames per second | ~127 (trying for 165) | 60 |
| World GPU time per frame | 5.5–5.8 ms (4× MSAA) | 3.6–4.1 ms (2× MSAA) |
| GPU busy, world only | ~70%, plus the interface, at the limit | ~25% |
| Whole process CPU, 10 s standing | 91% of one core | 30% of one core |

  Uncapped, the costs per frame are: MSAA 4× 5.5 ms, 2× 3.6 ms, off 2.0 ms of GPU; the sun's shadow 0.7 ms GPU and about 500 extra draw calls; the lamps' pooled lights nothing measurable. A frame shows about 860 draw calls and 540k triangles. The procedural leaf cubes are three quarters of the scene's triangles (about 800k in the whole valley), the largest remaining cost if more is ever needed. Booting to the title takes about 2 s; houses are already built only when entered, so loading needed no change.
- Known visual, behavior or pipeline defects: on a 165 Hz panel a 60 fps cap cannot divide the refresh evenly, so very fast camera glides may show slight unevenness; none was noticed in the automated runs, and no human session has judged it yet.
- Decision: keep.
- Next smallest proof needed: the owner plays a few minutes fullscreen and confirms the fan stays quiet and motion still looks smooth.
