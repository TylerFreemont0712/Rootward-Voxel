extends SceneTree
## Export contract for all six refined models: preserved sources, independent blink and wheel/pole sides.

const Assets:=preload("res://art/world_assets.gd")
var checks: int=0
var failures: Array[String]=[]

func _initialize()->void:run.call_deferred()

func run()->void:
	for name: String in ["pip","wick","trowel","heron","tender","tally"]:
		var id: String="robot-"+name
		var spec:=Assets.entry(id)
		var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/source/world/"+id+"/v2/provenance.json"))
		_check(spec.version=="v2" and FileAccess.get_sha256("res://"+str(provenance.previous_source))==str(provenance.previous_source_sha256),id+" retains its original adopted source")
		var model:=Assets.instantiate(id)
		root.add_child(model)
		await process_frame
		var blink:=model.get_node_or_null("SparkBlink") as RobotBlink
		_check(blink!=null and not blink._eyes.is_empty(),id+" has separately tagged spark eyes")
		if blink!=null and not blink._eyes.is_empty():
			blink.set_process(false)
			var eye:=blink._eyes[0]
			var original:=eye.scale
			var untouched: Dictionary={}
			for node: Node in model.find_children("*","MeshInstance3D",true,false):
				if node!=eye:untouched[node]=(node as Node3D).scale
			blink.blink();blink._process(.065)
			_check(eye.scale.y<original.y*.12,id+" closes just the eye shapes")
			_check(untouched.keys().all(func(node: Node3D)->bool:return node.scale==untouched[node]),id+" leaves its glass, body and carried light unchanged while blinking")
			blink._process(.20)
			_check(eye.scale.is_equal_approx(original),id+" reopens to the exact original eye scale")
		var wheels: Array[Node3D]=[]
		for node: Node in model.find_children("wheel*","Node3D",true,false):
			if WorldAssetMeta.value(node,"wheel_radius",0.0)>0:wheels.append(node as Node3D)
		_check(wheels.size()>=6,id+" preserves rolling axle pivots and radii")
		for wheel: Node3D in wheels:
			var radius: float=float(WorldAssetMeta.value(wheel,"wheel_radius",.12))
			_check(radius>.03 and radius<.20 and absf(wheel.position.y-radius)<.012,id+" axle puts its wheel on the floor")
		var presenter:=WorkshopLaneStage.new()
		var route: Array[Vector3]=[Vector3.ZERO,Vector3(0,0,10)]
		var trip: Dictionary={"node":model,"points":route,"next":1,"wait":0.0,"speed":1.0,"wheels":wheels,"loop":false,"step":1,"pause":0.0}
		if not wheels.is_empty():
			var original_spin:=wheels[0].rotation.x
			presenter._roll(trip,.10)
			_check(is_equal_approx(wheels[0].rotation.x-original_spin,.10/float(WorldAssetMeta.value(wheels[0],"wheel_radius",.12))),id+" rolling angle follows travelled distance and actual wheel radius")
		presenter.free()
		model.position=Vector3.ZERO
		if name=="pip":
			_check(model.find_children("*","Node3D",true,false).all(func(node: Node)->bool:return WorldAssetMeta.value(node,"part","")!="satchel"),"Pip has no satchel after the user revision")
			_check(model.find_children("*robot_parcel*","MeshInstance3D",true,false).size()>=2,"Pip carries wrapped parcels in its cubbies")
		if name=="wick":
			var pole: Array=model.find_children("pole__*","MeshInstance3D",true,false)
			_check(not pole.is_empty() and pole.all(func(node: Node3D)->bool:return (BuildOverlay.world_aabb(node).get_center().x)>.25),"Wick’s carried pole stays in his own left hand")
		if name=="tender":
			var moss: Array=model.find_children("plants__*","MeshInstance3D",true,false)
			_check(not moss.is_empty() and moss.all(func(node: Node3D)->bool:return BuildOverlay.world_aabb(node).get_center().x<0),"Tender’s moss stays on its physical rear-right seam")
		model.queue_free()
		await process_frame
	if failures.is_empty():print("Refined robot models: %d checks passed."%checks);quit()
	else:
		for failure: String in failures:printerr(failure)
		quit(1)

func _check(condition: bool,message: String)->void:
	checks+=1
	if not condition:failures.append(message)
