class_name EpilogueScreen
extends Modal
## Shown once the main arc is done: what the player built, and what they learned. `next` is the lesson that is
## waiting in the journal now (a later, optional chapter), or {}.

signal title_requested


func setup(area: AreaDef, stats: Dictionary, player_name: String, next: Dictionary = {}) -> void:
	card.custom_minimum_size = Vector2(700, 0)
	body.add_child(UI.caps("Kindle Hollow", Pal.GREEN))
	body.add_child(UI.heading("The hollow is lit", 40))
	body.add_child(UI.rule())
	var story := UI.dim("Every lantern burns, the bridge is up and the gate stands open. %s, the old lamplighter's apprentice, has lit a whole valley by writing code." % player_name, 21)
	story.add_theme_color_override("font_color", Pal.PARCHMENT)
	body.add_child(story)
	body.add_child(UI.caps("What you learned", Pal.VIOLET))
	for quest: Dictionary in Quests.main(area):
		var row := UI.hbox(10)
		var mark := Glyph.new()
		mark.kind = &"check"
		mark.color = Pal.GREEN
		mark.custom_minimum_size = Vector2(22, 22)
		row.add_child(mark)
		row.add_child(UI.label(str(quest.concept), &"", 21))
		body.add_child(row)
	body.add_child(UI.dim("%d programs run · %d changes applied. The notebook stays open: put the lamps out, rebuild the bridge, or write something new." % [int(stats.get("runs", 0)), int(stats.get("applies", 0))], 17))
	if not next.is_empty():
		var more := UI.dim("There is more to learn. A second chapter has opened in your journal (J): \"%s\". It is optional: take it when you like." % str(next.title), 18)
		more.add_theme_color_override("font_color", Pal.BRASS_HI)
		body.add_child(more)
	body.add_child(UI.rule())
	var buttons := UI.hbox(12)
	var back := UI.button("Return to title", &"door", &"", func() -> void:
		close()
		title_requested.emit())
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(back)
	var go_on := UI.button("Keep exploring", &"play", &"ButtonPrimary", close)
	go_on.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(go_on)
	body.add_child(buttons)
	go_on.grab_focus.call_deferred()
