class_name ConfirmDialog
extends Modal
## A yes/no question. `confirmed` fires only on the confirm button; Escape or Cancel just closes.

signal confirmed


func ask(title: String, text: String, confirm_label: String, danger: bool = false) -> void:
	card.custom_minimum_size = Vector2(500, 0)
	body.add_child(UI.heading(title, 28))
	var message := UI.dim(text, 19)
	message.add_theme_color_override("font_color", Pal.PARCHMENT)
	body.add_child(message)
	body.add_child(UI.rule())
	var row := UI.hbox(12)
	var cancel := UI.button("Cancel", &"cross", &"", close)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cancel)
	var ok := UI.button(confirm_label, &"check", &"ButtonDanger" if danger else &"ButtonPrimary", func() -> void:
		confirmed.emit()
		close())
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	body.add_child(row)
	cancel.grab_focus.call_deferred()
