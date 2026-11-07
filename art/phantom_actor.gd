class_name PhantomActor
extends SpriteAdventurer
## Anonymous gray versions of the selected painted sprites, with their exact frames, gait and foot anchors.

var profile: String = "man"
var _opacity: float = 0.96
static var _library: Dictionary = {}

static func library() -> Dictionary:
	if _library.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/phantoms/manifest.json"))
		if raw is Dictionary: _library = raw
	return _library

func _ready() -> void:
	var raw: Dictionary = library()
	if not raw is Dictionary or not raw.get("profiles", {}).has(profile) or not raw.profiles[profile].has_all(["pixel_size", "idle", "animations", "frames", "scale"]):
		push_error("Anonymous crowd art is incomplete. Build it with scripts/art.sh.")
		set_process(false)
		return
	var library: Dictionary = raw
	_manifest = library.profiles[profile]
	_shared_frames = load(_manifest.frames) as SpriteFrames
	_opacity = float(library.opacity)
	var proportions: Array = _manifest.scale
	scale = Vector3(float(proportions[0]), float(proportions[1]), float(proportions[0]))
	_cosmetic_rng.randomize()
	_upright = Node3D.new()
	_upright.scale.y = 1.0 / cos(CAMERA_ELEVATION)
	add_child(_upright)
	sprite = AnimatedSprite3D.new()
	sprite.sprite_frames = _shared_frames
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.pixel_size = float(_manifest.pixel_size)
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	sprite.shaded = false
	sprite.modulate = Color(float(library.gray), float(library.gray), float(library.gray), _opacity)
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_upright.add_child(sprite)
	sprite.frame_changed.connect(_anchor_frame)
	sprite.animation_changed.connect(_anchor_frame)
	_show_idle()
	_make_shadow()


## A passenger gets a fresh anonymous appearance on the next service, preserving
## the common animation phase, facing and idle clock when its atlas is exchanged.
func set_profile(id: String) -> bool:
	if not library().get("profiles", {}).has(id): return false
	profile = id
	if sprite == null: return true
	_manifest = library().profiles[id]
	var animation: StringName = sprite.animation
	var frame: int = sprite.frame
	var progress: float = sprite.frame_progress
	var playing: bool = sprite.is_playing()
	_shared_frames = load(_manifest.frames) as SpriteFrames
	sprite.sprite_frames = _shared_frames
	sprite.play(animation)
	sprite.set_frame_and_progress(frame, progress)
	if not playing: sprite.pause()
	var proportions: Array = _manifest.scale
	scale = Vector3(float(proportions[0]), float(proportions[1]), float(proportions[0]))
	_anchor_frame()
	return true


func set_presence(fraction: float) -> void:
	visible = fraction > 0.001
	if sprite != null: sprite.modulate.a = _opacity * clampf(fraction, 0.0, 1.0)
	var shadow := get_node_or_null("ContactShadow") as GeometryInstance3D
	if shadow != null: shadow.transparency = 1.0 - fraction * 0.35
