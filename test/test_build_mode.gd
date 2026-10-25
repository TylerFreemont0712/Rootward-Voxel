extends SceneTree
## Build mode as a player uses it: entering from the play HUD, the shelf, pointing and clicking through the game's own
## input path, the tools, rotate, undo and redo, the locked mill, leaving, and what is kept in the save.

const SCRATCH_SAVE: String = "user://test_build_save.json"
const SCRATCH_PROFILE: String = "user://test_build_profile.json"
var _checks: int = 0
var _failures: Array[String] = []
var game: Game
var builder: BuildMode


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveStore.save_path = SCRATCH_SAVE
	SaveStore.profile_path = SCRATCH_PROFILE
	SaveStore.force_enabled = true
	SaveStore.delete()
	await _flow()
	await _policy()
	await _doodads()
	await _large_shelf()
	await _layout_and_turning()
	await _drag_and_code()
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SCRATCH_PROFILE))
	if _failures.is_empty():
		print("Build mode: %d checks passed (entering, shelf, ghost, place/move/delete, undo, locked mill, leaving, saving, allowances)." % _checks)
		quit(0)
	else:
		for failure: String in _failures:
			printerr("FAIL: ", failure)
		quit(1)


func _flow() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game()
	await _frames(6)
	builder = game.builder
	var session: GameSession = game.session
	var base_buildings: int = game.area.buildings.size()
	var base_trees: int = game.area.trees.size()
	_check(not builder.active and game.hud.visible, "Play starts outside build mode")
	await _tap(KEY_B)
	_check(builder.active and builder.hud.visible and not game.hud.visible, "B enters build mode and swaps the play HUD for the build HUD")
	_check(game.view.camera_mode == ClearingView.CameraMode.FREE and not session.input_enabled, "The camera is free and walking is switched off")
	_check(builder.tool == BuildMode.Tool.PLACE and builder.item_id == "house-hollow", "It opens on Place with the first house chosen")
	var offered: int = builder._entries.size()
	_check(builder.hud._cards.size() == offered and (builder.hud._cards["house-hollow"] as BuildCard).selected, "The shelf shows every item and marks the chosen one")
	# Every card gets a picture of its model, drawn one at a time. (A headless run has no renderer, so only the
	# bookkeeping can be checked there; the pictures themselves are reviewed in a window with tools/build_tour.gd.)
	var waited: int = 0
	while waited < 900 and builder.pictures_done < offered:
		await process_frame
		waited += 1
	_check(builder.pictures_done == offered and not builder.studio._busy, "Every card's picture is finished (%d frames)" % waited)
	if DisplayServer.get_name() != "headless":
		_check(_pending_pictures() == 0, "...and every card shows it")
	# The shelf: tabs, choosing, the info panel.
	builder.hud._choose_category("trees")
	_check((builder.hud._cards["tree-oak"] as BuildCard).visible and not (builder.hud._cards["house-hollow"] as BuildCard).visible, "A tab shows only its own category")
	builder.choose_item("tree-elder")
	_check(builder.item_id == "tree-elder" and builder.hud.details._title.text == "Elder Oak" and (builder.hud._cards["tree-elder"] as BuildCard).selected and not (builder.hud._cards["house-hollow"] as BuildCard).selected, "Choosing a card updates the panel and the selection")
	builder.choose_item("house-hollow")
	_check(builder.hud._category == "houses" and builder.hud.details._spec.text.contains("5 × 5"), "...and switches the tab to the item's category")
	# Pointing: a ghost appears, green where allowed.
	await _point(Vector2(34, 5))
	_check(builder.overlay._ghost_root.visible and builder.overlay._ghost_tint.albedo_color.g > 0.8, "Pointing at open ground shows a green ghost")
	_check(builder.hud._bubble.visible and builder.hud._bubble_label.text == "Hollow House", "The bubble names what will be placed")
	await _point(Vector2(24, 7))
	_check(builder.overlay._ghost_tint.albedo_color.r > 0.9 and builder.hud._bubble_label.text == "Another building is too close.", "Pointing at a house shows a red ghost and the reason")
	var refused: int = game.ledger.edits.size()
	await _click()
	_check(game.ledger.edits.size() == refused, "Clicking a refused spot changes nothing")
	# Rotate with R.
	await _point(Vector2(34, 5))
	await _tap(KEY_R)
	_check(builder.facing == "E" and absf(builder.overlay._ghost_root.rotation_degrees.y - 90.0) < 0.1, "R turns the ghost")
	await _tap(KEY_R)
	await _tap(KEY_R)
	await _tap(KEY_R)
	_check(builder.facing == "S", "Four turns come back round")
	# Place.
	await _tap(KEY_R)
	await _click()
	await _frames(3)
	_check(game.ledger.edits.size() == 1 and game.area.buildings.size() == base_buildings + 1 and game.view.building_node("build-1") != null, "Clicking places the house in the valley")
	_check(game.area.building("build-1").facing == "E" and session.area == game.area, "...turned as the ghost was, and the session plays by the new world")
	_check(builder.hud._undo.disabled == false and builder.hud._redo.disabled, "Undo wakes up; redo stays asleep")
	_check(builder.hud._toasts.get_child_count() >= 1, "A toast says what was done")
	# Walking into the new house is blocked (it is part of the rules, not only the picture).
	_check(not session.rules.is_walkable(session.state, Vector2i(34, 5)), "The new house blocks walking")
	# Trees: place one.
	builder.choose_item("tree-elder")
	await _point(Vector2(39.5, 5.5))
	await _click()
	_check(game.area.trees.size() == base_trees + 1 and game.ledger.edits.size() == 2, "A tree is planted the same way")
	# Move: lift the house, carry it, set it down elsewhere.
	await _tap(KEY_1)
	_check(builder.tool == BuildMode.Tool.MOVE and (builder.hud._bubbles[BuildMode.Tool.MOVE] as BuildBubble).selected, "1 chooses Move")
	await _point(Vector2(34, 5))
	_check(builder._hover_object.get("id") == "build-1", "Pointing at the house in Move picks it up for hovering")
	await _click()
	_check(builder.selected.get("id") == "build-1" and builder.carrying.is_empty() and game.view.building_node("build-1").visible, "A first click chooses the house and leaves it standing")
	_check(builder.hud.details_visible() and builder.hud.details.subject_key() == "building:build-1", "...and the details panel opens for it")
	await _click()
	_check(builder.carrying.get("id") == "build-1" and not game.view.building_node("build-1").visible, "Clicking the chosen house lifts it (it vanishes from where it stood)")
	await _point(Vector2(36, 9))
	await _tap(KEY_ESCAPE)
	_check(builder.carrying.is_empty() and game.view.building_node("build-1").visible and game.area.building("build-1").at == Vector2(34, 5), "Escape puts it back exactly where it was")
	_check(builder.selected.get("id") == "build-1", "...and it is still the chosen thing")
	await _point(Vector2(34, 5))
	await _click()
	var set_down: Vector2 = Vector2(-1, -1)
	for y: int in range(2, 14):
		for x: int in range(31, 44):
			if set_down.x < 0.0 and Vector2(x, y).distance_to(Vector2(34, 5)) > 5.5 and game.ledger.check_move_building("build-1", Vector2(x, y), builder.facing, session.state).ok and game.ledger.move_building("build-1", Vector2(x, y), builder.facing, session.state, false).ok:
				set_down = Vector2(x, y)
	_check(set_down.x > 0.0, "There is somewhere else to set the house down")
	await _point(set_down)
	await _click()
	_check(builder.carrying.is_empty() and game.area.building("build-1").at == set_down and game.view.building_node("build-1").position.is_equal_approx(Vector3(set_down.x, 0, -set_down.y)), "Clicking sets it down where it was pointed")
	_check(builder.selected.get("id") == "build-1", "A thing that was set down stays chosen")
	# Delete: a tree, and the locked mill.
	await _tap(KEY_2)
	_check(builder.tool == BuildMode.Tool.DELETE and builder.selected.is_empty() and not builder.hud.details_visible(), "2 chooses Delete (and puts the details panel away)")
	await _point(Vector2(49.1, 24.6))
	_check(builder._hover_object.get("id") == "mill" and builder.hud._bubble_label.text == "Part of the lessons", "The mill is shown as part of the lessons")
	var kept: int = game.ledger.edits.size()
	await _click()
	_check(game.ledger.edits.size() == kept and game.area.building("mill").id == "mill", "The mill cannot be deleted")
	await _point(Vector2(39.5, 5.5))
	_check(builder._hover_object.get("kind") == "tree", "Pointing at the planted tree selects it")
	await _click()
	_check(game.area.trees.size() == base_trees and game.ledger.edits.size() == kept + 1, "Clicking deletes the tree")
	# Undo and redo through the keyboard.
	await _tap(KEY_Z, true)
	_check(game.area.trees.size() == base_trees + 1, "Ctrl+Z brings the tree back")
	await _tap(KEY_Y, true)
	_check(game.area.trees.size() == base_trees, "Ctrl+Y removes it again")
	await _tap(KEY_Z, true)
	await _tap(KEY_Z, true)
	await _tap(KEY_Z, true)
	_check(game.area.building("build-1").at == Vector2(34, 5) and game.ledger.edits.size() == 1 and game.area.trees.size() == base_trees, "Undo walks back through the delete, the move and the planting, leaving the house where it was first put")
	# Pan and zoom.
	var before: Vector2 = game.view.focus_point()
	game.view.pan_focus(Vector2(3, 0))
	await _frames(40)
	_check(game.view.focus_point().distance_to(before) > 2.0, "The free camera pans")
	var zoom: float = game.view.zoom()
	builder.handle_world_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	_check(game.view.zoom() < zoom, "The wheel zooms in")
	# Esc ladder: with a tool that has nothing held, Esc clears the chosen item, then leaves.
	await _tap(KEY_3)
	builder.choose_item("house-hollow")
	await _tap(KEY_ESCAPE)
	_check(builder.item_id == "" and builder.active and not builder.hud.details_visible(), "Escape first puts the chosen item away (and the details with it)")
	await _tap(KEY_ESCAPE)
	_check(not builder.active and game.hud.visible and game.view.camera_mode == ClearingView.CameraMode.FOLLOW and session.input_enabled, "Escape then leaves build mode: the play HUD, the follow camera and walking return")
	_check(not game.view._quest_marker.visible or session.current_quest().is_empty() or game.view._marker_hidden == false, "The quest beam comes back")
	# What was built is saved when leaving, and survives a return to the title and Continue.
	_check((SaveStore.read().get("edits", []) as Array).size() == 1, "Leaving build mode saves the edits")
	await game._return_to_title()
	await _frames(4)
	await game.continue_game()
	await _frames(4)
	_check(game.area.buildings.size() == base_buildings + 1 and game.area.trees.size() == base_trees and game.view.building_node("build-1") != null, "Continue restores the built valley")
	await _painting()
	await _shaping()
	# B again, and B or Done to leave.
	await _tap(KEY_B)
	_check(game.builder.active, "B enters again after Continue")
	game.builder.hud.done_pressed.emit()
	await _frames(2)
	_check(not game.builder.active, "The Done button leaves")
	# Not while a menu is up.
	game.open_pause()
	await _frames(3)
	game.open_build()
	_check(not game.builder.active, "Build mode does not open over a menu")
	game._pop_all_modals()
	game.queue_free()
	await process_frame


## The Doodads tab through the real input path: a prop that blocks and one that does not, lifting and setting one
## down, removing one, and finding them again after Continue.
func _doodads() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game()
	await _frames(6)
	builder = game.builder
	var session: GameSession = game.session
	await _tap(KEY_B)
	builder.hud._choose_category("doodads")
	_check((builder.hud._cards["wooden-chair"] as BuildCard).visible and not (builder.hud._cards["house-hollow"] as BuildCard).visible, "The Doodads tab shows only the props")
	builder.choose_item("wooden-chair")
	_check(builder.hud._category == "doodads" and builder.hud.details._spec.text.contains("blocks the way"), "A prop's panel says it blocks the way")
	builder.choose_item("watering-can")
	_check(builder.hud.details._spec.text.contains("walk past"), "...and a footprint-free one says it can be walked past")
	builder.choose_item("wooden-chair")
	await _point(Vector2(34, 5))
	_check(builder.overlay._ghost_root.visible and builder.overlay._ghost_tint.albedo_color.g > 0.8, "Pointing at open ground shows a green ghost for a prop")
	_check(builder.hud._bubble_label.text == "Wooden Chair", "The bubble names the prop")
	await _click()
	await _frames(3)
	_check(game.area.props.size() == 1 and game.view.building_node("prop-1") != null and session.area == game.area, "Clicking places the prop, draws it, and the session plays by the new world")
	_check(not session.rules.is_walkable(session.state, Vector2i(34, 5)), "A chair blocks the ground it stands on")
	# The can goes where no tree can stand between it and the camera, so the pointer reaches it later.
	var can_at := Vector2(-1, -1)
	for y: int in range(2, 14):
		for x: int in range(31, 44):
			var spot := Vector2(x, y)
			if can_at.x < 0.0 and spot.distance_to(Vector2(34, 5)) > 2.5 and spot.distance_to(Vector2(39, 8)) > 2.5 and game.ledger.check_item("watering-can", spot, "S", session.state).ok and game.area.trees.all(func(tree: Dictionary) -> bool: return (tree.at as Vector2).distance_to(spot) > 3.0):
				can_at = spot
	_check(can_at.x > 0.0, "There is clear ground for a watering can")
	builder.choose_item("watering-can")
	await _point(can_at)
	await _click()
	_check(game.area.props.size() == 2 and session.rules.is_walkable(session.state, Vector2i(roundi(can_at.x), roundi(can_at.y))), "A watering can is placed and can be walked over")
	await _tap(KEY_1)
	await _point(Vector2(34, 5))
	_check(builder._hover_object.get("kind") == "prop" and builder._hover_object.get("id") == "prop-1", "Pointing at the chair in Move picks it")
	await _click()
	_check(builder.selected.get("id") == "prop-1" and builder.hud.details.subject_key() == "prop:prop-1", "Clicking the chair chooses it")
	await _click()
	_check(builder.carrying.get("id") == "prop-1" and not game.view.building_node("prop-1").visible, "Clicking it again lifts the chair")
	await _point(Vector2(39, 8))
	await _click()
	_check(builder.carrying.is_empty() and game.area.prop("prop-1").at == Vector2(39, 8) and game.view.building_node("prop-1").visible, "Clicking sets it down where it was pointed")
	await _tap(KEY_2)
	await _point(can_at)
	_check(builder._hover_object.get("id") == "prop-2", "Pointing at the can in Delete picks it")
	await _click()
	_check(game.area.props.size() == 1 and game.view.building_node("prop-2") == null, "Clicking removes the can and its picture")
	_check(game.ledger.edits.size() == 4, "Each of those was one edit")
	builder.hud.done_pressed.emit()
	await _frames(2)
	_check((SaveStore.read().get("edits", []) as Array).size() == 4, "Leaving build mode saves the prop edits")
	await game._return_to_title()
	await _frames(4)
	await game.continue_game()
	await _frames(4)
	_check(game.area.props.size() == 1 and game.area.prop("prop-1").at == Vector2(39, 8) and game.view.building_node("prop-1") != null, "Continue restores the props")
	game._pop_all_modals()
	game.queue_free()
	await process_frame


## A second game as a villager: only open items, with allowances shown.
func _policy() -> void:
	OS.set_environment("VOXEL_BUILD_POLICY", "player")
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	OS.set_environment("VOXEL_BUILD_POLICY", "")
	await game.start_new_game()
	await _frames(6)
	builder = game.builder
	await _tap(KEY_B)
	_check(builder.ledger.policy_id == "player" and builder.hud._cards.size() == 6 and not builder.hud._cards.has("cottage-plaster"), "A villager's shelf leaves out the studio-only cottage")
	_check(builder.hud._allowance.visible and builder.hud._allowance_label.text == "Buildings 0 of 8   ·   Trees 0 of 40", "The allowance is on show: %s" % builder.hud._allowance_label.text)
	builder.choose_item("tree-oak")
	await _point(Vector2(39.5, 5.5))
	await _click()
	_check(builder.hud._allowance_label.text == "Buildings 0 of 8   ·   Trees 1 of 40", "Planting a tree spends one: %s" % builder.hud._allowance_label.text)
	game.queue_free()
	await process_frame


func _painting() -> void:
	builder = game.builder
	game.open_build()
	await _tap(KEY_4)
	_check(builder.tool == BuildMode.Tool.PAINT and builder.hud._paint_scroll.visible, "4 chooses Paint and opens Ground")
	builder.choose_paint("soil")
	builder.set_brush_size(2)
	await _point(Vector2(37, 10))
	var count: int = builder.ledger.edits.size()
	var skin: GroundSkin = game.view.ground_skin
	var skin_id: int = skin.get_instance_id()
	var control_id: int = skin.control_texture.get_instance_id()
	var original: PackedByteArray = skin.control_image.get_data()
	var rules: LabWorld = builder.ledger.rules
	await _click()
	_check(builder.stroke_active and builder.ledger.edits.size() == count, "Dragging is an unsaved proposal until release")
	_check(skin.control_image.get_data() != original, "The control texture updates during a stroke")
	await _point(Vector2(39, 10))
	_check(builder._stroke.size() >= 12, "Dragging fills intervening sub-tiles without holes")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = builder._pointer
	builder.handle_world_input(release)
	await _frames(3)
	_check(not builder.stroke_active and builder.ledger.edits.size() == count + 1, "Release commits one undo step for a whole drag")
	_check(skin.get_instance_id() == skin_id and skin.control_texture.get_instance_id() == control_id and builder.ledger.rules == rules, "Painting preserves ground meshes, texture resource and world rules")
	await create_timer(0.45).timeout
	_check((SaveStore.read().edits as Array).size() == count + 1, "A completed stroke is saved")
	builder.undo()
	_check(skin.control_image.get_data() == original, "Undo restores every previewed pixel")
	builder.redo()
	_check(skin.control_image.get_data() != original, "Redo restores the complete stroke")
	var committed: PackedByteArray = skin.control_image.get_data()
	builder.choose_paint("pebbles")
	await _click()
	await _tap(KEY_ESCAPE)
	_check(not builder.stroke_active and builder.active and skin.control_image.get_data() == committed and builder.ledger.edits.size() == count + 1, "Esc cancels live paint without adding history or leaving build mode")
	builder.eyedropper = true
	await _click()
	_check(builder.paint_material == "soil" and not builder.stroke_active, "Eyedropper picks the effective ground under the pointer")
	builder.choose_paint("dirt")
	await _click()
	var right := InputEventMouseButton.new()
	right.button_index = MOUSE_BUTTON_RIGHT
	right.pressed = true
	builder._input(right)
	_check(not builder.stroke_active and skin.control_image.get_data() == committed, "Right-click cancels a stroke even when GUI panels consume the event")
	await _tap(KEY_BRACKETRIGHT)
	_check(builder.brush_size == 4, "] increases brush size")
	await _tap(KEY_BRACKETLEFT)
	_check(builder.brush_size == 2, "[ decreases brush size")
	game.close_build()


## Land → Terrain and Water through the real input path: a terrace raised with one drag, stairs up its cliff, a stream
## that falls off it, the Delete tool taking stairs away and undo bringing them back, and the reshaped valley saved
## and restored by Continue.
func _shaping() -> void:
	builder = game.builder
	game.open_build()
	await _tap(KEY_4)
	var hud: BuildHud = builder.hud
	_check(hud._paint_tabs.has("Terrain") and hud._paint_tabs.has("Water") and not (hud._paint_tabs["Terrain"] as FButton).disabled and not (hud._paint_tabs["Water"] as FButton).disabled, "Land has working Terrain and Water tabs")
	_check(hud.land_tools.size() == 5 and hud._paint_cards.has("shape:raise") and hud._paint_cards.has("shape:stairs") and hud._paint_cards.has("shape:water"), "Terrain and Water offer raise, lower, stairs, dig and fill")
	builder.choose_shape("raise")
	_check(builder.land_tool == "raise" and builder.tool == BuildMode.Tool.PAINT and (hud._paint_cards["shape:raise"] as BuildCard).selected and (hud._paint_cards["shape:raise"] as BuildCard).visible and not (hud._paint_cards[""] as BuildCard).visible, "Choosing Raise opens Terrain, marks its card and hides the Eraser")
	_check((hud._brush_buttons[4] as FButton).text == "3" and not hud._pick_button.visible, "Land tools size their brush in whole cells and have no Pick")
	_check(hud.details_visible() and hud.details._title.text == "Raise land", "The details panel explains the tool")
	# A free 5 × 6 patch (nothing standing on it or needing it) with a free row in front for the stairs' foot.
	var corner: Vector2i = _open_patch(Vector2i(5, 8)) + Vector2i(0, 1)
	_check(corner.x >= 0, "The valley has open land to shape")
	var middle: Vector2i = corner + Vector2i(2, 3)
	builder.set_brush_size(4)
	var count: int = builder.ledger.edits.size()
	await _point_level(Vector2(corner + Vector2i(1, 2)), 0)
	await _click()
	_check(builder.stroke_active and builder.ledger.edits.size() == count, "A raise drag is a proposal until it is let go")
	await _point_level(Vector2(corner + Vector2i(3, 4)), 0)
	_check(builder.overlay._shape_pool.filter(func(box: MeshInstance3D) -> bool: return box.visible).size() >= 9, "The proposal shows the earth it would add")
	await _release()
	var area: AreaDef = builder.ledger.area
	_check(not builder.stroke_active and builder.ledger.edits.size() == count + 1 and builder.ledger.edits[-1].op == "level", "Release raises the land in one undo step")
	_check(area.level_at(middle) == 1 and is_equal_approx(game.view.ground_y(Vector2(middle)), TerrainBuilder.LEVEL_RISE), "The terrace stands a level up in the view")
	_check(game.session.area == area and game.session.rules == builder.ledger.rules, "The session walks the reshaped valley")
	_check(game.view.pick_cell(game.view.camera.unproject_position(Vector3(middle.x, TerrainBuilder.LEVEL_RISE, -middle.y))) == middle, "Pointing at the terrace's top picks the raised cell")
	builder.choose_shape("stairs")
	_check(not (hud._brush_buttons[4] as FButton).visible, "Stairs need no brush")
	var foot: Vector2i = corner + Vector2i(1, 0)
	await _point_level(Vector2(foot), 0)
	_check(builder._stairs_up == "N", "Stairs at the foot of the cliff climb toward it: %s" % builder._stairs_up)
	await _click()
	_check(not builder.ledger.area.stair_at(foot).is_empty(), "A click builds the stairs")
	_check(builder.ledger.rules.find_path(game.session.state, middle).has(foot), "The terrace can be walked to, up the stairs")
	builder.choose_shape("water")
	builder.set_brush_size(1)
	var stream: int = corner.x + 3
	await _point_level(Vector2(stream, corner.y + 4), 1)
	await _click()
	await _point_level(Vector2(stream, corner.y), 0)
	await _release()
	_check(builder.ledger.area.terrain_at(Vector2i(stream, corner.y + 4)) == AreaDef.Terrain.WATER and builder.ledger.area.terrain_at(Vector2i(stream, corner.y)) == AreaDef.Terrain.WATER, "A water drag digs a stream across both levels")
	_check(not TerrainBuilder.waterfalls(builder.ledger.area).is_empty() and game.view.water_surface.get_node_or_null("Waterfalls") != null, "Where the stream leaves the terrace it falls")
	await _tap(KEY_2)
	await _point_level(Vector2(foot), 0)
	_check(builder._hover_object.get("kind") == "stairs", "The Delete tool finds stairs under the pointer")
	await _click()
	_check(builder.ledger.area.stair_at(foot).is_empty(), "A click takes the stairs away")
	builder.undo()
	_check(not builder.ledger.area.stair_at(foot).is_empty() and not game.view.area.stair_at(foot).is_empty(), "Undo brings them back, in the view too")
	var edits: int = builder.ledger.edits.size()
	game.close_build()
	await create_timer(0.45).timeout
	await game._return_to_title()
	await _frames(4)
	await game.continue_game()
	await _frames(4)
	_check(game.ledger.edits.size() == edits and game.area.level_at(middle) == 1 and not game.area.stair_at(foot).is_empty() and game.area.terrain_at(Vector2i(stream, corner.y + 4)) == AreaDef.Terrain.WATER, "Continue restores the terrace, its stairs and the stream")
	_check(is_equal_approx(game.view.ground_y(Vector2(middle)), TerrainBuilder.LEVEL_RISE) and game.view._terrain_root != null, "Continue draws the reshaped land")
	# Leave the valley flat again for the checks that follow.
	game.open_build()
	for _step: int in range(3):
		game.builder.undo()
	_check(game.area.level_at(middle) == 0 and game.area.stairs.is_empty(), "Undo flattens the valley again")
	game.close_build()


## The south-west corner of the first `size` patch of open land a land tool may change, near the landing, or (-1, -1).
## No building may stand between it and the camera (toward +x and -y), so pointing at it reaches the land.
func _open_patch(size: Vector2i) -> Vector2i:
	var ledger: BuildLedger = game.builder.ledger
	for y: int in range(2, 30):
		for x: int in range(26, 44):
			var view_side := Rect2(Vector2(x, y) - Vector2(0.5, 8.5), Vector2(size) + Vector2(8, 8))
			var open: bool = not ledger.area.buildings.any(func(building: Dictionary) -> bool: return view_side.intersects(building.rect))
			for dy: int in range(size.y):
				for dx: int in range(size.x):
					if open and ledger.land_reason("raise", Vector2i(x + dx, y + dy), 1, game.session.state) != "":
						open = false
			if open:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## Points at a ground point at its land level, the way a mouse would.
func _point_level(logical: Vector2, level: int) -> void:
	game.view.focus_on(logical, true)
	await process_frame
	var on_screen: Vector2 = game.view.camera.unproject_position(Vector3(logical.x, float(level) * TerrainBuilder.LEVEL_RISE, -logical.y)) * game.surface.size / Vector2(game.world_viewport.size)
	var motion := InputEventMouseMotion.new()
	motion.position = on_screen
	game._on_world_input(motion)
	await _frames(3)


func _release() -> void:
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = builder._pointer
	builder.handle_world_input(release)
	await _frames(3)


func _large_shelf() -> void:
	var entries: Array[Dictionary] = []
	for n: int in range(40):
		entries.append({"id": "fake-%d" % n, "title": "House %d" % n, "blurb": "Needle" if n == 23 else "Village house", "kind": "building", "category": "houses" if n < 30 else "trees"})
	var host := Control.new()
	host.size = Vector2(1280, 720)
	root.add_child(host)
	var shelf := BuildHud.new()
	shelf.setup({"categories": [{"id": "houses", "title": "Houses"}, {"id": "trees", "title": "Trees"}]}, entries, func(_entry: Dictionary) -> Dictionary: return {"chip": "5 × 5", "spec": "Footprint 5 × 5 cells"})
	host.add_child(shelf)
	await _frames(8)
	await create_timer(0.5).timeout
	shelf._layout()
	await _frames(4)
	_check(shelf._cards.size() == 40, "A 40-item catalog builds a card for each")
	_check(shelf._tray.size.x >= shelf.size.x and absf(shelf._tray.position.y + shelf._tray.size.y - 8.0 - shelf.size.y) < 2.0, "The tray runs the full width along the bottom of the screen: %s in %s" % [shelf._tray.get_rect(), shelf.size])
	_check(shelf._tray.size.y <= shelf.size.y * 0.36 + 10.0, "...and stays within about a third of the window height")
	var first: Control = shelf._cards["fake-0"]
	var ninth: Control = shelf._cards["fake-9"]
	_check(absf(ninth.position.y - first.position.y) < 1.0 and ninth.position.x > first.position.x, "Cards sit in one row, not a grid")
	_check(shelf._scroll.get_h_scroll_bar().max_value > shelf._scroll.get_h_scroll_bar().page + 1.0, "A long category scrolls sideways")
	_check(shelf._page_left.disabled and not shelf._page_right.disabled, "The page buttons know the row is at its start")
	shelf._page(1)
	await create_timer(0.45).timeout
	_check(shelf._scroll.scroll_horizontal > 0 and not shelf._page_left.disabled, "The page button scrolls the row on")
	shelf.search.text = "Needle"
	shelf.search.text_changed.emit(shelf.search.text)
	await _frames(3)
	_check(shelf.visible_items().size() == 1 and shelf.visible_items()[0].id == "fake-23" and shelf._scroll.scroll_horizontal == 0, "Search filters blurbs across categories and returns to the start")
	var picked: Array[String] = []
	shelf.item_chosen.connect(func(id: String) -> void: picked.append(id))
	(shelf._cards["fake-23"] as BuildCard).chosen.emit("fake-23")
	_check(picked == ["fake-23"], "Choosing a filtered card still sends its identity")
	shelf.search.text = "trees"
	shelf.search.text_changed.emit(shelf.search.text)
	await _frames(2)
	_check(shelf.visible_items().size() == 10, "Search finds category names across tabs")
	shelf.clear_search()
	_check(shelf.visible_items().size() == 30, "Esc/clear returns to the selected category")
	shelf.show_details({"key": "x", "title": "Fake", "turns": true, "facing": "S", "door": true})
	await create_timer(0.45).timeout
	_check(shelf.details.visible and absf(shelf.details.size.x / shelf.size.x - 0.1875) < 0.05, "The details panel takes about a fifth of the width: %.2f" % (shelf.details.size.x / shelf.size.x))
	_check(shelf.details.position.x + shelf.details.size.x <= shelf.size.x and shelf.details.position.x > shelf._rail.position.x + shelf._rail.size.x, "...on the right, clear of the rail: %s, rail %s, window %s" % [shelf.details.get_rect(), shelf._rail.get_rect(), shelf.size])
	_check(shelf.details.size.y + shelf.details.position.y <= shelf._tray.position.y + 1.0, "...and above the tray")
	host.queue_free()
	await process_frame


## The new layout in a running game: a rail on the left in the asked order, a tray the width of the screen, and a
## details panel on the right. Then turning things: the thing being placed, one already standing, and the mill.
func _layout_and_turning() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game()
	await _frames(6)
	builder = game.builder
	var session: GameSession = game.session
	await _tap(KEY_B)
	await create_timer(0.5).timeout
	var hud: BuildHud = builder.hud
	var order: Array[int] = [BuildMode.Tool.MOVE, BuildMode.Tool.DELETE, BuildMode.Tool.PLACE, BuildMode.Tool.PAINT]
	var heights: Array[float] = []
	for tool: int in order:
		heights.append((hud._bubbles[tool] as Control).global_position.y)
	_check(heights[0] < heights[1] and heights[1] < heights[2] and heights[2] < heights[3], "The rail lists Move, Delete, Objects, Land from the top")
	_check(hud._rail.global_position.x < 40.0 and hud._rail.global_position.x + hud._rail.size.x * hud._rail.scale.x < hud.size.x * 0.12, "The rail hugs the left edge")
	_check(hud._rail.global_position.y >= 0.0 and hud._rail.global_position.y + hud._rail.size.y * hud._rail.scale.y <= hud._tray.position.y, "The rail fits above the tray at %s" % str(hud.size))
	var rail_at: Vector2 = hud._rail.position
	_check(hud._tray.visible and hud._tray.size.x >= hud.size.x and builder.tool == BuildMode.Tool.PLACE, "Objects opens a tray across the whole bottom")
	_check(hud.details_visible() and hud.details.subject_key() == "item:house-hollow", "The chosen house has its details on the right")
	_check(hud.details.turntable.visible and hud.details.turntable.spinning, "A house that can be turned shows a turning model" + (" (no renderer here)" if DisplayServer.get_name() == "headless" else ""))
	_check(hud.details.compass.facing == "S" and hud.details._facing_box.visible, "...and a compass on its facing")
	hud.details.compass.chosen.emit("E")
	_check(builder.facing == "E" and hud.details.compass.facing == "E" and game.ledger.edits.is_empty(), "Choosing a facing on the compass turns the thing to be placed, and changes nothing yet")
	await _point(Vector2(34, 5))
	_check(absf(builder.overlay._ghost_root.rotation_degrees.y - 90.0) < 0.1, "...and its ghost")
	await _click()
	await _frames(3)
	_check(game.area.building("build-1").facing == "E", "It is placed facing that way")
	builder.choose_item("tree-elder")
	_check(not hud.details._facing_box.visible, "A tree has no compass")
	# Turn a standing house.
	await _tap(KEY_1)
	await create_timer(0.5).timeout
	_check(hud._rail.position.is_equal_approx(rail_at) and not hud._tray.visible, "Choosing Move puts the tray away, and the rail stays exactly where it was")
	await _point(Vector2(34, 5))
	await _click()
	_check(builder.selected.get("id") == "build-1" and builder.facing == "E" and hud.details.compass.facing == "E", "Choosing a standing house shows its facing")
	_check(hud.details._remove.visible and hud.details._facing_box.visible, "...with a Remove button and the compass")
	var edits: int = game.ledger.edits.size()
	hud.details.compass.chosen.emit("N")
	await _frames(3)
	_check(game.area.building("build-1").facing == "N" and game.ledger.edits.size() == edits + 1 and game.area.building("build-1").at == Vector2(34, 5), "The compass turns it where it stands (one edit)")
	_check(builder.selected.get("id") == "build-1" and hud.details.compass.facing == "N", "...and it stays chosen")
	_check(hud._toasts.get_child_count() >= 1 and game.ledger.describe(game.ledger.edits[-1]) == "Turned Hollow House", "The history says it was turned")
	await _tap(KEY_R)
	await _frames(3)
	_check(game.area.building("build-1").facing == "W" and game.ledger.edits.size() == edits + 2, "R turns the chosen house too")
	await _tap(KEY_R, false, true)
	await _frames(3)
	_check(game.area.building("build-1").facing == "N", "Shift+R turns it back")
	await _tap(KEY_Z, true)
	_check(game.area.building("build-1").facing == "W" and game.ledger.edits.size() == edits + 2, "Undo turns it back one step")
	await _tap(KEY_Z, true)
	await _tap(KEY_Z, true)
	_check(game.area.building("build-1").facing == "E" and game.ledger.edits.size() == edits, "...and all the way to how it was placed")
	hud.details.turn_pressed.emit(1)
	await _frames(3)
	_check(game.area.building("build-1").facing == "N", "The turn buttons work")
	# The mill belongs to the lessons.
	await _point(Vector2(49.1, 24.6))
	await _click()
	_check(builder.selected.get("id") == "mill" and not hud.details._facing_box.visible and not hud.details._remove.visible, "The mill can be looked at but not turned or removed")
	var kept: int = game.ledger.edits.size()
	builder.set_facing("E")
	_check(game.ledger.edits.size() == kept and game.area.building("mill").facing == "S", "Turning the mill is refused")
	# Esc lets go of the choice before it leaves.
	await _tap(KEY_ESCAPE)
	_check(builder.selected.is_empty() and builder.active and not hud.details_visible(), "Escape lets go of the chosen thing, and the details panel goes")
	# Removing from the panel.
	await _point(Vector2(34, 5))
	await _click()
	var count: int = game.area.buildings.size()
	hud.details.remove_pressed.emit()
	await _frames(3)
	_check(game.area.buildings.size() == count - 1 and builder.selected.is_empty() and not hud.details_visible(), "Remove in the panel takes it away and clears the choice")
	await _tap(KEY_Z, true)
	_check(game.area.buildings.size() == count, "...and Ctrl+Z brings it back")
	game.close_build()
	game._pop_all_modals()
	game.queue_free()
	await process_frame


## Dragging a thing to a new place, and the code panel for a lamp.
func _drag_and_code() -> void:
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(8)
	await game.start_new_game()
	await _frames(6)
	builder = game.builder
	var session: GameSession = game.session
	await _tap(KEY_B)
	await _point(Vector2(34, 5))
	await _click()
	await _frames(3)
	await _tap(KEY_1)
	await _point(Vector2(34, 5))
	var target := Vector2(-1, -1)
	for y: int in range(2, 14):
		for x: int in range(31, 44):
			if target.x < 0.0 and Vector2(x, y).distance_to(Vector2(34, 5)) > 6.0 and Vector2(x, y).distance_to(Vector2(34, 5)) < 8.0 and game.ledger.check_move_building("build-1", Vector2(x, y), "S", session.state).ok:
				target = Vector2(x, y)
	_check(target.x > 0.0, "There is somewhere to drag the house to")
	# Press on it (nothing chosen yet), pull, let go.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = builder._pointer
	game._on_world_input(press)
	await _frames(2)
	_check(builder.selected.get("id") == "build-1" and builder.carrying.is_empty(), "Pressing a house chooses it")
	var there: Vector2 = game.view.camera.unproject_position(Vector3(target.x, 0.0, -target.y)) * game.surface.size / Vector2(game.world_viewport.size)
	var pull := InputEventMouseMotion.new()
	pull.position = there
	pull.relative = there - builder._pointer
	game._on_world_input(pull)
	await _frames(3)
	await create_timer(0.16).timeout
	_check(builder.carrying.get("id") == "build-1", "Pulling it lifts it")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = there
	game._on_world_input(release)
	await _frames(3)
	_check(builder.carrying.is_empty() and game.area.building("build-1").at == target, "Letting go sets it down where it was dragged: %s" % str(game.area.building("build-1").at))
	_check(builder.selected.get("id") == "build-1", "...and it stays chosen")
	# A lamp: its code.
	var lamp: Dictionary = game.area.lamp("landing-lamp")
	await _point(lamp.at)
	await _click()
	_check(builder.selected.get("kind") == "lamp" and builder.selected.get("id") == "landing-lamp", "Pointing at a lamp chooses it: %s" % str(builder.selected))
	var details: BuildDetails = builder.hud.details
	_check(details._code_box.visible and details._code_snippet.text == "lamp = world.lamp(\"landing-lamp\")", "A lamp has a code section that says how to reach it")
	_check(details._members.get_child_count() == ApiReference.members_of("Lamp").size(), "...and lists what it can do")
	_check(details._code_button.visible and not details._facing_box.visible and not details._remove.visible, "The player has been there, so they can write code for it; it has no facing and cannot be removed")
	var far: Dictionary = game.area.lamp("road-lamp-6")
	await _point(far.at)
	await _click()
	_check(builder.selected.get("id") == "road-lamp-6" and details._code_box.visible and not details._code_button.visible and details._code_note.text.contains("visited"), "A lamp in a place not yet visited says so and offers no code")
	var asked: Array[String] = []
	builder.code_requested.connect(func(snippet: String) -> void: asked.append(snippet))
	await _point(lamp.at)
	await _click()
	details.code_pressed.emit("lamp = world.lamp(\"landing-lamp\")")
	await _frames(4)
	_check(asked == ["lamp = world.lamp(\"landing-lamp\")"] and not builder.active and game.notebook_open, "Write code for it leaves build mode and opens the notebook")
	_check(game.notebook.editor.text.contains("lamp = world.lamp(\"landing-lamp\")"), "...with the line in the editor")
	game.close_notebook(true)
	await _frames(2)
	await _tap(KEY_B)
	_check(game.builder.active, "Build mode opens again")
	# Houses, trees and doodads: the Code section's three honest states.
	await _tap(KEY_1)
	await _point(target)
	await _click()
	_check(builder.selected.get("id") == "build-1" and details._code_box.visible and details._code_snippet.text == "house = world.house(\"build-1\")", "A house has a code section that says how to reach it")
	_check(not details._code_button.visible and details._code_note.text.contains("Reach the lesson \"Face the lane\""), "Before the lesson, there is no button, and the note names it: %s" % details._code_note.text)
	game.session.extra_abilities = ["read", "turn"]
	builder._refresh_details()
	_check(details._code_button.visible and details._code_note.text == "", "Once the code may read, and the house is within reach, the button appears")
	var faraway: Dictionary = game.area.building("brook-hall")
	builder._select({"kind": "building", "id": "brook-hall", "locked": false, "at": faraway.at})
	_check(builder.selected.get("id") == "brook-hall" and not details._code_button.visible and details._code_note.text.contains("Out of reach"), "A house far from the player in a place never visited is out of reach: %s" % details._code_note.text)
	builder.choose_item("tree-elder")
	await _point(Vector2(39.5, 5.5))
	await _click()
	await _tap(KEY_1)
	builder._select({"kind": "tree", "at": Vector2(39.5, 5.5), "size": 1.25, "asset": "", "locked": false})
	_check(builder.selected.get("kind") == "tree" and details._code_snippet.text == "tree = world.tree(39.5, 5.5)", "A tree is fetched by where it stands, written plainly: %s" % details._code_snippet.text)
	builder._select({"kind": "tree", "at": Vector2(37.9000015258789, 4.0), "size": 1.0, "asset": "", "locked": false})
	_check(details._code_snippet.text == "tree = world.tree(37.9, 4)", "...even for a tree at an awkward place: %s" % details._code_snippet.text)
	_check(details._code_button.visible and details._members.get_child_count() == ApiReference.members_of("Tree").size(), "...with the members a tree offers")
	game.session.extra_abilities = []
	# Land shows the ground in the details panel.
	await _tap(KEY_4)
	_check(builder.hud.details_visible() and builder.hud.details.subject_key().begins_with("paint:") and not builder.hud.details._facing_box.visible, "Land shows the chosen paint, which has no facing")
	game.close_build()
	game._pop_all_modals()
	game.queue_free()
	await process_frame


# ------------------------------------------------------------------ helpers
## Moves the pointer onto a ground cell the way a mouse would, through the game's own world input handler.
func _point(logical: Vector2) -> void:
	game.view.focus_on(logical, true)
	await process_frame
	var on_screen: Vector2 = game.view.camera.unproject_position(Vector3(logical.x, 0.0, -logical.y)) * game.surface.size / Vector2(game.world_viewport.size)
	var motion := InputEventMouseMotion.new()
	motion.position = on_screen
	game._on_world_input(motion)
	await _frames(3)
	await create_timer(0.16).timeout
	await _frames(2)


func _click() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = builder._pointer
	game._on_world_input(press)
	await _frames(3)


func _wheel(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = builder._pointer
	return event


func _tap(code: Key, ctrl: bool = false, shift: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	game._unhandled_key_input(event)
	await _frames(2)


func _pending_pictures() -> int:
	var pending: int = 0
	for card: Variant in builder.hud._cards.values():
		if (card as BuildCard)._picture.texture == null:
			pending += 1
	return pending


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value:
		_failures.append(message)
