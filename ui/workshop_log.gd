class_name WorkshopLog
extends Modal
## A deliberate, saved transcript drawer. World inspections never enter it.
func setup(tokens: Array, scenes: Dictionary, note: Dictionary = {}, note_read: bool = false) -> void:
	theme = PaperTheme.theme()
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	card.theme_type_variation = &"PanelCard"
	_scrim.color.a = .12
	var top := UI.hbox(8)
	top.add_child(UI.fill(UI.heading("Story log", 27)))
	top.add_child(UI.icon_button(&"cross", "Close story log", close))
	body.add_child(top)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var entries := UI.vbox(10)
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	if note_read and not note.is_empty():
		entries.add_child(UI.heading("Nell’s note", 23))
		var lines: PackedStringArray = [str(note.get("salutation", ""))]
		for line: Variant in note.get("lines", []): lines.append(str(line))
		lines.append(str(note.get("signature", "")))
		if str(note.get("postscript", "")) != "": lines.append(str(note.postscript))
		entries.add_child(UI.dim("\n\n".join(lines), 19))
	if tokens.is_empty() and not note_read: entries.add_child(UI.dim("Story conversations will be kept here as you read them.", 19))
	var previous: String = ""
	for token: Dictionary in tokens:
		var line: Dictionary = WorkshopStory.log_line(scenes, token)
		if line.is_empty(): continue
		if token.scene != previous:
			entries.add_child(UI.rule())
			entries.add_child(UI.heading(str(scenes[token.scene].title), 23))
			previous = token.scene
		var speaker: String = {"hotaru":"HOTARU", "player":"YOU", "ticket":"NELL’S TICKET", "narration":""}.get(line.speaker, "")
		if speaker != "": entries.add_child(UI.label(speaker, &"LabelCaps", 12, PaperPal.TEAL_DEEP))
		entries.add_child(UI.dim(str(line.text), 19))
	resized.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	var width: float = minf(620, size.x*.46)
	card.position = Vector2(size.x-width-18, 18)
	card.size = Vector2(width, size.y-36)
