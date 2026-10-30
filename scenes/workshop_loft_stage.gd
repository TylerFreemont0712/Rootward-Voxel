class_name WorkshopLoftStage
extends RoomStage
## Furnished loft, terminal output and the first committed greeting. Logical speech
## and quest progress belong to the session; this node only presents them.

var awake: bool = false
var output_is_preview: bool = false
var _robot: Node3D
var _rotor: Node3D
var _window: MeshInstance3D
var _unlit: Material
var _eyes: Node3D
var _glow: OmniLight3D
var _time: float = 0.0
var _rest_height: float = 0.0
signal speech_finished
var speech_text: String = ""
var speech_speaker: String = "player"
var speech_preview: bool = false
var speech_characters: int = 0
var speech_complete: bool = false
var _speech_queue: Array[Dictionary] = []
var _speech_clock: float = 0.0
var _hold_last: bool = false


## Every line is actual validated runner output or authored conversation.
func play_speech(lines: Array[Dictionary], provisional: bool = false, hold_last: bool = false) -> void:
	clear_speech()
	speech_preview = provisional
	_hold_last = hold_last
	_speech_queue.assign(lines)
	_next_speech()


func clear_speech() -> void:
	_speech_queue.clear()
	speech_text = ""
	speech_characters = 0
	_speech_clock = 0.0
	speech_complete = false
	speech_preview = false
	_hold_last = false


func _next_speech() -> void:
	_speech_clock = 0.0
	speech_characters = 0
	if _speech_queue.is_empty():
		speech_complete = true
		if not _hold_last: speech_text = ""
		speech_characters = speech_text.length()
		speech_finished.emit()
		return
	var line: Dictionary = _speech_queue.pop_front()
	speech_text = str(line.text)
	speech_speaker = str(line.get("speaker", "player"))


## Continue reveals a line first, then advances. Also supports an unhurried reader.
func advance_speech() -> void:
	if speech_text == "" or speech_complete: return
	if speech_characters < speech_text.length():
		speech_characters = speech_text.length()
		_speech_clock = speech_text.length() * .028
	else:
		_next_speech()


func setup(scene_view: ClearingView) -> void:
	super.setup(scene_view)
	var fill := DirectionalLight3D.new()
	fill.name = "WarmWindowBounce"
	fill.rotation_degrees = Vector3(-32.0, 140.0, 0.0)
	fill.light_color = Color("ffedce")
	fill.light_energy = 0.18
	fill.light_specular = 0.0
	fill.shadow_enabled = false
	add_child(fill)
	for item: Dictionary in view.area.interior.get("lighting", []):
		var lamp: Light3D
		if item.has("target"):
			var spot := SpotLight3D.new()
			spot.spot_range = float(item.range)
			spot.spot_angle = float(item.angle)
			spot.spot_attenuation = 0.7
			lamp = spot
		else:
			var omni := OmniLight3D.new()
			omni.omni_range = float(item.range)
			omni.omni_attenuation = 1.5
			lamp = omni
		add_child(lamp)
		lamp.position = Vector3(float(item.at[0]), float(item.height), -float(item.at[1]))
		lamp.light_color = Color(str(item.color))
		lamp.light_energy = float(item.energy)
		lamp.shadow_enabled = false
		if item.has("target"):
			lamp.look_at(Vector3(float(item.target[0]), 0.0, -float(item.target[1])))
	_robot = view.find_child("dormant-hotaru", true, false) as Node3D
	if _robot != null:
		_rest_height = _robot.position.y
		_rotor = _robot.find_child("rotor", true, false) as Node3D
		for child: Node in _robot.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			if mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
				var material := mesh.get_active_material(0) as StandardMaterial3D
				if material != null and material.resource_name == "loft_glass":
					_window = mesh
					_unlit = material
		_eyes = Node3D.new()
		_eyes.name = "SparkEyes"
		_robot.add_child(_eyes)
		var eye_material := StandardMaterial3D.new()
		eye_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eye_material.albedo_color = Color("fff2c8")
		for x: float in [-0.05, 0.05]:
			var eye := MeshInstance3D.new()
			var shape := SphereMesh.new()
			shape.radius = 0.021
			shape.height = 0.075
			eye.mesh = shape
			eye.material_override = eye_material
			eye.position = Vector3(x, 0.26, 0.236)
			eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_eyes.add_child(eye)
		_eyes.visible = false
		_glow = OmniLight3D.new()
		_glow.position = Vector3(0.0, 0.25, 0.25)
		_glow.omni_range = 1.25
		_glow.light_color = Color("ffd58a")
		_glow.light_energy = 0.4
		_glow.visible = false
		_robot.add_child(_glow)


func replaces_companion() -> bool:
	return true


func companion_node() -> Node3D:
	return _robot


func sync_progress(state: Dictionary, completed: Array) -> void:
	var voiced: bool = CompanionLesson.has_voice(state, completed)
	var note: Node3D = view.building_node("nell-note")
	if note != null: note.visible = not voiced and not (state.get("inspections_read", []) as Array).has("nell-note")
	if voiced != awake:
		awake = voiced
		if _window != null:
			if awake:
				var warm := StandardMaterial3D.new()
				warm.albedo_color = Color("e0a144")
				warm.emission_enabled = true
				warm.emission = Color("ffc861")
				warm.emission_energy_multiplier = 0.85
				warm.roughness = 0.65
				_window.material_override = warm
			else:
				_window.material_override = _unlit
		if _eyes != null: _eyes.visible = awake
		if _glow != null: _glow.visible = awake
	if view.area.id == "workshop-loft" and str(state.get("spoken", "")) != "":
		show_output(str(state.spoken), false)


func show_output(words: String, provisional: bool) -> void:
	output_is_preview = provisional
	if view.terminal_display != null: view.terminal_display.show_output(words, provisional)


func clear_test_output() -> void:
	if speech_preview: clear_speech()
	output_is_preview = false
	if view.terminal_display != null: view.terminal_display.clear_test_output()


func _process(delta: float) -> void:
	if speech_text != "" and not speech_complete:
		_speech_clock += delta
		speech_characters = mini(speech_text.length(), int(_speech_clock / .028))
		if _speech_clock > speech_text.length() * .028 + (1.8 if speech_preview else 2.8):
			_next_speech()
	if not awake: return
	_time += delta
	if _rotor != null: _rotor.rotate_y(delta * 2.3)
	if _robot != null: _robot.position.y = _rest_height + 0.05 + sin(_time * 1.8) * 0.018
