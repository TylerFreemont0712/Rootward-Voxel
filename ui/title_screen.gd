class_name TitleScreen
extends Control
## The main menu, laid over the live 3D valley. Everything on it is built from the shared UI kit: no
## painted backdrop is needed, because the world itself is the title art.

signal continue_requested
signal new_game_requested
signal character_requested
signal settings_requested
signal quit_requested

var _column: VBoxContainer
var _continue: FButton
var _summary: Label
var _first_button: FButton


func setup(has_save: bool, summary: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := TextureRect.new()
	shade.texture = _shade_texture()
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(shade)
	add_child(shade)
	_column = UI.vbox(14)
	_column.position = Vector2(96, 0)
	_column.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_column.offset_left = 96
	_column.offset_right = 560
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_column)
	_column.add_child(UI.caps("A programming adventure", Pal.BRASS))
	var wordmark := Label.new()
	wordmark.text = "ROOTWARD"
	wordmark.add_theme_font_override("font", UITheme.display_font(800, 4))
	wordmark.add_theme_font_size_override("font_size", 92)
	wordmark.add_theme_color_override("font_color", Color("f2c868"))
	wordmark.add_theme_color_override("font_outline_color", Color("3a2408"))
	wordmark.add_theme_constant_override("outline_size", 8)
	wordmark.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	wordmark.add_theme_constant_override("shadow_offset_y", 5)
	_column.add_child(wordmark)
	var sub := UI.hbox(12)
	_column.add_child(sub)
	var voxel := UI.label("VOXEL", &"LabelHeading", 26, Pal.PARCHMENT)
	voxel.add_theme_font_override("font", UITheme.display_font(700, 10))
	sub.add_child(voxel)
	var rule := UI.rule()
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sub.add_child(rule)
	var tagline := UI.dim("Write the spell. Light the hollow.", 24)
	tagline.add_theme_color_override("font_color", Pal.PARCHMENT)
	_column.add_child(tagline)
	_column.add_child(UI.spacer(26))
	if has_save:
		_continue = UI.button("Continue", &"play", &"ButtonPrimary", func() -> void: continue_requested.emit())
		_continue.custom_minimum_size = Vector2(340, 56)
		_column.add_child(_continue)
		_first_button = _continue
		_summary = UI.dim(summary, 17)
		_column.add_child(_summary)
	var new_game := UI.button("New journey", &"star", &"ButtonPrimary" if not has_save else &"", func() -> void: new_game_requested.emit())
	new_game.custom_minimum_size = Vector2(340, 56)
	_column.add_child(new_game)
	if _first_button == null:
		_first_button = new_game
	for spec: Array in [["Character", &"person", character_requested], ["Settings", &"gear", settings_requested], ["Quit", &"door", quit_requested]]:
		var button := UI.button(spec[0], spec[1], &"", func() -> void: (spec[2] as Signal).emit())
		button.custom_minimum_size = Vector2(340, 50)
		_column.add_child(button)
	var footer := UI.label("Arrows or Tab move  ·  Enter selects  ·  Your Python runs in a sandbox", &"LabelDim", 15)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 96
	footer.offset_bottom = -26
	footer.offset_top = -52
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(footer)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.8)


func focus_first() -> void:
	if _first_button != null:
		_first_button.grab_focus()


func _shade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.04, 0.03, 0.02, 0.9))
	gradient.set_color(1, Color(0.04, 0.03, 0.02, 0.0))
	gradient.add_point(0.5, Color(0.04, 0.03, 0.02, 0.62))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0.5)
	texture.fill_to = Vector2(0.7, 0.5)
	texture.width = 256
	texture.height = 4
	return texture
