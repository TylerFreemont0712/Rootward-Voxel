#!/usr/bin/env bash
# Walks the real game through its screens (title, naming, the opening, each room, pause, map, job book and the
# layout studio) and saves PNGs in .cache/tour, or in the directory given. Opens a window at 1600x1000.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
export VOXEL_LAB_FRESH=1
tour="${1:-$project_root/.cache/tour}"
rm -rf "$tour"
"$project_root/scripts/play.sh" --resolution "${SHOT_SIZE:-1600x1000}" -s res://tools/reviews/sparks_tour.gd -- "$tour"
echo "Screens saved in $tour"
