class_name MapPanel
extends Modal
## The map screen: the isometric chart plus a legend. Fog hides places you have not visited yet.


func setup(session: GameSession) -> void:
	title_row("Kindle Hollow", "Dim places are unexplored. Walk into them to reveal them, and your notebook will be able to reach what is there.")
	var frame := UI.panel(&"PanelInset")
	body.add_child(frame)
	var map := MapView.new()
	map.setup(session.area)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(map.custom_minimum_size.x + 20.0, map.custom_minimum_size.y + 10.0)
	frame.add_child(holder)
	holder.add_child(map)
	var focus: Variant = null
	var quest: Dictionary = session.current_quest()
	if not quest.is_empty() and not (quest.focus as Dictionary).is_empty():
		focus = Vector2(float(quest.focus.at[0]), float(quest.focus.at[1]))
	map.refresh(session.state, focus)
	var legend := UI.hbox(26)
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	for entry: Array in [["You", Color("ff7b4a")], ["Lamp lit", Pal.BRASS_HI], ["Lamp dark", Color("8c7a5b")], ["Current quest", Pal.GREEN], ["Gate shut", Color("e88a79")]]:
		var item := UI.hbox(8)
		var dot := Glyph.new()
		dot.kind = &"dot"
		dot.color = entry[1]
		dot.custom_minimum_size = Vector2(18, 18)
		item.add_child(dot)
		item.add_child(UI.label(String(entry[0]), &"LabelDim", 16))
		legend.add_child(item)
	body.add_child(legend)
	body.add_child(UI.rule())
	var done := UI.button("Close", &"check", &"ButtonPrimary", close)
	body.add_child(done)
