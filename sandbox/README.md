# Player-code runtime

Player Python runs in the copied Wasmtime/CPython WASI boundary, on a worker thread. The engine never executes submitted source with host Python. `lab_program.gd` supplies the snapshot, limits and protocol; `world_harness.py` executes inside WASI through the copied sandbox/launch boundary and builds the friendly `world`, zone, lamp, gate and bridge objects from the snapshot (it records their calls as commands; it never touches the engine). Source provenance and copied-file hashes are in [PROVENANCE.json](PROVENANCE.json).

## Local setup

On Linux x86_64, run `scripts/setup-runtime.sh` from the project root. It downloads pinned archives, verifies checksums and prepares ignored `sandbox/runtime/`. Initial setup needs the network; subsequent play and tests use local files. The script exits without replacing an existing prepared runtime.

Godot is the runtime engine. Host Python runs authoring/test helpers only. Blender and AI services are not game dependencies. Other host platforms need a matching Wasmtime/CPython WASI distribution and explicit packaging verification; the bootstrap currently supports Linux x86_64.

## Boundaries

The current limits are a 2-second WASI timeout, 7-second wall backstop, 96 MiB memory, 32 KiB combined output, and 16 KiB source/result payloads. Jobs receive their working files and a read-only standard library, without host filesystem or network capabilities. Every returned command passes pure world validation before an atomic proposal can be applied.

The local dependency directory is ignored and platform-specific. Keep the bootstrap, runner, adapter and provenance with source. Test changes with `scripts/test.sh`, which includes actual WASI execution and stale-result/atomic-command checks. Update provenance deliberately when changing copied boundary files.

See [the programming API](../docs/PROGRAMMING.md) and [main-project handoff](../docs/PROJECT_HANDOFF.md).
