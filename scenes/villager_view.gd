class_name VillagerView
extends Node3D
## Appearance and interpolation of the pure VillageLife state, using the shared character template.

var view: ClearingView
var actors: Dictionary = {}
var life: Dictionary = {}
var rules: LabWorld
var paused: bool = false


func setup(clearing: ClearingView) -> void:
	view = clearing
	name = "Villagers"
	life = VillageLife.initial(view.area)
	rules = LabWorld.new(view.area)
	var people: Dictionary = AreaStore.read_villagers()
	for resident: Dictionary in view.area.villagers:
		if not people.has(resident.id):
			push_error("Unknown resident identity: " + str(resident.id))
			continue
		var actor := SpriteAdventurer.new()
		actor.skin_id = str(people[resident.id].skin)
		actor.name = str(resident.id)
		add_child(actor)
		actor.position = Vector3(resident.at.x, view._deck_height(Vector2(resident.at)), -resident.at.y)
		actors[resident.id] = actor


func near(point: Vector2, distance: float = 1.9) -> String:
	var found: String = ""
	var best: float = distance
	var level: int = view.area.level_at(Vector2i(floori(point.x + 0.5), floori(point.y + 0.5)))
	for id: String in actors:
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


func _process(delta: float) -> void:
	if view == null or view._committed.is_empty():
		return
	if not paused:
		VillageLife.advance(view.area, rules, view._committed, life, minf(delta, 0.1), view.player_cells())
	for id: String in actors:
		var state: Dictionary = life[id]
		var actor: SpriteAdventurer = actors[id]
		var at: Vector2 = VillageLife.position(state)
		actor.position = Vector3(at.x, view._deck_height(at), -at.y)
		var motion: Vector2 = Vector2(state.to - state.from) if float(state.phase) < 1.0 and not paused else Vector2.ZERO
		actor.set_screen_motion(view._screen_direction(motion) if motion != Vector2.ZERO else Vector2.ZERO)
