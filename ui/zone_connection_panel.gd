class_name ZoneConnectionPanel
extends Modal
## Says where a piece of code is written and offers to walk there: a terminal's screen for a zone, or the
## place to stand beside a single fitting. Code reaches only what the traveller stands beside.
signal destination_requested(id: String)

func setup(terminal: Dictionary) -> void:
	var jack: bool = terminal.has("requires")
	var zone: String = str(terminal.zone)
	if jack:
		_card("AREA NODE", str(terminal.title), 'The "%s" zone answers to this screen. Plug your tablet into the socket below it once, and the tablet will remember the link. Its code works only while you stand there.' % zone, "Go to the screen", str(terminal.id))
	else:
		_card("ZONE TERMINAL", str(terminal.title), 'This terminal connects the "%s" zone. Use its screen once; the link is remembered for this room.' % zone, "Go to the terminal", str(terminal.id))

func setup_device(lamp: Dictionary) -> void:
	var title: String = str(lamp.get("title", lamp.id))
	_card("A FITTING", title, "Stand beside it with your tablet and press F to open its code. A fitting answers only to someone close enough to touch it.", "Go to the " + title.to_lower(), str(lamp.id))

func _card(caption: String, title: String, text: String, button: String, target: String) -> void:
	theme = PaperTheme.theme()
	_scrim.color.a = .12
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	card.theme_type_variation = &"PanelCard"
	card.size = Vector2(580, 380)
	body.add_child(UI.label(caption, &"LabelCaps", 14, PaperPal.TEAL_DEEP))
	body.add_child(UI.heading(title, 27))
	body.add_child(UI.dim(text, 20))
	body.add_child(UI.button(button, &"", &"ButtonPrimary", func() -> void: destination_requested.emit(target)))
	body.add_child(UI.button("Back to the room", &"", &"ButtonQuiet", close))
	resized.connect(_layout)
	_layout.call_deferred()

func _layout() -> void:
	var width: float = minf(580, size.x*.43)
	card.size = Vector2(width, 380)
	card.position = Vector2(size.x-width-20, (size.y-card.size.y)*.5)

func open() -> void:
	super.open()
	await get_tree().process_frame
	card.reset_size()
	_layout()
