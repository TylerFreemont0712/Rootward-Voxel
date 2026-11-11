# Desktop graphics and runtime

This page is about running from a checkout. Players install a built game instead: see [RELEASES](RELEASES.md) and the README.

Use Godot **4.7.2**. The supplied models and paintings run locally without Blender, AI tools or a network connection. The game already renders through the GPU; the launcher chooses the adapter and backend. Settings → Display shows the adapter actually selected by Godot.

## Linux x86_64

```sh
scripts/setup.sh          # once on a new checkout: the sandbox runtime and the game's media
scripts/play.sh
```

The launcher defaults to OpenGL Compatibility. On a hybrid NVIDIA laptop, `auto` requests PRIME offload when the NVIDIA driver and an offload-capable session are present. Otherwise it uses the system adapter. These environment choices apply to the game process only.

```sh
scripts/play.sh --gpu default  # system graphics / lower laptop power use
scripts/play.sh --gpu nvidia   # explicit NVIDIA PRIME offload
scripts/play.sh --renderer mobile --gpu 1  # optional Vulkan adapter index
```

Put launcher options before Godot arguments. Environment alternatives are `ROOTWARD_GPU=auto|default|nvidia|N`, `ROOTWARD_RENDERER=compatibility|mobile|forward_plus` and `GODOT_BIN=/path/to/godot`. Numeric GPU indices require Mobile or Forward+; Compatibility uses the system/PRIME choice. GPU indices come from the engine's adapter enumeration and can vary between machines.

`python3 scripts/install-desktop.py` installs a shortcut with automatic GPU selection. Use `--gpu default`, `--gpu nvidia` (or the older `--nvidia` alias), and optionally `--renderer mobile`. Re-run the installer to change an existing shortcut. `--prepare-only` only writes a candidate under `.cache/desktop/`.

## Windows x64

Install the Godot 4.7.2 Windows executable, then run these commands in PowerShell from this checkout. Substitute its actual path. The per-process execution-policy option permits the checked-in script without changing the machine's permanent policy.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\play.ps1 -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe'
```

Setup verifies pinned Wasmtime and CPython/WASI downloads and compiles Python with the native Windows Wasmtime. Windows uses `sandbox/runtime-windows/`; Linux uses `sandbox/runtime/`. Do not copy a Linux `python.cwasm` into the Windows runtime: the portable `python.wasm` must be compiled for its host. An explicit `ROOTWARD_SANDBOX_RUNTIME` overrides either location.

Compatibility uses OpenGL. On a hybrid laptop, select the Godot executable under **Settings → System → Display → Graphics → High performance**; include the `_console.exe` companion if the launcher finds and uses it. This project does not change system GPU preferences.

Optional modern-backend launch:

```powershell
.\scripts\play.ps1 -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe' -Renderer mobile -Driver vulkan -GpuIndex 1
```

`-Driver d3d12` is also accepted for Mobile/Forward+. Keep Compatibility as the default: native Windows Vulkan/Direct3D gameplay has not been validated here. Pass additional engine arguments as `-GodotArgs @('--resolution','1600x1000')` when invoking from PowerShell. Both launchers import changed resources before starting and stop if import fails.

## Checks and current limits

Linux: `scripts/test.sh`. Windows authoring: `scripts/test.ps1 -Godot <path> -Python python` uses the same canonical suite list. Authoring checks also need Python with NumPy/Pillow and filesystem symlink support; normal play does not need host Python. Blender source checks use the existing world-art workflow.

Linux gameplay has been checked on AMD Radeon 680M and NVIDIA RTX 3070 Ti Laptop GPU with OpenGL Compatibility. A native NVIDIA Vulkan test also checks the square's depth-fog shader. Windows scripts have parser and argument/exit-path checks using Microsoft PowerShell on Linux; **native Windows installation, WASI execution and gameplay still need a Windows verification run**. This is checkout launching; the redistributable Windows build and installer are described in [RELEASES](RELEASES.md), and `.github/workflows/windows-check.yml` checks a published release on a clean Windows machine.

Resource/cache fixes and measurements are in the [memory and desktop review](../pipeline/reviews/2026-11-05-memory-and-desktop-graphics.md). A dedicated GPU can reduce rendering pressure on integrated graphics, but does not guarantee lower process RAM: the driver can reserve its own host allocations.
