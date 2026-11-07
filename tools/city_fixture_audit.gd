extends SceneTree
## Inspect every actual runtime binding, including hidden optional house lanterns and supply loss.
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for id: String in LevelStore.entry("sparks-and-machines").room_areas:
		var area: AreaDef=AreaStore.load_area(id)
		var view:=ClearingView.new()
		root.add_child(view)
		await process_frame
		view.setup(area)
		_check(view._lamps.size()==area.lamps.size(),"Every logical fitting has a real runtime binding in "+id)
		var state: Dictionary=LabWorld.new(area).initial_state()
		for lamp_id: String in state.lamps:state.lamps[lamp_id]=true
		var cycle: Dictionary=CityCycle.fresh()
		CityCycle.at_hour(cycle,22)
		view.set_city_cycle(CityCycle.time(cycle),CityCycle.power(cycle))
		view.apply_state(state)
		await process_frame
		for lamp_id: String in view._lamps:
			var fitting: Node3D=view._lamps[lamp_id]
			var glass:=fitting.get_meta("glass") as MeshInstance3D
			var light:=fitting.get_node("FixtureLight") as OmniLight3D
			_check(glass.material_override==fitting.get_meta("lit"),id+"/"+lamp_id+" has committed illuminated glass")
			_check(light.visible==glass.is_visible_in_tree(),id+"/"+lamp_id+" lights only its visible fixture")
		var dark: Dictionary=state.duplicate(true)
		for lamp_id: String in dark.lamps:dark.lamps[lamp_id]=false
		view.apply_state(dark)
		view.apply_state(state,true)
		await process_frame
		for fitting: Node3D in view._lamps.values():
			_check((fitting.get_node("Halo") as Node3D).visible==(fitting.get_meta("glass") as Node3D).is_visible_in_tree(),"Preview respects optional hidden lantern geometry in "+id)
		CityCycle.set_pressure(cycle,15)
		view.set_city_cycle(CityCycle.time(cycle),CityCycle.power(cycle))
		await process_frame
		for fitting: Node3D in view._lamps.values():
			_check(not (fitting.get_node("FixtureLight") as OmniLight3D).visible,"The city breaker removes actual fixture light in "+id)
		view.queue_free()
		await process_frame
	for issue: String in failures:printerr("FAIL: ",issue)
	print("Runtime city fixtures: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message)
