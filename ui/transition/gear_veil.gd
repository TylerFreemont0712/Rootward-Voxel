class_name GearVeil
extends ColorRect
## The clockwork curtain between places (`gear_veil.gdshader`). A toothed brass edge grows out of a point on the
## screen until nothing else shows, a train of meshed gears turns while the scene is swapped behind it, and the same
## edge opens a hole to the new scene. Presentation only: the rules never wait on it, the game does.

const SHADER: Shader = preload("res://ui/transition/gear_veil.gdshader")

var _material: ShaderMaterial
## How many times the veil has drawn itself while a scene was being built.
var pumped: int = 0
var _clock_last: int = Time.get_ticks_msec()
var _clock: float = 0.0
var _front: float = 0.0
var _opening: bool = false
var clockwork: ClockworkGears
var rendered_frames: int = 0


func _init() -> void:
	name = "GearVeil"
	color = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	resized.connect(_fit_aspect)
	clockwork = ClockworkGears.new()
	UI.full_rect(clockwork)
	add_child(clockwork)


func _ready() -> void:
	_fit_aspect()


func _process(_delta: float) -> void:
	if visible:
		_turn()


## Scene construction yields real frames. Bound a missed frame's phase increment so the
## train resumes cleanly instead of jumping through several teeth after an OS/GPU stall.
func _turn() -> void:
	var now: int = Time.get_ticks_msec()
	var delta: float = minf(.05, maxf(0.0, float(now - _clock_last) / 1000.0))
	_clock_last = now
	_clock += delta
	rendered_frames += 1
	_material.set_shader_parameter("spin", _clock)
	clockwork.advance(delta)


## Compatibility redraw for older synchronous builders. Natural Sparks travel yields
## real frames instead; both paths share the train's bounded phase clock.
func keep_turning() -> void:
	if not visible:
		return
	_turn()
	pumped += 1
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw(true, 0.0)


## Whether any of the veil is showing.
func covering() -> bool:
	return visible


## Grows the veil out of `origin` (0..1 of the screen) until it fills the screen. `during` receives 0..1, evenly, as
## it grows, for a walk that carries on underneath.
func close(origin: Vector2, seconds: float, during: Callable = Callable()) -> void:
	_begin(origin, false)
	await _sweep(seconds, during)


## Opens a hole out of `origin` until the veil is gone.
func open(origin: Vector2, seconds: float, during: Callable = Callable()) -> void:
	_begin(origin, true)
	await _sweep(seconds, during)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _begin(origin: Vector2, opening: bool) -> void:
	_material.set_shader_parameter("origin", origin)
	_material.set_shader_parameter("opening", 1.0 if opening else 0.0)
	_clock_last = Time.get_ticks_msec()
	_opening = opening
	set_front(0.0)
	_fit_aspect()
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _sweep(seconds: float, during: Callable) -> void:
	if seconds <= 0.0:
		set_front(1.0)
		if during.is_valid():
			during.call(1.0)
		await get_tree().process_frame
		return
	var tween := create_tween()
	tween.tween_method(set_front, 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if during.is_valid():
		tween.parallel().tween_method(during, 0.0, 1.0, seconds)
	await tween.finished


func set_front(value: float) -> void:
	_front = value
	_material.set_shader_parameter("front", value)
	clockwork.modulate.a = 1.0 - smoothstep(0.0, .25, value) if _opening else smoothstep(.80, 1.0, value)


## Presentation of the saved city supply. Ordinary states without
## city_power keep the neutral appearance; this never grants or saves progression.
func set_world_state(state: Dictionary) -> void:
	var raw: Variant = state.get("city_power", {})
	clockwork.set_power(raw if raw is Dictionary else {})


func set_status(text: String) -> void:
	clockwork.set_status(text)


func _fit_aspect() -> void:
	if size.y > 0.0:
		_material.set_shader_parameter("aspect", size.x / size.y)
