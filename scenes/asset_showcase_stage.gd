class_name AssetShowcaseStage
extends ModelTurntable
## Isolated presentation stage. Uses the existing turntable world/light; no session or saves.

signal manually_turned

var subject_bounds:=AABB()
var show_guide: bool=true
var _floor: MeshInstance3D
var _grid: MeshInstance3D
var _guide: SpriteAdventurer
var _zoom: float=1.0
var _fit_size: float=12.0

func _init()->void:
	super()
	mouse_filter=Control.MOUSE_FILTER_STOP
	_viewport.transparent_bg=false
	for child: Node in _viewport.get_children():
		if child is WorldEnvironment:
			child.environment.background_mode=Environment.BG_COLOR
			child.environment.background_color=Color("263337")
		if child is DirectionalLight3D:child.shadow_enabled=true
	_floor=MeshInstance3D.new()
	var plane:=PlaneMesh.new()
	plane.size=Vector2(40,40)
	_floor.mesh=plane
	_floor.position.y=-.025
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("92968c")
	material.roughness=1.0
	_floor.material_override=material
	_floor.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_viewport.add_child(_floor)
	_grid=MeshInstance3D.new()
	_grid.visible=false
	_viewport.add_child(_grid)
	_make_grid(20)
	_guide=SpriteAdventurer.new()
	_guide.skin_id="adventurer"
	_guide.visible=false
	_viewport.add_child(_guide)
	_frame()

func display(model: Node3D)->AABB:
	var bounds:=_measure(model)
	var center:=bounds.get_center()
	model.position+=Vector3(-center.x,-bounds.position.y,-center.z)
	subject_bounds=AABB(Vector3(-bounds.size.x*.5,0,-bounds.size.z*.5),bounds.size)
	_zoom=1.0
	super.show_model(model,false)
	var reach:=Vector2(bounds.size.x,bounds.size.z).length()*.5
	_guide.position=Vector3(-1,0,1).normalized()*(reach+1.0)
	_guide.visible=show_guide
	var span:=maxf(12,reach*4+8)
	(_floor.mesh as PlaneMesh).size=Vector2(span,span)
	_make_grid(mini(100,ceili(span*.5)))
	_frame()
	return bounds

func empty()->void:
	clear()
	subject_bounds=AABB()
	_guide.visible=false
	spinning=false
	_zoom=1.0
	_frame()

func set_guide(enabled: bool)->void:
	show_guide=enabled
	_guide.visible=enabled and has_model()
	_frame()

func set_grid(enabled: bool)->void:
	_grid.visible=enabled

func turn(degrees: float)->void:
	spinning=false
	_angle+=degrees
	_target=_angle
	_pivot.rotation_degrees.y=_angle
	manually_turned.emit()

func reset_view()->void:
	_zoom=1.0
	_angle=0
	_target=0
	_pivot.rotation_degrees.y=0
	spinning=false
	manually_turned.emit()
	_frame()

func _gui_input(event: InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			_zoom=clampf(_zoom*(.88 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/.88),.2,3.0)
			_camera.size=_fit_size*_zoom
			accept_event()
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		turn(-event.relative.x*.45)
		accept_event()

func _frame()->void:
	if _camera==null:return
	var reach:=Vector2(subject_bounds.size.x,subject_bounds.size.z).length()*.5
	var high: float=subject_bounds.size.y
	if has_model() and show_guide:
		reach+=1.3
		high=maxf(high,1.45)
	if not has_model():reach=5;high=0
	var offset: Vector3=ClearingView.CAMERA_OFFSET
	var elevation:=atan2(offset.y,Vector2(offset.x,offset.z).length())
	var tall:=high*cos(elevation)+2.0*reach*sin(elevation)
	var aspect:=maxf(.4,size.x/size.y) if size.y>1 else 1.4
	_fit_size=maxf(2.0,maxf(tall,2.0*reach/aspect)/FILL)
	_camera.size=_fit_size*_zoom
	_camera.far=maxf(200,reach*10+high*4)
	var target:=Vector3(0,high*.5,0)
	_camera.transform=Transform3D(Basis.looking_at(-offset,Vector3.UP),target+offset.normalized()*maxf(40,reach*4+high*2))

func _make_grid(reach: int)->void:
	var lines:=ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for index: int in range(-reach,reach+1):
		lines.surface_add_vertex(Vector3(index,.002,-reach))
		lines.surface_add_vertex(Vector3(index,.002,reach))
		lines.surface_add_vertex(Vector3(-reach,.002,index))
		lines.surface_add_vertex(Vector3(reach,.002,index))
	lines.surface_end()
	_grid.mesh=lines
	var material:=StandardMaterial3D.new()
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=Color("777f77")
	_grid.material_override=material
	_grid.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## The model's visible bounds in its own frame.
func measure(model: Node3D)->AABB:
	return _measure(model)

func _measure(model: Node3D)->AABB:
	var result:=AABB()
	var found: bool=false
	var stack: Array=[[model,model.transform,true]]
	while not stack.is_empty():
		var pair: Array=stack.pop_back()
		var node: Node3D=pair[0]
		var transform: Transform3D=pair[1]
		var shown: bool=pair[2] and node.visible
		if node is MeshInstance3D and node.mesh!=null and shown:
			var box: AABB=node.get_aabb()
			for index: int in range(8):
				var point: Vector3=transform*box.get_endpoint(index)
				if not found:result=AABB(point,Vector3.ZERO);found=true
				else:result=result.expand(point)
		for child: Node in node.get_children():
			if child is Node3D:stack.append([child,transform*child.transform,shown])
	return result if found else AABB(Vector3.ZERO,Vector3.ONE)
