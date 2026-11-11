class_name ThumbnailStudio
extends Node
## Renders a model to a small picture from the game's own camera angle and light, on a transparent
## background, so a catalog card shows the real building or tree. One hidden SubViewport does every picture:
## the model is stood in it, drawn once, read back and removed. Used by build mode's dock.

const SIZE: int = 168
## How much of the picture the model fills.
const FILL: float = 0.9
const CAMERA_OFFSET: Vector3 = Vector3(21.0, 17.8, 21.0)

var _viewport: SubViewport
var _camera: Camera3D
var _holder: Node3D
var _busy: bool = false


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(SIZE, SIZE)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
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
	_camera.size = 12.0
	_camera.far = 120.0
	_viewport.add_child(_camera)
	_holder = Node3D.new()
	_viewport.add_child(_holder)


## The picture of `model` (which this takes over and frees), or null where nothing can be drawn (a headless run has
## no renderer). Several can be asked for in a row; they are drawn one at a time.
func render(model: Node3D) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		model.queue_free()
		return null
	while _busy:
		await get_tree().process_frame
	_busy = true
	_holder.add_child(model)
	var box: AABB = BuildOverlay.world_aabb(model)
	var center: Vector3 = box.get_center()
	_camera.position = center + CAMERA_OFFSET
	_camera.h_offset = 0.0
	_camera.v_offset = 0.0
	_camera.look_at(center)
	await get_tree().process_frame
	# Frame the model's real outline (every vertex, along the camera's own right and up axes), not its box.
	var right: Vector3 = _camera.global_transform.basis.x
	var up: Vector3 = _camera.global_transform.basis.y
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	var stack: Array[Node] = [model]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var placement: Transform3D = (node as MeshInstance3D).global_transform
			for vertex: Vector3 in (node as MeshInstance3D).mesh.get_faces():
				var world: Vector3 = placement * vertex
				var point := Vector2(world.dot(right), world.dot(up))
				low = low.min(point)
				high = high.max(point)
		stack.append_array(node.get_children())
	var span: float = maxf(high.x - low.x, high.y - low.y)
	_camera.size = span / FILL
	var middle: Vector2 = (low + high) * 0.5
	_camera.h_offset = middle.x - center.dot(right)
	_camera.v_offset = middle.y - center.dot(up)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image: Image = _viewport.get_texture().get_image()
	_holder.remove_child(model)
	model.queue_free()
	_busy = false
	return ImageTexture.create_from_image(image)
