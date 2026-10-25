class_name UITheme
extends RefCounted
## One Theme for the whole game, built in code from the palette. Fonts: Cinzel for engraved headings and
## buttons, Alegreya for reading, IBM Plex Mono for code. Button looks are theme variations:
## "" (plaque), "Primary" (brass), "Quiet" (text only), "Tab", "Icon", "Danger".

const CINZEL: Font = preload("res://ui/fonts/cinzel.ttf")
const ALEGREYA: Font = preload("res://ui/fonts/alegreya.ttf")
const MONO: Font = preload("res://ui/fonts/ibm-plex-mono-latin-400-normal.woff2")

static var _theme: Theme
static var _fonts: Dictionary = {}


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func display_font(weight: int = 700, spacing: int = 1) -> Font:
	return _variation("display%d_%d" % [weight, spacing], CINZEL, weight, spacing)


static func body_font(weight: int = 500) -> Font:
	return _variation("body%d" % weight, ALEGREYA, weight, 0)


static func mono_font() -> Font:
	return MONO


static func _variation(key: String, base: Font, weight: int, spacing: int) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var font := FontVariation.new()
	font.base_font = base
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("weight"): weight}
	font.spacing_glyph = spacing
	_fonts[key] = font
	return font


static func plaque(state: StringName, variation: String = "", pad: Vector2 = Vector2(20, 11)) -> FantasyBox:
	var primary: bool = variation == "Primary"
	var danger: bool = variation == "Danger"
	var tab: bool = variation == "Tab"
	var options: Dictionary = {"chamfer": 8.0, "shadow": 2.0, "studs": false}
	if primary:
		options.merge({"fill_top": Color("f1c767"), "fill_bottom": Color("c98f33"), "border": Color("fbe2a0"), "inner_line": Color(1, 1, 1, 0.2), "bevel": 0.25}, true)
		match state:
			&"hover":
				options.merge({"fill_top": Color("f8d98a"), "fill_bottom": Color("d89d3b"), "glow": Color(1.0, 0.84, 0.4, 0.28)}, true)
			&"pressed":
				options.merge({"fill_top": Color("c98f33"), "fill_bottom": Color("e0a949"), "shadow": 0.0, "bevel": 0.0}, true)
			&"disabled":
				options.merge({"fill_top": Color("5b4a2c"), "fill_bottom": Color("493a22"), "border": Color("6e5a35"), "inner_line": Color(0, 0, 0, 0), "bevel": 0.0}, true)
	elif tab:
		options.merge({"chamfer": 6.0, "shadow": 0.0, "fill_top": Pal.PANEL_LO, "fill_bottom": Pal.PANEL_LO, "border": Color(0.55, 0.42, 0.2, 0.45), "inner_line": Color(0, 0, 0, 0), "bevel": 0.0}, true)
		match state:
			&"hover":
				options.merge({"fill_top": Pal.PANEL, "fill_bottom": Pal.PANEL, "border": Pal.BRASS_LO}, true)
			&"pressed":
				options.merge({"fill_top": Pal.WOOD, "fill_bottom": Pal.PANEL_HI, "border": Pal.BRASS, "inner_line": Color(0.95, 0.8, 0.45, 0.22)}, true)
	elif variation == "Quiet":
		options.merge({"fill_top": Color(0, 0, 0, 0), "fill_bottom": Color(0, 0, 0, 0), "border": Color(0, 0, 0, 0), "inner_line": Color(0, 0, 0, 0), "shadow": 0.0, "bevel": 0.0}, true)
		match state:
			&"hover":
				options.merge({"fill_top": Color(1, 1, 1, 0.05), "fill_bottom": Color(1, 1, 1, 0.05)}, true)
			&"pressed":
				options.merge({"fill_top": Color(1, 1, 1, 0.09), "fill_bottom": Color(1, 1, 1, 0.09)}, true)
	else:
		options.merge({"fill_top": Pal.WOOD_HI, "fill_bottom": Pal.WOOD, "border": Pal.BRASS_LO, "studs": true, "stud_color": Pal.BRASS}, true)
		if danger:
			options.merge({"fill_top": Color("5a2a24"), "fill_bottom": Color("3d1d1a"), "border": Color("a85a4d"), "stud_color": Color("d98a78")}, true)
		match state:
			&"hover":
				options.merge({"fill_top": Color("5d4529"), "fill_bottom": Color("42311f"), "border": Pal.BRASS, "glow": Color(0.95, 0.75, 0.35, 0.2)}, true)
				if danger:
					options.merge({"fill_top": Color("6d3329"), "fill_bottom": Color("4a2320"), "border": Color("e2897a")}, true)
			&"pressed":
				options.merge({"fill_top": Pal.WOOD, "fill_bottom": Color("2a1e13"), "border": Pal.BRASS_HI, "shadow": 0.0, "bevel": 0.0}, true)
			&"disabled":
				options.merge({"fill_top": Color("2a221a"), "fill_bottom": Color("221b14"), "border": Color("4a3e2c"), "studs": false, "inner_line": Color(0, 0, 0, 0), "bevel": 0.0}, true)
	if state == &"focus":
		return FantasyBox.make({"fill_top": Color(0, 0, 0, 0), "fill_bottom": Color(0, 0, 0, 0), "border": Pal.BRASS_HI, "border_width": 2.0, "chamfer": 8.0, "inner_line": Color(0, 0, 0, 0), "bevel": 0.0, "studs": false, "shadow": 0.0}, pad)
	return FantasyBox.make(options, pad)


static func panel(kind: String = "panel") -> FantasyBox:
	match kind:
		"inset":
			return FantasyBox.make({"fill_top": Color("0e0b08"), "fill_bottom": Color("130f0b"), "border": Color(0.55, 0.42, 0.2, 0.55), "border_width": 1.0, "chamfer": 6.0, "inner_line": Color(0, 0, 0, 0), "bevel": 0.0}, Vector2(10, 8))
		"pill":
			return FantasyBox.make({"fill_top": Color(0.1, 0.075, 0.05, 0.9), "fill_bottom": Color(0.07, 0.05, 0.035, 0.9), "border": Pal.BRASS, "border_width": 1.5, "chamfer": 9.0, "inner_line": Color(0.95, 0.8, 0.45, 0.12), "shadow": 2.0, "bevel": 0.0}, Vector2(14, 7))
		"card":
			return FantasyBox.make({"fill_top": Color("221a13"), "fill_bottom": Color("181410"), "border": Color(0.55, 0.42, 0.2, 0.7), "border_width": 1.0, "chamfer": 7.0, "inner_line": Color(0, 0, 0, 0), "bevel": 0.06}, Vector2(14, 12))
		"scrim":
			return FantasyBox.make({"fill_top": Color(0.04, 0.03, 0.02, 0.92), "fill_bottom": Color(0.06, 0.045, 0.03, 0.95), "border": Pal.BRASS, "border_width": 2.0, "chamfer": 14.0, "inner_line": Color(0.95, 0.8, 0.45, 0.22), "studs": true, "stud_color": Pal.BRASS, "shadow": 6.0, "bevel": 0.1}, Vector2(26, 22))
		"drawer":
			return FantasyBox.make({"fill_top": Color(0.1, 0.075, 0.05, 0.96), "fill_bottom": Color(0.075, 0.055, 0.04, 0.97), "border": Pal.BRASS, "border_width": 2.0, "chamfer": 16.0, "inner_line": Color(0.95, 0.8, 0.45, 0.2), "studs": true, "stud_color": Pal.BRASS, "shadow": 0.0, "bevel": 0.1}, Vector2(20, 18))
		_:
			return FantasyBox.make({"fill_top": Pal.PANEL_HI, "fill_bottom": Pal.PANEL, "border": Pal.BRASS, "border_width": 2.0, "chamfer": 14.0, "inner_line": Color(0.95, 0.8, 0.45, 0.2), "studs": true, "shadow": 4.0}, Vector2(22, 18))


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font(500)
	t.default_font_size = 18
	# Labels
	t.set_color("font_color", "Label", Pal.PARCHMENT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_type_variation("LabelDim", "Label")
	t.set_color("font_color", "LabelDim", Pal.PARCH_DIM)
	t.set_type_variation("LabelHeading", "Label")
	t.set_font("font", "LabelHeading", display_font(700, 1))
	t.set_color("font_color", "LabelHeading", Pal.BRASS_HI)
	t.set_font_size("font_size", "LabelHeading", 22)
	t.set_type_variation("LabelCaps", "Label")
	t.set_font("font", "LabelCaps", display_font(600, 2))
	t.set_color("font_color", "LabelCaps", Pal.BRASS)
	t.set_font_size("font_size", "LabelCaps", 14)
	# Buttons
	t.set_font("font", "Button", display_font(700, 1))
	t.set_font_size("font_size", "Button", 17)
	t.set_color("font_color", "Button", Pal.PARCHMENT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Pal.BRASS_HI)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("6f6350"))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.5))
	t.set_constant("outline_size", "Button", 2)
	t.set_constant("h_separation", "Button", 8)
	for variation: String in ["", "Primary", "Quiet", "Tab", "Icon", "Danger"]:
		var type_name: String = "Button" if variation == "" else "Button" + variation
		if variation != "":
			t.set_type_variation(type_name, "Button")
		var pad := Vector2(22, 11)
		if variation == "Tab":
			pad = Vector2(16, 7)
		elif variation == "Icon":
			pad = Vector2(9, 9)
		elif variation == "Quiet":
			pad = Vector2(12, 6)
		var base_variation: String = "" if variation == "Icon" else variation
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			t.set_stylebox(state, type_name, plaque(state, base_variation, pad))
		if variation == "Primary":
			t.set_color("font_color", type_name, Color("2b1d0c"))
			t.set_color("font_hover_color", type_name, Color("1b1207"))
			t.set_color("font_pressed_color", type_name, Color("2b1d0c"))
			t.set_color("font_outline_color", type_name, Color(1, 1, 1, 0.0))
			t.set_color("font_focus_color", type_name, Color("2b1d0c"))
		elif variation == "Tab":
			t.set_font_size("font_size", type_name, 15)
			t.set_color("font_color", type_name, Pal.PARCH_DIM)
			t.set_color("font_pressed_color", type_name, Pal.BRASS_HI)
			t.set_color("font_hover_color", type_name, Pal.PARCHMENT)
		elif variation == "Quiet":
			t.set_color("font_color", type_name, Pal.PARCH_DIM)
			t.set_font_size("font_size", type_name, 15)
	# Panels
	t.set_stylebox("panel", "PanelContainer", panel("panel"))
	t.set_stylebox("panel", "Panel", panel("panel"))
	for kind: String in ["inset", "pill", "card", "scrim", "drawer"]:
		var type_name: String = "Panel" + kind.capitalize()
		t.set_type_variation(type_name, "PanelContainer")
		t.set_stylebox("panel", type_name, panel(kind))
	# Text input
	t.set_stylebox("normal", "LineEdit", panel("inset"))
	var focused := panel("inset")
	focused.border = Pal.BRASS
	focused.border_width = 1.5
	t.set_stylebox("focus", "LineEdit", focused)
	t.set_stylebox("read_only", "LineEdit", panel("inset"))
	t.set_color("font_color", "LineEdit", Pal.PARCHMENT)
	t.set_color("caret_color", "LineEdit", Pal.BRASS_HI)
	t.set_color("selection_color", "LineEdit", Color(0.84, 0.65, 0.29, 0.35))
	t.set_font("font", "LineEdit", body_font(600))
	t.set_font_size("font_size", "LineEdit", 20)
	t.set_stylebox("normal", "TextEdit", panel("inset"))
	t.set_stylebox("focus", "TextEdit", focused)
	t.set_stylebox("read_only", "TextEdit", panel("inset"))
	t.set_color("font_color", "TextEdit", Pal.PARCHMENT)
	t.set_color("font_readonly_color", "TextEdit", Pal.TEAL)
	# Scroll bars: a thin brass grabber on a dark groove
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(0, 0, 0, 0.28)
	groove.set_corner_radius_all(4)
	groove.content_margin_left = 3
	groove.content_margin_right = 3
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.55, 0.42, 0.2, 0.9)
	grabber.set_corner_radius_all(4)
	var grabber_hot := grabber.duplicate() as StyleBoxFlat
	grabber_hot.bg_color = Pal.BRASS
	for bar: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, groove)
		t.set_stylebox("grabber", bar, grabber)
		t.set_stylebox("grabber_highlight", bar, grabber_hot)
		t.set_stylebox("grabber_pressed", bar, grabber_hot)
	# Sliders
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.06, 0.045, 0.03)
	track.set_corner_radius_all(4)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	track.border_color = Color(0.55, 0.42, 0.2, 0.6)
	track.set_border_width_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Pal.BRASS_LO
	fill.set_corner_radius_all(4)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _knob(false))
	t.set_icon("grabber_highlight", "HSlider", _knob(true))
	t.set_icon("grabber_disabled", "HSlider", _knob(false))
	# Tooltips
	var tooltip := panel("pill")
	t.set_stylebox("panel", "TooltipPanel", tooltip)
	t.set_color("font_color", "TooltipLabel", Pal.PARCHMENT)
	t.set_font_size("font_size", "TooltipLabel", 16)
	# Rich text and code editor surfaces
	t.set_color("default_color", "RichTextLabel", Pal.PARCHMENT)
	t.set_font("normal_font", "RichTextLabel", body_font(500))
	t.set_font("bold_font", "RichTextLabel", body_font(800))
	t.set_font("mono_font", "RichTextLabel", MONO)
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	t.set_font_size("mono_font_size", "RichTextLabel", 17)
	return t


static func _knob(hot: bool) -> ImageTexture:
	var image := Image.create(22, 22, false, Image.FORMAT_RGBA8)
	var center := Vector2(10.5, 10.5)
	for y: int in range(22):
		for x: int in range(22):
			var distance: float = Vector2(float(x), float(y)).distance_to(center)
			if distance <= 9.5:
				var shade: float = clampf((float(y) - 2.0) / 18.0, 0.0, 1.0)
				var base: Color = Pal.BRASS_HI.lerp(Pal.BRASS_LO, shade)
				if hot:
					base = base.lightened(0.15)
				if distance > 8.2:
					base = Color("3a2a12")
				image.set_pixel(x, y, base)
			elif distance <= 10.5:
				image.set_pixel(x, y, Color(0, 0, 0, 0.35 * (10.5 - distance)))
	return ImageTexture.create_from_image(image)
