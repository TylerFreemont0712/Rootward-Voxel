class_name JobTicket
extends PanelContainer
## A job pinned to the board: "JOB No. 0", what it is, one line of help, and a red DONE stamp once finished.
## Paper-and-enamel interface; clicking it opens Field Notes.

signal pressed

var number: Label
var title: Label
var hint: Label
var _stamp: Label
var _steps: VBoxContainer


func _init() -> void:
	theme_type_variation = &"PanelQuest"
	custom_minimum_size.x = 300
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var column := UI.vbox(4)
	add_child(column)
	number = UI.label("", &"LabelCaps", 13, PaperPal.RED)
	number.add_theme_constant_override("outline_size", 0)
	column.add_child(number)
	title = UI.label("", &"LabelHeading", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	hint = UI.dim("", 16)
	column.add_child(hint)
	_steps = UI.vbox(2)
	column.add_child(_steps)
	_stamp = UI.label("DONE", &"LabelHeading", 30, PaperPal.RED)
	_stamp.rotation_degrees = -12.0
	_stamp.modulate.a = 0.0
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.top_level = false
	_stamp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	var stamp_layer := Control.new()
	stamp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stamp_layer)
	stamp_layer.add_child(_stamp)
	_stamp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_stamp.offset_left = -108.0
	_stamp.offset_right = -8.0
	_stamp.offset_top = 0.0
	_stamp.offset_bottom = 42.0
	_stamp.pivot_offset = Vector2(50.0, 18.0)
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit())


func set_job(job_number: String, job_title: String, job_hint: String) -> void:
	number.text = ("JOB " + job_number).to_upper() if job_number != "" else "PINNED"
	title.text = job_title
	hint.text = job_hint
	hint.visible = job_hint != ""


func set_steps(steps: Array[Dictionary]) -> void:
	for child: Node in _steps.get_children():
		_steps.remove_child(child)
		child.queue_free()
	for step: Dictionary in steps:
		var done: bool = bool(step.get("done", false))
		var current: bool = bool(step.get("current", false))
		var row := UI.label(("✓  " if done else ("›  " if current else "○  ")) + str(step.get("text", "")), &"", 16, PaperPal.TEAL_DEEP if done or current else PaperPal.PENCIL)
		_steps.add_child(row)
	_steps.visible = not steps.is_empty()


## The red rubber stamp, pressed on or lifted off.
func stamp(done: bool) -> void:
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_stamp, "modulate:a", 0.85 if done else 0.0, 0.22)
	_stamp.scale = Vector2(1.4, 1.4) if done else Vector2.ONE
	tween.tween_property(_stamp, "scale", Vector2.ONE, 0.25)


func stamped() -> bool:
	return _stamp.modulate.a > 0.5
