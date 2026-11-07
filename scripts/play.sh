#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
if [[ ! -x "$ROOTWARD_SANDBOX_RUNTIME/bin/wasmtime" || ! -f "$ROOTWARD_SANDBOX_RUNTIME/python/python.cwasm" ]]; then
  echo "The Python sandbox runtime is missing. See docs/concept/v0.6/04-voxel-world-prototype-spec.md." >&2
  exit 1
fi
# Renderer and GPU choices apply only to this game process, never to system settings.
game_gpu="${ROOTWARD_GPU:-auto}"
game_renderer="${ROOTWARD_RENDERER:-compatibility}"
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --gpu|--renderer)
      if [[ "$#" -lt 2 ]]; then echo "$1 needs a value." >&2; exit 2; fi
      if [[ "$1" == --gpu ]]; then game_gpu="$2"; else game_renderer="$2"; fi
      shift 2 ;;
    *) break ;;
  esac
done
render_args=()
case "$game_renderer" in
  compatibility|gl_compatibility) render_args=(--rendering-method gl_compatibility --rendering-driver opengl3) ;;
  mobile|forward_plus) render_args=(--rendering-method "$game_renderer" --rendering-driver vulkan) ;;
  *) echo "Unknown renderer '$game_renderer': use compatibility, mobile or forward_plus." >&2; exit 2 ;;
esac
if [[ "$game_gpu" == auto ]]; then
  game_gpu=default
  if [[ -d /proc/driver/nvidia ]]; then
    if [[ "${XDG_SESSION_TYPE:-}" == wayland ]] || { command -v xrandr >/dev/null && [[ "$(xrandr --listproviders 2>/dev/null)" == *NVIDIA* ]]; }; then
      game_gpu=nvidia
    fi
  fi
fi
case "$game_gpu" in
  default) ;;
  nvidia)
    if [[ ! -d /proc/driver/nvidia ]]; then
      echo "The NVIDIA driver is not loaded. Use --gpu default for system graphics." >&2
      exit 1
    fi
    ;;
  *)
    if [[ "$game_gpu" =~ ^[0-9]+$ && "$game_renderer" != compatibility && "$game_renderer" != gl_compatibility ]]; then
      render_args+=(--gpu-index "$game_gpu")
    else
      echo "Use --gpu auto, default or nvidia; a numeric index requires --renderer mobile or forward_plus." >&2
      exit 2
    fi ;;
esac
mkdir -p "$project_root/.cache"
godot_bin="${GODOT_BIN:-godot}"
if ! "$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/import.log" 2>&1; then
  cat "$project_root/.cache/import.log" >&2
  exit 1
fi
if [[ "$game_gpu" == nvidia ]]; then
  export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only
fi
echo "Rootward: requested GPU=$game_gpu renderer=$game_renderer (the engine prints the selected adapter below)."
exec "$godot_bin" --path "$project_root" "${render_args[@]}" "$@"
