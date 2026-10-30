class_name OutdoorBackdrop
extends MeshInstance3D
## The painted distance behind an outdoor room: one picture on the camera's far plane. It drifts a little against
## the following camera, so the town below reads as far away while the room itself moves at full speed.
## Presentation only; it never covers the room, because everything in the room is nearer than it.

## How far in front of the camera's far plane the picture sits.
const FAR_MARGIN: float = 6.0
const HAZE: Shader = preload("res://art/backdrop_haze.gdshader")

var view: ClearingView
## 0 keeps the picture still on screen; larger values let it follow the room further.
var parallax: float = 0.2
var _aspect: float = 16.0 / 9.0
var _centre: Vector3


func setup(scene_view: ClearingView, outdoor: Dictionary) -> bool:
	view = scene_view
	var texture := load(str(outdoor.backdrop)) as Texture2D
	if texture == null:
		push_error("The outdoor backdrop %s could not be loaded." % str(outdoor.backdrop))
		return false
	_aspect = float(texture.get_width()) / float(maxi(1, texture.get_height()))
	parallax = float(outdoor.get("parallax", 0.2))
	var paint := ShaderMaterial.new()
	paint.shader = HAZE
	paint.set_shader_parameter("painting", texture)
	paint.set_shader_parameter("haze", Color(str(outdoor.haze)))
	mesh = QuadMesh.new()
	material_override = paint
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var area: AreaDef = view.area
	_centre = Vector3(float(area.width - 1) * 0.5, 0.0, -float(area.height - 1) * 0.5)
	_fit()
	return true


func _process(_delta: float) -> void:
	_fit()


## Covers the whole view with room to drift, keeping the picture's own proportions.
func _fit() -> void:
	var camera: Camera3D = view.camera if view != null else null
	if camera == null or not is_inside_tree(): return
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = screen.x / maxf(1.0, screen.y)
	var slack: float = 1.0 + parallax
	var tall: float = maxf(camera.size * slack, camera.size * aspect * slack / _aspect)
	scale = Vector3(tall * _aspect, tall, 1.0)
	# The camera's offset from the room's centre, in its own right/up axes, slides the picture the other way.
	var offset: Vector3 = view.focus_world() - _centre
	var right: float = offset.dot(camera.global_basis.x)
	var up: float = offset.dot(camera.global_basis.y)
	var limit := Vector2(tall * _aspect - camera.size * aspect, tall - camera.size) * 0.5
	position = Vector3(camera.h_offset + clampf(-right * parallax, -limit.x, limit.x), clampf(-up * parallax, -limit.y, limit.y), -(camera.far - FAR_MARGIN))
