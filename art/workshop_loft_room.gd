class_name WorkshopLoftRoom
extends RefCounted
## The Sparks loft: adopted shell and bespoke furniture. The area document owns
## every placement and blocking footprint; meshes never decide traversal.


static func build(area: AreaDef, place: Callable) -> void:
	var shell: String = str(area.interior.get("shell", ""))
	if shell == "" or not place.is_valid():
		push_error("The workshop loft needs interior.shell and a way to place world assets.")
		return
	var names: Dictionary = {"workshop-floor": "WorkshopShell", "workshop-lane": "LaneSet", "workshop-square": "SquareSet"}
	place.call(shell, Vector3.ZERO, 1.0, 0.0, str(names.get(area.interior.get("style"), "LoftShell")))
	for item: Dictionary in area.interior.get("assets", []):
		var at: Array = item.at
		place.call(str(item.asset), Vector3(float(at[0]), float(item.get("height", 0.0)), -float(at[1])),
			float(item.get("scale", 1.0)), float(item.get("turn", 0.0)), str(item.id), item.get("look"))
