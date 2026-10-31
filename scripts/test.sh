#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
export ROOTWARD_SANDBOX_RUNTIME="${ROOTWARD_SANDBOX_RUNTIME:-$project_root/sandbox/runtime}"
export VOXEL_LAB_FRESH=1
mkdir -p "$project_root/.cache"
godot_bin="${GODOT_BIN:-godot}"
"$godot_bin" --headless --editor --path "$project_root" --import --quit > "$project_root/.cache/import.log" 2>&1
"$godot_bin" --headless --path "$project_root" -s res://test/test_lab.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_area.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_companion.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_morning.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_sparks.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_workshop.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_workshop_quests.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_zone_terminals.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_lane.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_square.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_landmarks.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_illustrated_lamps.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_illustrated_village.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_reference_cottage.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_places.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_town_life.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_house_flow.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_doorway_boundaries.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_dialogue.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_build.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_terrain.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_walk_surfaces.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_build_assets.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_building_refresh.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_builder_library.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_prop_flow.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_ground.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_finishes.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_seaside_house_textures.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_house_variants.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_rootwell.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_coplanar.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_material_flow.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_build_mode.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_code_build.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_ui.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_app.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_asset_showcase.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_asset_request_ui.gd < /dev/null

"$godot_bin" --headless --path "$project_root" -s res://test/test_movement.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_art.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_frame_skins.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_robot_movement_art.gd < /dev/null
"$godot_bin" --headless --path "$project_root" -s res://test/test_refined_robots.gd < /dev/null

"$godot_bin" --headless --path "$project_root" -s res://test/test_world_art.gd < /dev/null

python3 "$project_root/test/test_authoring_guards.py"
python3 "$project_root/test/test_asset_workflow.py"
python3 "$project_root/test/test_pipeline_handoff.py"
"${ART_PYTHON:-/usr/bin/python3}" "$project_root/test/test_ground_art.py"
