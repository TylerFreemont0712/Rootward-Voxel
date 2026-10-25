#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
if [[ ! -x "$ROOTWARD_SANDBOX_RUNTIME/bin/wasmtime" || ! -f "$ROOTWARD_SANDBOX_RUNTIME/python/python.cwasm" ]]; then
  echo "The Python sandbox runtime is missing. See docs/concept/v0.6/04-voxel-world-prototype-spec.md." >&2
  exit 1
fi
mkdir -p "$project_root/.cache"
godot_bin="${GODOT_BIN:-godot}"
if ! "$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/import.log" 2>&1; then
  cat "$project_root/.cache/import.log" >&2
  exit 1
fi
exec "$godot_bin" --path "$project_root" "$@"
