class_name WorldView
extends VBoxContainer
## The World tab: what your program can see right now, in readable form, with the raw data one click away.

var _summary: RichTextLabel
var _raw: TextEdit
var _toggle: Toggle


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.scroll_following = false
	_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary.add_theme_stylebox_override("normal", UITheme.panel("inset"))
	add_child(_summary)
	_raw = TextEdit.new()
	_raw.editable = false
	_raw.visible = false
	_raw.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_raw.add_theme_font_override("font", UITheme.mono_font())
	_raw.add_theme_font_size_override("font_size", 15)
	_raw.add_theme_color_override("font_readonly_color", Pal.TEAL)
	add_child(_raw)
	_toggle = Toggle.make("Show the raw data", false)
	_toggle.toggled.connect(func(on: bool) -> void:
		_raw.visible = on
		_summary.visible = not on)
	add_child(_toggle)


func refresh(snapshot: Dictionary) -> void:
	if _summary == null:
		return
	var lines: PackedStringArray = []
	var player: Array = snapshot.player
	lines.append("[b][color=#f4d186]You[/color][/b]  standing at [code][%d, %d, 0][/code]%s" % [player[0], player[1], _here(snapshot)])
	lines.append("[color=#b9aa8b]Your program only sees places you have visited. Walk somewhere new to reveal it.[/color]")
	var build: Dictionary = snapshot.get("build", {})
	var working: Dictionary = {}
	for prop: Dictionary in snapshot.get("props", []):
		working[prop.id] = true
	for zone: Dictionary in snapshot.zones:
		lines.append("")
		lines.append("[b][color=#f4d186]%s[/color][/b]  [color=#7f725c]world.zone(\"%s\")[/color]" % [zone.title, zone.id])
		for lamp: Dictionary in snapshot.lamps:
			if lamp.zone == zone.id:
				lines.append("   %s  [code]%s[/code]  [color=#7f725c]%s[/color]" % ["[color=#f4d186]● lit[/color]" if lamp.lit else "[color=#7f725c]○ dark[/color]", lamp.id, str(lamp.cell)])
		for gate: Dictionary in snapshot.gates:
			if gate.zone == zone.id:
				lines.append("   gate  [code]%s[/code]  %s" % [gate.id, "[color=#97d474]open[/color]" if gate.open else "[color=#e88a79]shut[/color]"])
		for bridge: Dictionary in snapshot.bridges:
			if bridge.zone == zone.id:
				lines.append("   bridge  [code]%s[/code]  %d of %d decks down" % [bridge.id, bridge.built, bridge.cells.size()])
		for prop: Dictionary in snapshot.get("props", []):
			if prop.zone == zone.id:
				lines.append("   [code]%s[/code]  %s · %s" % [prop.id, prop.name, "active" if prop.active else "inactive"])
		lines.append_array(_structures(build, zone.id, working, "   "))
	for prop: Dictionary in snapshot.get("props", []):
		if prop.zone == "":
			lines.append("   nearby  [code]%s[/code]  %s · %s" % [prop.id, prop.name, "active" if prop.active else "inactive"])
	var between: PackedStringArray = _structures(build, "", working, "   nearby  ")
	if not between.is_empty():
		lines.append("")
		lines.append("[b][color=#f4d186]Between places[/color][/b]  [color=#7f725c]within reach of you[/color]")
		lines.append_array(between)
	var lessons: Dictionary = build.get("lessons", {})
	if lessons.has("read") and not (build.get("abilities", []) as Array).has("read"):
		lines.append("")
		lines.append("[color=#7f725c]Houses, trees and doodads appear here once you reach the lesson \"%s\".[/color]" % str(lessons.read))
	if (snapshot.memory as Dictionary).size() > 0:
		lines.append("")
		lines.append("[b][color=#f4d186]Memory[/color][/b]  [code]%s[/code]" % JSON.stringify(snapshot.memory))
	_summary.text = "\n".join(lines)
	_raw.text = JSON.stringify(snapshot, "  ")


## The houses, doodads and trees in one place (or between places, with an empty id), in readable lines.
func _structures(build: Dictionary, zone_id: String, working: Dictionary, indent: String) -> PackedStringArray:
	var lines: PackedStringArray = []
	for house: Dictionary in build.get("houses", []):
		if house.zone == zone_id:
			lines.append("%shouse  [code]%s[/code]  %s · faces %s%s" % [indent, house.id, house.name, house.facing, " · locked" if house.locked else ""])
	for doodad: Dictionary in build.get("doodads", []):
		if doodad.zone == zone_id and not working.has(doodad.id):
			lines.append("%sdoodad  [code]%s[/code]  %s · faces %s" % [indent, doodad.id, doodad.name, doodad.facing])
	var trees: int = 0
	for tree: Dictionary in build.get("trees", []):
		if tree.zone == zone_id:
			trees += 1
	if trees > 0:
		lines.append("%s%d %s  [color=#7f725c]%s[/color]" % [indent, trees, "tree" if trees == 1 else "trees", ("world.zone(\"%s\").trees" % zone_id) if zone_id != "" else "world.trees"])
	return lines


func _here(snapshot: Dictionary) -> String:
	for zone: Dictionary in snapshot.zones:
		if zone.id == snapshot.zone:
			return " in [b]%s[/b]" % zone.title
	return ""
