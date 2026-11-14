# Main-project handoff

This is a self-contained Godot 4.7.2 project. **Sparks & Machines** is the only journey: it starts in `content/areas/workshop-loft.json` and passes through the workshop floor, Spindle Lane, Rootward Square, City Hall and five shops (ten saved rooms, listed in `content/levels/catalog.json`). The user accepted the clearing's size, camera scale, painted boy and voxel-inspired style as the baseline; keep them stable unless a feature deliberately needs a reviewed change. Nothing here depends on, or edits, the separate main Rootward game.

Kindle Hollow and Village Morning were removed on 2026-11-05. See [what was removed and how to get it back](PURGE_2026-11-05.md). Folders, file names and ids follow [NAMING](NAMING.md); the 2026-11-07 tidy-up that set them is [RENAMES_2026-11-07](RENAMES_2026-11-07.md).

## Start and verify

```sh
scripts/setup.sh             # once per clone: pinned Python/WASI runtime and the game's media packs (--dev adds art sources)
scripts/play.sh
scripts/test.sh              # quick tier, ~20 s; `flow`, `full` and `smoke` add more (see [../test/README.md](../test/README.md))
```

Playing uses supplied runtime art; no Blender, AI service or network is needed once the media is fetched. Pictures and models live in release packs pinned by `media.lock`, not in git ([RELEASES](RELEASES.md)): after an art build, `scripts/pack-media.sh --write` and commit the lock. Builds for players and the installer are also in [RELEASES](RELEASES.md). After changing character sources run `scripts/art.sh`; after changing an adopted model edit its `model.blend` and run `scripts/world-art.sh build <id>`, then `godot --headless --editor --import --quit` before any capture. The project keeps the name and the `RootwardVoxelLab` save directory so existing saves load; a future rename needs an explicit saved-source migration.

## What the game is

| Area | Contract |
| --- | --- |
| Engine and view | Godot 4.7.2 desktop, orthographic camera at the approved heading and elevation, following the player; textured 3D world with painted billboard characters. Maps are versioned area documents in `content/areas/`; one world unit per cell; logical `[x,y,height]` maps to Godot `(x,height,-y)`. |
| Movement | Four-direction grid steps at 60 Hz (13/60 s each), smooth presentation, one buffered tap, held repeat and click routing. |
| Characters | Shared `painted_chibi_v1` frame template: eight-pose walk in four views, breathing idle, front blinks. Skins ([CHARACTERS](../pipeline/CHARACTERS.md)) are shared-frame paintings; the boy is the only player appearance. Hotaru and the robots are Blender models. |
| Programming | Python runs only in the pinned Wasmtime/CPython WASI runner on a worker thread; every returned command passes `core/` validation. A preview is a proposal until Apply commits that same proposal. Code sees only places the player has visited and stood beside ([PROGRAMMING](PROGRAMMING.md)). |
| Persistence | One save slot for the journey: every room's state, quests, program memory, source, name, pay and the shared clock, plus the player's layout edits in the square. The edit layer never rewrites an area document. |
| Source authority | Versioned painted art and adopted Blender masters; runtime output is rebuilt from the catalogs. |

## The places

- **Loft and workshop floor** (`workshop-loft`, `workshop-floor`): bed, desk terminal, Nell's note, the field tablet and wall screen; chapters 00–02 (`say-hello`, `waiting-ticket`, `landing-light`, `morning-round`). Reviews: [loft](../pipeline/reviews/2026-10-27-sparks-loft-furnished-and-first-code.md), [workshop](../pipeline/reviews/2026-10-27-workshop-floor.md), [rearranged](../pipeline/reviews/2026-10-29-workshop-floor-rearranged.md), [tablet and wall screen](../pipeline/reviews/2026-10-27-tablet-and-wall-screen.md).
- **Spindle Lane** (`haverlund-lane`): the street, the town gate (two real hinge nodes), the tram halt, Braum's garden and the tram sign for **A proper welcome**. Reviews: [lane](../pipeline/reviews/2026-10-28-spindle-lane.md), [tram stop](../pipeline/reviews/2026-11-02-tram-stop-and-shared-slate.md), [welcome quest](../pipeline/reviews/2026-11-02-welcome-quest-and-property.md), [lane errands](../pipeline/reviews/2026-11-02-lane-errands-and-development.md).
- **Rootward Square** (`haverlund-square`, 88×64): the Rootwell, the guild hall and City Hall, market, shops, a terraced west promenade (Spindle Walk, with Pendulum & Pin) and the **Layout · B** studio. The square stands high over the harbour: below the walls everything vanishes into solid white mist ([depth mist](../pipeline/AREAS.md#the-high-square-white-mist)). Reviews: [hub](../pipeline/reviews/2026-10-29-square-hub-v3.md), [lighting and shops](../pipeline/reviews/2026-11-03-square-lighting-and-shops.md), [layout studio](../pipeline/reviews/2026-11-03-square-layout-studio.md), [restoration](../pipeline/reviews/2026-11-04-square-restoration-and-clockshop.md), [clockshop expansion](../pipeline/reviews/2026-11-04-clockshop-expansion-and-depth.md).
- **City Hall and shops** (`city-hall`, `shop-bakery`, `shop-greengrocer`, `shop-tailor`, `shop-clockmaker`, `shop-apothecary`): cutaway rooms linked from the square; the clockmaker's 14×14 room has fifty placed objects, and Morning Loaf, The Pantry and Finch & Thread were furnished again on 2026-11-12 with their own storefronts ([review](../pipeline/reviews/2026-11-12-market-shops.md)). Thyme & Tonic (original model, 2026-11-05) stands beside the clockmaker; its room is still the empty shell.
- **City, clock and money:** `core/city_cycle.gd` owns the saved clock (a day is 24 minutes of exploration; travel and cognition pause it) and latched overload; `core/lamp_programs.gd` and `core/robot_programs.gd` compile real executions into validated routines; `core/player_accounts.gd` keeps an integer-pence purse, bank balance and receipts. Review: [clock, evening and City Hall](../pipeline/reviews/2026-11-02-city-clock-evening-and-hall.md).
- **Dialogue and transitions:** story windows and the clockwork veil. [Review](../pipeline/reviews/2026-11-02-dialogue-and-clockwork-transitions.md); voice rules in [concept/v0.7/07-dialogue.md](concept/v0.7/07-dialogue.md).

## Pipeline map

| Work | Authoritative source and build | Verification |
| --- | --- | --- |
| Characters and skins | [CHARACTERS](../pipeline/CHARACTERS.md); template and skin catalogs; `scripts/art.sh`. | `test_art`, `test_frame_skins`, robot art tests. |
| Buildings, props, room pieces | [WORLD_ASSETS](../pipeline/WORLD_ASSETS.md), [BLENDER](../pipeline/BLENDER.md); `pipeline/world-catalog.json`; masters in `art/source/world/<id>/vN/model.blend`; `scripts/world-art.sh build <id>`. | `test_world_art` (full tier), the room tests. |
| Area layout, lessons, collision | [AREAS](../pipeline/AREAS.md); `content/areas/<id>.json` and `.quests.json`; `core/area_def.gd`, `core/lab_world.gd`, `core/quests.gd`. | `test_area`, `test_lab`, the room tests. |
| Layout studio (build tools) | [BUILD](../pipeline/BUILD.md), [GROUND](../pipeline/GROUND.md); `core/area_build.gd`, `core/build_ledger.gd`, `app/build_mode.gd`, `content/build/`. | `test_build`, `test_ground`, `test_terrain`, `test_layout_flow`. |
| Programming API | [PROGRAMMING](PROGRAMMING.md); rules in `core/`, adapter in `sandbox/`. | `test_lab`, `test_ui`, flow tests. |
| Interface | [UI](../pipeline/UI.md); `ui/`, `app/game.gd`. | `test_app`, `test_ui`, flow tests. |
| Asset requests | [asset-requests/README](../asset-requests/README.md); `scripts/asset-requests.sh`. | `test_asset_workflow.py`, `test_asset_request_ui`. |
| Visual acceptance | [REVIEW](../pipeline/REVIEW.md); `tools/area_shot.gd`, `tools/reviews/`; selected `evidence/` (the `dev-evidence` pack). | Captures at the real camera scale. |
| Builds, installer, media packs | [RELEASES](RELEASES.md); `scripts/build.sh`, `installer/`, `scripts/media.py`. | `--self-test` of the exported game; the Windows check workflow. |

One active character pipeline: `scripts/art.sh` (`scripts/character-art.sh` delegates to it). Rejected cutout and interpolation experiments live only in import-excluded `art/source/archive/`.

## Keep with the project

`project.godot`, `core/`, `app/`, `scenes/`, `ui/`, `art/` code, `pipeline/`, `scripts/`, `test/`, `tools/`, `installer/`, documentation and `media.lock` (which pins `assets/`, `art/source/`, `reference/`, concept boards and review captures in the release packs). Do not carry the generated `.godot/`, `.cache/`, `build/` or a different machine's `sandbox/runtime/`. Blender and host Python are authoring tools only; submitted player code never runs in host Python.

## Open work

- The v0.8 [storyboard](concept/v0.8/storyboard.md) scripts Chapters 00 and 01 in full; it is an editorial draft for later passes.
- Shop interiors beyond the clockmaker (the apothecary's room is an empty shell); no trading or clock-setting challenge exists yet.
- The layout studio is deliberately small (fourteen park and barrier pieces, half-cell paint). Build engine features without current content (houses, procedural trees, terrain and water tools, room finishes) remain in code with fixture-based tests; strip them when the studio's future is decided.
- Save migration policy when an area document changes version.
- Audio, platform packaging, export presets, credits review and release testing. Nothing here creates a release or publishes.
