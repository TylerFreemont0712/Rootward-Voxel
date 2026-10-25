class_name ModelTurntable
extends SubViewportContainer
## A small live picture of one model, lit and angled like the valley, for build mode's details panel. A model
## that can be turned spins slowly on its spot; asked to face a direction, it swings round to it and holds there
## for a moment so the chosen facing can be seen, then spins on. One that cannot be turned stands still.

const SPIN_DEGREES: float = 24.0
const HOLD_SECONDS: float = 2.4
## How much of the picture the model fills at its widest.
const FILL: float = 0.86

var spinning: bool = false
var _viewport: SubViewport
var _camera: Camera3D
var _pivot: Node3D
var _angle: float = 0.0
var _target: float = 0.0
var _hold: float = 0.0


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c3cde2")
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_viewport.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color("fff0d8")
	sun.light_energy = 0.9
	_viewport.add_child(sun)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.far = 120.0
	_viewport.add_child(_camera)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)
	resized.connect(_frame)


## Stands `model` (which this takes over) on the turntable, facing `facing_degrees`. Null clears it.
func show_model(model: Node3D, can_spin: bool, facing_degrees: float = 0.0) -> void:
	clear()
	spinning = can_spin
	_angle = facing_degrees
	_target = facing_degrees
	_hold = HOLD_SECONDS * 0.5
	_pivot.rotation_degrees.y = _angle
	if model == null:
		return
	_pivot.add_child(model)
	_frame()


## Swings round to face `degrees` (the same angle the valley uses), then holds there for a moment.
func face(degrees: float) -> void:
	_target = _angle + wrapf(degrees - _angle, -180.0, 180.0)
	_hold = HOLD_SECONDS


func clear() -> void:
	for child: Node in _pivot.get_children():
		_pivot.remove_child(child)
		child.queue_free()


func has_model() -> bool:
	return _pivot.get_child_count() > 0


func _process(delta: float) -> void:
	if not spinning or not is_visible_in_tree() or not has_model():
		return
	if _hold > 0.0:
		_hold -= delta
		_angle = lerpf(_angle, _target, 1.0 - exp(-delta * 9.0))
	else:
		_angle += SPIN_DEGREES * delta
		_target = _angle
	_pivot.rotation_degrees.y = _angle


## Points the camera so the model fits whichever way it is turned: every vertex's distance from the turning axis
## bounds its width, and its height and that distance bound how tall it can look from above.
func _frame() -> void:
	if not has_model():
		return
	var reach: float = 0.0
	var low: float = INF
	var high: float = -INF
	var stack: Array = [[_pivot.get_child(0), (_pivot.get_child(0) as Node3D).transform]]
	while not stack.is_empty():
		var pair: Array = stack.pop_back()
		var node: Node = pair[0]
		var placement: Transform3D = pair[1]
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null and (node as MeshInstance3D).visible:
			for vertex: Vector3 in (node as MeshInstance3D).mesh.get_faces():
				var local: Vector3 = placement * vertex
				reach = maxf(reach, Vector2(local.x, local.z).length())
				low = minf(low, local.y)
				high = maxf(high, local.y)
		for child: Node in node.get_children():
			if child is Node3D:
				stack.append([child, placement * (child as Node3D).transform])
	if low > high:
		low = 0.0
		high = 1.0
	var offset: Vector3 = ClearingView.CAMERA_OFFSET
	var elevation: float = atan2(offset.y, Vector2(offset.x, offset.z).length())
	var tall: float = (high - low) * cos(elevation) + 2.0 * reach * sin(elevation)
	var aspect: float = maxf(0.4, size.x / size.y) if size.y > 1.0 else 1.4
	_camera.size = maxf(tall, 2.0 * reach / aspect) / FILL
	var middle := Vector3(0.0, (low + high) * 0.5, 0.0)
	_camera.transform = Transform3D(Basis.looking_at(-offset, Vector3.UP), middle + offset)
