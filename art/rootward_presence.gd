class_name RootwardPresence
extends Node3D
## Cosmetic light only. Lantern and wisp positions are authored in the Blender model.
## Three instanced draws, a bounded handful of lights, no collision or game commands.

const FADE_START: float=8.0
const FADE_END: float=10.0

var _wisps: Array[Vector3]=[]
var _motes: MultiMesh
var _halos: MultiMesh
var _lanterns: MultiMesh
var _time: float=0.0


func _ready() -> void:
	var source: Node3D=get_parent() as Node3D
	# The complete tree remains in its adopted source. Its spreading crown and
	# boughs stay out of the village view, including their large ground shadows.
	for node: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var role: String=str((node.get_meta("extras",{}) as Dictionary).get("part",""))
		if role in ["Crown","Boughs"]:
			node.hide()
			continue
		var mesh_to_tree: Transform3D=source.global_transform.affine_inverse()*node.global_transform
		if (mesh_to_tree*node.mesh.get_aabb()).end.y<=FADE_START:continue
		# A soft cutaway avoids an exposed pointed top, and lets the trunk imply
		# the rest of the giant tree overhead. Keep its painted/emissive surfaces.
		for surface: int in range(node.mesh.get_surface_count()):
			var original:=node.get_active_material(surface) as StandardMaterial3D
			if original==null:continue
			var material:=ShaderMaterial.new()
			material.shader=preload("res://art/rootward_cutaway.gdshader")
			if original.albedo_texture!=null:material.set_shader_parameter("painted_albedo",original.albedo_texture)
			material.set_shader_parameter("base_colour",original.albedo_color)
			material.set_shader_parameter("glow_colour",original.emission if original.emission_enabled else Color.BLACK)
			material.set_shader_parameter("glow_strength",original.emission_energy_multiplier)
			material.set_shader_parameter("surface_roughness",original.roughness)
			material.set_shader_parameter("surface_metallic",original.metallic)
			material.set_shader_parameter("mesh_to_tree",mesh_to_tree)
			material.set_shader_parameter("fade_start",FADE_START)
			material.set_shader_parameter("fade_end",FADE_END)
			node.set_surface_override_material(surface,material)
	for node: Node in source.find_children("RootwardWisp_*","Node3D",true,false):
		_wisps.append((node as Node3D).position)
	var anchors: Array[Node]=source.find_children("RootwardLight_*","Node3D",true,false).filter(func(node: Node) -> bool:return (node as Node3D).position.y<=FADE_START)
	_lanterns=_batch(anchors.size(),true)
	for i: int in range(anchors.size()):
		var anchor: Vector3=(anchors[i] as Node3D).position
		_lanterns.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*1.9),anchor))
		_lanterns.set_instance_color(i,_colour(i,.65))
		# A bounded handful of lower lanterns illuminate the bole and roots.
		if i%5==0:
			var light:=OmniLight3D.new()
			light.position=anchor
			light.light_color=_colour(i,1)
			light.light_energy=.55
			light.omni_range=4.0
			light.shadow_enabled=false
			add_child(light)
	_motes=_batch(_wisps.size(),false)
	_halos=_batch(_wisps.size(),true)
	for i: int in range(_wisps.size()):
		_motes.set_instance_color(i,_colour(i,1))
		_halos.set_instance_color(i,_colour(i,.55))
	_process(0)


func _batch(count: int,halo: bool) -> MultiMesh:
	var batch:=MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	if halo:
		var quad:=QuadMesh.new()
		quad.size=Vector2.ONE
		var material:=ShaderMaterial.new()
		material.shader=preload("res://art/rootward_glow.gdshader")
		quad.material=material
		batch.mesh=quad
	else:
		var sphere:=SphereMesh.new()
		sphere.radius=.5;sphere.height=1;sphere.radial_segments=8;sphere.rings=4
		var material:=StandardMaterial3D.new()
		material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo=true
		sphere.material=material
		batch.mesh=sphere
	batch.instance_count=count
	var node:=MultiMeshInstance3D.new()
	node.multimesh=batch
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return batch


func _colour(index: int,alpha: float) -> Color:
	var color: Color=[Color("ffda89"),Color("fff1b4"),Color("8cffe0"),Color("d4adff")][index%4]
	color.a=alpha
	return color


func _process(delta: float) -> void:
	if _motes==null:return
	_time+=delta
	for i: int in range(_wisps.size()):
		var phase: float=float(i)*2.39996
		var at: Vector3=_wisps[i]+Vector3(sin(_time*.43+phase)*.45,sin(_time*.81+phase)*.32,cos(_time*.37+phase)*.40)
		var pulse: float=.7+.3*sin(_time*1.6+phase)
		_motes.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(.045+.025*pulse)),at))
		_halos.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*(.50+.26*pulse)),at))
