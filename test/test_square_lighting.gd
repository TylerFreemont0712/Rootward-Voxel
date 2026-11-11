extends SceneTree
## Every section stays inside Compatibility lighting limits; lights stay at their fittings.
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var view:=WorldView.new()
	root.add_child(view)
	await process_frame
	view.setup(AreaStore.load_area("haverlund-square"))
	var state:=LabWorld.new(view.area).initial_state()
	for id: String in state.lamps:state.lamps[id]=true
	view.apply_state(state)
	var lights: Array[Node]=view.find_children("*","OmniLight3D",true,false)
	var worst: Array[Dictionary]=[]
	for part: Node in view._content.find_children("*","MeshInstance3D",true,false):
		var mesh:=part as MeshInstance3D
		if mesh.name==&"IllustratedOutline":continue
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		var affected: Array[String]=[]
		for node: Node in lights:
			var lamp:=node as OmniLight3D
			if not lamp.is_visible_in_tree():continue
			if (lamp.light_cull_mask & mesh.layers) == 0:continue
			var nearest: Vector3=lamp.global_position.clamp(box.position,box.end)
			if nearest.distance_squared_to(lamp.global_position)<pow(lamp.omni_range*lamp.global_basis.get_scale().x,2):affected.append(lamp.get_parent().name)
		if affected.size()>8:worst.append({"mesh":str(mesh.get_path()),"lights":affected})
	var failures: Array[String] = []
	if not worst.is_empty(): failures.append("Meshes exceed eight real lights: " + JSON.stringify(worst.slice(0,5)))
	if view._lamps.size() != view.area.lamps.size(): failures.append("A logical lamp has no binding")
	var positions: Dictionary = {}
	for id: String in view._lamps:
		var fitting: Node3D = view._lamps[id]
		if fitting.find_children("*", "OmniLight3D", true, false).size() != 1: failures.append("Duplicate light at " + id)
		positions[id] = (fitting.get_node("FixtureLight") as OmniLight3D).global_position
	for point: Vector2 in [Vector2(1,8), Vector2(70,44), Vector2(41,49)]:
		view.focus_on(point, true)
		for id: String in view._lamps:
			var fitting: Node3D = view._lamps[id]
			var light := fitting.get_node("FixtureLight") as OmniLight3D
			if not light.global_position.is_equal_approx(positions[id]): failures.append("Camera moved light " + id)
			if light.visible != (fitting.get_meta("glass") as Node3D).is_visible_in_tree(): failures.append("Camera distance hid light " + id)
	var dark: Dictionary = state.duplicate(true)
	for id: String in dark.lamps: dark.lamps[id] = false
	view.apply_state(dark)
	view.apply_state(state,true)
	view.clear_preview()
	for fitting: Node3D in view._lamps.values():
		var light := fitting.get_node("FixtureLight") as OmniLight3D
		if light.visible: failures.append("Cleared preview left a real light on")
	view.apply_state(state)
	var cycle := CityCycle.fresh()
	CityCycle.set_pressure(cycle,15)
	view.set_city_cycle(CityCycle.time(cycle),CityCycle.power(cycle))
	for fitting: Node3D in view._lamps.values():
		if (fitting.get_node("FixtureLight") as OmniLight3D).visible: failures.append("Supply trip left a light on")
	CityCycle.at_hour(cycle,23.0)
	view.set_city_cycle(CityCycle.time(cycle),CityCycle.power(cycle))
	var mist: Array[Node]=view._content.find_children("LowerTownMist*","MeshInstance3D",false,false)
	if mist.size()!=1:failures.append("The lower wall has no height-based depth overlay")
	for layer: MeshInstance3D in mist:
		if layer.layers!=2 or float((layer.material_override as ShaderMaterial).get_shader_parameter("daylight"))>.01:failures.append("Night leaves a pale or locally lit mist layer")
		var material:=layer.material_override as ShaderMaterial
		if float(material.get_shader_parameter("fade_bottom"))> -6.0 or float(material.get_shader_parameter("fade_top"))-float(material.get_shader_parameter("fade_bottom"))<3.0:failures.append("Mist has no gradual transition at twice the previous depth")
	for issue: String in failures: printerr("FAIL: ",issue)
	print("Square lighting: %d fittings; %d over-budget meshes; %d failures." % [view._lamps.size(),worst.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
