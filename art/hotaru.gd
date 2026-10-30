class_name HotaruFairy
extends Node3D
## A tiny winged light in the world. The detailed fairy is reserved for dialogue.
## Cosmetic only: no grid occupancy, commands or collision.
const TEXTURE: String="res://assets/companions/hotaru.png"
const ORB_RADIUS: float=.06
var target: Node3D
var orb: MeshInstance3D
var wings: Array[Node3D]=[]
var _wing_rig: Node3D
var _time: float=0.0

func _ready() -> void:
	name="Hotaru"
	orb=_ellipsoid(Vector3.ONE*ORB_RADIUS,Color("fff3b8"),false)
	add_child(orb)
	var halo:=_ellipsoid(Vector3.ONE*.105,Color(1,.89,.53,.12),true)
	add_child(halo)
	_wing_rig=Node3D.new()
	add_child(_wing_rig)
	for index: int in range(4):
		var side: float=-1.0 if index%2==0 else 1.0
		var lower: bool=index>=2
		var hinge:=Node3D.new()
		hinge.position=Vector3(side*.025,0,0)
		_wing_rig.add_child(hinge)
		var wing:=_ellipsoid(Vector3(.034,.082 if not lower else .058,.009),Color(.83,1,.95,.72),true)
		wing.position=Vector3(side*.052,.067 if not lower else -.041,.006)
		hinge.add_child(wing)
		wings.append(hinge)
	if is_instance_valid(target):global_position=target.global_position+Vector3(.55,1.25,-.16)
	_animate(0)

func _ellipsoid(dimensions: Vector3,color: Color,transparent: bool) -> MeshInstance3D:
	var mesh:=SphereMesh.new()
	mesh.radius=1;mesh.height=2
	mesh.radial_segments=12;mesh.rings=6
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled=true
	material.emission=color
	material.emission_energy_multiplier=.7
	if transparent:material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	var node:=MeshInstance3D.new()
	node.mesh=mesh;node.material_override=material;node.scale=dimensions
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

func _process(delta: float) -> void:
	if not is_instance_valid(target):return
	_time+=delta
	var destination: Vector3=target.global_position+Vector3(.55,1.25+sin(_time*3.4)*.045,-.16)
	global_position=global_position.lerp(destination,1.0-exp(-delta*7.0))
	var camera:=get_viewport().get_camera_3d()
	if camera!=null:_wing_rig.global_basis=camera.global_basis
	_animate(_time)

func _animate(time: float) -> void:
	for index: int in range(wings.size()):
		var side: float=-1.0 if index%2==0 else 1.0
		wings[index].rotation=Vector3(0,side*sin(time*48.0+(.55 if index>=2 else 0))*.95,side*(-.5 if index<2 else .55))
	orb.scale=Vector3.ONE*ORB_RADIUS*(1.0+sin(time*4)*.045)
