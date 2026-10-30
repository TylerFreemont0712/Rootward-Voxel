class_name DoorSwing
extends RefCounted
## Swings the hinged door leaves of a placed model: every node named `door_leaf*` turns about its own vertical axis
## (the hinge) by the angle its Blender extras give as `swing` (degrees; positive opens one way, negative the other).
## Presentation only: a door's state never decides where anyone may walk.

const OPEN_SECONDS: float = 0.35


static func leaves(model: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	if model == null:
		return found
	for node: Node in model.find_children("door_leaf*", "Node3D", true, false):
		found.append(node as Node3D)
	return found


static func swing_of(leaf: Node3D) -> float:
	return deg_to_rad(float((leaf.get_meta("extras", {}) as Dictionary).get("swing", 95.0)))


## Rest angles are remembered the first time a leaf is moved, so opening and closing always return exactly.
static func _rest(leaf: Node3D) -> float:
	if not leaf.has_meta("door_rest"):
		leaf.set_meta("door_rest", leaf.rotation.y)
	return float(leaf.get_meta("door_rest"))


## Opens (or closes) every leaf of `model`; returns the tween, or null when there is nothing to swing or `seconds` is 0.
static func set_open(model: Node, open: bool, seconds: float = OPEN_SECONDS) -> Tween:
	var all: Array[Node3D] = leaves(model)
	if all.is_empty():
		return null
	var tween: Tween = null
	for leaf: Node3D in all:
		var target: float = _rest(leaf) + (swing_of(leaf) if open else 0.0)
		if seconds <= 0.0 or not leaf.is_inside_tree():
			leaf.rotation.y = target
			continue
		if tween == null:
			tween = leaf.create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT if open else Tween.EASE_IN_OUT)
		tween.tween_property(leaf, "rotation:y", target, seconds)
	return tween


static func is_open(model: Node) -> bool:
	var all: Array[Node3D] = leaves(model)
	return not all.is_empty() and all.all(func(leaf: Node3D) -> bool: return absf(leaf.rotation.y - _rest(leaf)) > 0.5)
