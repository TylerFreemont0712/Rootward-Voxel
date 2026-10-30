class_name MovementTestView
extends SubViewportContainer
## Disposable demonstration in a copied room. Receives only bounded core traces.
## Nothing here can apply a program, move the real player or award quest progress.
signal demonstrated(trial: Dictionary)
class TestScene extends ClearingView:
	func set_zoom(value: float) -> void:_zoom_target=clampf(value,4.0,8.0)
	func _clamped_focus(point: Vector3) -> Vector3:return point
class TraceOverlay extends Control:
	var bench: MovementTestView
	func _draw() -> void:bench.draw_trace(self)

var trials: Array[Dictionary]=[]
var active_key: String=""
var playing: bool=false
var view: ClearingView
var _viewport: SubViewport
var _area: AreaDef
var _state: Dictionary={}
var _marks: Node3D
var _motion: Tween
var _overlay: TraceOverlay
var _trial: Dictionary={}

func _init() -> void:
	stretch=true
	focus_mode=Control.FOCUS_ALL
	mouse_filter=Control.MOUSE_FILTER_STOP
	custom_minimum_size=Vector2(0,152)
	_viewport=SubViewport.new()
	_viewport.own_world_3d=true
	_viewport.size=Vector2i(520,152)
	_viewport.msaa_3d=Viewport.MSAA_2X
	_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	_overlay=TraceOverlay.new()
	_overlay.bench=self
	_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	clip_contents=true
	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:grab_focus())

func setup(area: AreaDef, state: Dictionary) -> void:
	_area=area
	_state=state.duplicate(true)
	if is_node_ready():_build()

func _ready() -> void:_build()

func _build() -> void:
	if _area==null:return
	if view!=null:view.queue_free()
	view=TestScene.new()
	_viewport.add_child(view)
	view.setup(_area)
	view.set_camera_mode(ClearingView.CameraMode.FIXED)
	view.set_zoom(4.8)
	view.camera.size=4.8
	view.apply_state(_state)
	view.focus_on(Vector2(float(_state.player[0]),float(_state.player[1])),true)
	_marks=Node3D.new()
	view.add_child(_marks)

func clear() -> void:
	if _motion!=null:_motion.kill()
	playing=false
	active_key=""
	_trial.clear()
	trials.clear()
	if view!=null:
		view.apply_state(_state)
		view.set_player_motion(Vector2.ZERO)
		for node: Node in _marks.get_children():node.queue_free()

func load_trials(values: Array[Dictionary], state: Dictionary) -> void:
	clear()
	_state=state.duplicate(true)
	trials=values.duplicate(true)
	if view!=null:
		view.apply_state(_state)
		view.focus_on(Vector2(float(_state.player[0]),float(_state.player[1])),true)

func play_key(key: String) -> bool:
	for trial: Dictionary in trials:
		if trial.key==key:
			_play(trial)
			return true
	return false

func _play(trial: Dictionary) -> void:
	if view==null:return
	if _motion!=null:_motion.kill()
	for node: Node in _marks.get_children():node.queue_free()
	active_key=trial.key
	_trial=trial.duplicate(true)
	var start: Vector2i=trial.from
	var target: Vector2i=trial.target
	var color: Color=Pal.GREEN if trial.ok else Pal.RED
	_mark(trial.expected,Pal.GREEN,.82,.018)
	_mark(target,color,.60,.035)
	for cell: Vector2i in trial.path:
		if cell!=start:_mark(cell,Pal.TEAL,.18,.018)
	view.apply_state(_state)
	var delta: Vector2i=trial.delta
	var centre:=Vector2(start)+Vector2(target-start)*.35
	view.focus_on(centre,true)
	view.set_player_motion(Vector2(delta))
	playing=true
	demonstrated.emit(trial)
	_motion=create_tween()
	var path: Array=trial.path
	for index: int in range(1,path.size()):
		var from:=Vector2(path[index-1])
		var to:=Vector2(path[index])
		_motion.tween_method(func(t: float) -> void:view.interpolate_player(from,to,t),0.0,1.0,.38)
	_motion.tween_interval(.25)
	_motion.tween_callback(func() -> void:
		view.set_player_motion(Vector2.ZERO)
		playing=false)

func _mark(cell: Vector2i, color: Color, width: float, height: float) -> void:
	var mesh:=MeshInstance3D.new()
	var box:=BoxMesh.new()
	box.size=Vector3(width,.018,width)
	mesh.mesh=box
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(color,.76)
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override=material
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.position=Vector3(cell.x,.16+height,-cell.y)
	_marks.add_child(mesh)

func _unhandled_key_input(event: InputEvent) -> void:
	if not has_focus() or not event is InputEventKey or not event.pressed or event.echo:return
	var physical: Key=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	for key: String in GameSession.BINDING_CODES:
		if GameSession.BINDING_CODES[key]==physical and play_key(key):
			get_viewport().set_input_as_handled()
			return

func _process(_delta: float) -> void:
	if is_visible_in_tree():_overlay.queue_redraw()

func _screen(cell: Vector2i) -> Vector2:
	return view.camera.unproject_position(Vector3(cell.x,.2,-cell.y))*size/Vector2(_viewport.size)

func draw_trace(canvas: Control) -> void:
	if view==null or _trial.is_empty():return
	var delta: Vector2i=_trial.delta
	var start: Vector2i=_trial.from
	var origin: Vector2=_screen(start)
	canvas.draw_circle(origin,4,Pal.PARCHMENT)
	var unit:=Vector2i(signi(delta.x),signi(delta.y))
	if delta==Vector2i.ZERO:
		canvas.draw_circle(origin,9,Pal.RED,false,2,true)
		canvas.draw_string(UITheme.mono_font(),origin+Vector2(10,-6),"0",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Pal.RED)
		return
	if unit.x!=0 and unit.y!=0:
		canvas.draw_line(origin,_screen(start+delta),Pal.RED,2,true)
		return
	var previous: Vector2=origin
	for step: int in range(1,maxi(absi(delta.x),absi(delta.y))+1):
		var point: Vector2=_screen(start+unit*step)
		var color: Color=Pal.GREEN if step==1 else Pal.RED
		canvas.draw_line(previous,point,Color(color,.8),2,true)
		canvas.draw_circle(point,7,color,false,2,true)
		canvas.draw_string(UITheme.mono_font(),point+Vector2(9,-7),str(step),HORIZONTAL_ALIGNMENT_LEFT,-1,16,color)
		previous=point
