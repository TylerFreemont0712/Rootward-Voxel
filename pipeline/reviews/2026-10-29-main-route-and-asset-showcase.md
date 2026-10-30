# Sparks main route and title asset showcase — 2026-10-29

The user selected **Sparks & Machines** as the main game, paused Kindle Hollow and Village Morning for rework, and requested an empty development display directly on the main title before detailed building work.

## Result

- The catalog selects Sparks as `default`. New game opens its naming screen directly; Continue considers only unarchived saves. Startup shows the loft with its fixed room camera.
- Kindle Hollow and Village Morning have `archived: true`. Their IDs, authored content, code and save filenames remain intact. Explicit development/test start and continue calls still work; legacy regression tools now name their intended journey.
- **Asset Showcase (Dev)** appears on the title. It opens an initially empty, separate orthographic viewport, hides/pauses the normal world presentation, and restores the title on Esc or Back to title. It has no session or save access.
- Search and select models from `pipeline/world-catalog.json`; drag to turn, use the wheel to zoom, or use quarter-turn/reset and auto-rotate. Optional metre grid and the unchanged boy sprite give scale. Bounds fitting preserves the whole model through rotations. Reload uses the existing model factory with cache replacement; Clear restores the empty stage.
- `rootward/development/asset_showcase_on_title=true` in `project.godot` exposes the option now. Set it to `false` to hide both the entry and handler later. Release builds also hide it.

Implementation: `app/level_store.gd`, `app/game.gd`, `ui/title_screen.gd`, `ui/asset_showcase.gd`, `scenes/asset_showcase_stage.gd`, the existing `ModelTurntable` and `WorldAssets` loader. No new art pipeline, engine, provider or runtime service.

## Verification

- Headless import passed. `test/test_asset_showcase.gd` passed **35 checks**: real title mouse input, keyboard search, catalog-row selection, drag/turn, wheel, grid/figure checkboxes, reload, clear and Escape; empty initial stage; four complete workshop views; correct New game/Continue; disabled-entry behavior; unchanged profile/session and byte-identical archived test saves.
- Native Compatibility/llvmpipe review passed at **1600×1000**, **1280×720**, and **1280×720 with 150% UI scale**. The input-driven test also passed in those windows. No cropped model roof or clipped showcase controls. Moving the boy along the camera’s screen-left ground direction keeps him visible beside a large building.
- Focused Village Morning and Sparks regressions passed after updating public-route expectations and explicit legacy IDs.
- Full `scripts/test.sh` **passed, exit 0**: both archived journeys, Sparks and connected rooms/quests, WASI, app/save flows, the new 35 showcase checks, movement, artwork, 224 house-material checks, 124 asymmetric robot-art checks, 885 world-art checks, 11 source guards, 1,342 pipeline/link checks and ground handoff.
- `git diff --check` passed. Existing source art, model masters, area layouts and actual player saves were not rewritten by this slice.

Local logs: `.cache/main-route-and-showcase-full-test.log`, `.cache/asset-showcase-test.log`, `.cache/asset-showcase-native-1600.log`, `.cache/asset-showcase-native-1280.log`, `.cache/asset-showcase-native-ui150.log`. Xvfb emitted its usual input-method and unsupported V-Sync warnings; the native runs had no script/rendering errors.

## Selected evidence

- [Main title](../../evidence/asset-showcase/2026-10-29/1600x1000/01-title.png)
- [Initially empty stage](../../evidence/asset-showcase/2026-10-29/1600x1000/02-empty-stage.png)
- [Workshop and scale figure](../../evidence/asset-showcase/2026-10-29/1600x1000/03-workshop.png)
- [Wick with metre grid](../../evidence/asset-showcase/2026-10-29/1600x1000/04-robot.png)
- [Smaller window](../../evidence/asset-showcase/2026-10-29/1280x720/03-workshop.png)
- [Smaller window, 150% interface](../../evidence/asset-showcase/2026-10-29/1280x720-ui150/03-workshop.png)

## Boundary and next work

Accepted as the development inspection space. It displays existing runtime models; it does not model a new house, import raw concept PNGs, edit geometry or place objects in the playable world. Future detailed buildings should get versioned sources and a normal world-catalog/runtime handoff, then be reviewed here before placement. Source material and concept galleries remain under `docs/concept/v0.72/` and `art/source/`.
