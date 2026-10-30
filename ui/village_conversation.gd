class_name VillageConversation
extends Modal
## A single-speaker visual novel scene. Optional examples are read-only until copied to the notebook.

signal settings_requested
signal notebook_requested
signal read_changed(keys: Array)

var dialogue: VillageDialogue
var settings: GameSettings
var portrait: TextureRect
var text: RichTextLabel
var choices: VBoxContainer
var next_button: FButton
var code_button: FButton
var auto_button: FButton
var skip_button: FButton
var extra: PanelContainer
var code: CodeEditor
var mode: String = ""
var ui_hidden: bool = false
var auto: bool = false
var skipping: bool = false
var _nameplate: PanelContainer
var _name: Label
var _role: Label
var _footer: HFlowContainer
var _hint: Label
var _restore: FButton
var _panel_body: VBoxContainer
var _clock: float = 0.0
var _characters: float = 0.0
var _closing: bool = false


func setup(person: Dictionary, preferences: GameSettings = null, previously_read: Array = []) -> void:
	settings = preferences if preferences != null else GameSettings.new()
	dialogue = VillageDialogue.new(person, previously_read)
	if not dialogue.issues.is_empty():
		push_error("Invalid village conversation: " + str(dialogue.issues))
		return
	# Use the Modal stack/input contract, with its plaque placed at the bottom instead of centred.
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	_scrim.color = Color(0.025, 0.018, 0.012, 0.28)
	portrait = TextureRect.new()
	portrait.name = "SpeakerPortrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = DialoguePortraits.texture_for(str(person.skin))
	add_child(portrait)
	move_child(portrait, card.get_index())
	_nameplate = UI.panel(&"PanelPill")
	var names := UI.hbox(18)
	_name = UI.heading(str(person.name), 30)
	_role = UI.label(str(person.role), &"", 19, Pal.BRASS)
	names.add_child(_name)
	names.add_child(_role)
	_nameplate.add_child(names)
	add_child(_nameplate)
	text = RichTextLabel.new()
	text.name = "DialogueText"
	text.bbcode_enabled = false
	text.add_theme_font_size_override("normal_font_size", 25)
	text.add_theme_color_override("default_color", Pal.PARCHMENT)
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.y = 64
	text.scroll_active = true
	text.scroll_following = true
	text.gui_input.connect(_on_text_click)
	body.add_child(text)
	_footer = HFlowContainer.new()
	_footer.add_theme_constant_override("h_separation", 8)
	_footer.add_theme_constant_override("v_separation", 6)
	body.add_child(_footer)
	_footer.add_child(UI.button("History", &"book", &"ButtonQuiet", func() -> void: show_panel("history")))
	auto_button = _toggle("Auto", &"play", func() -> void:
		auto = not auto
		_clock = 0.0
		_update_buttons())
	_footer.add_child(auto_button)
	auto_button.visible = not dialogue.is_guided()
	skip_button = _toggle("Skip read", &"", _toggle_skip)
	skip_button.tooltip_text = "Fast-forward pages already read. Stops at new text and choices."
	_footer.add_child(skip_button)
	skip_button.visible = not dialogue.is_guided()
	var hide_button := UI.button("Hide UI", &"", &"ButtonQuiet", toggle_ui)
	hide_button.visible = not dialogue.is_guided()
	_footer.add_child(hide_button)
	_footer.add_child(UI.button("Settings", &"gear", &"ButtonQuiet", func() -> void: show_panel("settings")))
	if not dialogue.is_guided():
		_footer.add_child(UI.button("Leave", &"door", &"ButtonQuiet", close))
	if not dialogue.is_guided() and not str(person.get("notebook_title", "")).is_empty():
		_footer.add_child(UI.button(str(person.notebook_title),&"book",&"ButtonPrimary",func() -> void:notebook_requested.emit()))
	_footer.add_child(UI.spacer(0, true))
	code_button = UI.button("Show code", &"code", &"ButtonTab", func() -> void: show_panel("code" if mode != "code" else ""))
	code_button.tooltip_text = "An optional code example for what this character is explaining."
	_footer.add_child(code_button)
	_hint = UI.label("Click / Space", &"", 17, Pal.PARCH_DIM)
	_footer.add_child(_hint)
	next_button = UI.button("Continue" if dialogue.is_guided() else "Next", &"chevron", &"ButtonPrimary", advance)
	_footer.add_child(next_button)
	choices = UI.vbox(8)
	choices.name = "Responses"
	add_child(choices)
	extra = UI.panel(&"PanelDrawer")
	extra.name = "ConversationExtra"
	extra.visible = false
	var panel_scroll := ScrollContainer.new()
	panel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	extra.add_child(panel_scroll)
	_panel_body = UI.vbox(12)
	_panel_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_scroll.add_child(_panel_body)
	add_child(extra)
	_restore = UI.button("Show dialogue · H", &"", &"ButtonQuiet", toggle_ui)
	_restore.visible = false
	add_child(_restore)
	resized.connect(_layout)
	gui_input.connect(_on_text_click)
	card.gui_input.connect(_on_text_click)
	_present()
	_layout.call_deferred()


func open() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)


func close() -> void:
	if _closing:
		return
	_closing = true
	if text != null and text.visible_characters == -1:
		dialogue.mark_read()
	read_changed.emit(dialogue.read_pages.keys())
	super.close()


func _layout() -> void:
	if portrait == null:
		return
	var margin: float = maxf(20, size.x * 0.025)
	var height: float = maxf(clampf(size.y * 0.235, 200, 280), body.get_combined_minimum_size().y + 44)
	card.position = Vector2(margin, size.y - height - 18)
	card.size = Vector2(size.x - margin * 2, height)
	# Keep the smaller scale, lifted 125 px at the standard 1000 px canvas to show the upper body.
	var lift: float = size.y * 0.125
	portrait.position = Vector2(margin + 10, size.y * 0.5 - lift)
	portrait.size = Vector2(minf(size.x * 0.30, size.y * 0.43), minf(size.y * 0.5, card.get_rect().end.y - size.y * 0.5))
	portrait.position.y = minf(portrait.position.y, card.position.y - portrait.size.y * 0.72)
	_nameplate.reset_size()
	_nameplate.position = Vector2(portrait.get_rect().end.x + 16, card.position.y - _nameplate.size.y + 4)
	var response_width: float = minf(size.x * 0.43, 640)
	choices.size = Vector2(response_width, choices.get_combined_minimum_size().y)
	choices.position = Vector2(size.x - margin - response_width, card.position.y - choices.get_combined_minimum_size().y - 24)
	extra.position = Vector2(maxf(size.x * 0.39, margin), 20 if size.y < 800 else size.y * 0.12)
	extra.size = Vector2(size.x - extra.position.x - margin, maxf(240, _nameplate.position.y - extra.position.y - 18))
	_restore.reset_size()
	_restore.position = Vector2(size.x - _restore.size.x - margin, size.y - _restore.size.y - 20)


func _present() -> void:
	var page: Dictionary = dialogue.current()
	if page.is_empty():
		close()
		return
	show_panel("")
	text.text = page.text
	_characters = 0
	_clock = 0
	text.visible_characters = 0 if int(settings.get_value("dialogue_speed")) > 0 else -1
	for child: Node in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	for response: Dictionary in page.choices:
		var button := UI.button(str(response.title), &"chevron", &"", choose.bind(str(response.id)))
		button.custom_minimum_size.y = 48
		button.add_theme_font_override("font", UITheme.body_font(600))
		button.add_theme_font_size_override("font_size", 23)
		choices.add_child(button)
	choices.visible = false
	code_button.visible = not dialogue.is_guided() and not (page.lesson as Dictionary).is_empty()
	next_button.disabled = not (page.choices as Array).is_empty()
	if skipping and not dialogue.read_before_enter:
		skipping = false
	_update_buttons()
	if text.visible_characters == -1:
		reveal()
	_layout.call_deferred()


func reveal() -> void:
	text.visible_characters = -1
	dialogue.mark_read()
	read_changed.emit(dialogue.read_pages.keys())
	choices.visible = not (dialogue.current().choices as Array).is_empty() and not ui_hidden and mode == ""
	if choices.visible:
		if choices.get_child_count() > 0:
			(choices.get_child(0) as Control).grab_focus()
		skipping = false
	_hint.text = "Choose a reply" if choices.visible else "Click / Space"
	_update_buttons()


func advance() -> void:
	if ui_hidden:
		toggle_ui()
		return
	if mode != "":
		return
	if text.visible_characters != -1:
		reveal()
	elif dialogue.advance():
		if dialogue.closed:
			var open_notes: bool = dialogue.person.get("on_finish", "") == "notebook"
			close()
			if open_notes:
				notebook_requested.emit()
		else:
			_present()


func choose(id: String) -> void:
	if text.visible_characters != -1 or mode != "" or ui_hidden:
		return
	if dialogue.choose(id):
		if dialogue.closed:
			close()
		else:
			_present()


func _process(delta: float) -> void:
	if dialogue == null or _closing or not is_visible_in_tree() or ui_hidden or mode != "":
		return
	if text.visible_characters != -1:
		if skipping and dialogue.read_before_enter:
			reveal()
			return
		var speed: int = int(settings.get_value("dialogue_speed"))
		_characters += delta * speed
		text.visible_characters = int(_characters)
		if speed == 0 or _characters >= text.get_total_character_count():
			reveal()
		return
	if not (dialogue.current().choices as Array).is_empty():
		return
	_clock += delta
	if skipping and _clock >= 0.15:
		advance()
	elif auto and _clock >= float(settings.get_value("dialogue_delay")) + text.get_total_character_count() / 40.0:
		advance()


func _toggle_skip() -> void:
	skipping = not skipping
	if skipping:
		if dialogue.read_before_enter:
			reveal()
		else:
			skipping = false
	_clock = 0
	_update_buttons()


func _update_buttons() -> void:
	auto_button.set_pressed_no_signal(auto)
	skip_button.set_pressed_no_signal(skipping)


func _toggle(label: String, icon: StringName, action: Callable) -> FButton:
	var button := UI.button(label, icon, &"ButtonQuiet", action)
	button.toggle_mode = true
	return button


func toggle_ui() -> void:
	ui_hidden = not ui_hidden
	portrait.visible = not ui_hidden
	card.visible = not ui_hidden
	_nameplate.visible = not ui_hidden
	_scrim.visible = not ui_hidden
	choices.visible = not ui_hidden and text.visible_characters == -1 and not (dialogue.current().choices as Array).is_empty()
	_restore.visible = ui_hidden
	if ui_hidden:
		show_panel("")
	_clock = 0


func show_panel(which: String) -> void:
	if which == "code" and (dialogue.current().lesson as Dictionary).is_empty():
		return
	if which == "code" and text.visible_characters != -1:
		reveal()
	mode = which
	extra.visible = which != "" and not ui_hidden
	choices.visible = which == "" and not ui_hidden and text.visible_characters == -1 and not (dialogue.current().choices as Array).is_empty()
	code_button.text = "Hide code" if which == "code" else "Show code"
	_clock = 0
	for child: Node in _panel_body.get_children():
		_panel_body.remove_child(child)
		child.queue_free()
	code = null
	if which == "":
		return
	var heading := UI.hbox(12)
	var title_text: String = str(dialogue.current().lesson.title) if which == "code" else {"history":"Conversation history", "settings":"Conversation settings"}[which]
	var title := UI.heading(title_text, 25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(UI.icon_button(&"cross", "Back to conversation", func() -> void: show_panel("")))
	_panel_body.add_child(heading)
	match which:
		"code": _build_code()
		"history": _build_history()
		"settings": _build_settings()
	_layout.call_deferred()


func _build_code() -> void:
	var lesson: Dictionary = dialogue.current().lesson
	_panel_body.add_child(UI.caps("Optional example · " + str(lesson.concept), Pal.TEAL))
	code = CodeEditor.new()
	code.name = "OptionalExample"
	code.text = str(lesson.source)
	code.editable = false
	code.code_completion_enabled = false
	code.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code.custom_minimum_size.y = 120
	code.add_theme_font_size_override("font_size", 19)
	_panel_body.add_child(code)
	_panel_body.add_child(UI.dim(str(lesson.explanation), 21))
	_panel_body.add_child(UI.dim("Read it here, or copy it to try in your notebook. Run previews; Apply commits.", 18))
	var row := UI.hbox(10)
	var copy_button := UI.button("Copy example", &"code")
	copy_button.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(str(lesson.source))
		copy_button.text = "Copied")
	row.add_child(copy_button)
	row.add_child(UI.button("Open notebook", &"book", &"ButtonPrimary", func() -> void: notebook_requested.emit()))
	_panel_body.add_child(row)


func _build_history() -> void:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel_body.add_child(scroll)
	var entries := UI.vbox(14)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	for item: Dictionary in dialogue.history:
		entries.add_child(UI.caps(str(item.speaker)))
		entries.add_child(UI.dim(str(item.text), 21))
	scroll.set_deferred("scroll_vertical", 100000)


func _build_settings() -> void:
	_panel_body.add_child(UI.dim("Text speed and auto-advance are remembered. Auto and Skip always stop for a reply.", 21))
	_panel_body.add_child(_slider("Text speed (0 shows the whole line)", "dialogue_speed", 0, 80, 2))
	_panel_body.add_child(_slider("Pause before auto-advance", "dialogue_delay", 1, 8, 0.5))
	_panel_body.add_child(UI.button("Game settings", &"gear", &"", func() -> void: settings_requested.emit()))


func _slider(label: String, key: String, low: float, high: float, step: float) -> Control:
	var box := UI.vbox(8)
	var caption := UI.label("", &"", 21)
	var update := func() -> void:
		caption.text = "%s · %s" % [label, str(settings.get_value(key))]
	update.call()
	box.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = float(settings.get_value(key))
	slider.value_changed.connect(func(value: float) -> void:
		settings.set_value(key, int(value) if key == "dialogue_speed" else value)
		update.call())
	box.add_child(slider)
	return box


func _on_text_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		advance()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo:
		return
	var owner: Control = get_viewport().gui_get_focus_owner()
	if owner is TextEdit and (event.ctrl_pressed or event.meta_pressed):
		return
	if event.keycode == KEY_SPACE and mode == "":
		get_viewport().set_input_as_handled()
		advance()
	elif event.keycode == KEY_H:
		get_viewport().set_input_as_handled()
		toggle_ui()
	elif event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if ui_hidden:
			toggle_ui()
		elif mode != "":
			show_panel("")
		else:
			close()


func _unhandled_key_input(_event: InputEvent) -> void:
	# Escape is handled above so it first restores hidden UI or closes the optional panel.
	pass
