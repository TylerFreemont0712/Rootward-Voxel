class_name WorkshopFloorStage
extends WorkshopLoftStage
## The downstairs uses the same authored robot and speech presenter. An awake
## Hotaru accompanies the lodger; before greeting she stays asleep upstairs.
var _fire: OmniLight3D
var _fire_time: float = 0.0
var _street_door: Node3D
var _door_parts: Array[Dictionary] = []
var _door_faded: bool = false

func setup(scene_view: ClearingView) -> void:
	super.setup(scene_view)
	_fire = OmniLight3D.new()
	_fire.name = "StoveWarmth"
	_fire.position = Vector3(8.0, .85, -10.0)
	var stove := view.find_child("stove", true, false) as Node3D
	if stove != null: _fire.position = stove.transform * Vector3(0, .70, .40)
	_fire.light_color = Color("ffc47b")
	_fire.omni_range = 3.1
	_fire.light_energy = .34
	_fire.shadow_enabled = false
	add_child(_fire)
	if _robot != null: _robot.visible = false
	_street_door = view.find_child("shop-doors", true, false) as Node3D
	if _street_door != null:
		for child: Node in _street_door.find_children("*", "MeshInstance3D", true, false):
			if child.name == &"IllustratedOutline": continue
			var mesh := child as MeshInstance3D
			var original := mesh.get_active_material(0) as StandardMaterial3D
			if original == null: continue
			var faded := original.duplicate() as StandardMaterial3D
			faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			faded.albedo_color.a = .25
			_door_parts.append({"node": mesh, "original": original, "faded": faded})

func sync_progress(state: Dictionary, completed: Array) -> void:
	super.sync_progress(state, completed)
	if _robot != null: _robot.visible = awake

func companion_node() -> Node3D:
	return _robot if awake else null

func _process(delta: float) -> void:
	super._process(delta)
	_fire_time += delta
	if _fire != null: _fire.light_energy = .34 + sin(_fire_time * 2.3) * .018 + sin(_fire_time * 5.1) * .009
	if _street_door != null and view.player_node() != null:
		var local: Vector3 = _street_door.to_local(view.player_node().global_position)
		var fade: bool = absf(local.x) < 2.1 and local.z > -2.4 and local.z < .6 and local.y < 2.8
		if fade != _door_faded:
			_door_faded = fade
			for part: Dictionary in _door_parts:
				(part.node as MeshInstance3D).material_override = part.faded if fade else part.original
				var outline: Node3D = (part.node as Node3D).get_node_or_null("IllustratedOutline")
				if outline != null: outline.visible = not fade
