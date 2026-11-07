class_name RoomFinishes
extends Modal
## Appearance-only room finishing. Furniture layout and collision stay in the authored room document.

signal finish_chosen(slot: String, material: String)
signal undo_requested
signal redo_requested

var _rows: VBoxContainer
var _undo: FButton
var _redo: FButton
var _note: Label


func setup(area: AreaDef, ledger: BuildLedger) -> void:
	card.custom_minimum_size = Vector2(620, 0)
	title_row("Room materials", "Choose finishes for this home. Each house remembers its own look.")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size.y = 350
	body.add_child(scroll)
	_rows = UI.vbox(10)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	_note = UI.dim("", 17)
	body.add_child(_note)
	var actions := UI.hbox(8)
	_undo = UI.button("Undo", &"undo", &"", func() -> void: undo_requested.emit())
	_redo = UI.button("Redo", &"redo", &"", func() -> void: redo_requested.emit())
	actions.add_child(_undo)
	actions.add_child(_redo)
	actions.add_child(UI.spacer(0, true))
	actions.add_child(UI.button("Done", &"check", &"ButtonPrimary", close))
	body.add_child(actions)
	refresh(area, ledger)


func refresh(area: AreaDef, ledger: BuildLedger, message: String = "") -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for slot: String in SurfaceFinishes.ROOM_SLOTS:
		var row := UI.hbox(16)
		var label := UI.label(str(SurfaceFinishes.TITLES[slot]), &"", 20)
		label.custom_minimum_size.x = 100
		row.add_child(label)
		var choice := OptionButton.new()
		choice.name = "Finish_" + slot
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.custom_minimum_size.y = 44
		choice.add_theme_constant_override("icon_max_width", 30)
		var original: String = str((area.interior.get("materials", {}) as Dictionary).get(slot, ""))
		choice.add_item("Original" + (" · " + FinishMaterials.title(original) if original != "" else ""))
		choice.set_item_metadata(0, "")
		for id: String in SurfaceFinishes.OPTIONS[SurfaceFinishes.ROOM_SLOTS[slot]]:
			choice.add_icon_item(WorldTextures.texture(id), FinishMaterials.title(id))
			choice.set_item_metadata(choice.item_count - 1, id)
			if (area.interior.get("finishes", {}) as Dictionary).get(slot) == id:
				choice.select(choice.item_count - 1)
		choice.item_selected.connect(func(index: int) -> void: finish_chosen.emit(slot, str(choice.get_item_metadata(index))))
		row.add_child(choice)
		_rows.add_child(row)
	_undo.disabled = not ledger.can_undo()
	_redo.disabled = not ledger.can_redo()
	_note.text = message if message != "" else "Finishes change appearance. Your furniture, walking space and notebook stay where they are."
