class_name PaperHud
extends Hud
## The Sparks & Machines HUD in paper and enamel: a location plate, the pinned job ticket, an enamel
## Field Notes button and a menu button. It keeps Hud's signals and inset behaviour, so the game drives it
## exactly like the default HUD. Only that journey creates it.

var story: Dictionary = {}
var ticket: JobTicket
var _holding_completed: bool = false
var _notes_open: bool = false
var _dev_button: FButton
var _purse_button: FButton


func _init() -> void:
	theme = PaperTheme.theme()


func setup(game_session: GameSession, game_settings: GameSettings) -> void:
	super.setup(game_session,game_settings)
	session.state_changed.connect(_refresh_purse)


func _refresh_purse() -> void:
	if _purse_button!=null:_purse_button.text="Bag · %d p" % session.accounts.wallet


func set_notebook_open(open: bool) -> void:
	super.set_notebook_open(open)
	_notes_open = open
	_place_ticket()


func _process(_delta: float) -> void:
	# Wrapped labels settle after the container's minimum-size notification.
	# Fit the small pin once the final height is available, including after a job changes.
	if ticket != null: _place_ticket()


func _place_ticket() -> void:
	if _quest_group != null:
		if ticket != null:
			# This panel is a child of a plain Control, so it grows to fit text
			# but needs an explicit shrink after wrapping or changing jobs.
			ticket.size = Vector2(380.0, ticket.get_combined_minimum_size().y)
		_quest_group.position.y = maxf(84.0, size.y - ticket.size.y - 108.0) if _notes_open and ticket != null else 84.0
		if _toast_box != null:
			_toast_box.offset_bottom = -(size.y - _quest_group.position.y + 18.0) if _notes_open else -96.0


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
	var dial := DayDial.new()
	dial.session = session
	dial.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dial.offset_left = -270
	dial.offset_top = 18
	dial.offset_right = -22
	dial.offset_bottom = 68
	add_child(dial)
	_quest_group = Control.new()
	_quest_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_group.position = Vector2(22, 84)
	_quest_group.size = Vector2(380, 300)
	add_child(_quest_group)
	resized.connect(_place_ticket)
	ticket = JobTicket.new()
	ticket.pressed.connect(func() -> void: journal_requested.emit())
	_quest_group.add_child(ticket)
	ticket.resized.connect(_place_ticket)
	ticket.minimum_size_changed.connect(_place_ticket)
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
	if DevelopmentMode.available():
		_dev_button = UI.button("Dev · F8", &"", &"", func() -> void: development_requested.emit())
		_dev_button.tooltip_text = "Chapter starts, ends and reference code (F8)"
		buttons.add_child(_dev_button)
	_purse_button=UI.button("Bag · I",&"",&"",func()->void:inventory_requested.emit())
	_purse_button.tooltip_text="Inventory and account book (I)"
	buttons.add_child(_purse_button)
	_build_button = UI.button("Layout · B", &"hammer", &"", func() -> void: build_requested.emit())
	_build_button.tooltip_text = "Arrange the upper paths, park and barriers (B)"
	_build_button.focus_mode = Control.FOCUS_NONE
	_build_button.visible = false
	buttons.add_child(_build_button)
	# No controls hint here: the buttons carry their own tooltips and the lower right stays clear for dialogue.
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


func reset_pin() -> void:
	_holding_completed = false
	ticket.clear_stamp()
	_refresh()


func _refresh() -> void:
	if _location == null:
		return
	_build_button.visible = not (session.area.interior.get("layout", {}) as Dictionary).is_empty()
	_refresh_purse()
	if _dev_button != null: _dev_button.text = "Dev mode · F8" if SaveStore.development else "Dev · F8"
	var zone: Dictionary = session.area.zone(session.current_zone) if session.current_zone != "" else {}
	_location.text = "%s  ·  %s" % [session.area.title, zone.title] if not zone.is_empty() else session.area.title
	if _holding_completed:
		return
	var quest: Dictionary = session.current_quest()
	if quest.get("id","")=="proper-welcome" and not session.accounts.receipts.has("morning-round"):
		ticket.set_context("02","The morning round","")
		ticket.set_steps([])
		ticket.set_job("","Out on the lane","Nell’s morning round is waiting inside. Finish the workshop lights before taking on another job.")
		return
	var chapter: Dictionary = DevelopmentMode.chapter(story, str(quest.get("id", "")), session.area.id)
	ticket.set_context(str(chapter.get("id", "")), str(chapter.get("title", "")), str(quest.get("concept", "")))
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
	if quest.id=="proper-welcome" and not session.state.inspections_read.has("sign-commission"):
		hint="Braum is looking for Nell’s help. Speak to him outside the white garden fence, then meet Iona at the tram sign."
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
	if where != "" and not (quest.id=="proper-welcome" and not session.state.inspections_read.has("sign-commission")): hint = (hint + " " + where).strip_edges()
	ticket.set_job(str(numbers.get(quest.id, "")), str(quest.title), hint)
	if ticket.stamped():
		ticket.stamp(false)


func _on_quest_completed(quest: Dictionary) -> void:
	_holding_completed = true
	var chapter: Dictionary = DevelopmentMode.chapter(story, str(quest.id), session.area.id)
	ticket.set_context(str(chapter.get("id", "")), str(chapter.get("title", "")), str(quest.get("concept", "")))
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
