extends SceneTree
## One-time native rig/motion bootstrap. Source resources become artist-owned after this.

const ScenePath: String = "res://art/rigs/chibi_v1/rig.tscn"
const MotionPath: String = "res://art/rigs/chibi_v1/motion.tres"
const RigScript := preload("res://art/cutout_rig.gd")
var paths: Dictionary = {}
var config: Dictionary


func _initialize() -> void:
	if FileAccess.file_exists(ScenePath) or FileAccess.file_exists(MotionPath):
		printerr("Rig/motion source already exists. Edit it visually; seeding never overwrites artist changes.")
		quit(1)
		return
	config = JSON.parse_string(FileAccess.get_file_as_string("res://art/rigs/chibi_v1/rig.json"))
	var rig := Node2D.new()
	rig.name = "CharacterRig"
	rig.set_script(RigScript)
	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	rig.add_child(skeleton)
	skeleton.owner = rig
	for id: String in config.bones:
		var spec: Dictionary = config.bones[id]
		var bone := Bone2D.new()
		bone.name = id
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(float(spec.length))
		bone.set_bone_angle(PI / 2)
		bone.position = Vector2(float(spec.position[0]), float(spec.position[1]))
		var parent: Node = skeleton if str(spec.parent) == "" else rig.get_node(NodePath(paths[spec.parent]))
		parent.add_child(bone)
		bone.owner = rig
		bone.rest = bone.transform
		paths[id] = str(rig.get_path_to(bone))
	for slot: String in config.slots:
		var spec: Dictionary = config.slots[slot]
		var sprite := Sprite2D.new()
		sprite.name = "Art"
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var holder := Node2D.new()
		holder.name = "slot_" + slot
		rig.get_node(NodePath(spec.bone)).add_child(holder)
		holder.owner = rig
		holder.add_child(sprite)
		sprite.owner = rig
	var socket := Marker2D.new()
	socket.name = "item_r"
	rig.get_node(NodePath(paths.hand_r)).add_child(socket)
	socket.owner = rig
	var library := AnimationLibrary.new()
	for direction: String in ["se", "sw", "ne", "nw"]:
		library.add_animation("walk_" + direction, _clip(direction, true))
		library.add_animation("idle_" + direction, _clip(direction, false))
	ResourceSaver.save(library, MotionPath)
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library("", load(MotionPath) as AnimationLibrary)
	rig.add_child(player)
	player.owner = rig
	var packed := PackedScene.new()
	packed.pack(rig)
	ResourceSaver.save(packed, ScenePath)
	rig.free()
	print("Seeded native Skeleton2D, 16 attachments, hand socket and eight editable continuous clips.")
	quit(0)


func _clip(direction: String, walking: bool) -> Animation:
	var clip := Animation.new()
	clip.length = 0.60 if walking else 1.80
	clip.loop_mode = Animation.LOOP_LINEAR
	var tracks: Dictionary = {}
	for id: String in paths:
		for property: String in ["position", "rotation"]:
			var track: int = clip.add_track(Animation.TYPE_VALUE)
			clip.track_set_path(track, NodePath(str(paths[id]) + ":" + property))
			clip.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
			tracks[id + ":" + property] = track
	var steps: int = 24 if walking else 16
	for frame: int in range(steps + 1):
		var phase: float = float(frame) / float(steps)
		var pose: Dictionary = _pose(direction, walking, phase)
		for id: String in pose:
			clip.track_insert_key(tracks[id + ":position"], phase * clip.length, pose[id].position)
			clip.track_insert_key(tracks[id + ":rotation"], phase * clip.length, pose[id].rotation)
	return clip


func _pose(direction: String, walking: bool, phase: float) -> Dictionary:
	var pose: Dictionary = {}
	var mirror: float = -1.0 if direction.ends_with("w") else 1.0
	var travel := Vector2(mirror * 0.88, -0.42 if direction.begins_with("n") else 0.42)
	var wave: float = sin(phase * TAU)
	for id: String in config.bones:
		var rest: Array = config.bones[id].position
		pose[id] = {"position": Vector2(float(rest[0]) * (mirror if id != "hips" else 1.0), float(rest[1])), "rotation": 0.0}
	pose.hips.position.y += -2.0 * absf(wave) if walking else -10.0 + sin(phase * TAU) * 1.2
	pose.spine.rotation = mirror * wave * (0.025 if walking else 0.008)
	pose.head.rotation = -pose.spine.rotation * 0.7
	for side: String in ["l", "r"]:
		var offset: float = 0.0 if side == "l" else 0.5
		var leg_phase: float = fposmod(phase + offset, 1.0)
		var swing: float = sin(leg_phase * TAU)
		pose["upper_arm_" + side].rotation = mirror * (-swing * 0.38 if walking else wave * 0.025)
		pose["forearm_" + side].rotation = mirror * (-0.12 - maxf(0, swing) * 0.18 if walking else -0.08)
		var hip: Vector2 = pose.hips.position + pose["thigh_" + side].position
		var ankle := Vector2(192 + (-12 if side == "l" else 12) * mirror, 315)
		if walking:
			var stride: float = lerpf(20.0, -20.0, leg_phase * 2.0) if leg_phase < 0.5 else lerpf(-20.0, 20.0, (leg_phase - 0.5) * 2.0)
			ankle += travel * stride
			if leg_phase >= 0.5:
				ankle.y -= sin((leg_phase - 0.5) * TAU) * 13.0
		var delta: Vector2 = ankle - hip
		var distance: float = clampf(delta.length(), 4.0, 65.5)
		ankle = hip + delta.normalized() * distance
		var along: float = (34.0 * 34.0 - 32.0 * 32.0 + distance * distance) / (2.0 * distance)
		var perpendicular: Vector2 = Vector2(-delta.y, delta.x).normalized()
		var knee: Vector2 = hip + delta.normalized() * along - perpendicular * sqrt(maxf(0.0, 34.0 * 34.0 - along * along)) * mirror
		var thigh_angle: float = (knee - hip).angle() - PI / 2
		pose["thigh_" + side].rotation = thigh_angle
		pose["shin_" + side].rotation = (ankle - knee).angle() - PI / 2 - thigh_angle
		pose["boot_" + side].rotation = -thigh_angle - pose["shin_" + side].rotation
	return pose
