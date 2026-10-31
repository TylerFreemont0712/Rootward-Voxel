class_name VillagerView
extends Node3D
## Appearance and interpolation of the pure VillageLife state, using the shared character template.

var view: ClearingView
var actors: Dictionary = {}
var phantoms: Dictionary = {}
var robots: Dictionary = {}
var speakers: Dictionary = {}
var life: Dictionary = {}
var rules: LabWorld
var paused: bool = false
var _arrival_pending: bool = true


func setup(clearing: ClearingView) -> void:
	view = clearing
	name = "Villagers"
	life = VillageLife.initial(view.area)
	rules = LabWorld.new(view.area)
	var people: Dictionary = AreaStore.read_villagers()
	for resident: Dictionary in view.area.villagers:
		if resident.has("phantom"):
			var phantom := PhantomActor.new()
			phantom.profile = str(resident.phantom)
			phantom.name = str(resident.id)
			add_child(phantom)
			phantom.position = Vector3(resident.at.x, view._deck_height(Vector2(resident.at)), -resident.at.y)
			phantom.set_presence(float(life[resident.id].presence))
			phantoms[resident.id] = phantom
			continue
		if resident.has("object"):
			var robot: Node3D = view.building_node(str(resident.object))
			if robot == null:
				push_error("Missing resident robot: " + str(resident.object))
				continue
			var wheels: Array[Node3D] = []
			for part: Node in robot.find_children("wheel*", "Node3D", true, false):
				wheels.append(part as Node3D)
			robots[resident.id] = {"node": robot, "wheels": wheels, "previous": Vector2(resident.at)}
			continue
		if not resident.has("skin") and not people.has(resident.id):
			push_error("Unknown resident identity: " + str(resident.id))
			continue
		var actor := SpriteAdventurer.new()
		actor.skin_id = str(resident.skin) if resident.has("skin") else str(people[resident.id].skin)
		actor.name = str(resident.id)
		add_child(actor)
		actor.position = Vector3(resident.at.x, view._deck_height(Vector2(resident.at)), -resident.at.y)
		actors[resident.id] = actor
		if not resident.has("skin"):
			speakers[resident.id] = true


func near(point: Vector2, distance: float = 1.9) -> String:
	var found: String = ""
	var best: float = distance
	var level: int = view.area.level_at(Vector2i(floori(point.x + 0.5), floori(point.y + 0.5)))
	for id: String in speakers:
		var at: Vector3 = (actors[id] as Node3D).position
		var apart: float = point.distance_to(Vector2(at.x, -at.z))
		# Nobody talks up or down a cliff.
		if view.area.level_at(Vector2i(floori(at.x + 0.5), floori(-at.z + 0.5))) != level:
			continue
		if apart < best:
			best = apart
			found = id
	return found


## Turns a resident to look at a logical point, such as the player who has come to talk.
func face(id: String, toward: Vector2) -> void:
	if not actors.has(id):
		return
	var actor: SpriteAdventurer = actors[id]
	var at := Vector2(actor.position.x, -actor.position.z)
	if not at.is_equal_approx(toward):
		actor.face_screen_direction(view._screen_direction(toward - at))


func _physics_process(delta: float) -> void:
	if view == null or view._committed.is_empty():
		return
	if _arrival_pending:
		VillageLife.clear_arrival(view.area, rules, view._committed, life, view.player_cells())
		_arrival_pending = false
		for id: String in robots:
			robots[id].previous = VillageLife.position(life[id])
	if not paused:
		VillageLife.advance(view.area, rules, view._committed, life, delta, view.player_cells())


func _process(delta: float) -> void:
	if view == null or view._committed.is_empty():
		return
	for id: String in actors:
		var state: Dictionary = life[id]
		var actor: SpriteAdventurer = actors[id]
		var at: Vector2 = VillageLife.position(state)
		actor.position = Vector3(at.x, view._deck_height(at), -at.y)
		var motion: Vector2 = Vector2(state.to - state.from) if float(state.phase) < 1.0 and not paused else Vector2.ZERO
		actor.set_screen_motion(view._screen_direction(motion) if motion != Vector2.ZERO else Vector2.ZERO)
	for id: String in phantoms:
		var state: Dictionary = life[id]
		var phantom: PhantomActor = phantoms[id]
		phantom.set_presence(float(state.presence) if state.active else 0.0)
		if not state.active: continue
		var at: Vector2 = VillageLife.position(state)
		phantom.position = Vector3(at.x, view._deck_height(at), -at.y)
		var motion := Vector2(state.to - state.from) if float(state.phase) < 1.0 and not paused else Vector2.ZERO
		phantom.set_screen_motion(view._screen_direction(motion) if motion != Vector2.ZERO else Vector2.ZERO)
	for id: String in robots:
		var state: Dictionary = life[id]
		var appearance: Dictionary = robots[id]
		var robot: Node3D = appearance.node
		var at: Vector2 = VillageLife.position(state)
		robot.position = Vector3(at.x, view._deck_height(at), -at.y)
		var direction := Vector2(state.to - state.from)
		if direction != Vector2.ZERO and not paused:
			robot.rotation.y = lerp_angle(robot.rotation.y, atan2(direction.x, -direction.y), 1.0 - exp(-delta * 7.0))
		var travel: float = at.distance_to(appearance.previous)
		for wheel: Node3D in appearance.wheels:
			var radius: float = clampf(float(WorldAssetMeta.value(wheel, "wheel_radius", 0.12)) * robot.scale.x, 0.02, 3.0)
			wheel.rotation.x += travel / radius
		appearance.previous = at
