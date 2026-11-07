class_name WorkshopLoftRoom
extends RefCounted
## The Sparks loft: adopted shell and bespoke furniture. The area document owns
## every placement and blocking footprint; meshes never decide traversal.


static func build(area: AreaDef, place: Callable) -> void:
	var shell: String = str(area.interior.get("shell", ""))
	if shell == "" or not place.is_valid():
		push_error("The workshop loft needs interior.shell and a way to place world assets.")
		return
	for item: Dictionary in placements(area):
		place.call(item.asset, item.at, item.scale, item.turn, item.id, item.get("look"))


static func build_async(area: AreaDef, place: Callable) -> void:
	var frame_start: int = Time.get_ticks_usec()
	for item: Dictionary in placements(area):
		await place.call(item.asset, item.at, item.scale, item.turn, item.id, item.get("look"))
		if Time.get_ticks_usec() - frame_start >= 5000:
			await (Engine.get_main_loop() as SceneTree).process_frame
			frame_start = Time.get_ticks_usec()


static func placements(area: AreaDef) -> Array[Dictionary]:
	var names: Dictionary = {"workshop-floor":"WorkshopShell", "workshop-lane":"LaneSet", "workshop-square":"SquareSet"}
	var result: Array[Dictionary] = [{"asset":str(area.interior.shell), "at":Vector3.ZERO,
		"scale":1.0, "turn":0.0, "id":str(names.get(area.interior.get("style"), "LoftShell"))}]
	for item: Dictionary in area.interior.get("assets", []):
		result.append({"asset":str(item.asset), "at":Vector3(float(item.at[0]), float(item.get("height",0)), -float(item.at[1])),
			"scale":float(item.get("scale",1)), "turn":float(item.get("turn",0)), "id":str(item.id), "look":item.get("look")})
	return result
