class_name GearVeil
extends ColorRect
## The clockwork curtain between places (`gear_veil.gdshader`). A toothed brass edge grows out of a point on the
## screen until nothing else shows, a train of meshed gears turns while the scene is swapped behind it, and the same
## edge opens a hole to the new scene. Presentation only: the rules never wait on it, the game does.

const SHADER: Shader = preload("res://ui/gear_veil.gdshader")

var _material: ShaderMaterial
## How many times the veil has drawn itself while a scene was being built.
var pumped: int = 0
var _clock_start: int = Time.get_ticks_msec()


func _init() -> void:
	name = "GearVeil"
	color = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	material = _material
	resized.connect(_fit_aspect)


func _ready() -> void:
	_fit_aspect()


func _process(_delta: float) -> void:
	if visible:
		_turn()


## The gears follow the clock rather than the frame time, so a stalled frame never makes them jump or stop and start.
func _turn() -> void:
	_material.set_shader_parameter("spin", float(Time.get_ticks_msec() - _clock_start) / 1000.0)


## Called while a scene is being built (see BuildPump): the main thread is busy, so the veil draws itself, with the
## gears turned to the time it is now.
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
	_material.set_shader_parameter("front", 0.0)
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
	_material.set_shader_parameter("front", value)


func _fit_aspect() -> void:
	if size.y > 0.0:
		_material.set_shader_parameter("aspect", size.x / size.y)
