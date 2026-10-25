#!/usr/bin/env bash
# Walks the real game through its screens (title, character, play, notebook tabs, a preview, an error,
# pause, journal, map) and saves PNGs in .cache/tour; then does the same for build mode in .cache/build-tour.
# A few selected frames are copied to evidence/.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
export VOXEL_LAB_FRESH=1
tour="$project_root/.cache/tour"
rm -rf "$tour"
"$project_root/scripts/play.sh" --resolution "${SHOT_SIZE:-1600x1000}" -s res://tools/ui_tour.gd -- "$tour"
mkdir -p "$project_root/evidence"
cp "$tour/01-title.png" "$project_root/evidence/title.png"
cp "$tour/04-play-start.png" "$project_root/evidence/voxel-clearing.png"
cp "$tour/05-notebook-code.png" "$project_root/evidence/notebook-code.png"
cp "$tour/06-notebook-lesson.png" "$project_root/evidence/notebook-lesson.png"
cp "$tour/11-run-error.png" "$project_root/evidence/notebook-error.png"
cp "$tour/14-map.png" "$project_root/evidence/map.png"
cp "$tour/15-character.png" "$project_root/evidence/character.png"

# Build mode: the shelf, a good and a refused placement, moving, and the locked mill.
build_tour="$project_root/.cache/build-tour"
rm -rf "$build_tour"
"$project_root/scripts/play.sh" --resolution "${SHOT_SIZE:-1600x1000}" -s res://tools/build_tour.gd -- "$build_tour"
cp "$build_tour/01-build-open.png" "$project_root/evidence/build-mode.png"
cp "$build_tour/02-place-ok.png" "$project_root/evidence/build-place.png"
cp "$build_tour/03-place-refused.png" "$project_root/evidence/build-refused.png"
cp "$build_tour/07-move-hover.png" "$project_root/evidence/build-move.png"
cp "$build_tour/10-locked-mill.png" "$project_root/evidence/build-locked.png"
cp "$build_tour/13-paint-stroke.png" "$project_root/evidence/build-land.png"

# Build mode's details panel: a chosen and turned house, a doodad on offer, and a lamp's code.
details_tour="$project_root/.cache/details-tour"
rm -rf "$details_tour"
"$project_root/scripts/play.sh" --resolution "${SHOT_SIZE:-1600x1000}" -s res://tools/build_details_tour.gd -- "$details_tour"
cp "$details_tour/21-house-turned.png" "$project_root/evidence/build-details-house.png"
cp "$details_tour/23-doodad-ghost.png" "$project_root/evidence/build-details-doodad.png"
cp "$details_tour/24-lamp-code.png" "$project_root/evidence/build-details-code.png"

# Code that builds: the optional chapter's lesson and journal, the World tab, a Run preview, the applied houses and
# the builder's Code section.
code_tour="$project_root/.cache/code-tour"
rm -rf "$code_tour"
"$project_root/scripts/play.sh" --resolution "${SHOT_SIZE:-1600x1000}" -s res://tools/code_build_tour.gd -- "$code_tour"
cp "$code_tour/30-world-tab.png" "$project_root/evidence/code-world-tab.png"
cp "$code_tour/32-preview.png" "$project_root/evidence/code-preview.png"
cp "$code_tour/33-applied.png" "$project_root/evidence/code-applied.png"
cp "$code_tour/35-build-code.png" "$project_root/evidence/code-build-details.png"
cp "$code_tour/36-lesson.png" "$project_root/evidence/code-lesson.png"
cp "$code_tour/37-journal.png" "$project_root/evidence/code-journal.png"
