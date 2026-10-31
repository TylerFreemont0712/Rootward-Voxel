class_name WorkshopScene
extends Modal
## Story dialogue uses the portrait stage; incidental speech stays in the world.
signal finished
signal logged(token: Dictionary)
signal log_requested
var pages: Array = []
var index: int = 0
var _stage: WorkshopLoftStage
var _speaker: Label
var _text: Label
var _count: Label
var _next: FButton
var _choices: VBoxContainer
var _portrait: TextureRect
var _player_portrait: TextureRect
var _settings: GameSettings
var _clock: float = 0.0
var _replying: bool = false
var _response_kind: String = ""
var _choice_index: int = -1
var _page_logged: bool = false
var _page: Dictionary = {}
var _finish_label: String = "Back to the workshop"
var _narrator: String = "The workshop"
var _paper: StyleBox

## The one window every story page uses, drawn at the same size and place for every page: from just right of the
## HUD buttons to the screen's right margin, 22% of the screen high, resting near the bottom. Name and text sit on
## the left, the choices (or Continue) on the right, and nothing in it changes size with the words. Portraits
## stand behind its top corners.
const HUD_CLEAR_LEFT: float = 0.145
const EDGE_MARGIN: float = 22.0
const WINDOW_HEIGHT: float = 0.225

var _frame: Control
var _text_box: Control
var _side: Control
var _close: Button
var _log: Button


func setup(scene: Dictionary, stage: WorkshopLoftStage, settings: GameSettings) -> void:
	theme = PaperTheme.theme()
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	card.custom_minimum_size = Vector2.ZERO
	_paper = PaperTheme.panel("card").duplicate() as StyleBox
	for edge: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_paper.set_content_margin(edge, 0.0)
	card.add_theme_stylebox_override("panel", _paper)
	card.remove_child(body)
	body.queue_free()
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_frame)
	_scrim.color.a = .14
	_stage = stage
	_settings = settings
	pages = scene.pages.duplicate(true)
	var upstairs: bool = str(scene.get("area", "")) == "workshop-loft"
	_finish_label = str(scene.get("finish_label", "Back to the loft" if upstairs else "Back to the workshop"))
	_narrator = str(scene.get("narrator", "The loft" if upstairs else "The workshop"))
	_portrait = _make_portrait("HotaruPortrait", "hotaru-robot")
	_portrait.flip_h = true
	_player_portrait = _make_portrait("TravellerPortrait", "traveller")
	_speaker = UI.heading("", 27)
	_speaker.clip_text = true
	_frame.add_child(_speaker)
	_count = UI.label("", &"LabelCaps", 13, PaperPal.PENCIL)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_frame.add_child(_count)
	_text_box = Control.new()
	_text_box.clip_contents = true
	_text_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_text_box.gui_input.connect(_text_input)
	_frame.add_child(_text_box)
	_text = UI.label("", &"", 26, PaperPal.INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_box.add_child(_text)
	_log = UI.button("Story log", &"book", &"Button", func() -> void: log_requested.emit())
	_frame.add_child(_log)
	_close = UI.icon_button(&"cross", "Leave conversation", close)
	_frame.add_child(_close)
	_side = Control.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_child(_side)
	_choices = UI.vbox(8)
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_side.add_child(_choices)
	_next = UI.button("Continue", &"chevron", &"ButtonPrimary", advance)
	_next.custom_minimum_size.y = 46
	_side.add_child(_next)
	resized.connect(_layout)
	_show_page(pages[0])
	_layout()


func _make_portrait(node_name: String, skin: String) -> TextureRect:
	var portrait := TextureRect.new()
	portrait.name = node_name
	portrait.texture = DialoguePortraits.texture_for(skin)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	move_child(portrait, card.get_index())
	return portrait


func open() -> void:
	_layout()
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, .18)


func _layout() -> void:
	if size.x <= 0 or _frame == null: return
	var left: float = clampf(size.x * HUD_CLEAR_LEFT, 190.0, 260.0)
	var right: float = size.x - EDGE_MARGIN
	if right - left < 620.0: left = maxf(16.0, right - 620.0)
	var width: float = right - left
	var height: float = clampf(size.y * WINDOW_HEIGHT, 188.0, 300.0)
	card.custom_minimum_size = Vector2(width, height)
	card.size = Vector2(width, height)
	card.position = Vector2(roundf(left), roundf(size.y - height - maxf(18.0, size.y * .03)))
	var pad: float = clampf(width * .022, 20.0, 34.0)
	var side: float = clampf(width * .34, 250.0, 480.0)
	var column: float = width - side - pad * 3.0
	_speaker.position = Vector2(pad, 12)
	_speaker.size = Vector2(column - 70.0, 36)
	_count.position = Vector2(pad + maxf(124.0, _log.get_combined_minimum_size().x) + 14.0, height - 38.0)
	_count.size = Vector2(70, 20)
	_text_box.position = Vector2(pad, 56)
	_text_box.size = Vector2(column, height - 56.0 - 52.0)
	_text.position = Vector2.ZERO
	_text.size = _text_box.size
	_text.add_theme_font_size_override("font_size", clampi(roundi(height * .105), 19, 26))
	_log.size = Vector2(maxf(124.0, _log.get_combined_minimum_size().x), 34)
	_log.position = Vector2(pad, height - 46.0)
	_close.size = Vector2(30, 30)
	_close.position = Vector2(width - 42.0, 10)
	_side.position = Vector2(width - side - pad, 52)
	_side.size = Vector2(side, height - 52.0 - 16.0)
	_next.size = Vector2(side, 46)
	_next.position = Vector2(0, _side.size.y - 46.0)
	_choices.position = Vector2.ZERO
	_choices.size = _side.size
	var portrait_size := Vector2(minf(size.x * .17, 270.0), minf(size.y * .38, 390.0))
	_portrait.size = portrait_size
	_player_portrait.size = portrait_size
	_portrait.position = Vector2(card.position.x - portrait_size.x * .25, card.position.y - portrait_size.y + 28.0)
	_player_portrait.position = Vector2(minf(card.position.x + width - portrait_size.x * .75, size.x - portrait_size.x - 6.0), card.position.y - portrait_size.y + 28.0)

func _show_page(page: Dictionary) -> void:
	_page = page
	_clock = 0
	_page_logged = false
	_count.text = "%d / %d" % [index+1, pages.size()]
	var speaker: String = str(page.speaker)
	_speaker.text = {"hotaru":"Hotaru", "player":"You", "ticket":"Nell’s ticket", "narration":_narrator}.get(speaker, "")
	_portrait.visible = speaker in ["hotaru", "player"]
	_player_portrait.visible = _portrait.visible
	_portrait.modulate = Color(.52, .52, .52, 1) if speaker == "player" else Color.WHITE
	_player_portrait.modulate = Color.WHITE if speaker == "player" else Color(.52, .52, .52, 1)
	_text.text = str(page.text)
	_text.visible_characters = -1 if float(_settings.get_value("dialogue_speed")) == 0 else 0
	for child: Node in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	_choices.hide()
	_next.show()
	_next.text = _finish_label if index == pages.size()-1 and not _replying else "Continue"
	if is_instance_valid(_stage): _stage.clear_speech()
	_update_choices()

func _process(delta: float) -> void:
	if _page.is_empty() or not is_visible_in_tree(): return
	var speed: float = float(_settings.get_value("dialogue_speed"))
	if speed > 0:
		_clock += delta
		_text.visible_characters = mini(_text.text.length(), int(_clock*speed))
	_update_choices()

func _revealed() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.text.length()

func _record_current() -> void:
	if _page_logged or not _revealed(): return
	_page_logged = true
	var token: Dictionary = {"page":index, "kind":_response_kind if _replying else "page"}
	if _replying: token["choice"] = _choice_index
	logged.emit(token)

func _update_choices() -> void:
	if not _revealed(): return
	_record_current()
	if _replying or (_page.get("choices", []) as Array).is_empty(): return
	if _choices.get_child_count() == 0:
		for choice: Dictionary in _page.choices:
			var button := UI.button(str(choice.text), &"", &"Button", _choose.bind(choice))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size.y = 42
			button.add_theme_font_size_override("font_size", clampi(roundi(card.size.y * .082), 16, 20))
			_choices.add_child(button)
	_choices.show()
	_next.hide()

func _choose(choice: Dictionary) -> void:
	if not _revealed() or _replying: return
	_record_current()
	_choice_index = (pages[index].get("choices", []) as Array).find(choice)
	if _choice_index < 0: return
	_replying = true
	_response_kind = "choice"
	_show_page({"speaker":"player", "text":choice.text})

func advance() -> void:
	if not _revealed():
		_clock = 1000
		_text.visible_characters = -1
		_update_choices()
		return
	_record_current()
	if not _replying and not (_page.get("choices", []) as Array).is_empty(): return
	if _replying and _response_kind == "choice":
		_response_kind = "reply"
		_show_page({"speaker":"hotaru", "text":pages[index].choices[_choice_index].reply})
		return
	_replying = false
	_response_kind = ""
	index += 1
	if index == pages.size():
		finished.emit()
		close()
	else: _show_page(pages[index])

func _text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: advance()

func close() -> void:
	if is_instance_valid(_stage): _stage.clear_speech()
	super.close()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		advance()
	else: super._unhandled_key_input(event)
