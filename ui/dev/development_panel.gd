class_name DevelopmentPanel
extends Modal
signal checkpoint_requested(id: String)
signal solution_requested
signal finish_requested
signal normal_requested
signal power_preview_requested(power: Dictionary)
signal hour_requested(hour: float)
signal pressure_requested(pressure: float)
signal breaker_reset_requested

func setup(game: Game) -> void:
	theme = PaperTheme.theme()
	card.custom_minimum_size.x = 600
	card.remove_child(body)
	var scroller:=ScrollContainer.new()
	scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroller.custom_minimum_size=Vector2(600,minf(640,game.get_viewport().get_visible_rect().size.y-100))
	card.add_child(scroller)
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroller.add_child(body)
	title_row("Dev mode", "Chapter checkpoints and reference routines · F8")
	body.add_child(UI.dim("Checkpoints use a separate development save. Return to title for your regular Continue.", 16))
	for chapter: Dictionary in game._story.get("chapters", []):
		var row := UI.hbox(12)
		row.add_child(UI.fill(UI.label("%s · %s" % [chapter.id, chapter.title], &"LabelHeading", 20)))
		row.add_child(UI.button("Start", &"", &"", func() -> void: checkpoint_requested.emit(str(chapter.start))))
		row.add_child(UI.button("End", &"", &"", func() -> void: checkpoint_requested.emit(str(chapter.end))))
		body.add_child(row)
	var places := UI.hbox(12)
	for id: String in ["lane", "square", "city-hall"]:
		places.add_child(UI.button({"lane":"Spindle Lane","square":"Rootward Square","city-hall":"City Hall"}[id], &"", &"", func() -> void: checkpoint_requested.emit(id)))
	body.add_child(places)
	body.add_child(UI.rule())
	var quest: Dictionary = DevelopmentMode.current_code_job(game)
	body.add_child(UI.label("Current job · " + str(quest.get("title", "Exploring")), &"LabelHeading", 20))
	var actions := UI.hbox(12)
	var fill := UI.button("Fill reference code", &"code", &"", func() -> void: solution_requested.emit())
	fill.disabled = not DevelopmentMode.catalog().get("solutions", {}).has(quest.get("id", ""))
	actions.add_child(fill)
	var finish := UI.button("Finish current job", &"check", &"ButtonPrimary", func() -> void: finish_requested.emit())
	finish.disabled = quest.is_empty()
	actions.add_child(finish)
	body.add_child(actions)
	body.add_child(UI.dim("Fill opens the correct terminal or fitting. Finish runs and applies its reference code, or reads the current ticket.", 16))
	body.add_child(UI.rule())
	body.add_child(UI.label("Shared clock and city supply", &"LabelHeading", 20))
	var clock_row := UI.hbox(8)
	for phase: Dictionary in [{"name":"Morning","hour":8.0},{"name":"Day","hour":12.0},{"name":"Evening","hour":19.25},{"name":"Night","hour":22.0}]:
		clock_row.add_child(UI.button(str(phase.name),&"",&"",func()->void:hour_requested.emit(float(phase.hour))))
	body.add_child(clock_row)
	var supply_row := UI.hbox(8)
	for pressure: float in [5.6,8.5,9.5,12.0,15.0]:
		supply_row.add_child(UI.button("%.1f"%pressure,&"",&"",func()->void:pressure_requested.emit(pressure)))
	supply_row.add_child(UI.button("Reset breaker",&"",&"",func()->void:breaker_reset_requested.emit()))
	body.add_child(supply_row)
	var power_row := UI.hbox(12)
	for preset: Dictionary in [
		{"label":"Low power", "pressure":1.6,"strength":.16, "stability":.25, "restored_links":0},
		{"label":"Steady", "pressure":5.6,"strength":.56, "stability":1.0, "restored_links":1},
		{"label":"Overpressure", "pressure":12.0,"strength":1.0, "stability":1.0, "restored_links":3}]:
		power_row.add_child(UI.button(str(preset.label), &"", &"", func() -> void: power_preview_requested.emit(preset.duplicate(true))))
	body.add_child(power_row)
	body.add_child(UI.dim("Clock and pressure buttons change the isolated development save. At 15, the supply trips. Reset breaker explicitly restores it. Loading studies below only preview the artwork.", 15))
	var footer := UI.hbox(12)
	if SaveStore.development:
		footer.add_child(UI.button("Return to regular game", &"", &"", func() -> void: normal_requested.emit()))
	footer.add_child(UI.button("Back", &"", &"ButtonQuiet", close))
	body.add_child(footer)
