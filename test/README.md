# Tests

One command runs everything, in parallel, from [manifest.json](manifest.json):

```sh
scripts/test.sh                  # quick tier (~20 s): pure rules, documents, art contracts, guards
scripts/test.sh flow             # + the real game scene driven headless (~1 min)
scripts/test.sh full             # + the audit of every runtime model
scripts/test.sh smoke            # boot the game and load every room (~20 s)
scripts/test.sh square lane      # tests whose id contains these words
scripts/test.sh --list           # every test, its tier and rough cost
```

Options: `-j N` jobs (default half the cores, at most eight), `--serial`, `-v` (show passing output), `--no-import`, `--check` (validate the manifest only). The runner imports resources first only when something under `assets/`, `art/`, `scenes/` and the like changed since the last import, prints one line per test as it finishes, shows the tail of any failure, writes `.cache/test-report.json`, and exits non-zero on a failing test **or** a `SCRIPT ERROR` hidden behind a passing one. `scripts/test.ps1` is the same runner for Windows.

## Media

Tests need the game's pictures and models (`scripts/fetch-media.sh`); the runner stops with that hint when they are missing. A test marked `"needs": ["dev"]` in the manifest compares art-source pixels and is listed as `[skip]` until `scripts/fetch-media.sh dev`. Other checks that an art source exists or has a recorded hash use `tools/media_lock.gd`, which accepts the copy pinned in `media.lock`.

## Which tier for which change

| You changed | Run |
|---|---|
| Rules in `core/`, area documents, catalogs, art contracts | `quick` |
| `app/`, `ui/`, `scenes/`, anything the player walks through or clicks | `flow` (or the one test: `scripts/test.sh square`) |
| A Blender master or a runtime GLB | `scripts/world-art.sh build <id>`, then `full` |
| Before handing work over | `full` |
| "Does it still start?" | `smoke` |

## Adding a test

1. Write `test/test_<name>.gd` (`extends SceneTree`, print one summary line containing "checks", `quit(0)` or `quit(1)`) or a Python `test_<name>.py`. Use `OS.get_process_id()` in any scratch save path (`user://...`) so parallel tests never share a file, and `VOXEL_LAB_FRESH=1` is set for you.
2. Register it in `manifest.json` with a tier. `quick` tests must not start the `Game` scene.
3. `scripts/test.sh --check` fails if a `test_*` file is not registered.

## Fixtures

`fixtures/` holds the removed Kindle Hollow village, the original clearing and four house rooms as plain JSON, with footprint-only model entries. The build, terrain, ground, door and finish rules are still proved over them: a test calls `AreaStore.use_fixtures()` first. No fixture needs a model file, and none is part of the game.
