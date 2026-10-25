# Bigger houses, the texture pack, blocked-direction facing and build mode — 2026-10-23

- **Asset/area/source version:** `log-cabin-large` v1 and `log-cabin-large-teal` v1 (new); `cottage`, `mill-house`, `clearing-ground`, `log-cabin`, `lamppost` retextured (their `.blend` files rewritten by `retexture`, originals kept as `model.pre-retexture.blend`); `content/areas/kindle-hollow.json` re-laid (buildings, one fence end, `locked` on the mill); `pipeline/texture-catalog.json` (new); `content/build/catalog.json` (new); build mode in `core/area_build.gd`, `core/build_ledger.gd`, `app/build_mode.gd`, `scenes/build_overlay.gd`, `ui/build_hud.gd` and friends.
- **Intended change and reference qualities:** the owner asked for (1) the delivered texture pack wired in; (2) houses about two tiles bigger on each side, with the town re-laid; (3) the character to turn toward a blocked direction instead of doing nothing, for keys and for clicks; (4) a Sims-style in-game editor started and organised (add, move, delete; a polished interface; eventually open to players in part); (5) a think about 2×2 ground sub-tiles.
- **Build/check commands actually run:**
  - `scripts/test.sh`: **every suite passes**, run one by one and together: lab 73, area 90, **build 96 (new)**, **build mode 48 (new)**, ui 32, app 95, movement 30, art 100, frame skins 42, world art 124, source protection 7, handoff/links 306. `test_build_mode` also passes (49 checks, including that every card shows its picture) when run in a window.
  - `scripts/world-art.sh seed|init|build|compare` for both new houses: lossless round trip (18,264 triangles each). `compare` failed on the first attempt (see defects).
  - `scripts/world-art.sh retexture` + `build` for the seven adopted sources above.
  - `tools/build_tour.gd` (via `scripts/screenshot.sh`) drives build mode through the real game and saves frames; `tools/build_overlay_shot.gd` renders the drawing alone; `tools/area_shot.gd`/`asset_shot.gd` for the town and the houses.
- **Gameplay resolution/camera and renderer:** 1600×1000 for the tours, 1440×900 for area shots; GL Compatibility on an AMD Radeon 680M. The build camera is free at ortho size 15 (the play zoom is a setting, default 13).
- **Selected evidence:** [build mode with the shelf](../../evidence/build-mode.png), [a good placement](../../evidence/build-place.png), [a refused one](../../evidence/build-refused.png), [moving](../../evidence/build-move.png), [the locked mill](../../evidence/build-locked.png), and the new town in [the play start](../../evidence/voxel-clearing.png).

## What was observed

- **Facing:** walking into water, a wall or a house turns the character toward it; clicking an unreachable or blocked cell turns toward the larger part of the offset. Turning is ignored mid-step. Tested with simulated steps and clicks; not with real held keys (a headless run has no window focus).
- **Textures:** the ground, paving, water, trees, fences, walls and decks now wear the painted pictures at one tile per cell, lined up across every block; the cobble courtyard and the river read as painted. The lush set is the default. Baked into the adopted models, the cabins and the lamppost show log courses, stone blocks and roof tiles at the right scale, and the lit lantern uses the painted glow.
- **Houses:** the five-cell houses read as a village rather than a row of sheds, and the teal-roofed miller's house echoes the mill. Every reachability and quest test still passes after the re-lay (88 then 90 area checks).
- **Build mode:** the shelf shows the real models (drawn from the game's own camera angle and light), the ghost is green where allowed and red with a reason where not, the grid glows near the pointer, and the cut-off check refuses a cabin standing in the Night Gate's doorway ("That would cut you off from…"). Measured: about 110 ms to place and about 50 ms to refuse, so it is safe to run live. The mill reads as "Part of the lessons" and cannot be moved or removed. Edits survive a trip to the title and Continue.

## Defects found and fixed during the work

- The ground rendered black when triplanar sharpness was 40: Godot weights projections by instance scale, so thin slabs underflowed. It is 4 now, with a comment saying why.
- The first `compare` of the large houses failed: the seed's "lighter" tones had a colour factor above 1, which glTF cannot store. Seeds now clamp tints; `retexture` bakes the real tints into the pictures. The drafts (unedited, hashes matching) were moved aside and the one-time handoff redone.
- Per-cell paving tone made a checkerboard; it now drifts in broad patches.
- Picking used each model's whole bounding box, so a house's roof overhang swallowed the mill behind it; it uses the footprint, grown a little, up to the model's top.
- A removed building kept its node name until freed, so a replacement of the same id was renamed and could not be found; the name is released at once.
- The thumbnail studio waited forever for a frame in a headless run, and cached ghost models were never freed; both leaked resources at exit. The studio skips drawing without a renderer and the overlay frees its cache.
- Tree crowns are now seeded from where a tree stands (not its position in a list), so adding or removing one cannot change another. This changes how existing crowns look.
- The lamp test hard-coded my first geometry's lantern height; it now checks the halo sits at the glass wherever the model puts it.

## Known gaps

- **No human has played build mode.** The tests drive the game's own input path with simulated events; no real mouse or keyboard session was recorded, and no gamepad or touch support exists.
- Build-mode frame rate was not measured separately. The grid is one transparent plane and the overlay is a handful of nodes.
- The mill, the plaster cottage and the lamps were not changed or made movable; there are no walls, fences, paths, ground painting, copy/paste or multi-select.
- The `player` policy and its allowances (8 buildings, 40 trees) are placeholders chosen by `VOXEL_BUILD_POLICY=player`; nothing stores a player's tier.
- Ground sub-tiles are a design note only ([the handoff](../../docs/HANDOFF_2026-10-23_build-mode.md#5-ground-sub-tiles-design-only)).
- The `solid` texture set is wired but there is no Settings choice; baked models are fixed until retextured.
- The lamppost's saved source contains the owner's hand edit and my added lantern cross bars (`lantern_mullions_geometry`); the owner has not said whether to keep them.

## Decision

Accept the texture wiring, the five-cell houses and the blocked-direction facing. Accept build mode as the **foundation** of the editor (rules, ledger, saves, interface and picture), not as finished.

## Next smallest proofs

1. A human session in build mode: place, move and delete with a real mouse, noting anything that fights the hand (hover, rotate, panning, the shelf).
2. Ground painting through the same ledger (an edit op `paint`), starting with the 2×2 sub-tile data from the handoff's design.
3. A Settings choice for solid or lush, and a decision on whether the mill and cottage grow too.
