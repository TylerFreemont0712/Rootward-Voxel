#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -ne 0 ]]; then
  echo 'Usage: scripts/art.sh (build selected character art, shared skins, dialogue portraits and application icons)' >&2
  exit 2
fi
project_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
mkdir -p "$project_root/.cache"
"${ART_PYTHON:-/usr/bin/python3}" "$project_root/pipeline/normalize_ground.py"
"$godot_bin" --headless --path "$project_root" -s res://pipeline/build_art.gd -- --prepare
"$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/art-import.log" 2>&1
"$godot_bin" --headless --path "$project_root" -s res://pipeline/build_art.gd -- --configure-import
"$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/art-import.log" 2>&1
"$godot_bin" --headless --path "$project_root" -s res://pipeline/build_art.gd
"$godot_bin" --headless --path "$project_root" -s res://test/test_art.gd
"$godot_bin" --headless --path "$project_root" -s res://test/test_frame_skins.gd
