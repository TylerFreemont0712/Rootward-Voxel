class_name CharacterScreen
extends Modal
## Choose a painted appearance, turn it on the dais, change your name and view your journey.

signal begin_requested
signal name_changed(new_name: String)
signal skin_changed(id: String)

const FACINGS: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
const FACING_NAMES: Array[String] = ["front right", "front left", "back left", "back right"]

var _actor: SpriteAdventurer
var _facing: int = 0
var _facing_label: Label
var _name_edit: LineEdit
var _viewport: SubViewport
var _skin_id: String = "adventurer"
var _skin_buttons: Dictionary = {}


## options: mode "new" | "view", name, area, completed, stats, lamps_lit, zones_found
func setup(options: Dictionary) -> void:
	_skin_id = "adventurer"
	card.custom_minimum_size = Vector2(1080, 640)
	var area: AreaDef = options.area
	var new_game: bool = options.mode == "new"
	var layout := UI.hbox(32)
	body.add_child(layout)
	layout.add_child(_stage())
	var right := UI.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right)
	right.add_child(UI.caps("Apprentice tinker of Kindle Hollow", Pal.BRASS))
	_name_edit = LineEdit.new()
	_name_edit.text = str(options.name)
	_name_edit.max_length = 16
	_name_edit.placeholder_text = "Your name"
	_name_edit.add_theme_font_override("font", UITheme.display_font(700, 2))
	_name_edit.add_theme_font_size_override("font_size", 34)
	_name_edit.text_submitted.connect(func(value: String) -> void:
		_commit_name()
		_name_edit.release_focus())
	_name_edit.focus_exited.connect(_commit_name)
	right.add_child(_name_edit)
	right.add_child(UI.dim("Click the name to change it. Your name is only used here and in your notebook's greeting.", 16))
	right.add_child(UI.rule())
	right.add_child(_stats(options))
	right.add_child(UI.rule())
	right.add_child(UI.caps("Ideas learned", Pal.VIOLET))
	right.add_child(_skills(area, options.completed))
	right.add_child(UI.spacer(0, true))
	right.add_child(UI.dim("You are the boy apprenticed to the lamplighter. Mira and the other residents live in the village.", 15))
	var row := UI.hbox(12)
	right.add_child(row)
	if new_game:
		var back := UI.button("Back", &"chevron_left", &"", close)
		back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(back)
		var begin := UI.button("Begin the journey", &"play", &"ButtonPrimary", func() -> void:
			_commit_name()
			begin_requested.emit())
		begin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(begin)
		begin.grab_focus.call_deferred()
	else:
		var done := UI.button("Done", &"check", &"ButtonPrimary", close)
		done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(done)


func _stage() -> Control:
	var stage := UI.vbox(8)
	stage.custom_minimum_size = Vector2(380, 0)
	var frame := UI.panel(&"PanelInset")
	frame.custom_minimum_size = Vector2(380, 440)
	stage.add_child(frame)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(container)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.size = Vector2i(360, 480)
	container.add_child(_viewport)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.35
	_viewport.add_child(camera)
	camera.look_at_from_position(Vector3(2.5, 1.55, 4.8), Vector3(0, 0.62, 0))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = 0.9
	_viewport.add_child(sun)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c9d4e8")
	environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)
	for spec: Array in [[0.82, 0.1, Color("6e675b")], [0.7, 0.2, Color("9a9282")], [0.6, 0.26, Color("b7ae98")]]:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = float(spec[0])
		cylinder.bottom_radius = float(spec[0])
		cylinder.height = float(spec[1])
		var material := StandardMaterial3D.new()
		material.albedo_color = spec[2]
		material.roughness = 0.95
		var dais := MeshInstance3D.new()
		dais.mesh = cylinder
		dais.material_override = material
		dais.position.y = float(spec[1]) * 0.5 - 0.1 + (0.0 if spec[1] < 0.15 else 0.02)
		_viewport.add_child(dais)
	_actor = SpriteAdventurer.new()
	_actor.skin_id = _skin_id
	_viewport.add_child(_actor)
	_actor.position = Vector3(0, 0.16, 0)
	var controls := UI.hbox(10)
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_child(controls)
	controls.add_child(UI.icon_button(&"chevron_left", "Turn left (Left arrow)", func() -> void: _turn(-1)))
	_facing_label = UI.label("", &"LabelDim", 17)
	_facing_label.custom_minimum_size.x = 150
	_facing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_child(_facing_label)
	controls.add_child(UI.icon_button(&"chevron", "Turn right (Right arrow)", func() -> void: _turn(1)))
	stage.add_child(_appearance_controls())
	_apply_facing.call_deferred()
	return stage


func _appearance_controls() -> Control:
	var row := UI.hbox(8)
	var group := ButtonGroup.new()
	var library := SpriteAdventurer.Skins.read_library()
	for id: String in library.skins:
		var skin: Dictionary = library.skins[id]
		if not skin.get("selectable", true):
			continue
		var button := UI.button(str(skin.label), &"", &"ButtonTab")
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = id == _skin_id
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select_skin.bind(id))
		_skin_buttons[id] = button
		row.add_child(button)
	return row


func _select_skin(id: String) -> void:
	if id != "adventurer":
		return
	if not _actor.set_skin(id):
		return
	_skin_id = id
	for key: String in _skin_buttons:
		(_skin_buttons[key] as BaseButton).set_pressed_no_signal(key == id)
	skin_changed.emit(id)


func _stats(options: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 22)
	var stats: Dictionary = options.stats
	for entry: Array in [["Programs run", str(int(stats.get("runs", 0)))], ["Changes applied", str(int(stats.get("applies", 0)))],
			["Lamps burning", "%d / %d" % [int(options.lamps_lit), (options.area as AreaDef).lamps.size()]], ["Places found", "%d / %d" % [int(options.zones_found), (options.area as AreaDef).zones.size()]]]:
		var cell := UI.vbox(0)
		cell.add_child(UI.label(entry[1], &"LabelHeading", 30))
		cell.add_child(UI.label(String(entry[0]), &"LabelDim", 15))
		grid.add_child(cell)
	return grid


func _skills(area: AreaDef, completed: Array) -> Control:
	var column := UI.vbox(6)
	for quest: Dictionary in Quests.listed(area, completed):
		var known: bool = completed.has(quest.id)
		var row := UI.hbox(10)
		var mark := Glyph.new()
		mark.kind = &"check" if known else &"lock"
		mark.color = Pal.GREEN if known else Pal.MUTED
		mark.custom_minimum_size = Vector2(22, 22)
		row.add_child(mark)
		row.add_child(UI.label(str(quest.concept), &"", 20, Pal.PARCHMENT if known else Pal.MUTED))
		var where := UI.label("" if known else "Quest: " + str(quest.title), &"LabelDim", 15)
		where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		where.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(where)
		column.add_child(row)
	return column


func _turn(step: int) -> void:
	_facing = posmod(_facing + step, FACINGS.size())
	_apply_facing()


func _apply_facing() -> void:
	if _actor == null or _actor.sprite == null:
		return
	_actor.set_screen_motion(FACINGS[_facing])
	_actor.set_screen_motion(Vector2.ZERO)
	_facing_label.text = "Facing %s" % FACING_NAMES[_facing]


func _commit_name() -> void:
	var clean: String = SaveStore.set_player_name(_name_edit.text)
	_name_edit.text = clean
	name_changed.emit(clean)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not _name_edit.has_focus():
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_turn(-1)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_turn(1)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_key_input(event)
