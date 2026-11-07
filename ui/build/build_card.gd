class_name BuildCard
extends PanelContainer
## One thing on offer in build mode's dock: a picture of it, its name and its size. Click to choose it.
## The chosen card gets a bright brass border and a soft glow; hovering lifts it a little.

signal chosen(item_id: String)

var item_id: String = ""
var selected: bool = false:
	set(value):
		selected = value
		_restyle()
var _picture: TextureRect
var _hover: bool = false
var _tween: Tween


static func make(entry: Dictionary, chip: String, card_size: Vector2 = Vector2(104, 124)) -> BuildCard:
	var card := BuildCard.new()
	card.item_id = str(entry.id)
	card.custom_minimum_size = card_size
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "%s\n%s\n%s" % [str(entry.title), str(entry.get("blurb", "")), chip]
	var column := UI.vbox(2)
	card.add_child(column)
	var frame := PanelContainer.new()
	frame.theme_type_variation = &"PanelInset"
	frame.custom_minimum_size = Vector2(0, card_size.y - 44.0)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(frame)
	# Until its picture is drawn (or if none can be), the card shows a quiet icon of what it is.
	var placeholder := Glyph.new()
	placeholder.kind = {"building": &"house", "prop": &"sparkle"}.get(str(entry.get("kind", "")), &"tree")
	if entry.get("kind") == "paint":
		placeholder.kind = &"eraser" if card.item_id == "" else &"brush"
	if entry.has("icon"):
		placeholder.kind = StringName(str(entry.icon))
	placeholder.color = Color(Pal.BRASS_LO, 0.55)
	placeholder.custom_minimum_size = Vector2(46, 46)
	placeholder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	placeholder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frame.add_child(placeholder)
	card._picture = TextureRect.new()
	card._picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card._picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card._picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	card._picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card._picture.modulate.a = 0.0
	frame.add_child(card._picture)
	var title := UI.label(str(entry.title), &"", 13, Pal.PARCHMENT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = card_size.x - 16.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)
	card._restyle()
	return card


func _ready() -> void:
	mouse_entered.connect(func() -> void:
		_hover = true
		_restyle())
	mouse_exited.connect(func() -> void:
		_hover = false
		_restyle())


func set_picture(texture: Texture2D) -> void:
	if texture == null:
		return
	_picture.texture = texture
	var fade := create_tween()
	fade.tween_property(_picture, "modulate:a", 1.0, 0.25)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		chosen.emit(item_id)


func _restyle() -> void:
	var options: Dictionary = {"fill_top": Color("221a13"), "fill_bottom": Color("181410"), "border": Color(0.55, 0.42, 0.2, 0.7), "border_width": 1.0, "chamfer": 8.0, "inner_line": Color(0, 0, 0, 0), "bevel": 0.06}
	if selected:
		options = {"fill_top": Color("3a2c1b"), "fill_bottom": Color("2a2016"), "border": Pal.BRASS_HI, "border_width": 2.0, "chamfer": 8.0, "inner_line": Color(0.95, 0.8, 0.45, 0.3), "bevel": 0.1, "glow": Color(0.96, 0.8, 0.45, 0.22), "studs": true}
	elif _hover:
		options = {"fill_top": Color("2d2218"), "fill_bottom": Color("1f1812"), "border": Pal.BRASS, "border_width": 1.5, "chamfer": 8.0, "inner_line": Color(0.95, 0.8, 0.45, 0.12), "bevel": 0.08}
	add_theme_stylebox_override("panel", FantasyBox.make(options, Vector2(6, 6)))
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate", Color(1.12, 1.1, 1.06) if _hover and not selected else Color.WHITE, 0.12)
