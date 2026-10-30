class_name NellNote
extends Modal
## The desk note is read in the room and only put away deliberately.
signal read

func setup(note: Dictionary) -> void:
	theme = PaperTheme.theme()
	_scrim.color.a = .12
	var center: Node = card.get_parent()
	card.reparent(self)
	center.queue_free()
	card.theme_type_variation = &"PanelCard"
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.offset_right = -24
	card.offset_left = -610
	card.offset_top = -245
	card.offset_bottom = 245
	body.add_child(UI.label("A NOTE FROM NELL", &"LabelCaps", 14, PaperPal.RED))
	body.add_child(OpeningCard._make_note(note))
	body.add_child(UI.button("Put the note away", &"check", &"ButtonPrimary", func() -> void:
		read.emit()
		close()))
