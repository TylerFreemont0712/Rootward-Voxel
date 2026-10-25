class_name SpriteAdventurer
extends Node3D
## Presentation only. Walking rules and authoritative position live in core/app.

const Skins := preload("res://art/frame_skin.gd")
@export var skin_id: String = ""
## A faint copy drawn over scenery, so the player never vanishes behind a tree or roof.
@export var occlusion_silhouette: bool = false
var sprite: AnimatedSprite3D
var _silhouette: AnimatedSprite3D
## Keep the painted picture's projected proportions, but stand its depth plane upright.
## A camera-facing plane leans into the ground behind the feet on steps and terraces.
const CAMERA_ELEVATION: float = atan2(17.8, sqrt(21.0 * 21.0 * 2.0))
var _upright: Node3D
var _manifest: Dictionary = {}
var _skin_library: Dictionary = {}
var _shared_frames: SpriteFrames
var animation_name: String:
	get:
		return ("walk_" if _moving else "idle_") + _direction
var _direction: String = "se"
var _moving: bool = false
var _idle_seconds: float = 0.0
var _next_blink_at: float = 0.0
var _blink_until: float = 0.0
var _cosmetic_rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "SpriteAdventurer"
	_skin_library = Skins.read_library()
	if _skin_library.is_empty():
		return
	_manifest = JSON.parse_string(FileAccess.get_file_as_string(_skin_library.template.manifest))
	_shared_frames = load(_skin_library.template.frames) as SpriteFrames
	_cosmetic_rng.randomize()
	_upright = Node3D.new()
	_upright.name = "UprightProjection"
	_upright.scale.y = 1.0 / cos(CAMERA_ELEVATION)
	add_child(_upright)
	sprite = AnimatedSprite3D.new()
	sprite.name = "AnimatedSprite3D"
	sprite.sprite_frames = _shared_frames
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.pixel_size = float(_manifest.pixel_size)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.18
	sprite.shaded = false
	sprite.modulate = Color("fff5e8")
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_upright.add_child(sprite)
	if occlusion_silhouette:
		_make_silhouette()
	sprite.frame_changed.connect(_anchor_frame)
	sprite.animation_changed.connect(_anchor_frame)
	_show_idle()
	if not set_skin(str(_skin_library.active) if skin_id.is_empty() else skin_id):
		push_error("Invalid selected character skin: " + skin_id)
	_make_shadow()


func set_skin(id: String) -> bool:
	if _skin_library.is_empty():
		_skin_library = Skins.read_library()
	if _skin_library.is_empty() or not _skin_library.skins.has(id):
		return false
	if sprite == null:
		skin_id = id
		return true
	var skin: Dictionary = _skin_library.skins[id]
	var atlas := load(skin.atlas) as Texture2D
	var size: Array = _skin_library.template.sheet_size
	if atlas == null or atlas.get_size() != Vector2(float(size[0]), float(size[1])):
		return false
	var animation := sprite.animation
	var frame := sprite.frame
	var progress := sprite.frame_progress
	var playing := sprite.is_playing()
	sprite.sprite_frames = Skins.frames_for(_shared_frames, atlas)
	sprite.play(animation)
	sprite.set_frame_and_progress(frame, progress)
	if not playing:
		sprite.pause()
	var tint: Array = skin.tint
	sprite.modulate = Color("fff5e8") * Color(float(tint[0]), float(tint[1]), float(tint[2]), float(tint[3]))
	skin_id = id
	_anchor_frame()
	return true


func set_screen_motion(screen_motion: Vector2) -> void:
	if sprite == null:
		return
	var moving := screen_motion.length() > 0.001
	if not moving:
		if _moving:
			_moving = false
			_show_idle()
		return
	var was_moving := _moving
	_moving = true
	_direction = facing_for_screen_motion(screen_motion)
	sprite.flip_h = false
	sprite.scale = Vector3.ONE
	_blink_until = 0.0
	var animation := StringName("walk_" + _direction)
	if sprite.animation != animation:
		var old_frame := sprite.frame
		var old_progress := sprite.frame_progress
		sprite.play(animation)
		sprite.set_frame_and_progress(old_frame if was_moving else 0, old_progress if was_moving else 0.0)
	elif not sprite.is_playing():
		sprite.play()
	_anchor_frame()


## Turns to face a screen direction without walking, for when something blocks the way. Walking
## animations and the walking direction stay with set_screen_motion.
func face_screen_direction(screen_direction: Vector2) -> void:
	if sprite == null or _moving or screen_direction.length() < 0.001:
		return
	var facing := facing_for_screen_motion(screen_direction)
	if facing == _direction:
		return
	_direction = facing
	_show_idle()


func _show_idle() -> void:
	_idle_seconds = 0.0
	_blink_until = 0.0
	_next_blink_at = _blink_interval()
	sprite.scale = Vector3.ONE
	sprite.play("idle_" + _direction)
	sprite.set_frame_and_progress(0, 0.0)
	sprite.pause()
	_anchor_frame()


func _blink_interval() -> float:
	var interval: Array = _manifest.idle.blink_interval
	return _cosmetic_rng.randf_range(float(interval[0]), float(interval[1]))


func _process(delta: float) -> void:
	_advance_idle(delta)
	if _silhouette != null:
		_silhouette.sprite_frames = sprite.sprite_frames
		_silhouette.animation = sprite.animation
		_silhouette.frame = sprite.frame
		_silhouette.scale = sprite.scale
		_silhouette.offset = sprite.offset


func _make_silhouette() -> void:
	_silhouette = AnimatedSprite3D.new()
	_silhouette.name = "OcclusionSilhouette"
	_silhouette.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_silhouette.pixel_size = sprite.pixel_size
	_silhouette.texture_filter = sprite.texture_filter
	_silhouette.shaded = false
	_silhouette.no_depth_test = true
	_silhouette.transparent = true
	_silhouette.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_silhouette.render_priority = 8
	_silhouette.modulate = Color(0.95, 0.9, 1.0, 0.34)
	_silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_upright.add_child(_silhouette)


func _advance_idle(delta: float) -> void:
	if _moving or sprite == null:
		return
	_idle_seconds += maxf(0.0, delta)
	var idle: Dictionary = _manifest.idle
	var front: bool = _direction in idle.blink_directions
	var amplitude := float(idle.breath_amplitude if front else idle.rear_breath_amplitude)
	var breath := 0.5 - 0.5 * cos(TAU * _idle_seconds / float(idle.breath_period))
	# The foot origin is local zero. This tiny breath raises the upper body
	# without translating the planted feet.
	sprite.scale.y = 1.0 + amplitude * breath
	while _idle_seconds >= _next_blink_at:
		_blink_until = _next_blink_at + float(idle.blink_duration)
		_next_blink_at += _blink_interval()
	sprite.frame = 1 if front and _idle_seconds < _blink_until else 0


static func facing_for_screen_motion(motion: Vector2) -> String:
	if motion.y >= 0.0:
		return "se" if motion.x >= 0.0 else "sw"
	return "ne" if motion.x >= 0.0 else "nw"


func _anchor_frame() -> void:
	if sprite == null or not _manifest.animations.has(str(sprite.animation)):
		return
	var data: Array = _manifest.animations[str(sprite.animation)]
	var frame: Dictionary = data[mini(sprite.frame, data.size() - 1)]
	var width: float = float(frame.region[2])
	var height: float = float(frame.region[3])
	var anchor: Vector2 = Vector2(float(frame.anchor[0]), float(frame.anchor[1]))
	sprite.offset = Vector2(width * 0.5 - anchor.x, anchor.y - height * 0.5)


func _make_shadow() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y: int in range(32):
		for x: int in range(32):
			var radius: float = Vector2(float(x) - 15.5, float(y) - 15.5).length() / 15.5
			image.set_pixel(x, y, Color(0.16, 0.19, 0.13, maxf(0.0, 1.0 - radius) * 0.3))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.65, 0.42)
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.mesh = mesh
	shadow.material_override = material
	shadow.rotation.x = -PI / 2.0
	shadow.position.y = 0.017
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
