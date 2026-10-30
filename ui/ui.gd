class_name UI
extends RefCounted
## Small factories so screens read as layout, not styling.


static func label(text: String, variation: StringName = &"", font_size: int = 0, color: Color = Color(0, 0, 0, 0)) -> Label:
	var node := Label.new()
	node.text = text
	node.theme_type_variation = variation
	if font_size > 0:
		node.add_theme_font_size_override("font_size", font_size)
	if color.a > 0.0:
		node.add_theme_color_override("font_color", color)
	return node


static func heading(text: String, font_size: int = 22) -> Label:
	return label(text, &"LabelHeading", font_size)


static func caps(text: String, color: Color = Color(0, 0, 0, 0)) -> Label:
	return label(text.to_upper(), &"LabelCaps", 0, color)


static func dim(text: String, font_size: int = 16) -> Label:
	var node := label(text, &"LabelDim", font_size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return node


static func button(text: String, icon: StringName = &"", variation: StringName = &"", action: Callable = Callable()) -> FButton:
	var node := FButton.make(text, icon, variation)
	if action.is_valid():
		node.pressed.connect(action)
	return node


static func icon_button(icon: StringName, tip: String, action: Callable = Callable()) -> FButton:
	var node := FButton.make("", icon, &"ButtonIcon")
	node.custom_minimum_size = Vector2(30, 30)
	node.tooltip_text = tip
	if action.is_valid():
		node.pressed.connect(action)
	return node


static func panel(variation: StringName = &"") -> PanelContainer:
	var node := PanelContainer.new()
	node.theme_type_variation = variation
	return node


static func rule() -> Ornament:
	return Ornament.new()


static func spacer(vertical: float = 0.0, expand: bool = false) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, vertical)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func margin(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var node := MarginContainer.new()
	node.add_theme_constant_override("margin_left", left)
	node.add_theme_constant_override("margin_top", top)
	node.add_theme_constant_override("margin_right", right)
	node.add_theme_constant_override("margin_bottom", bottom)
	node.add_child(child)
	return node


static func vbox(gap: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	return node


static func hbox(gap: int = 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", gap)
	return node


static func fill(node: Control) -> Control:
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func full_rect(node: Control) -> Control:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return node
