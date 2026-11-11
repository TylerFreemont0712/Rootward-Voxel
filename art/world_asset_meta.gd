class_name WorldAssetMeta
extends RefCounted
## Blender custom properties arrive in glTF's extras dictionary in Godot.

static func value(node: Node,key: StringName,fallback: Variant=null)->Variant:
	if node.has_meta(key):return node.get_meta(key)
	var extras: Variant=node.get_meta("extras",{})
	return (extras as Dictionary).get(key,fallback) if extras is Dictionary else fallback
