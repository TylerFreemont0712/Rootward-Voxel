class_name BuildMode
extends Node
## Build mode's controller: the tools (Move, Delete, Objects, Land), what the pointer is over, the ghost and its
## colour, what is chosen and its details, the clicks that change the valley, undo and redo, and the free camera. It asks BuildLedger what is allowed
## and draws the answer through BuildOverlay and BuildHud; it decides nothing about the rules itself.
## Game owns the world and the save, and is told through `edited`.

signal exit_requested
signal edited(label: String)
## The player asked to write code for a thing in the valley; `snippet` is the line that fetches it.
signal code_requested(snippet: String)

enum Tool { PLACE, MOVE, DELETE, PAINT }

const WorldAssets := preload("res://art/world_assets.gd")

const ZOOM_RANGE := Vector2(8.0, 24.0)
const BUILD_ZOOM: float = 15.0
const FULL_CHECK_DELAY: float = 0.11
## How far (in pixels) the pointer must travel with the button down before it counts as a drag.
const DRAG_PIXELS: float = 8.0
## What a program can reach in the valley today: lamps, gates and bridges (the World tab and Reference say how).
const CODE_TYPES: Dictionary = {"lamp": "Lamp", "gate": "Gate", "bridge": "Bridge"}

var active: bool = false
var tool: int = Tool.PLACE
var item_id: String = ""
var facing: String = "S"
var ledger: BuildLedger
var view: ClearingView
var session: GameSession
var surface: Control
var world_viewport: SubViewport
var hud: BuildHud
var overlay: BuildOverlay
var studio: ThumbnailStudio
## What is being carried in the Move tool: {kind, id | from, asset, size, node}.
var carrying: Dictionary = {}
## What the Move tool has chosen, kept while the pointer wanders: {kind, id | at, size, asset, locked}.
var selected: Dictionary = {}
var _left_down: bool = false
var _press_point: Vector2 = Vector2.ZERO
var _press_object: Dictionary = {}
var _drag_lift: bool = false
var _pointer: Vector2 = Vector2(-1.0, -1.0)
var _pointer_in: bool = false
var _hover_dirty: bool = false
var _snapped: Vector2 = Vector2(-1.0, -1.0)
var _hover_object: Dictionary = {}
var _candidate: Dictionary = {}
var _full_timer: Timer
var _full_key: String = ""
var _full_result: Dictionary = {}
var _entries: Array[Dictionary] = []
var _pictures_started: bool = false
var _dragging: bool = false
## How many card pictures have finished (drawn, or skipped where nothing can be drawn).
var pictures_done: int = 0
var paint_material: String = "dirt"
## The chosen land-shaping tool, or "" while painting: "raise", "lower", "stairs", "water" or "land" (fill in).
var land_tool: String = ""
var brush_size: int = 1
var eyedropper: bool = false
var stroke_active: bool = false
var _stroke: Dictionary = {}
var _last_sub: Vector2i = Vector2i(-999, -999)
var _brush_sub: Vector2i = Vector2i.ZERO
var _picture_cache: Dictionary = {}
## The cell a land tool is over, the level a raise or lower stroke heads for, and which way stairs there would climb.
var _land_cell: Vector2i = Vector2i(-1, -1)
var _stroke_level: int = 0
var _stairs_up: String = ""


## Builds the overlay, the interface and the thumbnail studio. `host` is where the interface goes.
func setup(p_view: ClearingView, p_session: GameSession, p_surface: Control, p_viewport: SubViewport, host: Control, p_ledger: BuildLedger) -> void:
	view = p_view
	session = p_session
	surface = p_surface
	world_viewport = p_viewport
	ledger = p_ledger
	overlay = BuildOverlay.new()
	view.add_child(overlay)
	overlay.setup(view)
	studio = ThumbnailStudio.new()
	add_child(studio)
	_entries = AreaBuild.allowed_items(ledger.build_catalog, ledger.policy_id)
	hud = BuildHud.new()
	hud.setup(ledger.build_catalog, _entries, describe_item)
	hud.visible = false
	host.add_child(hud)
	hud.tool_chosen.connect(set_tool)
	hud.item_chosen.connect(choose_item)
	hud.paint_chosen.connect(choose_paint)
	hud.shape_chosen.connect(choose_shape)
	hud.brush_chosen.connect(set_brush_size)
	hud.eyedropper_pressed.connect(func() -> void: eyedropper = true)
	hud.undo_pressed.connect(undo)
	hud.redo_pressed.connect(redo)
	hud.done_pressed.connect(func() -> void: exit_requested.emit())
	hud.details.facing_chosen.connect(set_facing)
	hud.details.turn_pressed.connect(rotate)
	hud.details.remove_pressed.connect(remove_selected)
	hud.details.code_pressed.connect(func(snippet: String) -> void: code_requested.emit(snippet))
	hud.details.finish_chosen.connect(set_finish)
	_full_timer = Timer.new()
	_full_timer.one_shot = true
	_full_timer.timeout.connect(_run_full_check)
	add_child(_full_timer)
	surface.mouse_exited.connect(_pointer_left)


## The size line on a card and the facts in the dock's panel, from the world catalog and the audience.
func describe_item(entry: Dictionary) -> Dictionary:
	var who: String = "Open to everyone" if entry.get("audience") == "player" else "Studio only"
	if entry.kind == "building":
		var rect: Rect2 = AreaBuild.footprint_rect(ledger.assets, str(entry.asset), Vector2.ZERO, "S", 1.0)
		var across: int = maxi(1, ceili(rect.size.x - 0.2))
		var deep: int = maxi(1, ceili(rect.size.y - 0.2))
		return {"chip": "%d × %d cells" % [across, deep], "spec": "Footprint %d × %d cells  ·  door on the front\n%s" % [across, deep, who]}
	if entry.kind == "prop":
		var body: Rect2 = AreaBuild.prop_rect(ledger.assets, str(entry.asset), Vector2.ZERO, "S", 1.0)
		if AreaBuild.prop_is_solid(ledger.assets, str(entry.asset)):
			return {"chip": "%.1f × %.1f cells" % [body.size.x, body.size.y], "spec": "Footprint %.1f × %.1f cells  ·  blocks the way\n%s" % [body.size.x, body.size.y, who]}
		return {"chip": "Walk-through", "spec": "A decoration you can walk past\n%s" % who}
	var size: float = float(entry.get("size", 1.0))
	if entry.has("asset"):
		var radius: float = float(ledger.assets[entry.asset].logical_footprint.trunk_radius) * size
		return {"chip": "Trunk radius %.2f" % radius, "spec": "Trunk radius %.2f cells\nGrows on grass · %s" % [radius, who]}
	var word: String = "Small" if size < 0.9 else ("Medium" if size < 1.1 else "Large")
	return {"chip": "%s tree" % word, "spec": "Grows on grass, keeps a cell clear\n%s" % who}


# ---------------------------------------------------------------- entering
func enter() -> void:
	if active:
		return
	active = true
	carrying = {}
	selected = {}
	facing = "S"
	_hover_object = {}
	session.replace_area(ledger.area, ledger.rules)
	overlay.set_active(true)
	view.set_camera_mode(ClearingView.CameraMode.FREE)
	view.set_marker_hidden(true)
	view.focus_on(Vector2(session.player_cell()))
	view.set_zoom(BUILD_ZOOM)
	hud.visible = true
	set_tool(Tool.PLACE)
	choose_item(item_id if item_id != "" else (str(_entries[0].id) if not _entries.is_empty() else ""))
	_refresh_status()
	hud.toast("Build mode  ·  pick something from the tray")
	if not _pictures_started:
		_pictures_started = true
		_make_pictures()


func leave() -> void:
	if not active:
		return
	_cancel_carry()
	_cancel_stroke()
	selected = {}
	overlay.clear_selection()
	hud.hide_details()
	active = false
	view.set_marker_hidden(false)
	_full_timer.stop()
	overlay.set_active(false)
	hud.hide_bubble()
	hud.visible = false


# -------------------------------------------------------------------- state
func set_tool(new_tool: int) -> void:
	_cancel_stroke()
	_cancel_carry()
	_full_timer.stop()
	_candidate = {}
	if new_tool != Tool.MOVE:
		_clear_selection(false)
	tool = new_tool
	hud.set_tool(tool)
	overlay.set_paint_grid(tool == Tool.PAINT and land_tool == "")
	overlay.clear_shape()
	overlay.hide_ghost()
	overlay.clear_highlight()
	hud.hide_bubble()
	_refresh_details()
	_hover_dirty = true


func choose_item(id: String) -> void:
	item_id = id
	if tool != Tool.PLACE:
		set_tool(Tool.PLACE)
	hud.set_item(id)
	_refresh_details()
	_hover_dirty = true


## Turns the thing being placed, carried or chosen a quarter turn (negative for the other way).
func rotate(steps: int = 1) -> void:
	set_facing(AreaBuild.turned(facing, steps))


## Faces the thing being placed or carried that way, or turns a chosen standing thing on the spot (one undo step,
## refused with the reason if it would then not fit).
func set_facing(new_facing: String) -> void:
	if tool == Tool.MOVE and carrying.is_empty():
		_turn_selected(new_facing)
		return
	facing = new_facing
	hud.set_details_facing(facing)
	_hover_dirty = true


func _turn_selected(new_facing: String) -> void:
	if selected.is_empty() or not selected.kind in ["building", "prop"]:
		return
	var result: Dictionary
	if selected.kind == "building":
		result = ledger.turn_building(str(selected.id), new_facing, session.state)
	else:
		result = ledger.turn_prop(str(selected.id), new_facing, session.state)
	if not result.ok:
		_deny(str(result.reason))
		hud.set_details_facing(facing)
		return
	facing = new_facing
	_after_edit(ledger.describe(result.edit))


## Takes the chosen thing away (the details panel's Remove, or the Delete key).
func remove_selected() -> void:
	if tool == Tool.MOVE and carrying.is_empty():
		_delete_object(selected)


func undo() -> void:
	_cancel_stroke()
	if not ledger.can_undo():
		hud.toast("Nothing to undo")
		return
	var label: String = "Undid: %s" % ledger.describe(ledger.edits[-1])
	var result: Dictionary = ledger.undo(session.state)
	if result.ok:
		_after_edit(label)
	else:
		hud.toast(str(result.reason))


func redo() -> void:
	_cancel_stroke()
	if not ledger.can_redo():
		hud.toast("Nothing to redo")
		return
	var result: Dictionary = ledger.redo(session.state)
	if result.ok:
		_after_edit("Redid: %s" % ledger.describe(ledger.edits[-1]))
	else:
		hud.toast(str(result.reason))


# -------------------------------------------------------------------- input
## Keys while building. Returns true if the key was used.
func handle_key(event: InputEventKey) -> bool:
	if not active or not event.pressed:
		return false
	match event.keycode:
		KEY_ESCAPE:
			if stroke_active:
				_cancel_stroke()
			elif hud.clear_search():
				pass
			elif not carrying.is_empty():
				_cancel_carry()
			elif not selected.is_empty():
				_clear_selection()
			elif tool == Tool.PLACE and item_id != "":
				_put_item_away()
			else:
				exit_requested.emit()
		KEY_R:
			if not event.ctrl_pressed:
				rotate(-1 if event.shift_pressed else 1)
		KEY_1:
			set_tool(Tool.MOVE)
		KEY_2, KEY_X:
			set_tool(Tool.DELETE)
		KEY_3:
			set_tool(Tool.PLACE)
		KEY_4:
			set_tool(Tool.PAINT)
		KEY_DELETE:
			if tool == Tool.MOVE and not selected.is_empty() and carrying.is_empty():
				remove_selected()
			else:
				set_tool(Tool.DELETE)
		KEY_F:
			if not event.ctrl_pressed:
				return false
			hud.focus_search()
		KEY_I:
			if tool != Tool.PAINT or land_tool != "":
				return false
			eyedropper = not eyedropper
			_hover_dirty = true
		KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
			if tool != Tool.PAINT:
				return false
			var sizes: Array[int] = [1, 2, 4]
			set_brush_size(sizes[clampi(sizes.find(brush_size) + (-1 if event.keycode == KEY_BRACKETLEFT else 1), 0, 2)])
		KEY_Z:
			if event.ctrl_pressed:
				if event.shift_pressed:
					redo()
				else:
					undo()
			else:
				return false
		KEY_Y:
			if event.ctrl_pressed:
				redo()
			else:
				return false
		KEY_TAB:
			hud.open_tray(not hud.tray_visible())
		KEY_B:
			exit_requested.emit()
		_:
			return false
	return true


func handle_world_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		_pointer = (event as InputEventMouseMotion).position
		_pointer_in = true
		if _dragging:
			var relative: Vector2 = (event as InputEventMouseMotion).relative
			var units_per_pixel: float = view.camera.size / float(world_viewport.size.y) * (float(world_viewport.size.y) / surface.size.y)
			view.pan_focus_screen(-relative.x * units_per_pixel, relative.y * units_per_pixel)
		elif _left_down and tool == Tool.MOVE and carrying.is_empty() and not _press_object.is_empty() and not _press_object.locked and _pointer.distance_to(_press_point) > DRAG_PIXELS:
			# Pressing a thing and pulling lifts it, and letting go sets it down.
			_pick_up(_press_object)
			_drag_lift = true
		_hover_dirty = true
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		_pointer = button.position
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				if button.pressed:
					_left_down = true
					_press_point = button.position
					if tool == Tool.PAINT and land_tool == "" and button.alt_pressed:
						eyedropper = true
					_refresh_hover()
					_press_object = _hover_object.duplicate() if tool == Tool.MOVE else {}
					_click()
				else:
					_left_released()
			MOUSE_BUTTON_RIGHT:
				if button.pressed:
					_cancel()
			MOUSE_BUTTON_MIDDLE:
				_dragging = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					view.set_zoom(clampf(view.zoom() - 0.8, ZOOM_RANGE.x, ZOOM_RANGE.y))
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					view.set_zoom(clampf(view.zoom() + 0.8, ZOOM_RANGE.x, ZOOM_RANGE.y))


func _process(delta: float) -> void:
	if not active:
		return
	var pan: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if pan != Vector2.ZERO and not _text_has_focus():
		var speed: float = view.zoom() * 0.9 * (2.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		# Screen-aligned: the ground's right-hand diagonal and its far diagonal.
		var ground: Vector2 = Vector2(1.0, 1.0) * pan.x + Vector2(-1.0, 1.0) * -pan.y
		view.pan_focus(ground.normalized() * minf(1.0, pan.length()) * speed * delta)
		_hover_dirty = true
	if _hover_dirty:
		_hover_dirty = false
		_refresh_hover()
		if stroke_active and _pointer_in and not hud.covers(_pointer):
			_extend_stroke()


## Release still lands when the pointer moved over a panel (whose GUI consumes mouse events).
func _input(event: InputEvent) -> void:
	if active and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_left_released()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and stroke_active:
			_cancel_stroke()


## The left button came up: a paint stroke is committed, and a thing that was dragged is set down where it was
## let go. (A click that only lifted it leaves it in hand for the next click.)
func _left_released() -> void:
	var was_down: bool = _left_down
	_left_down = false
	_press_object = {}
	if stroke_active:
		_finish_stroke()
	if was_down and _drag_lift and not carrying.is_empty() and _pointer_in and not hud.covers(_pointer) and _pointer.distance_to(_press_point) > DRAG_PIXELS:
		_refresh_hover()
		_set_down(session.state)
	_drag_lift = false


func _text_has_focus() -> bool:
	var owner: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return owner is LineEdit or owner is TextEdit


func _pointer_left() -> void:
	_pointer_in = false
	overlay.hide_ghost()
	overlay.clear_highlight()
	hud.hide_bubble()
	_hover_object = {}


# -------------------------------------------------------------------- hover
func _viewport_point() -> Vector2:
	return _pointer * Vector2(world_viewport.size) / surface.size


func _refresh_hover() -> void:
	if not _pointer_in or hud.covers(_pointer):
		overlay.hide_ghost()
		overlay.clear_highlight()
		hud.hide_bubble()
		_hover_object = {}
		return
	match tool:
		Tool.PLACE:
			_hover_place()
		Tool.MOVE:
			if carrying.is_empty():
				_hover_pick("move")
			else:
				_hover_carry()
		Tool.DELETE:
			_hover_pick("delete")
		Tool.PAINT:
			_hover_paint()


func choose_paint(material: String) -> void:
	_cancel_stroke()
	paint_material = material
	land_tool = ""
	eyedropper = false
	hud.set_paint(material)
	hud.set_land_mode("paint")
	overlay.set_paint_grid(tool == Tool.PAINT)
	overlay.hide_ghost()
	_refresh_details()
	_hover_dirty = true


## Chooses a land-shaping tool from Land's Terrain or Water: raise, lower, stairs, water or land (fill in).
func choose_shape(shape: String) -> void:
	_cancel_stroke()
	land_tool = shape
	eyedropper = false
	hud.set_paint("shape:" + shape)
	hud.set_land_mode("stairs" if shape == "stairs" else "shape")
	if tool != Tool.PAINT:
		set_tool(Tool.PAINT)
	overlay.set_paint_grid(false)
	overlay.hide_ghost()
	_refresh_details()
	_hover_dirty = true


func set_brush_size(side: int) -> void:
	brush_size = side if side in [1, 2, 4] else 1
	hud.set_brush(brush_size)
	_hover_dirty = true


func _brush_cells(sub: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start: Vector2i = sub - Vector2i(brush_size / 2, brush_size / 2)
	for dy: int in range(brush_size):
		for dx: int in range(brush_size):
			cells.append(start + Vector2i(dx, dy))
	return cells


func _hover_paint() -> void:
	if land_tool != "":
		_hover_land()
		return
	var ground: Variant = overlay.ground_point(_viewport_point())
	if ground == null:
		return
	_brush_sub = Vector2i(floori((ground.x + 0.5) * 2.0), floori((ground.y + 0.5) * 2.0))
	overlay.set_cursor(ground)
	var color: Color = preload("res://art/world_palette.gd").COLORS.get(paint_material, Color("dfd2ab"))
	overlay.show_brush(_brush_cells(_brush_sub), color)
	var valid: bool = GroundPaint.is_ground(ledger.area, _brush_sub) and view.ground_skin != null
	var label: String = "Pick a ground material" if eyedropper or Input.is_key_pressed(KEY_ALT) else ("Restore natural ground" if paint_material == "" else "Paint " + paint_material.replace("_", " "))
	hud.set_bubble(label if valid else "Paint only generated grass, paths or cobble", valid, _pointer)


func _start_stroke() -> void:
	if land_tool == "stairs":
		_place_stairs()
		return
	if land_tool != "":
		_start_shape()
		return
	if view.ground_skin == null:
		_deny("This area's ground is an authored model.")
		return
	if eyedropper or Input.is_key_pressed(KEY_ALT):
		if GroundPaint.is_ground(ledger.area, _brush_sub):
			choose_paint(GroundPaint.material_at(ledger.area, _brush_sub))
		return
	stroke_active = true
	_stroke.clear()
	_last_sub = Vector2i(-999, -999)
	_extend_stroke()


func _extend_stroke() -> void:
	if land_tool != "":
		_extend_shape()
		return
	var start: Vector2i = _brush_sub if _last_sub.x == -999 else _last_sub
	var delta: Vector2i = _brush_sub - start
	var steps: int = maxi(absi(delta.x), absi(delta.y))
	var fresh: Array[Vector2i] = []
	for step: int in range(steps + 1):
		var sub := Vector2i(Vector2(start).lerp(Vector2(_brush_sub), float(step) / float(maxi(steps, 1))).round())
		for cell: Vector2i in _brush_cells(sub):
			if GroundPaint.is_ground(ledger.area, cell) and not _stroke.has(cell):
				_stroke[cell] = true
				fresh.append(cell)
	_last_sub = _brush_sub
	if not fresh.is_empty():
		view.ground_skin.preview(paint_material, fresh)


func _finish_stroke() -> void:
	if not stroke_active:
		return
	if land_tool != "":
		_finish_shape()
		return
	if _pointer_in and not hud.covers(_pointer):
		_refresh_hover()
		_extend_stroke()
	stroke_active = false
	var cells: Array = []
	for sub: Vector2i in _stroke:
		cells.append([sub.x, sub.y])
	_stroke.clear()
	if cells.is_empty():
		return
	var result: Dictionary = ledger.paint(paint_material, cells, session.state)
	if result.ok:
		_after_edit(ledger.describe(result.edit))
	else:
		view.ground_skin.update_area(ledger.area)
		_deny(str(result.reason))


func _cancel_stroke() -> void:
	if not stroke_active:
		return
	stroke_active = false
	_stroke.clear()
	overlay.clear_shape()
	if view.ground_skin != null:
		view.ground_skin.update_area(ledger.area)
	_hover_dirty = true


# ------------------------------------------------------------- shaping land
## The cells under a land tool's brush round `cell`: 1×1, 2×2 or 3×3 cells for the three brush sizes.
func _land_brush(cell: Vector2i) -> Array[Vector2i]:
	var side: int = {1: 1, 2: 2, 4: 3}.get(brush_size, 1)
	var start: Vector2i = cell - Vector2i((side - 1) / 2, (side - 1) / 2)
	var cells: Array[Vector2i] = []
	for dy: int in range(side):
		for dx: int in range(side):
			cells.append(start + Vector2i(dx, dy))
	return cells


## The level a raise or lower stroke starting on this cell heads for: one up or one down from it.
func _target_level(cell: Vector2i) -> int:
	match land_tool:
		"raise":
			return ledger.area.level_at(cell) + 1
		"lower":
			return ledger.area.level_at(cell) - 1
	return 0


func _land_label(level: int) -> String:
	match land_tool:
		"raise":
			return "Raise to level %d" % level
		"lower":
			return "Lower to the valley floor" if level == 0 else "Lower to level %d" % level
		"water":
			return "Dig water"
		"land":
			return "Fill in with earth"
	return ""


## What a land tool would do here: the brush's cells, green where they would change and red where they would not,
## and the reason for the cell under the pointer. Stairs show a ghost flight climbing the cliff beside the cell.
func _hover_land() -> void:
	var ground: Variant = overlay.ground_point(_viewport_point())
	if ground == null:
		overlay.hide_ghost()
		overlay.clear_highlight()
		hud.hide_bubble()
		return
	var cell := Vector2i(floori((ground as Vector2).x + 0.5), floori((ground as Vector2).y + 0.5))
	_land_cell = cell
	overlay.set_cursor(ground)
	var state: Dictionary = session.state
	if land_tool == "stairs":
		_stairs_up = AreaBuild.stairs_direction(ledger.area, cell, facing)
		var checked: Dictionary = ledger.check_stairs(cell, _stairs_up, state) if _stairs_up != "" else {"ok": false, "reason": "Stairs go at the foot of a cliff one level high."}
		if not ledger.area.in_bounds(cell):
			overlay.hide_ghost()
		else:
			overlay.show_ghost({"kind": "stairs", "at": Vector2(cell), "facing": _stairs_up if _stairs_up != "" else facing, "valid": checked.ok})
		var way: String = {"N": "north", "E": "east", "S": "south", "W": "west"}.get(_stairs_up, "")
		hud.set_bubble("Build stairs climbing %s" % way if checked.ok else str(checked.reason), checked.ok, _pointer)
		return
	var level: int = _stroke_level if stroke_active else _target_level(cell)
	var cells: Array[Vector2i] = _land_brush(cell)
	var fits: Array[bool] = []
	for brushed: Vector2i in cells:
		fits.append(ledger.land_reason(land_tool, brushed, level, state) == "")
	overlay.show_land_brush(cells, fits)
	var reason: String = ledger.land_reason(land_tool, cell, level, state)
	hud.set_bubble(_land_label(level) if reason == "" else reason, reason == "", _pointer)


## A raise or lower stroke heads for one level from where it starts and keeps to it, so dragging across a slope
## makes one flat terrace; water and filling in have no level.
func _start_shape() -> void:
	_stroke_level = _target_level(_land_cell)
	if land_tool == "raise" and _stroke_level > AreaDef.MAX_LEVEL:
		_deny("Land rises no higher than level %d." % AreaDef.MAX_LEVEL)
		return
	if land_tool == "lower" and _stroke_level < 0:
		_deny("This is the valley floor. Dig water to go lower.")
		return
	stroke_active = true
	_stroke.clear()
	_last_sub = Vector2i(-999, -999)
	_extend_shape()


## Adds the cells the brush has crossed since the last pointer event (a line, so a fast drag leaves no holes) and
## shows the whole proposal. Nothing changes until the stroke is let go.
func _extend_shape() -> void:
	var start: Vector2i = _land_cell if _last_sub.x == -999 else _last_sub
	var delta: Vector2i = _land_cell - start
	var steps: int = maxi(absi(delta.x), absi(delta.y))
	var state: Dictionary = session.state
	for step: int in range(steps + 1):
		var along := Vector2i(Vector2(start).lerp(Vector2(_land_cell), float(step) / float(maxi(steps, 1))).round())
		for cell: Vector2i in _land_brush(along):
			if not _stroke.has(cell) and ledger.land_reason(land_tool, cell, _stroke_level, state) == "":
				_stroke[cell] = true
	_last_sub = _land_cell
	overlay.show_shape(_stroke.keys(), land_tool, _stroke_level)


func _finish_shape() -> void:
	if _pointer_in and not hud.covers(_pointer):
		_refresh_hover()
		_extend_shape()
	stroke_active = false
	var cells: Array = _stroke.keys()
	_stroke.clear()
	overlay.clear_shape()
	if cells.is_empty():
		_deny(ledger.land_reason(land_tool, _land_cell, _stroke_level, session.state) if ledger.area.in_bounds(_land_cell) else "Nothing there can change.")
		return
	var result: Dictionary = ledger.shape(land_tool, _stroke_level, cells, session.state)
	if result.ok:
		_after_edit(ledger.describe(result.edit))
	else:
		_deny(str(result.reason))


func _place_stairs() -> void:
	if _stairs_up == "":
		_deny("Stairs go at the foot of a cliff one level high.")
		return
	var result: Dictionary = ledger.place_stairs(_land_cell, _stairs_up, session.state)
	if result.ok:
		overlay.hide_ghost()
		_after_edit(ledger.describe(result.edit))
	else:
		_deny(str(result.reason))


func _hover_place() -> void:
	overlay.clear_highlight()
	if item_id == "":
		overlay.hide_ghost()
		hud.hide_bubble()
		return
	var ground: Variant = overlay.ground_point(_viewport_point())
	if ground == null:
		overlay.hide_ghost()
		hud.hide_bubble()
		return
	var entry: Dictionary = AreaBuild.item(ledger.build_catalog, item_id)
	_snapped = _snap(entry, ground)
	overlay.set_cursor(_snapped)
	_show_candidate(entry, ledger.check_item(item_id, _snapped, facing, session.state), "place|%s" % item_id, str(entry.title))


func _hover_carry() -> void:
	var ground: Variant = overlay.ground_point(_viewport_point())
	if ground == null:
		overlay.hide_ghost()
		hud.hide_bubble()
		return
	var state: Dictionary = session.state
	if carrying.kind == "building":
		_snapped = AreaBuild.snap_building(ledger.assets, str(carrying.asset), facing, float(carrying.scale), ground)
		overlay.set_cursor(_snapped)
		var checked: Dictionary = ledger.check_move_building(str(carrying.id), _snapped, facing, state)
		_show_candidate({"kind": "building", "asset": carrying.asset}, checked, "move|%s" % carrying.id, ledger.title_for_asset(str(carrying.asset)))
	elif carrying.kind == "prop":
		_snapped = AreaBuild.snap_prop(ground)
		overlay.set_cursor(_snapped)
		var prop_checked: Dictionary = ledger.check_move_prop(str(carrying.id), _snapped, facing, state)
		_show_candidate({"kind": "prop", "asset": carrying.asset}, prop_checked, "move|%s" % carrying.id, ledger.title_for_asset(str(carrying.asset)))
	else:
		_snapped = AreaBuild.snap_tree(ground)
		overlay.set_cursor(_snapped)
		_show_candidate({"kind": "tree", "size": carrying.size, "asset": carrying.get("asset", "")}, ledger.check_move_tree(carrying.from, _snapped, state), "move|tree", "Tree")


func _hover_pick(mode: String) -> void:
	_hover_object = overlay.pick_object(_viewport_point(), mode == "delete")
	if _hover_object.is_empty():
		overlay.clear_highlight()
		hud.hide_bubble()
		return
	var ground: Variant = overlay.ground_point(_viewport_point())
	if ground != null:
		overlay.set_cursor(ground)
	var thing: String = "tree"
	if _hover_object.kind == "building":
		thing = ledger.title_for_asset(str(ledger.area.building(str(_hover_object.get("id", ""))).get("asset", "")))
	elif _hover_object.kind == "prop":
		thing = ledger.title_for_asset(str(ledger.area.prop(str(_hover_object.get("id", ""))).get("asset", "")))
	elif CODE_TYPES.has(_hover_object.kind) or _hover_object.kind == "stairs":
		thing = str(_hover_object.kind)
	if _hover_object.locked:
		overlay.highlight(_hover_object, "locked")
		if mode == "move" and CODE_TYPES.has(_hover_object.kind):
			hud.set_bubble("Choose the %s to see its code" % thing, true, _pointer)
		else:
			hud.set_bubble("Part of the lessons", false, _pointer)
	elif mode == "move":
		var choosing: bool = not _same_object(_hover_object, selected)
		overlay.highlight(_hover_object, "move")
		hud.set_bubble(("Choose the %s" if choosing else "Pick up the %s") % thing.to_lower(), true, _pointer)
	else:
		overlay.highlight(_hover_object, mode)
		hud.set_bubble("Remove the %s" % thing.to_lower(), true, _pointer)


## Draws the ghost for a spot and its verdict. A spot that passes the cheap rules is shown green at once; the
## full cut-off check follows a moment after the pointer settles, and turns it red if it fails.
func _show_candidate(entry: Dictionary, checked: Dictionary, key: String, label: String) -> void:
	var full_key: String = "%s|%s|%s" % [key, str(_snapped), facing]
	var verdict: Dictionary = checked
	if checked.ok:
		if _full_key == full_key and not _full_result.is_empty():
			verdict = _full_result
		else:
			_full_timer.start(FULL_CHECK_DELAY)
	_candidate = {"entry": entry, "checked": checked, "key": full_key, "label": label}
	var spec: Dictionary = {"kind": entry.kind, "at": _snapped, "facing": facing, "valid": verdict.ok}
	if entry.kind == "building":
		spec["asset"] = entry.asset
		var rect: Rect2 = checked.get("rect", Rect2())
		spec["cells"] = AreaBuild.footprint_cells(rect) if rect.size != Vector2.ZERO else []
		spec["door"] = checked.get("door", Vector2i(-1, -1))
	elif entry.kind == "prop":
		spec["asset"] = entry.asset
		var body: Rect2 = checked.get("rect", Rect2())
		spec["cells"] = AreaBuild.footprint_cells(body) if body.size != Vector2.ZERO else []
	else:
		spec["size"] = entry.get("size", 1.0)
		if entry.get("asset", "") != "":
			spec["asset"] = entry.asset
	overlay.show_ghost(spec)
	hud.set_bubble(label if verdict.ok else str(verdict.reason), verdict.ok, _pointer)


## The slow half of the verdict, run once the pointer rests: would this strand a lamp, a door or the way back?
func _run_full_check() -> void:
	if not active or _candidate.is_empty() or not (_candidate.checked as Dictionary).ok:
		return
	var key: String = str(_candidate.key)
	var entry: Dictionary = _candidate.entry
	var state: Dictionary = session.state
	var result: Dictionary
	if tool == Tool.PLACE:
		result = ledger.place(item_id, _snapped, facing, state, false)
	elif carrying.get("kind") == "building":
		result = ledger.move_building(str(carrying.id), _snapped, facing, state, false)
	elif carrying.get("kind") == "prop":
		result = ledger.move_prop(str(carrying.id), _snapped, facing, state, false)
	else:
		result = ledger.move_tree(carrying.from, _snapped, state, false)
	_full_key = key
	_full_result = result
	if not result.ok and key == str(_candidate.key):
		_hover_dirty = true


func _snap(entry: Dictionary, ground: Vector2) -> Vector2:
	if entry.kind == "building":
		return AreaBuild.snap_building(ledger.assets, str(entry.asset), facing, 1.0, ground)
	if entry.kind == "prop":
		return AreaBuild.snap_prop(ground)
	return AreaBuild.snap_tree(ground)


# ------------------------------------------------------------------- acting
func _click() -> void:
	if not _pointer_in or hud.covers(_pointer):
		return
	var state: Dictionary = session.state
	match tool:
		Tool.PAINT:
			_start_stroke()
		Tool.PLACE:
			if item_id == "":
				hud.toast("Choose something from the tray first")
				return
			var result: Dictionary = ledger.place(item_id, _snapped, facing, state)
			if result.ok:
				_after_edit(ledger.describe(result.edit))
			else:
				_deny(str(result.reason))
		Tool.MOVE:
			if not carrying.is_empty():
				_set_down(state)
			elif _hover_object.is_empty():
				_clear_selection()
			elif _same_object(_hover_object, selected) and not _hover_object.locked:
				# A second click on the chosen thing lifts it; letting go after a drag sets it down.
				_pick_up(_hover_object)
				_drag_lift = true
			else:
				_select(_hover_object)
		Tool.DELETE:
			_delete_object(_hover_object)


func _pick_up(object: Dictionary) -> void:
	if object.is_empty():
		return
	if object.locked:
		_deny("This building is part of the lessons and cannot be moved or removed.")
		return
	if object.kind == "building":
		var building: Dictionary = ledger.area.building(str(object.id))
		carrying = {"kind": "building", "id": building.id, "asset": building.asset, "scale": building.scale, "node": view.building_node(building.id), "facing": building.facing, "from": building.at}
		facing = building.facing
		if carrying.node != null:
			(carrying.node as Node3D).visible = false
	elif object.kind == "prop":
		var prop: Dictionary = ledger.area.prop(str(object.id))
		carrying = {"kind": "prop", "id": prop.id, "asset": prop.asset, "scale": prop.scale, "node": view.building_node(prop.id), "facing": prop.facing, "from": prop.at}
		facing = prop.facing
		if carrying.node != null:
			(carrying.node as Node3D).visible = false
	else:
		var node: Node3D = view._asset_tree_nodes.get(AreaBuild.tree_key(object.at)) as Node3D
		carrying = {"kind": "tree", "from": object.at, "size": object.size, "asset": object.get("asset", ""), "node": node}
		if node != null and is_instance_valid(node):
			node.visible = false
	overlay.clear_highlight()
	overlay.clear_selection()
	hud.set_details_facing(facing)
	_hover_dirty = true


func _set_down(state: Dictionary) -> void:
	var result: Dictionary
	if carrying.kind == "building":
		result = ledger.move_building(str(carrying.id), _snapped, facing, state)
	elif carrying.kind == "prop":
		result = ledger.move_prop(str(carrying.id), _snapped, facing, state)
	else:
		result = ledger.move_tree(carrying.from, _snapped, state)
	if not result.ok:
		_deny(str(result.reason))
		return
	var node: Node3D = carrying.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.visible = true
	if carrying.kind == "tree":
		selected = {"kind": "tree", "at": _snapped, "size": carrying.size, "asset": carrying.get("asset", ""), "locked": false}
	carrying = {}
	_drag_lift = false
	_after_edit(ledger.describe(result.edit))


func _cancel() -> void:
	if stroke_active:
		_cancel_stroke()
	elif not carrying.is_empty():
		_cancel_carry()
	elif not selected.is_empty():
		_clear_selection()
	elif tool == Tool.PLACE and item_id != "":
		_put_item_away()


func _put_item_away() -> void:
	item_id = ""
	hud.set_item("")
	overlay.hide_ghost()
	hud.hide_bubble()
	_refresh_details()


func _cancel_carry() -> void:
	if carrying.is_empty():
		return
	var node: Node3D = carrying.get("node") as Node3D
	if node != null and is_instance_valid(node):
		node.visible = true
	carrying = {}
	_drag_lift = false
	overlay.hide_ghost()
	if not selected.is_empty():
		var standing: Dictionary = _resolve(selected)
		if selected.kind in ["building", "prop"] and not standing.is_empty():
			facing = str(standing.facing)
		overlay.show_selection(selected)
		_refresh_details()
	_hover_dirty = true


## A refused click: the reason, said once more where the eye is, and a nudge of the ghost.
func _deny(reason: String) -> void:
	hud.set_bubble(reason, false, _pointer)
	hud.toast(reason)


func set_finish(slot: String, material: String) -> void:
	if selected.is_empty() or not str(selected.get("kind", "")) in ["building", "prop"]:
		return
	var result: Dictionary = ledger.finish(str(selected.kind), str(selected.id), slot, material, session.state)
	if result.ok:
		_after_edit(ledger.describe(result.edit), false)
	else:
		_deny(str(result.reason))


func _after_edit(label: String, animate: bool = true) -> void:
	var reshaped: bool = view.area.terrain != ledger.area.terrain or view.area.levels != ledger.area.levels or view.area.stairs != ledger.area.stairs
	session.replace_area(ledger.area, ledger.rules)
	view.sync_edits(ledger.area, animate)
	if reshaped:
		overlay.refresh_grid()
	_full_key = ""
	_full_result = {}
	_refresh_status()
	_refresh_selection()
	hud.toast(label)
	edited.emit(label)
	_hover_dirty = true


func _refresh_status() -> void:
	hud.set_history(ledger.can_undo(), ledger.can_redo())
	var parts: PackedStringArray = []
	for kind: String in ["building", "tree", "prop"]:
		var limit: int = ledger.limit(kind)
		if limit >= 0:
			parts.append("%s %d of %d" % [{"building": "Buildings", "prop": "Doodads"}.get(kind, "Trees"), ledger.made(kind), limit])
	hud.set_allowance("   ·   ".join(parts))


# ---------------------------------------------------------------- selection
func _same_object(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty() or a.kind != b.kind:
		return false
	if a.has("id") or b.has("id"):
		return a.get("id") == b.get("id")
	return AreaBuild.tree_key(a.at) == AreaBuild.tree_key(b.at)


## Chooses a thing in the valley: it keeps a brass marker, and the details panel tells about it.
func _select(object: Dictionary) -> void:
	selected = object.duplicate()
	var standing: Dictionary = _resolve(selected)
	if selected.kind in ["building", "prop"] and not standing.is_empty():
		facing = str(standing.facing)
	overlay.show_selection(selected)
	_refresh_details()
	_hover_dirty = true


func _clear_selection(refresh: bool = true) -> void:
	selected = {}
	overlay.clear_selection()
	_hover_dirty = true
	if refresh:
		_refresh_details()


## The chosen thing as the world now has it, or {} if it is gone (taken away, or an undo put it back).
func _resolve(object: Dictionary) -> Dictionary:
	match str(object.get("kind", "")):
		"building":
			var building: Dictionary = ledger.area.building(str(object.id))
			return {"kind": "building", "id": building.id, "locked": building.locked, "at": building.at, "facing": building.facing} if not building.is_empty() else {}
		"prop":
			var prop: Dictionary = ledger.area.prop(str(object.id))
			return {"kind": "prop", "id": prop.id, "locked": false, "at": prop.at, "facing": prop.facing} if not prop.is_empty() else {}
		"tree":
			for tree: Dictionary in ledger.area.trees:
				if AreaBuild.tree_key(tree.at) == AreaBuild.tree_key(object.at):
					return {"kind": "tree", "at": tree.at, "size": tree.size, "asset": tree.get("asset", ""), "locked": false}
			return {}
	return object


## After any edit: keep the choice if the thing is still there (it may have turned or moved), else let it go.
func _refresh_selection() -> void:
	if selected.is_empty():
		return
	var fresh: Dictionary = _resolve(selected)
	if fresh.is_empty():
		_clear_selection()
		return
	selected = fresh
	if selected.kind in ["building", "prop"]:
		facing = str(selected.facing)
	if carrying.is_empty():
		overlay.show_selection(selected)
	_refresh_details()


func _delete_object(object: Dictionary) -> void:
	if object.is_empty():
		return
	if CODE_TYPES.has(object.kind):
		_deny("Lamps, gates and bridges are part of the lessons and stay where they are.")
		return
	var state: Dictionary = session.state
	var removal: Dictionary
	if object.kind == "stairs":
		removal = ledger.remove_stairs(object.cell, state)
	elif object.kind == "building":
		removal = ledger.remove_building(str(object.id), state)
	elif object.kind == "prop":
		removal = ledger.remove_prop(str(object.id), state)
	else:
		removal = ledger.remove_tree(object.at, state)
	if removal.ok:
		overlay.clear_highlight()
		_after_edit(ledger.describe(removal.edit))
	else:
		_deny(str(removal.reason))


# ------------------------------------------------------------------ details
## Shows the right thing in the details panel for the tool and what is chosen, or puts the panel away.
func _refresh_details() -> void:
	match tool:
		Tool.PLACE:
			if item_id == "":
				hud.hide_details()
			else:
				hud.show_details(_item_subject(AreaBuild.item(ledger.build_catalog, item_id)))
		Tool.MOVE:
			if selected.is_empty():
				hud.hide_details()
			else:
				hud.show_details(_object_subject(selected))
		Tool.PAINT:
			hud.show_details(_land_subject(land_tool) if land_tool != "" else _paint_subject(paint_material))
		_:
			hud.hide_details()


func _category_title(category_id: String) -> String:
	for category: Variant in ledger.build_catalog.get("categories", []):
		if (category as Dictionary).get("id") == category_id:
			return str((category as Dictionary).get("title", category_id))
	return category_id.capitalize()


## A function that makes a fresh model for the panel's turntable: the world asset, or a tree crown.
func _model_maker(asset: String, size: float, is_tree: bool, crown_seed: int = 7, finishes: Dictionary = {}) -> Callable:
	return func() -> Node3D:
		if asset != "":
			var model: Node3D = WorldAssets.instantiate(asset)
			if model != null:
				FinishMaterials.apply(model, ledger.assets.get(asset, {}), finishes)
			if model != null and is_tree:
				model.scale = Vector3.ONE * size
			return model
		var holder := MeshInstance3D.new()
		holder.mesh = view.build_tree_mesh(size, crown_seed)
		return holder


func _item_subject(entry: Dictionary) -> Dictionary:
	if entry.is_empty():
		return {}
	var facts: Dictionary = describe_item(entry)
	var kind: String = str(entry.kind)
	var blurb: String = str(entry.get("blurb", ""))
	var activity: Dictionary = (ledger.assets.get(str(entry.get("asset", "")), {}) as Dictionary).get("interaction", {})
	if not activity.is_empty():
		blurb += " Press F beside it after placing, or use prop.set_active in your notebook."
	return {
		"key": "item:%s" % entry.id,
		"kicker": _category_title(str(entry.category)),
		"title": str(entry.title),
		"blurb": blurb,
		"spec": str(facts.get("spec", "")),
		"model": _model_maker(str(entry.get("asset", "")), float(entry.get("size", 1.0)), kind == "tree"),
		"icon": {"building": &"house", "prop": &"sparkle"}.get(kind, &"tree"),
		"turns": kind != "tree",
		"facing": facing,
		"door": kind == "building",
	}


func _paint_subject(material: String) -> Dictionary:
	var subject: Dictionary = {
		"key": "paint:%s" % material,
		"kicker": "Land  ·  %s" % ("Eraser" if material == "" else hud.family_for(material)),
		"title": "Eraser" if material == "" else material.replace("_", " ").capitalize(),
		"blurb": "Restore the natural ground underneath." if material == "" else "Paint the ground's appearance. Paths and walking stay the same.",
		"spec": "One drag = one undo\nAlt or I picks a material",
		"icon": &"eraser" if material == "" else &"brush",
		"turns": false,
	}
	if material != "":
		var recipe: Dictionary = WorldTextures.entry(material)
		subject["texture"] = WorldTextures.texture(str(recipe.texture))
		var tint: float = float(recipe.tint)
		subject["tint"] = Color(tint, tint, tint)
	return subject


## A land-shaping tool: what it does, and a live picture of its sample land (content/build/land-tools.json).
func _land_subject(shape: String) -> Dictionary:
	var entry: Dictionary = {}
	for candidate: Dictionary in hud.land_tools:
		if candidate.id == shape:
			entry = candidate
	var sample: AreaDef = entry.get("area")
	return {
		"key": "land:%s" % shape,
		"kicker": "Land  ·  %s" % str(entry.get("family", "Terrain")),
		"title": str(entry.get("title", shape.capitalize())),
		"blurb": str(entry.get("blurb", "")),
		"spec": str(entry.get("spec", "")),
		"model": (func() -> Node3D: return view.build_land_model(sample)) if sample != null else Callable(),
		"icon": StringName(str(entry.get("icon", "land"))),
		"turns": false,
	}


## The catalog item that offers this asset, or {}.
func _entry_for_asset(asset: String) -> Dictionary:
	for entry: Variant in ledger.build_catalog.get("items", []):
		if entry is Dictionary and (entry as Dictionary).get("asset") == asset:
			return entry
	return {}


## What the details panel says about a thing standing in the valley.
func _object_subject(object: Dictionary) -> Dictionary:
	var kind: String = str(object.kind)
	if CODE_TYPES.has(kind):
		return _code_subject(object)
	if kind == "tree":
		var asset: String = str(object.get("asset", ""))
		var size: float = float(object.size)
		var entry: Dictionary = _entry_for_asset(asset) if asset != "" else {}
		if entry.is_empty():
			for candidate: Variant in ledger.build_catalog.get("items", []):
				if candidate is Dictionary and candidate.get("kind") == "tree" and not candidate.has("asset") and absf(float(candidate.get("size", 1.0)) - size) < 0.01:
					entry = candidate
		var facts: Dictionary = describe_item(entry) if not entry.is_empty() else {"spec": "Grows on grass, keeps a cell clear"}
		return {
			"key": "tree:%s" % AreaBuild.tree_key(object.at),
			"kicker": "In the valley",
			"title": str(entry.get("title", "Tree")),
			"blurb": str(entry.get("blurb", "")),
			"spec": str(facts.get("spec", "")),
			"model": _model_maker(asset, size, true, ClearingView.tree_seed(object.at)),
			"icon": &"tree",
			"turns": false,
			"removable": true,
			"note": "A tree has no front, so it cannot be turned.",
			"code": _structure_code("tree", object.at, "tree = world.tree(%s, %s)" % [_plain_number(object.at.x), _plain_number(object.at.y)]),
		}
	var body: Dictionary = ledger.area.building(str(object.id)) if kind == "building" else ledger.area.prop(str(object.id))
	var asset_id: String = str(body.get("asset", ""))
	var item: Dictionary = _entry_for_asset(asset_id)
	var locked: bool = bool(object.locked)
	var spec: String = str(describe_item(item).get("spec", "")) if not item.is_empty() else ""
	var subject: Dictionary = {
		"key": "%s:%s" % [kind, object.id],
		"kicker": "Part of the lessons" if locked else "In the valley",
		"title": ledger.title_for_asset(asset_id),
		"blurb": str(item.get("blurb", "")),
		"spec": spec,
		"model": _model_maker(asset_id, 1.0, false, 7, body.get("finishes", {})),
		"finish_slots": SurfaceFinishes.asset_slots(ledger.assets.get(asset_id, {})),
		"finish_values": body.get("finishes", {}).duplicate(true),
		"icon": &"house" if kind == "building" else &"sparkle",
		"turns": not locked,
		"facing": str(body.get("facing", "S")),
		"door": kind == "building",
		"removable": not locked,
		"note": "It belongs to the lessons, so it stays where it is." if locked else "Click it again to pick it up, or drag it. Turn it with R or the compass.",
	}
	if kind == "prop" and not (body.get("interaction", {}) as Dictionary).is_empty():
		var seen: bool = PropInteractions.known(session.state, body)
		subject.spec += "\nCalled \"%s\" · %s" % [body.id, "active" if bool((session.state.get("props", {}) as Dictionary).get(body.id, false)) else "inactive"]
		subject["code"] = {"snippet": "prop = world.prop(\"%s\")" % body.id, "members": ApiReference.members_of("Prop"), "reachable": seen,
			"note": "" if seen else "Visit this object's place first so your code can reach it."}
	elif kind == "building":
		subject["code"] = _structure_code("house", body.at, "house = world.house(\"%s\")" % body.id)
	else:
		subject["code"] = _structure_code("doodad", body.at, "doodad = world.doodad(\"%s\")" % body.id)
	return subject


## A coordinate as a person would write it: 39.5, not 39.5000001, and 6, not 6.0.
func _plain_number(value: float) -> String:
	var text: String = "%.2f" % value
	return text.rstrip("0").rstrip(".") if text.contains(".") else text


## The Code section for a house, doodad or tree. It always says how to fetch the thing and what it offers, and is
## honest about the three states: ready (the button appears), not learned yet (it names the lesson), or out of reach.
func _structure_code(type_key: String, at: Vector2, snippet: String) -> Dictionary:
	var abilities: Array[String] = session.abilities()
	var code: Dictionary = {"snippet": snippet, "members": ApiReference.members_of(type_key.capitalize()), "reachable": false, "note": ""}
	if not abilities.has("read"):
		var lesson: String = str(CodeBuild.lessons(ledger.area, abilities).get("read", ""))
		code.note = ("Reach the lesson \"%s\" to let your code see houses, trees and doodads." % lesson) if lesson != "" else "Your code cannot see houses, trees and doodads yet."
	elif not CodeBuild.in_reach(ledger.area, session.state, at):
		code.note = "Out of reach. Visit its place, or stand within %d cells of it, so your code can see it." % int(CodeBuild.REACH)
	else:
		code.reachable = true
	return code


## A lamp, gate or bridge: the things a program can reach today. The panel shows how to fetch it and what it can do;
## the button to write code only appears once the player has been to its place, because code only sees visited places.
func _code_subject(object: Dictionary) -> Dictionary:
	var kind: String = str(object.kind)
	var type_name: String = str(CODE_TYPES[kind])
	var info: Dictionary = ledger.area.lamp(str(object.id)) if kind == "lamp" else (ledger.area.gate(str(object.id)) if kind == "gate" else ledger.area.bridge(str(object.id)))
	var zone_id: String = str(info.get("zone", ""))
	var zone: Dictionary = ledger.area.zone(zone_id)
	var seen: bool = (session.state.get("zones_seen", []) as Array).has(zone_id)
	var place: String = str(zone.get("title", zone_id))
	var title: String = {"lamp": "Lamppost", "gate": "Gate", "bridge": "Bridge"}[kind]
	if kind == "lamp" and str(info.get("style", "")) == "beacon":
		title = "The Beacon"
	var model: Callable = Callable()
	if kind == "lamp" and str(info.get("style", "")) != "beacon" and WorldAssets.is_blender("lamppost"):
		model = _model_maker("lamppost", 1.0, false)
	return {
		"key": "%s:%s" % [kind, object.id],
		"kicker": "Part of the lessons",
		"title": title,
		"blurb": str(ApiReference.TYPES[type_name].summary),
		"spec": "Called \"%s\"\nIn %s" % [object.id, place],
		"model": model,
		"icon": {"lamp": &"lamp", "gate": &"gate", "bridge": &"bridge"}[kind],
		"turns": false,
		"note": "It belongs to the lessons, so it stays where it is.",
		"code": {
			"snippet": "%s = world.%s(\"%s\")" % [kind, kind, object.id],
			"members": ApiReference.members_of(type_name),
			"reachable": seen,
			"note": "" if seen else "Your code only sees places you have visited. Go to %s first." % place,
		},
	}


## A picture for every card, drawn one at a time so the dock fills in as they finish.
func _make_pictures() -> void:
	var pending: Array[Dictionary] = _entries.duplicate()
	while not pending.is_empty():
		var shown: Array[Dictionary] = hud.visible_items()
		var next: int = pending.find(shown.filter(func(entry: Dictionary) -> bool: return pending.has(entry))[0]) if shown.any(func(entry: Dictionary) -> bool: return pending.has(entry)) else 0
		var entry: Dictionary = pending.pop_at(next)
		if _picture_cache.has(str(entry.id)):
			hud.set_picture(str(entry.id), _picture_cache[str(entry.id)])
			pictures_done += 1
			continue
		var model: Node3D
		if entry.has("asset"):
			model = WorldAssets.instantiate(str(entry.asset))
		else:
			var holder := MeshInstance3D.new()
			holder.mesh = view.build_tree_mesh(float(entry.get("size", 1.0)), 7)
			model = holder
		if model == null:
			pictures_done += 1
			continue
		var picture: Texture2D = await studio.render(model)
		_picture_cache[str(entry.id)] = picture
		hud.set_picture(str(entry.id), picture)
		pictures_done += 1
		await get_tree().process_frame
	for land_entry: Dictionary in hud.land_tools:
		var land: Texture2D = await studio.render(view.build_land_model(land_entry.area))
		hud.set_land_picture(str(land_entry.id), land)
		await get_tree().process_frame

