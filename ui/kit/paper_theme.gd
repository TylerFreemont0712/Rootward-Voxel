class_name PaperTheme
extends RefCounted
## The Sparks & Machines interface theme, built in code like UITheme and using the same variation names
## (LabelHeading, ButtonPrimary, PanelPill, …) so shared UI helpers pick it up. Set it on that journey's own
## nodes only; the rest of the game keeps UITheme. Fonts: Spectral (provisional display face, OFL), Alegreya
## for reading and IBM Plex Mono for code. Buttons are enamel signs: cream (default), teal (Primary), red (Stamp).

const SPECTRAL: Font = preload("res://ui/fonts/spectral-600.ttf")

static var _theme: Theme
static var _fonts: Dictionary = {}


static func theme() -> Theme:
	if _theme == null:
		_theme = _build()
	return _theme


static func display_font(spacing: int = 0) -> Font:
	var key: String = "display%d" % spacing
	if not _fonts.has(key):
		var font := FontVariation.new()
		font.base_font = SPECTRAL
		font.spacing_glyph = spacing
		_fonts[key] = font
	return _fonts[key]


## Alegreya leaning a little, for handwriting-like notes; Alegreya has no italic file here.
static func slanted_font(weight: int = 500) -> Font:
	var key: String = "slant%d" % weight
	if not _fonts.has(key):
		var font := FontVariation.new()
		font.base_font = UITheme.ALEGREYA
		font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("weight"): weight}
		font.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
		_fonts[key] = font
	return _fonts[key]


## The enamel colour of each button look and state: [fill, rim, text].
static func enamel(variation: String, state: StringName) -> Array[Color]:
	var colors: Dictionary = {
		"": [PaperPal.CREAM, PaperPal.TEAL_DEEP, PaperPal.INK],
		"Primary": [PaperPal.TEAL, PaperPal.TEAL_DEEP, PaperPal.CREAM_HI],
		"Stamp": [PaperPal.RED, PaperPal.RED_DEEP, PaperPal.CREAM_HI],
		"Danger": [PaperPal.RED, PaperPal.RED_DEEP, PaperPal.CREAM_HI],
	}
	var base: Array = colors.get(variation, colors[""])
	var fill: Color = base[0]
	var rim: Color = base[1]
	var text: Color = base[2]
	match state:
		&"hover":
			fill = PaperPal.TEAL_HI if variation == "" else fill.lightened(0.12)
			text = PaperPal.INK if variation == "" else text
		&"pressed":
			fill = PaperPal.TEAL_DEEP if variation == "" else rim
			text = PaperPal.CREAM_HI
		&"disabled":
			fill = PaperPal.DISABLED
			rim = Color(PaperPal.PENCIL, 0.7)
			text = Color(PaperPal.INK_SOFT, 0.55)
	return [fill, rim, text]


static func button_box(variation: String, state: StringName, pad: Vector2) -> StyleBox:
	if variation == "Quiet" or variation == "Tab":
		var flat := PaperBox.make({"kind": &"card", "fill": Color(0, 0, 0, 0), "rim": Color(0, 0, 0, 0), "shadow": 0.0, "radius": 5.0}, pad)
		if state == &"hover":
			flat.fill = Color(PaperPal.TEAL, 0.10)
		elif state == &"pressed":
			flat.fill = Color(PaperPal.TEAL, 0.18)
			if variation == "Tab":
				flat.rim = PaperPal.TEAL_DEEP
				flat.rim_width = 1.5
		return flat
	if state == &"focus":
		return PaperBox.make({"kind": &"enamel", "fill": Color(0, 0, 0, 0), "rim": PaperPal.BRASS, "rim_width": 2.0, "shadow": 0.0, "radius": 14.0}, pad)
	var colors: Array[Color] = enamel(variation, state)
	return PaperBox.make({"kind": &"enamel", "fill": colors[0], "rim": colors[1], "rim_width": 2.0,
		"shadow": 0.0 if state == &"pressed" else 2.5, "radius": 14.0, "rivets": variation != "Icon"}, pad)


static func panel(kind: String) -> PaperBox:
	match kind:
		"inset":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER_HI, "rim": PaperPal.EDGE, "shadow": 0.0, "radius": 4.0}, Vector2(10, 8))
		"pill":
			return PaperBox.make({"kind": &"enamel", "fill": PaperPal.CREAM, "rim": PaperPal.TEAL_DEEP, "rim_width": 2.0, "shadow": 2.5, "radius": 12.0, "rivets": true}, Vector2(26, 7))
		"card":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER, "rim": PaperPal.EDGE, "shadow": 2.0, "radius": 5.0}, Vector2(14, 12))
		"scrim":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER, "rim": PaperPal.EDGE, "rim_width": 1.5, "shadow": 6.0, "radius": 8.0}, Vector2(30, 24))
		"drawer":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER, "rim": PaperPal.EDGE, "rim_width": 1.5, "shadow": 4.0, "radius": 6.0}, Vector2(18, 14))
		"quest":
			return PaperBox.make({"kind": &"ticket", "fill": PaperPal.PAPER_HI, "rim": PaperPal.EDGE, "shadow": 3.0, "radius": 0.0, "pin": true}, Vector2(20, 12))
		"test":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER_HI, "rim": PaperPal.TEAL, "shadow": 3.0, "radius": 5.0}, Vector2(12, 10))
		"graph":
			return PaperBox.make({"kind": &"card", "fill": PaperPal.PAPER_HI, "rim": PaperPal.EDGE, "shadow": 0.0, "radius": 3.0, "grid": 18.0}, Vector2(12, 10))
		"tape":
			return PaperBox.make({"kind": &"tape", "fill": PaperPal.CREAM_HI, "rim": Color(PaperPal.EDGE, 0.8), "shadow": 1.5, "radius": 2.0}, Vector2(16, 12))
	return PaperBox.make({"kind": &"card"})


static func _build() -> Theme:
	var t := Theme.new()
	t.default_font = UITheme.body_font(500)
	t.default_font_size = 16
	t.set_color("font_color", "Label", PaperPal.INK)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	t.set_type_variation("LabelDim", "Label")
	t.set_color("font_color", "LabelDim", PaperPal.INK_SOFT)
	t.set_type_variation("LabelHeading", "Label")
	t.set_font("font", "LabelHeading", display_font(0))
	t.set_color("font_color", "LabelHeading", PaperPal.INK)
	t.set_font_size("font_size", "LabelHeading", 22)
	t.set_type_variation("LabelCaps", "Label")
	t.set_font("font", "LabelCaps", display_font(2))
	t.set_color("font_color", "LabelCaps", PaperPal.TEAL_DEEP)
	t.set_font_size("font_size", "LabelCaps", 12)
	t.set_font("font", "Button", display_font(0))
	t.set_font_size("font_size", "Button", 15)
	t.set_constant("outline_size", "Button", 0)
	t.set_constant("h_separation", "Button", 8)
	for variation: String in ["", "Primary", "Stamp", "Quiet", "Tab", "Icon", "Danger"]:
		var type_name: String = "Button" if variation == "" else "Button" + variation
		if variation != "":
			t.set_type_variation(type_name, "Button")
		var pad := Vector2(26, 7)
		if variation == "Tab":
			pad = Vector2(10, 4)
		elif variation == "Icon":
			pad = Vector2(7, 6)
		elif variation == "Quiet":
			pad = Vector2(8, 4)
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			t.set_stylebox(state, type_name, button_box(variation, state, pad))
		if variation in ["Quiet", "Tab"]:
			t.set_color("font_color", type_name, PaperPal.INK_SOFT)
			t.set_color("font_hover_color", type_name, PaperPal.INK)
			t.set_color("font_pressed_color", type_name, PaperPal.TEAL_DEEP)
			t.set_color("font_focus_color", type_name, PaperPal.INK)
			t.set_color("font_disabled_color", type_name, PaperPal.PENCIL)
		else:
			var lookup: String = "" if variation == "Icon" else variation
			t.set_color("font_color", type_name, enamel(lookup, &"normal")[2])
			t.set_color("font_hover_color", type_name, enamel(lookup, &"hover")[2])
			t.set_color("font_pressed_color", type_name, enamel(lookup, &"pressed")[2])
			t.set_color("font_focus_color", type_name, enamel(lookup, &"normal")[2])
			t.set_color("font_disabled_color", type_name, enamel(lookup, &"disabled")[2])
	t.set_stylebox("panel", "PanelContainer", panel("card"))
	t.set_stylebox("panel", "Panel", panel("card"))
	for kind: String in ["inset", "pill", "card", "scrim", "drawer", "quest", "test", "graph", "tape"]:
		var type_name: String = "Panel" + kind.capitalize()
		t.set_type_variation(type_name, "PanelContainer")
		t.set_stylebox("panel", type_name, panel(kind))
	var field := panel("inset")
	var focused := panel("inset")
	focused.rim = PaperPal.TEAL
	focused.rim_width = 1.5
	for control: String in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", control, field)
		t.set_stylebox("focus", control, focused)
		t.set_stylebox("read_only", control, field)
		t.set_color("font_color", control, PaperPal.INK)
		t.set_color("caret_color", control, PaperPal.TEAL_DEEP)
		t.set_color("selection_color", control, Color(PaperPal.TEAL, 0.25))
	t.set_color("font_readonly_color", "TextEdit", PaperPal.INK_SOFT)
	t.set_font("font", "LineEdit", UITheme.body_font(600))
	var groove := StyleBoxFlat.new()
	groove.bg_color = Color(PaperPal.EDGE, 0.35)
	groove.set_corner_radius_all(4)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(PaperPal.TEAL, 0.75)
	grabber.set_corner_radius_all(4)
	var grabber_hot := grabber.duplicate() as StyleBoxFlat
	grabber_hot.bg_color = PaperPal.TEAL_DEEP
	for bar: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", bar, groove)
		t.set_stylebox("grabber", bar, grabber)
		t.set_stylebox("grabber_highlight", bar, grabber_hot)
		t.set_stylebox("grabber_pressed", bar, grabber_hot)
	t.set_stylebox("panel", "TooltipPanel", panel("card"))
	t.set_color("font_color", "TooltipLabel", PaperPal.INK)
	t.set_color("default_color", "RichTextLabel", PaperPal.INK)
	t.set_font("normal_font", "RichTextLabel", UITheme.body_font(500))
	t.set_font("bold_font", "RichTextLabel", UITheme.body_font(800))
	t.set_font("italics_font", "RichTextLabel", slanted_font(500))
	t.set_font("mono_font", "RichTextLabel", UITheme.MONO)
	for size_name: String in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		t.set_font_size(size_name, "RichTextLabel", 17)
	t.set_font_size("mono_font_size", "RichTextLabel", 15)
	return t
