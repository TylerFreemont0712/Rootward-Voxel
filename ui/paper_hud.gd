class_name PaperHud
extends Hud
## The Sparks & Machines HUD in paper and enamel: a location plate, the pinned job ticket, an enamel
## Field Notes button and a menu button. It keeps Hud's signals and inset behaviour, so the game drives it
## exactly like the default HUD. Only that journey creates it.

var story: Dictionary = {}
var ticket: JobTicket
var _holding_completed: bool = false
var _notes_open: bool = false


func _init() -> void:
	theme = PaperTheme.theme()


func set_notebook_open(open: bool) -> void:
	super.set_notebook_open(open)
	_notes_open = open
	_place_ticket()


func _place_ticket() -> void:
	if _quest_group != null:
		_quest_group.position.y = maxf(84.0, size.y - 300.0) if _notes_open else 84.0


func _build() -> void:
	var plate := UI.panel(&"PanelPill")
	plate.position = Vector2(22, 20)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := UI.hbox(10)
	var pin := Glyph.new()
	pin.kind = &"lamp"
	pin.color = PaperPal.TEAL_DEEP
	row.add_child(pin)
	_location = UI.label("", &"LabelHeading", 19)
	row.add_child(_location)
	plate.add_child(row)
	add_child(plate)
	_quest_group = Control.new()
	_quest_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_group.position = Vector2(22, 84)
	_quest_group.size = Vector2(320, 260)
	add_child(_quest_group)
	resized.connect(_place_ticket)
	ticket = JobTicket.new()
	ticket.pressed.connect(func() -> void: journal_requested.emit())
	_quest_group.add_child(ticket)
	_objective_pill = ticket
	_objective_title = ticket.title
	_objective_hint = ticket.hint
	_objective_progress = ticket.number
	var buttons := UI.hbox(10)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	buttons.offset_left = 22
	buttons.offset_bottom = -22
	buttons.offset_top = -72
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(buttons)
	_notebook_button = UI.button("Field Notes", &"book", &"ButtonPrimary", func() -> void: notebook_requested.emit())
	_notebook_button.toggle_mode = true
	_notebook_button.tooltip_text = "Open your Field Notes (E)"
	_notebook_button.focus_mode = Control.FOCUS_NONE
	buttons.add_child(_notebook_button)
	var menu := UI.icon_button(&"menu", "Menu (Esc)", func() -> void: menu_requested.emit())
	menu.focus_mode = Control.FOCUS_NONE
	buttons.add_child(menu)
	# The default HUD's build button is never offered here; it exists only so shared code can hide it.
	_build_button = UI.icon_button(&"hammer", "", Callable())
	_build_button.visible = false
	add_child(_build_button)
	_controls = UI.panel(&"PanelCard")
	_controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_controls.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_controls.offset_right = -22
	_controls.offset_bottom = -22
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_label = UI.label("WASD walk  ·  Click to travel  ·  F talk  ·  E field notes  ·  Esc menu", &"LabelDim", 15)
	_controls.add_child(_controls_label)
	_controls.visible = bool(settings.get_value("show_controls"))
	add_child(_controls)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_stage)
	add_child(_stage)
	_toast_box = UI.vbox(6)
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_box.offset_bottom = -96
	_toast_box.alignment = BoxContainer.ALIGNMENT_END
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_toast_box)
	_inspect = UI.panel(&"PanelCard")
	_inspect.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_inspect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_inspect.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_inspect.offset_bottom = -30
	_inspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect_label = UI.label("", &"LabelDim", 16)
	_inspect.add_child(_inspect_label)
	_inspect.visible = false
	_stage.add_child(_inspect)
	# Hud keeps a banner for finished quests; here the ticket is stamped instead.
	_banner = PanelContainer.new()
	_banner.visible = false
	_banner_title = Label.new()
	_banner_body = Label.new()
	var banner_contents := UI.vbox(0)
	banner_contents.add_child(_banner_title)
	banner_contents.add_child(_banner_body)
	_banner.add_child(banner_contents)
	add_child(_banner)


func show_toast(text: String) -> void:
	_show_feedback(text, &"PanelCard", PaperPal.INK, 3.0)


func _refresh() -> void:
	if _location == null:
		return
	var zone: Dictionary = session.area.zone(session.current_zone) if session.current_zone != "" else {}
	_location.text = "%s  ·  %s" % [session.area.title, zone.title] if not zone.is_empty() else session.area.title
	if _holding_completed:
		return
	var quest: Dictionary = session.current_quest()
	ticket.set_steps([])
	if quest.is_empty():
		ticket.stamp(false)
		var after_key: String = "workshop_after_greeting" if session.area.interior.get("style") == "workshop-floor" else "after_greeting"
		var after: Dictionary = story.get(after_key, {})
		if after_key == "after_greeting" and session.area.pickups.any(func(pickup: Dictionary) -> bool: return not PlayerItems.has(session.state, str(pickup.item))):
			after = story.get("tablet_waiting", after)
		# A room with no jobs of its own (the lane) pins its own note instead of pointing back indoors.
		var own: Variant = (story.get("pinned", {}) as Dictionary).get(session.area.id)
		if own is Dictionary: after = own
		ticket.set_job("", str(after.get("title", "Nothing else pinned")), str(after.get("hint", "Look around. Nell will be back soon.")))
		return
	var numbers: Dictionary = story.get("tickets", {})
	var hint: String = str(quest.get("summary", ""))
	if quest.id == "say-hello" and session.area.id == "workshop-loft":
		var read: Array = session.state.get("inspections_read", [])
		var note: bool = read.has("nell-note")
		var terminal_used: bool = read.has("desk-terminal")
		hint = "A note is tucked under the mug." if not note else ("Use the terminal on the desk." if not terminal_used else "Send Hotaru a greeting.")
		var steps: Array[Dictionary] = [
			{"text":"Read Nell’s note", "done":note, "current":not note},
			{"text":"Use the loft terminal", "done":terminal_used, "current":note and not terminal_used},
			{"text":"Greet Hotaru", "done":false, "current":terminal_used},
		]
		ticket.set_steps(steps)
	var where: String = FieldAccess.place_hint(session.area, quest)
	if where != "": hint = (hint + " " + where).strip_edges()
	ticket.set_job(str(numbers.get(quest.id, "")), str(quest.title), hint)
	if ticket.stamped():
		ticket.stamp(false)


func _on_quest_completed(quest: Dictionary) -> void:
	_holding_completed = true
	ticket.set_steps([])
	if quest.id == "say-hello":
		var steps: Array[Dictionary] = [{"text":"Read Nell’s note", "done":true}, {"text":"Use the loft terminal", "done":true}, {"text":"Greet Hotaru", "done":true}]
		ticket.set_steps(steps)
	ticket.set_job(str((story.get("tickets", {}) as Dictionary).get(quest.id, "")), str(quest.title), str(quest.get("done", "")))
	ticket.stamp(true)
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_inside_tree():
			_holding_completed = false
			_refresh())
