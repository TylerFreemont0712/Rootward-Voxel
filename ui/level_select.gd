class_name LevelSelect
extends Modal

signal chosen(level: String, resume: bool)

func setup() -> void:
	card.custom_minimum_size = Vector2(760,0)
	title_row("Choose a journey", "Each level keeps its own progress. These are different beginnings in the same world of code.")
	for entry: Dictionary in LevelStore.available_entries():
		var panel := UI.panel(&"PanelInset")
		var content := UI.vbox(8)
		panel.add_child(content)
		content.add_child(UI.caps(entry.subtitle, Pal.BRASS))
		content.add_child(UI.heading(entry.title,28))
		content.add_child(UI.dim(entry.description,19))
		var row := UI.hbox(12)
		row.add_child(UI.button("Begin new journey", &"star", &"ButtonPrimary", func() -> void:
			close()
			chosen.emit(entry.id,false)))
		if SaveStore.has_save(entry.id):
			row.add_child(UI.button("Continue this journey", &"play", &"", func() -> void:
				close()
				chosen.emit(entry.id,true)))
		content.add_child(row)
		body.add_child(panel)
	body.add_child(UI.button("Back", &"cross", &"", close))
