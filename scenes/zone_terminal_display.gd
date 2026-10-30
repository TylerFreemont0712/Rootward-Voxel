class_name ZoneTerminalDisplay
extends Node3D
## Glass lettering and connection lamps on the same reusable authored computer.
## The desk computer's glass, which the lettering size was drawn for.
const GLASS_WIDTH: float = .578
var view: ClearingView
var displays: Dictionary = {}
var _output: String = ""
var _output_preview: bool = false
var _output_zone: String = ""
var _state: Dictionary = {}
var _preview: bool = false

func setup(clearing: ClearingView) -> void:
	view = clearing
	for terminal: Dictionary in view.area.terminals:
		var model: Node3D = view.building_node(terminal.object)
		if model == null: continue
		var text := Label3D.new()
		text.name = "TerminalScreenText"
		text.font = UITheme.MONO
		text.font_size = 48
		text.outline_size = 0
		# The lettering is laid on the model's own glass, so a wide wall screen and the desk computer both fit.
		var glass: MeshInstance3D = model.find_child("terminal_screen", true, false) as MeshInstance3D
		var scale_to_glass: float = 1.0
		text.position = Vector3(-.252, .48, .099)
		if glass != null:
			var box: AABB = _relative_transform(glass, model) * glass.get_aabb()
			scale_to_glass = box.size.x / GLASS_WIDTH
			text.position = Vector3(box.position.x + .037 * scale_to_glass, box.position.y + box.size.y * .5, box.end.z + .0075)
		text.pixel_size = .00125 * scale_to_glass
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.shaded = false
		text.no_depth_test = false
		model.add_child(text)
		displays[terminal.id] = {"spec":terminal, "text":text, "lamp":model.find_child("connection_lamp", true, false)}

## `node`'s transform in `ancestor`'s frame, without needing either to be inside the tree.
static func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result: Transform3D = Transform3D.IDENTITY
	var step: Node = node
	while step != null and step != ancestor:
		if step is Node3D: result = (step as Node3D).transform * result
		step = step.get_parent()
	return result

func sync(state: Dictionary, preview: bool = false) -> void:
	_state = state
	_preview = preview
	for entry: Dictionary in displays.values():
		var terminal: Dictionary = entry.spec
		var connected: bool = ZoneTerminals.connected(view.area, state, terminal.zone)
		var words: String = "READY" if connected else str(terminal.get("idle", "USE TO CONNECT"))
		var count: int = 0
		var lit: int = 0
		for lamp: Dictionary in view.area.lamps:
			if lamp.zone == terminal.zone:
				count += 1
				if (state.get("lamps", {}) as Dictionary).get(lamp.id, false): lit += 1
		if connected and count > 0: words = "%d/%d LIGHTS ON" % [lit, count]
		var header: String = str(terminal.zone).to_upper()
		if preview: header = "TEST · " + header
		var has_output: bool = not _output.is_empty() and terminal.zone == _output_zone and connected
		if has_output:
			header = "TEST OUTPUT" if _output_preview else "MESSAGE SENT"
			words = _screen_words(_output)
		(entry.text as Label3D).text = header + "\n" + words
		(entry.text as Label3D).modulate = Color("ffd692") if preview or (has_output and _output_preview) else Color("b9edcf")
		var indicator: MeshInstance3D = entry.lamp as MeshInstance3D
		if indicator != null:
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color("9ed5ad") if connected else Color("d8a55e")
			indicator.material_override = material

static func _screen_words(words: String) -> String:
	var plain: String = words.strip_edges().replace("\n", " ")
	return plain.left(14) + ("\n" + plain.substr(14, 14) if plain.length() > 14 else "")

func show_output(words: String, provisional: bool) -> void:
	_output = words
	_output_preview = provisional
	var player: Array = _state.get("player", [view.area.spawn.x, view.area.spawn.y, 0])
	_output_zone = view.area.zone_at(Vector2i(int(player[0]), int(player[1])))
	sync(_state, _preview)

func clear_test_output() -> void:
	if not _output_preview: return
	_output = ""
	_output_preview = false
	sync(_state, _preview)
