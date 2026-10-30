class_name Hud
extends Control
## The in-game overlay: where you are, what you are doing, and a few round buttons. It stays out of
## the way so the world fills the screen; the notebook slides over it when summoned.

signal notebook_requested
signal journal_requested
signal map_requested
signal menu_requested
signal build_requested

var session: GameSession
var settings: GameSettings
var _location: Label
var _objective_title: Label
var _objective_progress: Label
var _objective_hint: Label
var _objective_pill: Control
var _controls: PanelContainer
var _toast_box: VBoxContainer
var _banner: PanelContainer
var _banner_title: Label
var _banner_body: Label
var _inspect: PanelContainer
var _inspect_label: Label
var _right_inset: float = 0.0
var _quest_group: Control
var _stage: Control
var _banner_tween: Tween
var _inspect_tween: Tween
var _notebook_button: FButton
var _controls_label: Label
var _build_button: FButton
var _shown_area: String=""
var _active_toasts: Dictionary = {}


func setup(game_session: GameSession, game_settings: GameSettings) -> void:
	session = game_session
	settings = game_settings
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	session.zone_changed.connect(func(_zone: Dictionary) -> void: _refresh())
	session.quest_changed.connect(_refresh)
	session.quest_completed.connect(_on_quest_completed)
	session.toast.connect(show_toast)
	settings.changed.connect(func(key: String) -> void:
		if key == "show_controls":
			_controls.visible = bool(settings.get_value("show_controls")))
	_refresh()


## Keep feedback in the free world area; the quest tracker always stays on the left.
func set_right_inset(pixels: float) -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(func(value: float) -> void:
		_right_inset = value
		_stage.offset_right = -value
		_controls.offset_right = -22.0 - value, _right_inset, pixels, 0.28)


func set_notebook_open(open: bool) -> void:
	_notebook_button.button_pressed = open
	_controls.visible = bool(settings.get_value("show_controls")) and not open


func show_toast(text: String) -> void:
	_show_feedback(text, &"PanelPill", Pal.PARCHMENT, 2.6)


## Repeated feedback renews one visible message, including during held input.
## Different messages remain distinct, with a small bound on the total stack.
func _show_feedback(text: String, style: StringName, color: Color, hold: float) -> void:
	if text.strip_edges().is_empty():
		return
	var entry: Dictionary = _active_toasts.get(text, {})
	var pill: PanelContainer = entry.get("panel") as PanelContainer
	if not is_instance_valid(pill) or pill.is_queued_for_deletion():
		_active_toasts.erase(text)
		while _toast_box.get_child_count() >= 3:
			var oldest: Node = _toast_box.get_child(0)
			var key: String = str(oldest.get_meta("feedback_text", ""))
			var previous: Dictionary = _active_toasts.get(key, {})
			if previous.has("tween"):
				(previous.tween as Tween).kill()
			_active_toasts.erase(key)
			_toast_box.remove_child(oldest)
			oldest.queue_free()
		pill = UI.panel(style)
		pill.set_meta("feedback_text", text)
		pill.custom_minimum_size.x = clampf(get_viewport_rect().size.x - _right_inset - 64.0, 260.0, 600.0)
		var label := UI.label(text, &"", 18, color)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pill.add_child(label)
		pill.modulate.a = 0.0
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_toast_box.add_child(pill)
	elif entry.has("tween"):
		(entry.tween as Tween).kill()
	var tween := create_tween()
	tween.tween_property(pill, "modulate:a", 1.0, 0.25)
	tween.tween_interval(hold)
	tween.tween_property(pill, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func() -> void:
		_active_toasts.erase(text)
		pill.queue_free())
	_active_toasts[text] = {"panel": pill, "tween": tween}


## A short line describing a clicked cell, so players can read ids and terrain from the world itself.
func show_inspection(text: String) -> void:
	_inspect_label.text = text
	_inspect.visible = true
	_inspect.modulate.a = 1.0
	if _inspect_tween != null:
		_inspect_tween.kill()
	_inspect_tween = create_tween()
	_inspect_tween.tween_interval(5.0)
	_inspect_tween.tween_property(_inspect, "modulate:a", 0.0, 0.8)
	_inspect_tween.tween_callback(func() -> void: _inspect.visible = false)


func _build() -> void:
	var top_left := UI.panel(&"PanelPill")
	top_left.position = Vector2(22, 20)
	top_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left_row := UI.hbox(10)
	var pin := Glyph.new()
	pin.kind = &"lamp"
	pin.color = Pal.BRASS
	left_row.add_child(pin)
	_location = UI.label("", &"", 20, Pal.PARCHMENT)
	left_row.add_child(_location)
	top_left.add_child(left_row)
	add_child(top_left)
	_quest_group=Control.new()
	_quest_group.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_quest_group.position=Vector2(22,82)
	_quest_group.size=Vector2(292,260)
	add_child(_quest_group)
	var pill:=UI.panel(&"PanelQuest")
	pill.custom_minimum_size.x=292
	pill.size.x=292
	pill.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	pill.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:journal_requested.emit())
	_quest_group.add_child(pill)
	_objective_pill=pill
	var texts:=UI.vbox(7)
	pill.add_child(texts)
	texts.add_child(UI.caps("YOUR NEXT STEP",Pal.TEAL))
	_objective_title=UI.label("",&"",21,Pal.PARCHMENT)
	_objective_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(_objective_title)
	_objective_progress=UI.dim("",16)
	texts.add_child(_objective_progress)
	_objective_hint=UI.dim("",17)
	texts.add_child(_objective_hint)
	var buttons := UI.hbox(8)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	buttons.offset_left = 22
	buttons.offset_bottom = -22
	buttons.offset_top = -68
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(buttons)
	_notebook_button = UI.button("Notebook", &"book", &"ButtonPrimary", func() -> void: notebook_requested.emit())
	_notebook_button.toggle_mode = true
	_notebook_button.tooltip_text = "Open your notebook and write code (E)"
	_notebook_button.focus_mode = Control.FOCUS_NONE
	buttons.add_child(_notebook_button)
	for spec: Array in [[&"scroll", "Journal and lessons (J)", journal_requested], [&"map", "Map of the hollow (M)", map_requested], [&"hammer", "Build mode: arrange the valley (B)", build_requested], [&"menu", "Menu (Esc)", menu_requested]]:
		var button := UI.icon_button(spec[0], spec[1], func() -> void: (spec[2] as Signal).emit())
		button.focus_mode = Control.FOCUS_NONE
		buttons.add_child(button)
		if spec[0]==&"hammer":_build_button=button
	_controls = UI.panel(&"PanelPill")
	_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_controls.offset_right = -22
	_controls.offset_bottom = -22
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_label=UI.label("", &"LabelDim", 15)
	_controls.add_child(_controls_label)
	_controls.visible = bool(settings.get_value("show_controls"))
	add_child(_controls)
	# Centered elements live on a stage that shrinks when the notebook opens, so they stay in view.
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_stage)
	add_child(_stage)
	_toast_box = UI.vbox(6)
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_box.offset_bottom = -92
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_toast_box)
	_inspect = UI.panel(&"PanelPill")
	_inspect.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_inspect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_inspect.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_inspect.offset_bottom = -30
	_inspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect_label = UI.label("", &"", 17, Pal.PARCH_DIM)
	_inspect.add_child(_inspect_label)
	_inspect.visible = false
	_stage.add_child(_inspect)
	_banner = UI.panel(&"PanelQuest")
	_banner.custom_minimum_size.x=292
	_banner.size.x=292
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner_column := UI.vbox(2)
	banner_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.add_child(banner_column)
	banner_column.add_child(UI.caps("Quest complete", Pal.GREEN))
	_banner_title = UI.heading("", 21)
	_banner_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	banner_column.add_child(_banner_title)
	_banner_body = UI.dim("", 18)
	banner_column.add_child(_banner_body)
	_banner.visible = false
	_quest_group.add_child(_banner)


func _refresh() -> void:
	if _location == null:
		return
	if _shown_area!=session.area.id:
		_shown_area=session.area.id
		if _banner_tween!=null:_banner_tween.kill()
		_banner.visible=false
		_objective_pill.visible=true
	var zone: Dictionary = session.area.zone(session.current_zone) if session.current_zone != "" else {}
	_location.text = "%s  ·  %s" % [session.area.title, zone.title] if not zone.is_empty() else session.area.title
	var quest: Dictionary = session.current_quest()
	_notebook_button.text = "Field Notes" if session.area.movement_lesson else "Notebook"
	_build_button.visible=not session.area.movement_lesson
	_controls_label.text="Your mapped keys walk  ·  E field notes  ·  M map  ·  Esc menu" if session.area.movement_lesson else "WASD walk  ·  Click to travel  ·  F talk or use  ·  E notebook  ·  M map  ·  B build"
	_objective_hint.text=str(quest.get("summary",""))
	if session.area.movement_lesson:
		if not CompanionLesson.has_voice(session.state,session.completed):
			_objective_hint.text='Hotaru is listening. Open your notes with E, Test your greeting, then Speak to her.'
		elif MovementBindings.mapped(session.state)<4:
			_objective_hint.text="Open your notes with E. Test each key’s code, then Apply your four movements."
		elif MovementBindings.tried(session.state)<4:
			_objective_hint.text="Continue from your notes and try every direction in the room. Practice: %d / 4." % MovementBindings.tried(session.state)
		else:
			if session.area.interior.get("style", "")=="morning-bedroom":
				_objective_hint.text="Walk through the open door to take a first look at the village lane."
			elif not session.area.interior.is_empty():
				_objective_hint.text="Explore the room. Walk through the doorway to return to the village."
			else:
				_objective_hint.text="Follow the lane to Rootward Square and the town hall. Your home waits down the lane."
	if session.area.movement_lesson and quest.is_empty():
		_objective_title.text = "Your first steps are yours" if MovementBindings.finished(session.state) else "Make the keys your own"
		_objective_progress.text = "Movement lesson complete" if MovementBindings.finished(session.state) else "Press E to connect your movement keys"
		return
	if quest.is_empty():
		if not session.area.interior.is_empty():
			_objective_title.text = "A quiet moment indoors"
			_objective_progress.text = "Walk out through the door to return to the village"
			_objective_hint.text=""
			return
		_objective_title.text = "Kindle Hollow is lit"
		_objective_progress.text = "%d %s burning · free exploration" % [session.lamps_lit(), "lamp" if session.lamps_lit() == 1 else "lamps"]
		return
	var progress: Dictionary = session.quest_progress()
	_objective_title.text = str(quest.title)
	_objective_progress.text = "%s   %d / %d %s" % [str(quest.concept), int(progress.done), int(progress.total), str(progress.noun)] if int(progress.total) > 1 else str(quest.concept)


func _on_quest_completed(quest: Dictionary) -> void:
	_banner_title.text = str(quest.title)
	_banner_body.text = str(quest.done)
	_banner.visible = true
	_objective_pill.visible=false
	_banner.modulate.a = 0.0
	if _banner_tween != null:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.35)
	_banner_tween.tween_interval(5.0)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.8)
	_banner_tween.tween_callback(func() -> void:
		_banner.visible=false
		_objective_pill.visible=true)
