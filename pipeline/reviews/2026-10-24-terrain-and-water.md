# Review: terraced land, stairs, water and waterfalls — 2026-10-24

- Asset/area/source version: Kindle Hollow document unchanged (no `levels` or `stairs` shipped); new optional document fields `levels` and `stairs`; new tool list `content/build/land-tools.json`; new shader `art/waterfall.gdshader`. No Blender source, GLB or character art changed.
- Intended change and reference qualities: the owner asked for land development "like Animal Crossing": level 1 and level 2 ground, stairs, and water on a higher level continuing to a lower one as a waterfall. Not too elaborate. Approved camera, characters and style retained.
- Build/check commands actually run and their results: every suite in `scripts/test.sh` was run one by one (each with a timeout) with `VOXEL_LAB_FRESH=1`: all Godot suites passed (counts below), `test_authoring_guards.py` 7 and `test_ground_art.py` 121 passed, and `test_pipeline_handoff.py` passed once this review existed.
- Gameplay resolution/camera and renderer: Godot 4.7.2 Compatibility, Radeon 680M, 1600×1000 window, build zoom 15 and play zoom 11–13.
- Selected evidence (from `tools/terrain_tour.gd`, which drives build mode as a player would): [a raise drag's proposal](../../evidence/terrain-raise-stroke.png), [stairs up two terraces](../../evidence/terrain-stairs.png), [a water drag across both levels](../../evidence/terrain-water-stroke.png), [the stream falling twice](../../evidence/terrain-waterfalls.png), [the apprentice climbing](../../evidence/terrain-climbing.png) and [standing on level 2](../../evidence/terrain-on-top.png).
- In-game observations: one drag raises a whole terrace; stairs snap to the cliff beside the pointer and show a ghost with the way up; the stream digs across both levels and falls at each cliff with spray at its foot; the apprentice routes up both flights, and the camera rises with them. The first look showed that a terrace's far (north and west) edges vanished into the land behind it from the fixed camera; the ground shader now draws a dark pixel contour along every edge that drops away, plus a soft shadow at cliff feet, which fixed it. A water drag's proposal was first drawn under the ground and was moved onto it. A flight could be built with its foot inside a house (unreachable); stairs now need room to stand at both ends.
- Performance: Kindle Hollow builds in about 1.67 s at 168 fps with terrain drawn per 16×16-cell chunk (767 draw calls), the same as the old single-pass build of the same document (1.66 s, 168 fps, 773 draw calls), measured back to back with `tools/area_shot.gd`. Shaping redraws only the touched chunks plus the skin, water and grid.
- Known visual, behavior or pipeline defects: land is whole levels only (no slopes); code cannot read or shape heights (cells keep `z = 0`); objects cannot straddle a cliff; no human mouse session has been recorded, only the automated tour; waterfalls on north or west faces are hidden by their own cliff, as cliffs are.
- Decision: keep. The shipped valley stays flat until the owner decides where terraces belong.
- Next smallest proof needed: the owner shapes a corner of the valley by hand and judges the cliff height (`TerrainBuilder.LEVEL_RISE`, 1.0) and the contour strength.

## Fullscreen green flash (reported at the same time)

Reported: a small green flash at the bottom of the screen, mostly in fullscreen and mostly inside houses. `tools/fullscreen_probe.gd` reproduces the owner's settings (fullscreen 2560×1440, interface scale 0.8) on this machine (Cinnamon on X11, Mesa radeonsi, Compatibility renderer), enters one house of each room template, walks every room, leaves again, and also toggles fullscreen inside a house. It checks every frame the game renders for strongly green pixels while indoors. `ffmpeg` recorded the real X screen at 60 fps at the same time.

- About 3,400 indoor frames rendered by the game: no green anywhere except single pixels of the apprentice's teal shirt.
- The X screen recordings (2,400 and 4,500 frames, fullscreen and toggling): no green at the bottom while indoors. The only green was the title screen's valley and, in windowed mode, the desktop panel.
- Ruled out in code: the quest marker (hidden indoors), the HUD (no green elements at the bottom), the fade veil, the room geometry and materials.
- Not reproduced, so nothing was changed. The kernel log shows panel self-refresh (PSR) enabled on this laptop's eDP panel, a known source of brief flicker on AMD Rembrandt laptops that a screen capture cannot see. A phone video of the flash, or a note of what was on screen and what was pressed, would show whether it is inside the game.

## Final validation

| Suite | Checks passed |
| --- | ---: |
| World rules and Python/WASI | 73 |
| Area documents and five-quest arc | 127 |
| Places and village | 93 |
| House travel and saves | 22 |
| Village dialogue | 119 |
| Build rules | 392 |
| **Terrain (new)** | **103** |
| Builder scenery | 62 |
| Building refresh | 48 |
| Builder library | 570 |
| Working prop flow | 16 |
| Ground | 121 |
| Surface finishes | 1,049 |
| Material controls and saves | 30 |
| Build mode (with land tools) | 170 |
| Building by code | 86 |
| Learning interface helpers | 32 |
| App, session and saves | 95 |
| Grid movement and routing | 30 |
| Painted art and idle | 100 |
| Shared frame skins | 66 |
| World art, area views and facing | 481 |
