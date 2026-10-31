class_name WorkshopLaneStage
extends WorkshopLoftStage
## The lane outside Nell's workshop. The same robot and speech presenter as indoors; an awake Hotaru waits by the
## shop door. The street's small motions live here: chimney smoke, laundry in the breeze, the hill tram coming up
## to its last stop and going down again, gulls over the harbour. Presentation only: the area document owns every
## position (interior.life) and LabWorld owns where anyone may stand.

## One shared breeze, off the sea, so smoke and laundry agree.
const WIND := Vector3(0.09, 0.0, -0.06)

var _cloths: Array[Node3D] = []
var _tram: Node3D
var _tram_spec: Dictionary = {}
var _tram_meshes: Array[GeometryInstance3D] = []
var _gulls: Array[Dictionary] = []
## Robots going about their rounds (interior.life.robots): node, path points, wheels, next point, direction, wait.
var _rounds: Array[Dictionary] = []
var _clock: float = 0.0


func setup(scene_view: ClearingView) -> void:
	super.setup(scene_view)
	var bounce := get_node_or_null("WarmWindowBounce") as DirectionalLight3D
	if bounce != null:
		# Outdoors the second light is the sky's blue bounce from the north, not a window.
		bounce.light_color = Color("cfdcf0")
		bounce.light_energy = 0.14
	if _robot != null: _robot.visible = false
	var life: Dictionary = view.area.interior.get("life", {})
	for spec: Dictionary in life.get("smoke", []):
		var puff: CPUParticles3D = _smoke(Vector3(float(spec.at[0]), float(spec.height), -float(spec.at[1])))
		puff.name = "ChimneySmoke%d" % get_child_count()
		add_child(puff)
	for id: String in life.get("sway", []):
		var holder: Node3D = view.building_node(id)
		if holder == null: continue
		for child: Node in holder.find_children("cloth*", "Node3D", true, false):
			_cloths.append(child as Node3D)
	_tram_spec = life.get("tram", {})
	if not _tram_spec.is_empty():
		_tram = view.building_node(str(_tram_spec.asset))
		if _tram != null:
			for child: Node in _tram.find_children("*", "GeometryInstance3D", true, false):
				_tram_meshes.append(child as GeometryInstance3D)
			_place_tram(0.0)
	var gulls: Dictionary = life.get("gulls", {})
	if not gulls.is_empty():
		for index: int in range(int(gulls.count)):
			_gulls.append(_gull(Vector3(float(gulls.at[0]), float(gulls.height), -float(gulls.at[1])), index))
	for spec: Dictionary in life.get("robots", []):
		var robot: Node3D = view.building_node(str(spec.asset))
		if robot == null: continue
		var points: Array[Vector3] = []
		for point: Array in spec.path:
			points.append(Vector3(float(point[0]), robot.position.y, -float(point[1])))
		var wheels: Array[Node3D] = []
		for child: Node in robot.find_children("wheel*", "Node3D", true, false):
			wheels.append(child as Node3D)
		robot.position = points[0]
		_rounds.append({"node": robot, "points": points, "wheels": wheels, "next": 1, "step": 1, "wait": float(spec.get("pause", 0.0)),
			"speed": float(spec.speed), "pause": float(spec.get("pause", 0.0)), "loop": bool(spec.get("loop", false))})


func sync_progress(state: Dictionary, completed: Array) -> void:
	super.sync_progress(state, completed)
	if _robot != null: _robot.visible = awake


func companion_node() -> Node3D:
	return _robot if awake else null


func _process(delta: float) -> void:
	super._process(delta)
	_clock += delta
	for index: int in range(_cloths.size()):
		var cloth: Node3D = _cloths[index]
		cloth.rotation.x = 0.16 + sin(_clock * 1.7 + index * 1.3) * 0.09 + sin(_clock * 3.1 + index) * 0.03
	if _tram != null:
		var service_time: float = VillageLife.clock(view.villagers.life) if view.villagers != null else _clock
		_place_tram(service_time)
	for gull: Dictionary in _gulls: _fly(gull)
	for trip: Dictionary in _rounds: _roll(trip, delta)


## The tram's round trip: up out of the cutting, a fifteen-second wait at the halt, back down, then a long gap.
func _place_tram(time: float) -> void:
	var schedule: Dictionary = TramSchedule.sample(_tram_spec, time)
	_tram.position.x = float(schedule.x)
	# Past the cutting the car fades into its shade; the room has no ground beyond the edge.
	var shade: float = clampf((float(_tram_spec.edge) - float(schedule.x)) / float(_tram_spec.get("fade", 2.6)), 0.0, 1.0)
	_tram.visible = shade < 0.99
	for mesh: GeometryInstance3D in _tram_meshes:
		mesh.transparency = shade


## A robot rolls toward its next point, turning to face the way it goes and turning its wheels, and waits at the
## ends of its round. It also waits while the apprentice stands in its way; it never decides where anyone may walk.
func _roll(trip: Dictionary, delta: float) -> void:
	var robot: Node3D = trip.node
	var points: Array[Vector3] = trip.points
	var target: Vector3 = points[int(trip.next)]
	var heading: Vector3 = target - robot.position
	heading.y = 0.0
	if heading.length() > 0.001:
		robot.rotation.y = lerp_angle(robot.rotation.y, atan2(heading.x, heading.z), 1.0 - exp(-delta * 5.0))
	if float(trip.wait) > 0.0:
		trip.wait = float(trip.wait) - delta
		return
	var player: Node3D = view.player_node() if view != null else null
	if player != null:
		var ahead: Vector3 = player.position - robot.position
		ahead.y = 0.0
		if ahead.length() < 1.15 and ahead.dot(heading) > 0.0: return
	var travel: float = minf(float(trip.speed) * delta, heading.length())
	if heading.length() > 0.001:
		robot.position += heading.normalized() * travel
	for wheel: Node3D in trip.wheels:
		wheel.rotation.x += travel / clampf(float(WorldAssetMeta.value(wheel,"wheel_radius",.12)),.02,1.0)
	if robot.position.distance_to(target) > 0.01: return
	var last: int = points.size() - 1
	var next: int = int(trip.next)
	if bool(trip.loop):
		trip.next = (next + 1) % points.size()
		trip.wait = float(trip.pause) if next == 0 else 0.7
	elif next == last or next == 0:
		trip.step = -int(trip.step)
		trip.next = next + int(trip.step)
		trip.wait = float(trip.pause)
	else:
		trip.next = next + int(trip.step)
		trip.wait = 0.7


func _smoke(at: Vector3) -> CPUParticles3D:
	var puff := CPUParticles3D.new()
	puff.name = "ChimneySmoke"
	puff.position = at
	puff.amount = 18
	puff.lifetime = 6.5
	puff.preprocess = 6.5
	puff.local_coords = false
	puff.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 0.06
	puff.direction = Vector3(0, 1, 0)
	puff.spread = 10.0
	puff.initial_velocity_min = 0.16
	puff.initial_velocity_max = 0.26
	puff.gravity = WIND + Vector3(0, 0.03, 0)
	puff.damping_min = 0.02
	puff.damping_max = 0.05
	puff.scale_amount_min = 0.7
	puff.scale_amount_max = 1.0
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.35))
	grow.add_point(Vector2(1, 1.6))
	puff.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_offset(0, 0.0)
	fade.set_color(0, Color(0.95, 0.93, 0.9, 0.0))
	fade.set_offset(1, 1.0)
	fade.set_color(1, Color(0.9, 0.9, 0.9, 0.0))
	fade.add_point(0.15, Color(0.96, 0.94, 0.9, 0.5))
	fade.add_point(0.6, Color(0.92, 0.92, 0.92, 0.28))
	puff.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.55, 0.55)
	var soft := StandardMaterial3D.new()
	soft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	soft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soft.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	soft.vertex_color_use_as_albedo = true
	soft.albedo_texture = _soft_dot()
	soft.disable_receive_shadows = true
	quad.material = soft
	puff.mesh = quad
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return puff


static func _soft_dot() -> GradientTexture2D:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.45, Color(1, 1, 1, 0.75))
	var dot := GradientTexture2D.new()
	dot.gradient = ramp
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.width = 64
	dot.height = 64
	return dot


## A gull: two pale wings on a small body, wheeling slowly over the harbour side of the rail.
func _gull(centre: Vector3, index: int) -> Dictionary:
	var body := Node3D.new()
	body.name = "Gull%d" % index
	add_child(body)
	var feather := StandardMaterial3D.new()
	feather.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	feather.albedo_color = Color("f4f1ea")
	feather.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wings: Array[Node3D] = []
	for side: float in [-1.0, 1.0]:
		var hinge := Node3D.new()
		body.add_child(hinge)
		var wing := MeshInstance3D.new()
		var shape := PrismMesh.new()
		shape.size = Vector3(0.36, 0.02, 0.14)
		shape.left_to_right = 0.0 if side < 0 else 1.0
		wing.mesh = shape
		wing.material_override = feather
		wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing.position = Vector3(side * 0.18, 0, 0)
		hinge.add_child(wing)
		wings.append(hinge)
	var tip := MeshInstance3D.new()
	var torso := CapsuleMesh.new()
	torso.radius = 0.035
	torso.height = 0.2
	tip.mesh = torso
	tip.rotation.x = PI * 0.5
	tip.material_override = feather
	tip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(tip)
	return {"node": body, "wings": wings, "centre": centre, "radius": 2.2 + index * 0.9, "speed": 0.16 + index * 0.035, "phase": index * 2.1, "lift": index * 0.7}


func _fly(gull: Dictionary) -> void:
	var angle: float = _clock * float(gull.speed) + float(gull.phase)
	var centre: Vector3 = gull.centre
	var at := centre + Vector3(cos(angle) * float(gull.radius), float(gull.lift) + sin(angle * 0.7) * 0.3, sin(angle) * float(gull.radius) * 0.6)
	var body: Node3D = gull.node
	body.position = at
	body.rotation.y = -angle
	var beat: float = sin(_clock * 6.0 + float(gull.phase)) * 0.45 if fmod(_clock * 0.3 + float(gull.phase), 3.0) < 1.2 else 0.12
	var wings: Array[Node3D] = gull.wings
	wings[0].rotation.z = beat
	wings[1].rotation.z = -beat
