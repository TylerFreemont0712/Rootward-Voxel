# Releases, media packs and the installer

Rootward Voxel ships three ways from one repository:

| Who | Gets | How |
|---|---|---|
| A player on Windows or Linux | The game, ready to play, no Godot needed | **Rootward Voxel Setup** from the [latest release](https://github.com/TylerFreemont0712/Rootward-Voxel/releases/latest) |
| Someone reading or changing the code | Code, content, docs (~6 MB clone) | `git clone`, then `scripts/setup.sh` (or `setup.ps1`) for the sandbox and the game's media |
| Someone remaking art | The above plus Blender masters, source paintings, concept boards and review captures | `scripts/setup.sh --dev` (or `scripts/fetch-media.sh dev`) |

## Media lives in release packs, not in git

Pictures and models (`*.png`, `*.jpg`, `*.webp`, `*.glb`, `*.blend`, `*.gif`, `*.mp4`, … and their Godot `.import`
sidecars) are listed in the media block at the top of [`.gitignore`](../.gitignore). Git never stores them.
[`media.lock`](../media.lock) names every one with its SHA-256, size and the **pack** that carries it; packs are tar
files attached to GitHub releases tagged `media-N`.

| Packs | Holds | Needed for |
|---|---|---|
| `world-*` (haverlund, workshop, seaside, loft, lane, town, square, shops, misc) | `assets/world/`: models, their textures, backdrops | Playing, testing, building |
| `assets-*` (characters, portraits, brand, ui) | The rest of `assets/` | Playing, testing, building |
| `dev-world-*`, `dev-art-*` | `art/source/`: Blender masters, painted sources | Rebuilding art, the 7 source-pixel tests |
| `dev-docs` | Concept boards in `docs/concept/`, `reference/` | Reading the concept documents with their pictures |
| `dev-evidence` | Review captures in `evidence/` that a review record links to | Reading `pipeline/reviews/` with their pictures |

The README's own screenshots (`docs/images/`) stay in git so GitHub can show them.

```sh
scripts/fetch-media.sh              # the game's packs (about 790 MB, once; only changed packs are fetched later)
scripts/fetch-media.sh dev          # the art sources too
scripts/fetch-media.sh --status     # what is installed, missing, changed or not yet packed
```

`fetch` checks every pack and every file against the lock before it lands, writes only to the paths the lock names,
and never overwrites a file you changed since it was fetched (unless `--force`). Offline, set `VOXEL_MEDIA_FROM` to a
folder holding the `.tar` packs. Downloads are cached in `~/.cache/rootward-voxel/media`.

### After making or changing art

The art pipeline writes runtime files as before (`scripts/art.sh`, `scripts/world-art.sh build <id>`). Git does not
see them, so:

1. `scripts/pack-media.sh` lists what changed (it exits 1 when the lock is behind the disk).
2. `scripts/pack-media.sh --write` rebuilds only the changed packs under a new `media-<time>` tag and rewrites
   `media.lock`.
3. Commit `media.lock` with the change that needed the new files, and push.
4. `scripts/pack-media.sh --publish` creates the release and uploads the new packs (needs `gh`, signed in).

Unchanged packs keep their old release; nothing is uploaded twice. A clone that pulls the new `media.lock` runs
`scripts/fetch-media.sh` to bring itself up to date.

### Tests and missing sources

`scripts/test.sh` refuses to run without the game's packs. Tests marked `"needs": ["dev"]` in
[test/manifest.json](../test/manifest.json) compare source pixels and are listed as **skipped** until the dev packs
are fetched. Elsewhere, a check that an art source exists or has a given hash accepts the copy pinned in `media.lock`
(`tools/media_lock.gd`, and the link checker in `test/test_pipeline_handoff.py`), so a broken reference still fails.

## Builds for Windows and Linux

```sh
scripts/build.sh                    # both systems and both installers into build/release/ (Linux host, about a minute)
scripts/build.sh --only linux       # one system's game (installers are still made for both)
scripts/build.sh --set-version 0.2.0   # bump the version in project.godot and both export presets
scripts/build.sh --publish          # build, then upload everything as the GitHub release v<version>
```

The game exports with Godot's official 4.7.2 templates (downloaded once, checked against Godot's SHA-512).
[export_presets.cfg](../export_presets.cfg) packs area documents, catalogs and the Python harness; tests, tools, art
sources, docs, evidence and the installer stay out. Release builds switch off the developer tools (F8, the asset
showcase) because they are not debug builds.

| File in `build/release/` | What it is |
|---|---|
| `Rootward-Voxel-Setup-<v>.exe` | The Windows installer (about 110 MB: Godot's runtime with the installer inside) |
| `rootward-voxel-setup-<v>-linux.tar.gz` | The Linux installer (a tar keeps its executable bit) |
| `rootward-voxel-<v>.pck` | Everything the game shows and reads; the same file for both systems |
| `rootward-voxel-<v>-<os>-game.zip` | The executable (and on Windows its console twin), README, licences |
| `rootward-voxel-<v>-<os>-sandbox.zip` | Wasmtime and CPython compiled ahead of time for that system ([scripts/sandbox_dist.py](../scripts/sandbox_dist.py)) |
| `rootward-voxel-manifest.json` | Every package with its size and SHA-256: the installer reads it first |

The sandbox ships beside the executable as ordinary files, because wasmtime is a separate program and cannot read
inside a `.pck`. An exported game finds it there (`Sandbox.runtime_dir()`) and marks the Python standard library
read-only on its first start, as `setup-runtime.sh` does for a checkout.

**Self-test.** `RootwardVoxel.x86_64 -- --self-test` (Windows: `RootwardVoxel.console.exe -- --self-test`) loads every
area, checks every catalogued model is packed, loads one, and runs real Python in the shipped sandbox; it prints OK or
FAILED and exits 0 or 1. The build runs it on the Linux export, the installer runs it after installing, and the
Windows check runs it on Windows.

## Rootward Voxel Setup

[`installer/`](../installer/) is a small Godot project of its own, styled like the game (Cinzel and Alegreya, brass
on ink, a view of Spindle Lane behind). It:

- reads the manifest from a folder beside it (an **offline install**: put the release files in one folder with the
  installer) or from `installer/config.json`'s address, this repository's `releases/latest/download/`;
- installs per user with no administrator: `%LOCALAPPDATA%\Programs\Rootward Voxel` on Windows,
  `~/.local/share/rootward-voxel` on Linux, or a folder the player chooses;
- downloads with a progress bar, speed and time left; checks every SHA-256 before anything touches the game's folder;
  unpacks on a worker thread;
- adds a Start-menu or app-menu entry and a desktop shortcut (both optional), and on Windows an entry in
  **Settings → Apps** with an Uninstall button; on Linux the menu entry has an *Uninstall* action and asks for the
  discrete GPU on hybrid laptops;
- runs the game's self-test and says plainly whether Python works;
- run again, offers **Update** (only changed packages are downloaded), **Repair**, **Play** and **Uninstall**.
  Uninstalling never touches saves (`%APPDATA%\RootwardVoxelLab`, `~/.local/share/RootwardVoxelLab`).

Command line: `--silent [--install | --uninstall]` (with `--headless`) for scripts, `--dir <folder>`,
`--from <url or folder>`, `--repair`, `--no-shortcuts`, `--log <file>`, and `--shots <folder>` to save what the
window shows every 0.7 s when reviewing its look.

The Windows installer and game are **not code-signed**, so SmartScreen shows *"Windows protected your PC"* the first
time: *More info → Run anyway*. Signing needs a certificate the project does not have yet.

## Publishing a version

1. `scripts/build.sh --set-version X.Y.Z`, commit.
2. If art changed: `scripts/pack-media.sh --write`, commit `media.lock`, push, `scripts/pack-media.sh --publish`.
3. `scripts/build.sh --publish`: builds, self-tests and uploads the release `vX.Y.Z` (it becomes *latest*, which the
   installer downloads from).
4. Check Windows: `gh workflow run windows-check.yml -f tag=vX.Y.Z`
   ([.github/workflows/windows-check.yml](../.github/workflows/windows-check.yml)) installs the release with the real
   `.exe` on a clean Windows machine, checks the files, shortcut, Apps entry and self-test, and uninstalls.

## What has been verified, and what has not

- Linux: export, self-test of the exported game, silent and windowed offline installs into a scratch home, menu and
  desktop entries, uninstall (saves kept). The windowed installer was reviewed at its real size.
- Windows: the `.exe` builds and the Windows sandbox compiles from Linux. **Running it on Windows has not been checked
  yet**: that is what the Windows check workflow is for, once a release is published.
- Online installs need the release published; until then use an offline folder.
