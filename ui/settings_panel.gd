class_name SettingsPanel
extends Modal
## Display, camera and notebook preferences. Changes apply immediately and are saved as you go.

var settings: GameSettings


func setup(game_settings: GameSettings) -> void:
	settings = game_settings
	card.custom_minimum_size = Vector2(620, 0)
	title_row("Settings", "Changes apply right away and are remembered.")
	body.add_child(UI.caps("Display"))
	var fullscreen := Toggle.make("Fullscreen", bool(settings.get_value("fullscreen")))
	fullscreen.toggled.connect(func(on: bool) -> void: settings.set_value("fullscreen", on))
	body.add_child(fullscreen)
	body.add_child(_slider("Interface size", "ui_scale", 0.8, 1.5, 0.05, "%d%%", 100.0, true))
	body.add_child(UI.caps("World"))
	body.add_child(_slider("Camera zoom", "zoom", 8.0, 20.0, 0.5, "%.1f", 1.0))
	var hints := Toggle.make("Show the controls hint", bool(settings.get_value("show_controls")))
	hints.toggled.connect(func(on: bool) -> void: settings.set_value("show_controls", on))
	body.add_child(hints)
	body.add_child(UI.caps("Notebook"))
	body.add_child(_slider("Code text size", "font_size", 12, 26, 1, "%d px", 1.0))
	var completion := Toggle.make("Suggest names as you type", bool(settings.get_value("completion")))
	completion.toggled.connect(func(on: bool) -> void: settings.set_value("completion", on))
	body.add_child(completion)
	var brackets := Toggle.make("Close brackets and quotes for me", bool(settings.get_value("auto_brackets")))
	brackets.toggled.connect(func(on: bool) -> void: settings.set_value("auto_brackets", on))
	body.add_child(brackets)
	body.add_child(UI.rule())
	var row := UI.hbox(12)
	var defaults := UI.button("Restore defaults", &"reset", &"", func() -> void:
		settings.reset()
		_rebuild())
	defaults.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(defaults)
	var done := UI.button("Done", &"check", &"ButtonPrimary", close)
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(done)
	body.add_child(row)


func _rebuild() -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	setup(settings)


## `scale` converts the stored value to what the label shows (a 0.8..1.5 size shown as percent).
## `on_release` waits for the handle to be let go: resizing the whole interface mid-drag moves the slider.
func _slider(label: String, key: String, low: float, high: float, step: float, format: String, scale: float, on_release: bool = false) -> Control:
	var row := UI.hbox(14)
	var name := UI.label(label, &"", 19)
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
	var readout := UI.label(format % (slider.value * scale), &"LabelDim", 18)
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
