class_name Modal
extends Control
## A dimmed full-screen layer holding one centered plaque. Subclasses fill `body`. Escape closes it.

signal closed

var body: VBoxContainer
var card: PanelContainer
var _scrim: ColorRect


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_scrim = ColorRect.new()
	_scrim.color = Color(0.03, 0.02, 0.015, 0.62)
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_scrim)
	add_child(_scrim)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(center)
	add_child(center)
	card = UI.panel(&"PanelScrim")
	center.add_child(card)
	body = UI.vbox(12)
	card.add_child(body)


func open() -> void:
	modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	card.pivot_offset = card.size * 0.5
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(card, "scale", Vector2.ONE, 0.18)


func close() -> void:
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()


func title_row(title: String, subtitle: String = "") -> void:
	body.add_child(UI.heading(title, 32))
	if subtitle != "":
		body.add_child(UI.dim(subtitle, 18))
	body.add_child(UI.rule())
