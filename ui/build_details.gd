class_name BuildDetails
extends PanelContainer
## Build mode's details panel, which slides out on the right for whatever is chosen: a thing on the tray, a ground
## paint, or something already standing in the valley. It shows a live picture of the model (turning slowly when it
## can be turned), which way it faces with a compass to change that, its facts, what a program can do with it when
## it has code, and the actions that fit. It only shows a subject and sends signals; BuildMode decides.
##
## A subject is a Dictionary:
##   key: String                 what it is; showing the same key again keeps the picture
##   kicker, title, blurb, spec, note: String
##   model: Callable -> Node3D    a fresh model for the picture (optional)
##   texture: Texture2D, tint: Color   a ground swatch instead (optional)
##   icon: StringName            drawn when there is no picture
##   turns: bool, facing: String, door: bool
##   code: {snippet, members: Array[Dictionary], reachable: bool, note: String}   when a program can use it
##   removable: bool

signal facing_chosen(facing: String)
signal turn_pressed(steps: int)
signal remove_pressed
signal code_pressed(snippet: String)
signal finish_chosen(slot: String, material: String)
## The panel's content got taller or shorter (new words, a code section), so the window may want to resize it.
signal content_changed

var _column: VBoxContainer
var _key: String = ""
var _subject: Dictionary = {}
var _kicker: Label
var _title: Label
var _frame: PanelContainer
var turntable: ModelTurntable
var _swatch: TextureRect
var _placeholder: Glyph
var _blurb: Label
var _facing_box: VBoxContainer
var compass: _Compass
var _facing_label: Label
var _spec: Label
var _code_box: PanelContainer
var _code_snippet: Label
var _members: VBoxContainer
var _code_note: Label
var _code_button: FButton
var _note: Label
var _remove: FButton
var _finish_box: VBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", FantasyBox.make({"fill_top": Color(0.11, 0.08, 0.055, 0.96), "fill_bottom": Color(0.07, 0.05, 0.035, 0.97), "border": Pal.BRASS, "border_width": 2.0, "chamfer": 14.0, "inner_line": Color(0.95, 0.8, 0.45, 0.18), "studs": true, "shadow": 5.0, "bevel": 0.1}, Vector2(16, 14)))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var column := UI.vbox(9)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	_column = column
	column.minimum_size_changed.connect(func() -> void: content_changed.emit())
	_kicker = UI.label("", &"LabelCaps", 11)
	_kicker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_kicker)
	_title = UI.heading("", 21)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_title)
	_frame = UI.panel(&"PanelInset")
	_frame.custom_minimum_size = Vector2(0, 170)
	_frame.clip_contents = true
	column.add_child(_frame)
	turntable = ModelTurntable.new()
	_frame.add_child(turntable)
	_swatch = TextureRect.new()
	_swatch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_swatch.stretch_mode = TextureRect.STRETCH_TILE
	_swatch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_swatch)
	_placeholder = Glyph.new()
	_placeholder.color = Color(Pal.BRASS_LO, 0.6)
	_placeholder.custom_minimum_size = Vector2(64, 64)
	_placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_placeholder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_frame.add_child(_placeholder)
	_blurb = UI.dim("", 15)
	column.add_child(_blurb)
	# Which way it faces.
	_facing_box = UI.vbox(2)
	column.add_child(_facing_box)
	_facing_box.add_child(UI.label("FACING", &"LabelCaps", 11))
	var turn_row := UI.hbox(4)
	turn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_facing_box.add_child(turn_row)
	var left := UI.icon_button(&"turn_left", "Turn left (Shift+R)", func() -> void: turn_pressed.emit(-1))
	var right := UI.icon_button(&"turn_right", "Turn right (R)", func() -> void: turn_pressed.emit(1))
	compass = _Compass.new()
	compass.chosen.connect(func(facing: String) -> void: facing_chosen.emit(facing))
	for button: FButton in [left, right]:
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(46, 46)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	turn_row.add_child(left)
	turn_row.add_child(compass)
	turn_row.add_child(right)
	_facing_label = UI.label("", &"LabelDim", 14)
	_facing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_facing_box.add_child(_facing_label)
	_spec = UI.label("", &"", 13, Pal.BRASS_HI)
	_spec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_spec)
	_finish_box = UI.vbox(6)
	column.add_child(_finish_box)
	# What a program can do with it.
	_code_box = UI.panel(&"PanelInset")
	column.add_child(_code_box)
	var code_column := UI.vbox(6)
	_code_box.add_child(code_column)
	var code_head := UI.hbox(6)
	var code_mark := Glyph.new()
	code_mark.kind = &"code"
	code_mark.color = Pal.TEAL
	code_mark.custom_minimum_size = Vector2(18, 18)
	code_head.add_child(code_mark)
	code_head.add_child(UI.label("CODE", &"LabelCaps", 11, Pal.TEAL))
	code_column.add_child(code_head)
	code_column.add_child(UI.dim("Your program reaches it as", 13))
	_code_snippet = UI.label("", &"", 13, Pal.TEAL)
	_code_snippet.add_theme_font_override("font", UITheme.mono_font())
	_code_snippet.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	code_column.add_child(_code_snippet)
	_members = UI.vbox(1)
	code_column.add_child(_members)
	_code_note = UI.dim("", 13)
	code_column.add_child(_code_note)
	_code_button = UI.button("Write code for it", &"code", &"ButtonPrimary", func() -> void:
		code_pressed.emit(str((_subject.get("code", {}) as Dictionary).get("snippet", ""))))
	_code_button.focus_mode = Control.FOCUS_NONE
	_code_button.add_theme_font_size_override("font_size", 14)
	_code_button.custom_minimum_size.y = 40
	_code_button.tooltip_text = "Leave build mode and open your notebook with this line added"
	code_column.add_child(_code_button)
	_note = UI.dim("", 14)
	column.add_child(_note)
	_remove = UI.button("Remove", &"trash", &"ButtonDanger", func() -> void: remove_pressed.emit())
	_remove.focus_mode = Control.FOCUS_NONE
	_remove.custom_minimum_size.y = 40
	_remove.add_theme_font_size_override("font_size", 14)
	_remove.tooltip_text = "Take it away (Delete). Ctrl+Z brings it back."
	column.add_child(_remove)
	resized.connect(func() -> void: _frame.custom_minimum_size.y = clampf(size.x * 0.62, 130.0, 230.0))


func subject_key() -> String:
	return _key


## How tall the panel needs to be to show everything without scrolling.
func content_height() -> float:
	return _column.get_combined_minimum_size().y + 34.0


## Shows a subject (see the class notes). The same key again keeps the picture and only refreshes the words.
func show_subject(subject: Dictionary) -> void:
	var same: bool = _key != "" and str(subject.get("key", "")) == _key and _subject.get("finish_values", {}) == subject.get("finish_values", {})
	_subject = subject
	_key = str(subject.get("key", ""))
	_kicker.text = str(subject.get("kicker", "")).to_upper()
	_title.text = str(subject.get("title", ""))
	_blurb.text = str(subject.get("blurb", ""))
	_blurb.visible = _blurb.text != ""
	_spec.text = str(subject.get("spec", ""))
	_spec.visible = _spec.text != ""
	_note.text = str(subject.get("note", ""))
	_note.visible = _note.text != ""
	_remove.visible = bool(subject.get("removable", false))
	var turns: bool = bool(subject.get("turns", false))
	_facing_box.visible = turns
	compass.door = bool(subject.get("door", false))
	if not same:
		_show_picture(subject)
	set_facing(str(subject.get("facing", "S")), same)
	_show_code(subject.get("code", {}))
	_show_finishes(subject.get("finish_slots", {}), subject.get("finish_values", {}))


func _show_finishes(slots: Dictionary, values: Dictionary) -> void:
	for child: Node in _finish_box.get_children():
		_finish_box.remove_child(child)
		child.queue_free()
	_finish_box.visible = not slots.is_empty()
	if slots.is_empty():
		return
	_finish_box.add_child(UI.caps("Materials"))
	for slot: String in slots:
		_finish_box.add_child(UI.label(str(SurfaceFinishes.TITLES.get(slot, slot)), &"", 14))
		var choice := OptionButton.new()
		choice.name = "Finish_" + slot
		choice.add_theme_font_size_override("font_size", 14)
		choice.add_theme_constant_override("icon_max_width", 26)
		choice.add_item("Original")
		choice.set_item_metadata(0, "")
		for id: String in SurfaceFinishes.OPTIONS[slot]:
			choice.add_icon_item(WorldTextures.texture(id), FinishMaterials.title(id))
			choice.set_item_metadata(choice.item_count - 1, id)
			if values.get(slot) == id:
				choice.select(choice.item_count - 1)
		choice.item_selected.connect(func(index: int) -> void: finish_chosen.emit(slot, str(choice.get_item_metadata(index))))
		_finish_box.add_child(choice)


## Turns the compass (and the picture, swinging round to it) to `facing`.
func set_facing(facing: String, animate: bool = true) -> void:
	var changed: bool = compass.facing != facing
	compass.facing = facing
	compass.queue_redraw()
	var screen: Vector2 = _Compass.project(_Compass.DIRECTIONS[facing])
	var where: String = ("lower" if screen.y > 0.0 else "upper") + (" left" if screen.x < 0.0 else " right")
	_facing_label.text = ("Door faces the %s" if compass.door else "Faces the %s") % where
	if animate and changed:
		turntable.face(float(AreaDef.FACINGS[facing]))


func _show_picture(subject: Dictionary) -> void:
	turntable.clear()
	_swatch.texture = null
	var model: Node3D = null
	if subject.get("model") is Callable and (subject.model as Callable).is_valid():
		model = (subject.model as Callable).call()
	if model != null:
		turntable.show_model(model, bool(subject.get("turns", false)), float(AreaDef.FACINGS[str(subject.get("facing", "S"))]))
	elif subject.get("texture") is Texture2D:
		_swatch.texture = subject.texture
		_swatch.self_modulate = subject.get("tint", Color.WHITE)
	turntable.visible = model != null
	_swatch.visible = _swatch.texture != null
	_placeholder.visible = model == null and _swatch.texture == null
	_placeholder.kind = subject.get("icon", &"cube")


func _show_code(code: Variant) -> void:
	_code_box.visible = code is Dictionary and not (code as Dictionary).is_empty()
	if not _code_box.visible:
		return
	_code_snippet.text = str(code.snippet)
	for child: Node in _members.get_children():
		_members.remove_child(child)
		child.queue_free()
	for member: Dictionary in code.get("members", []):
		var line := UI.label(str(member.sig), &"", 12, Color("e0cfa3"))
		line.add_theme_font_override("font", UITheme.mono_font())
		line.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		line.tooltip_text = str(member.doc)
		line.mouse_filter = Control.MOUSE_FILTER_PASS
		_members.add_child(line)
	_code_note.text = str(code.get("note", ""))
	_code_note.visible = _code_note.text != ""
	_code_button.visible = bool(code.get("reachable", false))


## The facing compass: the valley's floor tile as the camera sees it, with a bubble on each side for the four
## facings. The lit bubble is where the front (or the door) points on screen; click another to turn to it.
class _Compass extends Control:
	signal chosen(facing: String)

	const DIRECTIONS: Dictionary = {"S": Vector2(0, -1), "E": Vector2(1, 0), "N": Vector2(0, 1), "W": Vector2(-1, 0)}
	const KNOB: float = 12.0

	var facing: String = "S"
	var door: bool = true
	var _hover: String = ""

	func _init() -> void:
		custom_minimum_size = Vector2(132, 88)
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_exited.connect(func() -> void:
			_hover = ""
			queue_redraw())

	## A logical ground direction (x east, y north) as the valley's camera draws it on screen.
	static func project(logical: Vector2) -> Vector2:
		var forward: Vector3 = -ClearingView.CAMERA_OFFSET.normalized()
		var right: Vector3 = forward.cross(Vector3.UP).normalized()
		var up: Vector3 = right.cross(forward)
		var world := Vector3(logical.x, 0.0, -logical.y)
		return Vector2(world.dot(right), -world.dot(up))

	func knob(name: String) -> Vector2:
		return size * 0.5 + project(DIRECTIONS[name]) * 0.5 * 1.3 * _scale()

	func _scale() -> float:
		var reach := Vector2.ZERO
		for name: String in DIRECTIONS:
			var point: Vector2 = project(DIRECTIONS[name]) * 0.5 * 1.3
			reach = Vector2(maxf(reach.x, absf(point.x)), maxf(reach.y, absf(point.y)))
		return minf((size.x * 0.5 - KNOB - 3.0) / maxf(0.01, reach.x), (size.y * 0.5 - KNOB - 3.0) / maxf(0.01, reach.y))

	func _draw() -> void:
		var middle: Vector2 = size * 0.5
		var unit: float = _scale()
		var corners := PackedVector2Array()
		for corner: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]:
			corners.append(middle + project(corner) * unit)
		draw_colored_polygon(corners, Color(Pal.PANEL_LO, 0.95))
		draw_line(middle + project(Vector2(-0.5, 0)) * unit, middle + project(Vector2(0.5, 0)) * unit, Color(Pal.BRASS_LO, 0.35), 1.0, true)
		draw_line(middle + project(Vector2(0, -0.5)) * unit, middle + project(Vector2(0, 0.5)) * unit, Color(Pal.BRASS_LO, 0.35), 1.0, true)
		var outline := corners.duplicate()
		outline.append(corners[0])
		draw_polyline(outline, Pal.BRASS_LO, 1.5, true)
		# The arrow from the middle to the lit side.
		var toward: Vector2 = (knob(facing) - middle)
		var along: Vector2 = toward.normalized()
		var across := Vector2(-along.y, along.x)
		var tip: Vector2 = middle + toward - along * (KNOB + 3.0)
		draw_line(middle - along * 6.0, tip - along * 6.0, Pal.BRASS_HI, 3.0, true)
		draw_colored_polygon(PackedVector2Array([tip, tip - along * 9.0 + across * 6.0, tip - along * 9.0 - across * 6.0]), Pal.BRASS_HI)
		draw_circle(middle, 4.0, Pal.BRASS)
		var font: Font = UITheme.display_font(700, 0)
		for name: String in DIRECTIONS:
			var at: Vector2 = knob(name)
			var lit: bool = name == facing
			if lit:
				draw_circle(at, KNOB + 4.0, Color(Pal.BRASS_HI, 0.2))
			draw_circle(at + Vector2(0, 1.5), KNOB, Pal.SHADOW)
			draw_circle(at, KNOB, Color("c99a45") if lit else (Pal.WOOD_HI if name == _hover else Pal.WOOD))
			draw_circle(at - Vector2(0, 2.5), KNOB * 0.62, Color("f1c767") if lit else (Color("5d4529") if name == _hover else Pal.PANEL_HI))
			draw_arc(at, KNOB - 0.6, 0.0, TAU, 28, Pal.BRASS_HI if lit or name == _hover else Pal.BRASS_LO, 1.5, true)
			draw_string(font, at + Vector2(-KNOB, 4.0), name, HORIZONTAL_ALIGNMENT_CENTER, KNOB * 2.0, 11, Pal.INK if lit else Pal.PARCH_DIM)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var near: String = _nearest((event as InputEventMouseMotion).position)
			if near != _hover:
				_hover = near
				queue_redraw()
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var picked: String = _nearest((event as InputEventMouseButton).position)
			accept_event()
			if picked != "":
				chosen.emit(picked)

	func _nearest(point: Vector2) -> String:
		for name: String in DIRECTIONS:
			if point.distance_to(knob(name)) <= KNOB + 5.0:
				return name
		return ""
