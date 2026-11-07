# Project map and naming rules

Where things live and what they are called, for anyone opening the project cold. The 2026-11-07 tidy-up that set
these rules, with every old name and its new one, is in [RENAMES_2026-11-07.md](RENAMES_2026-11-07.md).

## Folders

| Folder | Holds | Rule |
| --- | --- | --- |
| `core/` | Pure rules over plain data: areas, walking, quests, story scenes, build rules, town life. | No nodes, no files, no rendering. |
| `app/` | Game flow: the `Game` node, the play session, saves, settings, build-mode controller, development tools, quest staging. | Asks `core/`, drives `scenes/` and `ui/`. |
| `scenes/` | The 3D presentation of an area: `world_view.gd` and what it places. `stages/` holds per-room story staging; `preview/` the model turntables and thumbnail studio. | Never decides what is legal. |
| `ui/` | The code-drawn interface, by job: `kit/` widgets and themes, `hud/` the play overlay, `transition/` the clockwork veil, `story/` dialogue, `notebook/` the jobs journal and field notes, `code/` the editor and slate, `build/` build mode, `screens/` menus, `dev/` development-only screens. | Built from the `kit/`, no `.tscn` files. |
| `art/` | Rendering helpers: materials, builders, sprites, shaders. `art/source/` is the versioned, append-only history of every painted and modelled source. | Never move or rename inside `art/source/`; add a new version folder instead. |
| `assets/` | Built runtime output (sprites, portraits, GLB models, textures) selected by the catalogs in `pipeline/`. | Rebuilt by `scripts/art.sh` and `scripts/world-art.sh`, never hand-edited. |
| `content/` | Authored data: `areas/` (one document per place, plus `.quests.json`), `journeys/`, `levels/`, `build/`, `development/`. | Loaded through `app/area_store.gd`, validated by `core/area_def.gd`. |
| `pipeline/` | Catalogs, build scripts and the playbooks (`README.md` links them all); `reviews/` holds dated review records. | |
| `tools/` | Command-line capture helpers (`area_shot.gd`, `asset_shot.gd`, `screenshot.gd`, ...). `tools/reviews/` holds the one-off review, study and audit scripts named in `pipeline/reviews/`. | Never part of the game. |
| `test/` | Automated checks listed in `test/manifest.json`; `test/fixtures/` keeps the removed village as plain data so the build engine's rules stay proved. | |

## Names

- **Scripts:** one class per file; the file is the class name in snake_case (`WorldView` lives in
  `scenes/world_view.gd`). Helper scripts loaded with `preload` keep that pairing in their constant
  (`const WorldAssets := preload("res://art/world_assets.gd")`).
- **Content ids** (areas, quests, lamps, displays, world assets) are kebab-case and are what saves store. A
  rename needs an entry in `app/save_migration.gd`, so old saves still load.
- **Areas** are named for the place: `workshop-loft`, `haverlund-lane`, `haverlund-square`, `city-hall`, and
  `shop-<trade>` for the shops on the square (`shop-bakery`, `shop-greengrocer`, `shop-tailor`,
  `shop-clockmaker`, `shop-apothecary`).
- **World assets** are `<place or set>-<thing>`: the square's buildings are `haverlund-<trade>`, and a shop's
  furniture is `<trade>-<piece>` (`bakery-oven`, `greengrocer-counter`, `tailor-spool-wall`), with its room shell
  as `<trade>-shell`.
- **Character sprites (skins)** are `<journey>_<character>`: the Sparks & Machines cast is `sparks_nell`,
  `sparks_mira`, `sparks_rowan`, `sparks_braum`, `sparks_tessa`, `sparks_iona`. The retired village cast keeps
  its paintings as `village_<character>`. The player's default look is `adventurer`. Gray crowd silhouettes
  (`assets/characters/phantoms/`) use the id of the skin they were cut from; areas ask only for `man`, `woman`
  or `child`.
- **Story speakers and portraits** use the character's plain id (`nell`, `braum`, `iona`, `hotaru-robot`);
  they are people, not sprites.
- **Area document keys stay as authored.** `villagers` in an area document is the list of residents; the code
  that runs them is `TownLife` (rules) and `ResidentsView` (presentation).

## Saves

The journey saves to `user://rootward.save.sparks-and-machines.json` in the `RootwardVoxelLab` user folder. A
save written under the old name (`kindle_hollow.save.*.json`) is read once and then written under the new name.
`app/save_migration.gd` renames any retired area or skin id inside a save as it loads.
