class_name PauseMenu
extends Modal
## The Escape menu. It never loses progress: leaving for the title saves first.

signal resume_requested
signal journal_requested
signal map_requested
signal character_requested
signal settings_requested
signal reset_requested
signal title_requested
signal quit_requested

var _first: FButton


func setup(player_name: String, place: String, indoors: bool = false, journey: String = "Kindle Hollow") -> void:
	card.custom_minimum_size = Vector2(440, 0)
	body.add_child(UI.caps(journey, Pal.BRASS))
	body.add_child(UI.heading("Paused", 36))
	body.add_child(UI.dim("%s · %s" % [player_name, place], 18))
	body.add_child(UI.rule())
	_first = _add("Resume", &"play", &"ButtonPrimary", resume_requested)
	_add("Journal", &"scroll", &"", journal_requested)
	_add("Map", &"map", &"", map_requested)
	_add("Character", &"person", &"", character_requested)
	_add("Settings", &"gear", &"", settings_requested)
	body.add_child(UI.spacer(4))
	_add("Reset this room" if indoors else ("Start the hollow over" if journey=="Kindle Hollow" else "Reset this area"), &"reset", &"", reset_requested)
	_add("Save and return to title", &"door", &"", title_requested)
	_add("Quit game", &"cross", &"ButtonDanger", quit_requested)


func open() -> void:
	super.open()
	_first.grab_focus()


func _add(text: String, icon: StringName, variation: StringName, request: Signal) -> FButton:
	var button := UI.button(text, icon, variation, func() -> void: request.emit())
	button.custom_minimum_size.y = 50
	body.add_child(button)
	return button
