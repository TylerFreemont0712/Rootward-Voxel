# Memory retention and desktop graphics

The game was retaining departed districts through static rendering caches. The largest offender was the illustrated-outline dictionary: Mesh objects used as strong keys retained their source materials and textures, alongside outline buffers. Frame-skin and prepared named-character atlas caches also kept earlier casts alive. Anonymous crowd PNGs were small on disk but expanded into thirteen approximately 42 MiB GPU atlases.

## Implemented

- Outline meshes, frame skins and house material variants use weak cache references. Live instances still share resources; the final owner releases them. Area preparation holds its resources through construction and then clears them, including named actor atlases.
- Static authored house appearances are chosen before outlining. Invisible alternative roof/dressing branches are released from those instances, with semantic lamp emitters preserved. Editable models and the showcase retain complete alternatives. Adopted source models and their GLBs are unchanged.
- Only anonymous gray crowd masks use GPU texture compression through the existing art catalog/builder. Original PNG alpha and shared animation metadata remain exact; the imported GPU copy is compressed. The approved boy and named painted skins remain lossless. A crowd atlas uses about 10.5 MiB instead of 42 MiB. This follows [Godot's distinction between disk compression and VRAM compression](https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html).
- Linux launch/shortcuts default to automatic NVIDIA PRIME offload on supported sessions. Explicit system/NVIDIA choices and optional Vulkan adapter indices are available. Settings shows the actual adapter. Offload follows [NVIDIA's documented process environment](https://download.nvidia.com/XFree86/Linux-x86_64/550.78/README/primerenderoffload.html); no system graphics configuration is changed.
- Windows x64 has separate runtime setup, launcher and test scripts. Wasmtime's Windows executable and CPython/WASI archives have pinned verified hashes; Python is compiled natively into `sandbox/runtime-windows/`. Linux's native compiled cache stays separate. Platform executable/folder selection is recorded in the copied sandbox boundary's provenance.

OpenGL Compatibility remains the default on both platforms. Mobile/Forward+ are optional modern-renderer paths; [Godot documents their different drivers and rendering capabilities](https://docs.godotengine.org/en/4.7/engine_details/architecture/internal_rendering_architecture.html). For Windows, the launcher supports system GPU preferences for OpenGL, and explicit adapter indices with Vulkan/Direct3D. [Launch commands and platform limits](../../docs/DESKTOP.md).

## Measurements

Godot 4.7.2, Linux/X11, AMD Radeon 680M, Mesa 25.2.8, 1600×1000. The matched area-construction probe loads title → loft → lane → square → clockshop → square → lane → loft → title, with twenty idle frames per sample and isolated saves. These are **allocation/RSS snapshots, not FPS or peak-load measurements**. The extra continuous-render run restores normal viewport updates after each direct asynchronous review load; its final texture figures are about 6.1 MiB higher because of render targets.

| Sample / measured allocation | Before (MiB) | After matched probe (MiB) | Reduction |
| --- | ---: | ---: | ---: |
| Square, second visit: textures | 1,196.5 | 552.0 | 53.9% |
| Square, second visit: mesh/render buffers | 460.9 | 225.3 | 51.1% |
| Square, second visit: process RSS | 1,393.6 | 1,165.0 | 16.4% |
| Clockshop: textures | 624.1 | 142.5 | 77.2% |
| Clockshop: mesh/render buffers | 446.9 | 11.3 | 97.5% |
| Return to loft: textures | 635.1 | 223.5 | 64.8% |
| Return to loft: mesh/render buffers | 445.1 | 19.0 | 95.7% |
| Return to loft: process RSS | 1,365.3 | 1,193.2 | 12.6% |

The final continuous-render run measured **558.1 MiB textures / 225.3 MiB buffers** in the square and **229.6 / 19.0 MiB** on returning to the loft. Its process RSS reached about **1,232 MiB** after the tour. Allocators and drivers retain freed allocations for reuse, so process RAM does not fall by the same amount as Godot's resource counters. Graphics-memory and process-RAM figures must not be added together on shared-memory hardware. The dedicated GPU also has its own host allocations; switching adapters is not itself a RAM optimization.

The square has 7,525 live nodes versus 7,800 before this pass. On returning to the loft, cached outline entries fall back to 346 live meshes rather than retaining 1,632 historical ones; retained non-player frame-skin entries and pinned story atlases fall to zero. Large live world meshes and the unchanged player/named character atlases remain meaningful costs. Further work should profile those before reducing authored detail.

[Raw before/after and continuous-render snapshots](../../evidence/memory-gpu/metrics.json) · [Crowd at gameplay scale](../../evidence/memory-gpu/12-compressed-crowd.png) · [Clockshop](../../evidence/memory-gpu/09-room-overview.png).

## Desktop verification

- Linux native AMD 680M and NVIDIA RTX 3070 Ti Laptop GPU (driver 580.178.04): OpenGL Compatibility launches select the actual expected adapter. Automatic PRIME launcher also reports NVIDIA. Settings fits at 1600×1000 and 1280×720, including the long AMD device name. [NVIDIA readout](../../evidence/memory-gpu/14-settings-gpu-1280.png).
- Native NVIDIA clockshop review: **63 checks, zero failures**, including fourteen inspections, swinging entry/return, Continue, shared clock hands, restored terraces and day/night depth mist. Visible model alternatives and the painted cast remain intact.
- Native depth-gradient shader: **6 checks passed** on Compatibility and on NVIDIA Mobile/Vulkan. AMD Mobile/Vulkan startup also succeeds. These validate the tested paths; they are not an entire campaign qualification for every modern renderer.
- New resource-lifetime/platform regression: **12 checks passed**, proving live resource sharing, release of source meshes/atlases, unchanged visible trimmed geometry, import policy and platform runtime names.
- Desktop launch regression: **6 tests passed**, including literal/spaced arguments, Vulkan adapter options, import failure handling, PowerShell parsing and argument execution under Microsoft's portable PowerShell. Three Windows scripts parse successfully. Native Windows runtime download/setup, NTFS ACLs, WASI pipes, gameplay and Direct3D rendering **remain unverified on Windows hardware**.
- Normal `scripts/art.sh`: **100 painted-art and 111 shared-frame checks passed**. No source paintings/models changed. Fixed-lamp overlap regression: **68 fittings, zero over-budget meshes, zero failures**.
- Full `scripts/test.sh`: **passed, exit 0**, including actual local WASI, gameplay/UI/saves, 1,057 world-art/view checks, 1,665 handoff checks and authoring/workflow guards. Final documentation/link rerun: **1,673 passed**; final launcher rerun: **6 passed**. `git diff --check` passes.

Reproduce final memory snapshots with `godot --path . -s res://tools/memory_review.gd -- res://.cache/memory-gpu/memory.json`; use `tools/desktop_graphics_review.gd` for native crowd/settings captures. Choose the adapter before starting, and compare runs on the same adapter/backend/resolution. Review tools use isolated saves and a scratch layout export. Source work and the user's exported square layout are preserved; no commit or publication was made.
