extends SceneTree
## Meshing geometry, non-mutating power presentation, bounded outline work and animated real travel.
var checks: int = 0
var failures: Array[String] = []
var game: Game
const OutlineJob := preload("res://art/outline_job.gd")

func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	_run.call_deferred()

func _run() -> void:
	_gears()
	await _outline()
	await _dialogue()
	await _travel()
	for failure: String in failures: printerr("FAIL: ",failure)
	print("Dialogue and transitions: %d checks, %d failures." % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func _gears() -> void:
	for spec: Dictionary in ClockworkGears.TRAIN:
		var z: int = int(spec.teeth)
		var shape: PackedVector2Array = GearGeometry.outline(z)
		_check(shape.size() >= z*20 and Geometry2D.triangulate_polygon(shape).size() > 0,"Involute wheel is a complete drawable solid")
		if int(spec.parent) < 0: continue
		var parent_z: int = int(ClockworkGears.TRAIN[int(spec.parent)].teeth)
		var bearing: float = float(spec.bearing)
		var separation: Vector2 = Vector2.from_angle(bearing)*(GearGeometry.pitch(z)+GearGeometry.pitch(parent_z))
		var driver: PackedVector2Array = GearGeometry.outline(parent_z)
		var overlap: float = 0
		for sample: int in range(36):
			var angle: float = sample*TAU/(36.0*parent_z)
			var following: float = GearGeometry.mesh_angle(angle,parent_z,z,bearing)
			var a := PackedVector2Array()
			var b := PackedVector2Array()
			for point: Vector2 in driver: a.append(point.rotated(angle))
			for point: Vector2 in shape: b.append(point.rotated(following)+separation)
			for intersection: PackedVector2Array in Geometry2D.intersect_polygons(a,b): overlap += absf(_area(intersection))
		_check(overlap < 1.0,"Meshed pair %d:%d has clearance through a whole tooth engagement (%0.3f square px overlap)" % [parent_z,z,overlap])
		var advance: float = GearGeometry.mesh_angle(.5,parent_z,z,bearing)-GearGeometry.mesh_angle(0,parent_z,z,bearing)
		_check(is_equal_approx(advance,-.5*parent_z/z),"Follower angular speed follows the tooth-count ratio")
	var veil := GearVeil.new()
	root.add_child(veil)
	var state: Dictionary = {"city_power":{"strength":1.5,"stability":-.5,"restored_links":99}}
	var before: Dictionary = state.duplicate(true)
	veil.set_world_state(state)
	_check(veil.clockwork.power == {"strength":1.0,"pressure":5.6,"online":true,"stability":0.0,"restored_links":3} and state == before,"City power is bounded presentation data and never mutates progression")
	veil.set_world_state({})
	_check(veil.clockwork.power.strength == .56 and veil.clockwork.power.stability == 1.0,"A journey without the city power system keeps its normal loading appearance")
	veil.queue_free()

func _outline() -> void:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 64
	mesh.rings = 40
	var synchronous: ArrayMesh = IllustratedEdges._hull(mesh)
	var job := OutlineJob.new(mesh)
	job.advance(1)
	_check(not job.done,"Large outline construction yields before completing all vertices")
	var chunks: int = 1
	while not job.done:
		job.advance(1000)
		chunks += 1
		await process_frame
	var a: Array = synchronous.surface_get_arrays(0)
	var b: Array = job.result.surface_get_arrays(0)
	_check(chunks > 1 and a[Mesh.ARRAY_VERTEX] == b[Mesh.ARRAY_VERTEX] and a[Mesh.ARRAY_NORMAL] == b[Mesh.ARRAY_NORMAL] and a[Mesh.ARRAY_INDEX] == b[Mesh.ARRAY_INDEX],"Incremental and ordinary outlines have identical geometry")

func _dialogue() -> void:
	var settings := GameSettings.new()
	settings.set_value("dialogue_speed",0)
	for dimensions: Vector2 in [Vector2(1600,1000),Vector2(1280,720)]:
		var host := Control.new()
		host.size = dimensions
		root.add_child(host)
		var scene := DialogueWindow.new()
		host.add_child(scene)
		scene.setup({"pages":[{"speaker":"hotaru","text":"A longer story passage stays readable as the dialogue window becomes smaller. ".repeat(45),"choices":[{"text":"I arrived last night."},{"text":"How long have you been here?"},{"text":"What is Nell working on?"}]}]},null,settings)
		for frame: int in range(4): await process_frame
		_check(scene.card.get_rect().end.y <= dimensions.y-64 and scene.card.get_rect().end.x < dimensions.x*.9,"The dialogue leaves the HUD and right margin clear at "+str(dimensions))
		var scroll := scene._text_box as ScrollContainer
		_check(scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page and scroll.size.y > 80,"Long story text remains accessible in a scrolling text column")
		var fit: bool = true
		for choice: Control in scene._choices.get_children(): fit = fit and choice.get_rect().end.y <= scene._side.size.y
		_check(fit and scene._choices.get_child_count()==3,"Three replies fit inside the raised dialogue window")
		_check(scene._portrait.get_rect().position.y >= 0 and scene._player_portrait.get_rect().end.x <= dimensions.x and scene._portrait.size.x > scene._player_portrait.size.x,"Both full portraits stay on screen and Hotaru has the larger stage")
		scene._show_page({"speaker":"player","text":"A reply."})
		_check(scene._player_portrait.modulate==Color.WHITE and scene._portrait.modulate.r<1.0 and scroll.scroll_vertical==0,"A reply highlights the traveller and resets story scrolling")
		host.queue_free()
		await process_frame

func _travel() -> void:
	SaveStore.save_path = "user://transition_test_%d.json" % OS.get_process_id()
	SaveStore.profile_path = "user://transition_profile_test_%d.json" % OS.get_process_id()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._pop_all_modals()
	game.close_notebook(true)
	_check(DevelopmentMode.jump(game,"workshop-end"),"Set up the existing workshop chapter")
	game._dismissed_scenes = game._story.scenes.keys()
	await _cross(Vector2i(13,4),Vector2i.RIGHT,"haverlund-lane")
	await _cross(Vector2i(13,26),Vector2i(0,1),"haverlund-square")
	var uphill := RoomLinks.find(game.area,"uphill")
	await _cross(Vector2i(uphill.at[0],uphill.at[1]),Vector2i.LEFT,"haverlund-lane")
	var before: Dictionary = game.session.to_save()
	await game.preview_loading_power({"strength":.15,"stability":.25,"restored_links":0,"label":"Low power"})
	_check(game.session.to_save() == before and not game._veil.visible,"The power-study preview leaves the journey unchanged")
	game.queue_free()

func _cross(at: Vector2i, direction: Vector2i, destination: String) -> void:
	game._pop_all_modals()
	game.session.state.player = [at.x,at.y,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(direction)
	var frames: Dictionary = {}
	var positions: Dictionary = {}
	var loading_frames: int = 0
	var walking: int = 0
	var correct: bool = true
	var guard: int = 0
	while game._flow_busy and guard < 3600:
		await process_frame
		guard += 1
		if game.transition_phase == "loading": loading_frames += 1
		if game.view._body is SpriteActor and game.view._travel_motion != Vector2.ZERO:
			var sprite: AnimatedSprite3D = (game.view._body as SpriteActor).sprite
			game.view.set_player_motion(Vector2.ZERO)
			correct = correct and str(sprite.animation).begins_with("walk_") and sprite.is_playing()
			frames[sprite.frame] = true
			positions[game.view.player_node().position] = true
			walking += 1
	_check(game.area.id == destination and not game._flow_busy,"Real input completes travel to " + destination)
	_check(correct and walking > 5 and frames.size() > 2 and positions.size() > 3,"The traveller changes walking frames while moving, despite disabled normal input")
	_check(loading_frames > 2 and int(game.last_transition.warm_frames) >= Game.VEIL_WARM_FRAMES and float(game.last_transition.closed_seconds) >= Game.VEIL_CLOSED_SECONDS,"Scene construction yields frames and warms the renderer under full cover")
	_check(game.view._travel_motion == Vector2.ZERO and not game._veil.visible,"Travel releases animation ownership and removes the veil")

func _area(points: PackedVector2Array) -> float:
	var result: float = 0
	for index: int in range(points.size()): result += points[index].cross(points[(index+1)%points.size()])
	return result*.5

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
