class_name WorkshopJobLedger
extends Modal
## A deliberate list of reached jobs and their current, saved state.
signal notes_requested
signal destination_requested(id: String)

func setup(session: GameSession, story: Dictionary, reached: Array[Dictionary]) -> void:
	theme = PaperTheme.theme()
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	card.theme_type_variation = &"PanelCard"
	_scrim.color.a = .12
	var top := UI.hbox(8)
	top.add_child(UI.fill(UI.heading("Job book", 27)))
	top.add_child(UI.icon_button(&"cross", "Close job book", close))
	body.add_child(top)
	body.add_child(UI.dim("Nell’s work, kept together as you go.", 17))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var entries := UI.vbox(10)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	for record: Dictionary in reached:
		var quest: Dictionary = record.quest
		var panel := UI.panel(&"PanelInset")
		entries.add_child(panel)
		var column := UI.vbox(5)
		panel.add_child(column)
		var done: bool = bool(record.done)
		var number: String = str((story.get("tickets", {}) as Dictionary).get(quest.id, ""))
		column.add_child(UI.label(("JOB " + number + (" · DONE" if done else " · IN PROGRESS")).to_upper(), &"LabelCaps", 13, PaperPal.RED if done else PaperPal.TEAL_DEEP))
		column.add_child(UI.heading(str(quest.title), 22))
		column.add_child(UI.dim(str(quest.get("done", "")) if done else str(quest.get("summary", "")), 17))
		var place: Dictionary = _place(session, quest, str(record.get("room", "")))
		if not done and not place.is_empty():
			column.add_child(UI.button(str(place.label), &"", &"Button", func() -> void: destination_requested.emit(str(place.target))))
		if not done and quest.id == "say-hello" and session.area.id == "workshop-loft":
			var read: Array = session.state.get("inspections_read", [])
			var target: String = "nell-note" if not read.has("nell-note") else "desk-terminal"
			column.add_child(UI.button("Find the note" if target == "nell-note" else "Go to the terminal", &"", &"Button", func() -> void: destination_requested.emit(target)))
	var actions := UI.hbox(8)
	actions.add_child(UI.button("Open code", &"book", &"ButtonPrimary", func() -> void: notes_requested.emit()))
	actions.add_child(UI.button("Close", &"", &"ButtonQuiet", close))
	body.add_child(actions)
	resized.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	var width: float = minf(620, size.x*.46)
	card.position = Vector2(size.x-width-18, 18)
	card.size = Vector2(width, size.y-36)


## Where this job's code is written, as a button label and the id to walk to. Another floor's job points at the stairs.
static func _place(session: GameSession, quest: Dictionary, room: String) -> Dictionary:
	if not quest.get("access") is Dictionary: return {}
	if room != "" and room != session.area.id:
		return {"label": "Go downstairs", "target": "downstairs"} if session.area.id == "workshop-loft" else {}
	var place: Dictionary = FieldAccess.place_for(session.area, quest)
	return {} if place.is_empty() else {"label": "Go to the " + str(place.title).to_lower(), "target": str(place.target)}
