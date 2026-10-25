#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
if [[ ! -x "$ROOTWARD_SANDBOX_RUNTIME/bin/wasmtime" || ! -f "$ROOTWARD_SANDBOX_RUNTIME/python/python.cwasm" ]]; then
  echo "The Python sandbox runtime is missing. See docs/concept/v0.6/04-voxel-world-prototype-spec.md." >&2
  exit 1
fi
# ROOTWARD_GPU=nvidia draws the game on the NVIDIA card of a hybrid-graphics laptop (PRIME render offload).
# Unset, the system's default (usually integrated) GPU is used: it runs the game comfortably and uses less power.
case "${ROOTWARD_GPU:-}" in
  "" | default) ;;
  nvidia)
    if [[ ! -d /proc/driver/nvidia ]]; then
      echo "ROOTWARD_GPU=nvidia, but the NVIDIA driver is not loaded. Unset ROOTWARD_GPU to use the default GPU." >&2
      exit 1
    fi
    ;;
  *)
    echo "Unknown ROOTWARD_GPU '$ROOTWARD_GPU': use 'nvidia', or leave it unset for the default GPU." >&2
    exit 1
    ;;
esac
mkdir -p "$project_root/.cache"
godot_bin="${GODOT_BIN:-godot}"
if ! "$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/import.log" 2>&1; then
  cat "$project_root/.cache/import.log" >&2
  exit 1
fi
if [[ "${ROOTWARD_GPU:-}" == nvidia ]]; then
  export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only
fi
exec "$godot_bin" --path "$project_root" "$@"
