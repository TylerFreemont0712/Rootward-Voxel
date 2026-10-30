class_name RoomStage
extends Node3D
## A room's story presentation beyond its static shell: the things its scenes move and the companion who lives
## there. Rooms without one keep today's behaviour. Rendering only: rules and collision stay in LabWorld.

var view: ClearingView


## The stage for an area's room style, or null for every room that has none.
static func for_area(area: AreaDef) -> RoomStage:
	match str(area.interior.get("style", "")):
		"workshop-loft":
			return WorkshopLoftStage.new()
		"workshop-floor":
			return WorkshopFloorStage.new()
		"workshop-lane", "workshop-square":
			return WorkshopLaneStage.new()
	return null


func setup(scene_view: ClearingView) -> void:
	view = scene_view


## True when this room brings its own companion instead of the fairy.
func replaces_companion() -> bool:
	return false


func companion_node() -> Node3D:
	return null


## Committed progress only. A test proposal must never advance a room's story.
func sync_progress(_state: Dictionary, _completed: Array) -> void:
	pass


## Where a speech mark sits over the companion, in world space.
func companion_anchor() -> Vector3:
	var node: Node3D = companion_node()
	return node.global_position + Vector3(0, .45, 0) if node != null else Vector3.ZERO


## Where the camera looks while this room's job is being written: {"at": Vector2 cell, "zoom": float}, or {}.
func frame() -> Dictionary:
	var raw: Variant = view.area.interior.get("stage", {}).get("frame", {}) if view != null else {}
	if not raw is Dictionary or not raw.has("at"):
		return {}
	return {"at": Vector2(float(raw.at[0]), float(raw.at[1])), "zoom": float(raw.get("zoom", 10.0))}
