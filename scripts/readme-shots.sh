#!/usr/bin/env bash
# Retakes the README's screenshots from the real game at 1600x1000, as a player sees it (no development chrome),
# into docs/images/ (or the directory given). Opens a game window for about a minute. It also writes
# docs/images/installer-backdrop.jpg, which scripts/build.py puts behind the installer.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
export VOXEL_LAB_FRESH=1
out="${1:-$project_root/docs/images}"
mkdir -p "$out"
"$project_root/scripts/play.sh" --resolution 1600x1000 -s res://tools/reviews/readme_shots.gd -- "$out"
ls -l "$out"
