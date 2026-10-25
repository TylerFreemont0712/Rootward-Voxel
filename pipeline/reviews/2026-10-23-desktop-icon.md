# Rootward Voxel desktop identity — 2026-10-23

The application icon is a violet-capped amber lantern with branching golden roots and teal code brackets, on a dark chamfered backing with transparent surroundings. It reflects Kindle Hollow's lamplighter and the real-Python world-changing loop.

- Authored with built-in imagegen; the immutable [1254 px master](../../art/source/brand/v1-lantern-roots/icon.png) and [exact prompt](../../art/source/brand/v1-lantern-roots/prompt.txt) live together.
- `application_icon` in `pipeline/art-catalog.json` pins the source SHA-256 and the 256/512 px PNG outputs. The existing `scripts/art.sh` builds them through Godot. The source is never overwritten by the build.
- `project.godot` selects the 256 px icon. The launcher uses 512 px, calls this checkout's `scripts/play.sh` and records the installed Godot executable explicitly.
- `scripts/install-desktop.py` renders `packaging/rootward-voxel.desktop.in`, validates it, and installs **Rootward Voxel** in the applications menu and existing XDG desktop folder. `--prepare-only` stages it under `.cache/desktop/`. Re-run installation after moving the project.

Verification:

- [32/48/64/128 px review](../../evidence/icon-sizes.png), inspected on light and dark backgrounds. The lantern and code brackets remain readable.
- `scripts/art.sh`: passed, including 100 art-contract and 30 shared-skin checks.
- `scripts/test.sh`: passed all suites, 648 checks. Verification used workspace-local `XDG_DATA_HOME` and the suite's fresh-save mode.
- `desktop-file-validate`: passed for the staged and both installed launchers.
- Launched the installed applications-menu entry through native GIO; the real game opened at [1440×900](../../evidence/desktop-launch.png). X11 reported `WM_CLASS = "Godot_Engine", "Rootward Voxel"`, matching `StartupWMClass`. Its native 256 px icon matched the new artwork's opaque pixels exactly. Review launches disabled player saves.

The supplied runtime PNGs are sufficient to play. Imagegen and host Python are authoring/install tools, with no new game runtime dependency.
