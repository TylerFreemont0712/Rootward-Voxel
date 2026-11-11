# INACTIVE EXPERIMENT: visually rejected; preserve the original painted runtime character. See pipeline/CHARACTERS.md.
@tool
class_name CutoutRig
extends Node2D
## Native layered 2D rig. Clips are ordinary artist-editable Godot Animation resources.

const Skins := preload("res://art/cutout_skin.gd")
@export var skin_id: String = "adventurer"
var facing: String = "se"
var moving: bool = false
var skin: Dictionary = {}
var attachments: Dictionary = {}
var animation_name: String = "idle_se"
@onready var player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	set_skin(skin_id)
	player.play("idle_se")


func set_skin(id: String) -> void:
	skin_id = id
	skin = Skins.load_skin(id)
	if str(skin.rig_family) != "chibi_v1":
		push_error("Skin does not fit the chibi_v1 rig family.")
		return
	_apply_view()


func set_motion(direction: String, walking: bool) -> void:
	var changed: bool = direction != facing
	facing = direction
	var next: String = ("walk_" if walking else "idle_") + direction
	if changed:
		_apply_view()
	if animation_name == next:
		return
	var old_time: float = player.current_animation_position
	var old_length: float = player.current_animation_length
	var keep_phase: bool = moving and walking and old_length > 0.0
	moving = walking
	animation_name = next
	player.play(next, 0.10 if not changed else 0.0)
	if keep_phase:
		player.seek(fposmod(old_time / old_length, 1.0) * player.get_animation(next).length, true)


func equip_demo_staff(enabled: bool) -> void:
	var socket: Marker2D = find_child("item_r", true, false) as Marker2D
	if socket == null:
		return
	var old: Node = socket.get_node_or_null("DemoStaff")
	if old != null:
		old.free()
	if enabled:
		var staff := Line2D.new()
		staff.name = "DemoStaff"
		staff.width = 4.0
		staff.default_color = Color("90613c")
		staff.points = PackedVector2Array([Vector2(0, 16), Vector2(0, -44)])
		socket.add_child(staff)


func _apply_view() -> void:
	if skin.is_empty():
		return
	var view: Dictionary = skin.views[facing]
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/rigs/chibi_v1/rig.json"))
	for slot: String in rig.slots:
		var spec: Dictionary = rig.slots[slot]
		var art: Sprite2D = get_node(NodePath(str(spec.path) + "/Art")) as Sprite2D
		art.texture = Skins.texture_for(skin, facing, slot)
		art.flip_h = bool(view.mirror)
		var size: Vector2 = Vector2(float(spec.size[0]), float(spec.size[1]))
		art.scale = size / art.texture.get_size()
		art.position = Vector2(float(spec.offset[0]), float(spec.offset[1]))
		if spec.has("joints"):
			var start := Vector2(float(spec.joints[0][0]), float(spec.joints[0][1])) * art.texture.get_size()
			var end := Vector2(float(spec.joints[1][0]), float(spec.joints[1][1])) * art.texture.get_size()
			if bool(view.mirror):
				start.x = art.texture.get_width() - start.x
				end.x = art.texture.get_width() - end.x
			art.offset = -start
			art.position = Vector2.ZERO
			art.rotation = PI / 2 - (end - start).angle()
			art.scale = Vector2.ONE * float(spec.length) / start.distance_to(end)
		art.modulate = Color(str(skin.get("tints", {}).get(slot, "ffffff")))
		art.z_as_relative = false
		art.z_index = int(spec.z)
		if slot.ends_with("_l") or slot.ends_with("_r"):
			var near_left: bool = bool(view.mirror) != facing.begins_with("n")
			var near: bool = slot.ends_with("_l") == near_left
			art.z_index = 12 if near else -12
			if slot.begins_with("thigh") or slot.begins_with("shin") or slot.begins_with("boot"):
				art.z_index = -2 if near else -8
		attachments[slot] = art
	var item: Marker2D = find_child("item_r", true, false) as Marker2D
	if item != null:
		item.z_as_relative = false
		item.z_index = int(attachments.hand_r.z_index) + 1
