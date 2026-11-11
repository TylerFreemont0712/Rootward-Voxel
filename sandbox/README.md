# Player-code runtime

Player Python runs in the copied Wasmtime/CPython WASI boundary, on a worker thread. The engine never executes submitted source with host Python. `lab_program.gd` supplies the snapshot, limits and protocol; `world_harness.py` executes inside WASI through the copied sandbox/launch boundary and builds the friendly `world`, zone, lamp, gate and bridge objects from the snapshot (it records their calls as commands; it never touches the engine). Source provenance and copied-file hashes are in [PROVENANCE.json](PROVENANCE.json).

## Local setup

On Linux x86_64, run `scripts/setup-runtime.sh` from the project root. It downloads pinned archives, verifies checksums and prepares ignored `sandbox/runtime/`. Initial setup needs the network; subsequent play and tests use local files. The script exits without replacing an existing prepared runtime.

Windows x64 has `scripts/setup-runtime.ps1` and `scripts/play.ps1`. The bootstrap verifies pinned archives, installs `wasmtime.exe`, compiles the portable Python module natively, and makes the standard library read-only with NTFS permissions. Its ignored `sandbox/runtime-windows/` stays separate from Linux's native compiled module. Setup writes its completion marker only after all these steps. See [desktop commands and verification status](../docs/DESKTOP.md); native Windows WASI/gameplay validation remains outstanding.

Godot is the runtime engine. Host Python runs authoring/test helpers only. Blender and AI services are not game dependencies. Other host platforms need a matching native Wasmtime build and explicit packaging verification. `Sandbox.runtime_folder()` / `binary_name()` choose Windows or Linux paths; `ROOTWARD_SANDBOX_RUNTIME` overrides the directory. This platform adaptation is recorded with its upstream and current hashes in [PROVENANCE.json](PROVENANCE.json).

## Shipped builds

An exported game carries its own runtime as ordinary files in `sandbox/` beside the executable (wasmtime cannot read inside a `.pck`). `scripts/sandbox_dist.py --target linux|windows --out <dir>` builds it from the same pinned downloads, compiling CPython ahead of time for the target at baseline x86-64, with unchecked-hash bytecode. `Sandbox.runtime_dir()` looks there when `OS.has_feature("template")`, and `Sandbox.protect_stdlib()` marks the standard library read-only on first start. See [RELEASES](../docs/RELEASES.md).

## Boundaries

The current limits are a 2-second WASI timeout, 7-second wall backstop, 96 MiB memory, 32 KiB combined output, and 16 KiB source/result payloads. Jobs receive their working files and a read-only standard library, without host filesystem or network capabilities. Every returned command passes pure world validation before an atomic proposal can be applied.

The local dependency directory is ignored and platform-specific. Keep the bootstrap, runner, adapter and provenance with source. Test changes with `scripts/test.sh`, which includes actual WASI execution and stale-result/atomic-command checks. Update provenance deliberately when changing copied boundary files.

See [the programming API](../docs/PROGRAMMING.md) and [main-project handoff](../docs/PROJECT_HANDOFF.md).
