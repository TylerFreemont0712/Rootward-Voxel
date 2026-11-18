class_name SettingsSheet
extends VBoxContainer
## The settings themselves: display, camera and notebook preferences, applied and saved as they change.
## Shown inside the title's SettingsPanel modal and as an app on the field tablet.

var settings: GameSettings
var _on_done: Callable
## Each setting's row by key, so a lesson can point at one.
var rows: Dictionary = {}


func setup(game_settings: GameSettings, on_done: Callable = Callable()) -> void:
	settings = game_settings
	_on_done = on_done
	add_theme_constant_override("separation", 12)
	_build()


func _build() -> void:
	add_child(UI.caps("Display"))
	var adapter := RenderingServer.get_video_adapter_name()
	if not adapter.is_empty():
		add_child(UI.dim("Graphics: " + adapter, 14))
	var fullscreen := Toggle.make("Fullscreen", bool(settings.get_value("fullscreen")))
	fullscreen.toggled.connect(func(on: bool) -> void: settings.set_value("fullscreen", on))
	add_child(fullscreen)
	rows["fullscreen"] = fullscreen
	rows["ui_scale"] = _slider("Interface size", "ui_scale", 0.6, 1.5, 0.05, "%d%%", 100.0, true)
	add_child(rows["ui_scale"])
	add_child(UI.caps("World"))
	rows["zoom"] = _slider("Camera zoom", "zoom", 8.0, 20.0, 0.5, "%.1f", 1.0)
	add_child(rows["zoom"])
	var hints := Toggle.make("Show the controls hint", bool(settings.get_value("show_controls")))
	hints.toggled.connect(func(on: bool) -> void: settings.set_value("show_controls", on))
	add_child(hints)
	rows["show_controls"] = hints
	add_child(UI.caps("Notebook"))
	rows["font_size"] = _slider("Code text size", "font_size", 10, 26, 1, "%d px", 1.0)
	add_child(rows["font_size"])
	var completion := Toggle.make("Suggest names as you type", bool(settings.get_value("completion")))
	completion.toggled.connect(func(on: bool) -> void: settings.set_value("completion", on))
	add_child(completion)
	var brackets := Toggle.make("Close brackets and quotes for me", bool(settings.get_value("auto_brackets")))
	brackets.toggled.connect(func(on: bool) -> void: settings.set_value("auto_brackets", on))
	add_child(brackets)
	add_child(UI.rule())
	var row := UI.hbox(12)
	var defaults := UI.button("Restore defaults", &"reset", &"", func() -> void:
		settings.reset()
		_rebuild())
	defaults.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(defaults)
	if _on_done.is_valid():
		var done := UI.button("Done", &"check", &"ButtonPrimary", _on_done)
		done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(done)
	add_child(row)


func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	rows.clear()
	_build()


## `scale` converts the stored value to what the label shows (a 0.6..1.5 size shown as percent).
## `on_release` waits for the handle to be let go: resizing the whole interface mid-drag moves the slider.
func _slider(label: String, key: String, low: float, high: float, step: float, format: String, scale: float, on_release: bool = false) -> Control:
	var row := UI.hbox(14)
	var name := UI.label(label, &"", 16)
	name.custom_minimum_size.x = 200
	row.add_child(name)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = float(settings.get_value(key))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(240, 26)
	row.add_child(slider)
	var readout := UI.label(format % (slider.value * scale), &"LabelDim", 15)
	readout.custom_minimum_size.x = 70
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(readout)
	var commit := func(value: float) -> void:
		settings.set_value(key, int(value) if typeof(GameSettings.DEFAULTS[key]) == TYPE_INT else value)
	slider.value_changed.connect(func(value: float) -> void:
		readout.text = format % (value * scale)
		if not on_release:
			commit.call(value))
	if on_release:
		slider.drag_ended.connect(func(changed: bool) -> void:
			if changed:
				commit.call(slider.value))
	return row
