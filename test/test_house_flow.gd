extends SceneTree
## Actual scene transitions, isolated house state, return points and Continue while indoors.

var checks: int = 0
var failures: Array[String] = []
var game: Game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveStore.save_path = "user://test_house_flow.json"
	SaveStore.profile_path = "user://test_house_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game("kindle-hollow")
	_check(game.view.villagers.actors.size() == 5, "All five village residents are instantiated")
	_check((game.view._body as SpriteAdventurer).skin_id == "adventurer", "The player is the approved boy")
	game.session.state.lamps["landing-lamp"] = true
	var exterior_terrain: PackedByteArray = game.area.terrain.duplicate()
	var exterior_edits: Array = game.ledger.edits.duplicate(true)
	_at_door("home")
	_check(await game.enter_house("home"), "The front doorstep opens a house instance")
	_check(game.inside_house() and not game.area.interior.is_empty() and game.view.ground_skin == null, "The active scene is a furnished separate room")
	_check(game.view._lamp_lights.size() == ClearingView.LIGHT_POOL and is_instance_valid(game.view._lamp_lights[0]), "Room changes replace the light pool without stale scene references")
	_check(not game.session.state.lamps["hearth-lamp"], "A new room begins with its own lamp state")
	game.session.state.lamps["hearth-lamp"] = true
	game.session.state.memory = {"room_marker": "first home"}
	game.save_now()
	var saved: Dictionary = SaveStore.read()
	_check(saved.area == "kindle-hollow" and saved.state.lamps["landing-lamp"] == true and saved.travel.active == "kindle-hollow/home", "Saving indoors preserves the exterior and active room address")
	_at_exit()
	_check(await game.leave_house(), "The room's door returns outdoors")
	_check(game.session.state.lamps["landing-lamp"] == true and game.area.terrain == exterior_terrain and game.ledger.edits == exterior_edits, "Leaving preserves valley state, terrain and build edits")
	_check(game.session.player_cell() == HouseInstances.door(game.area, "home"), "The player returns to this house's doorstep")
	_at_door("row-north-a")
	_check(await game.enter_house("row-north-a"), "A second house opens the same template as a distinct instance")
	_check(not game.session.state.lamps["hearth-lamp"] and not game.session.state.memory.has("room_marker"), "Room lamp and memory do not leak to another house")
	game.session.state.memory = {"room_marker": "second home"}
	game.save_now()
	await game._return_to_title()
	_check(not game.playing and game.view.area.id == "kindle-hollow", "The title returns to the outdoor view without losing the saved room")
	await game.continue_game("kindle-hollow")
	_check(game.inside_house() and game._inside_id == "kindle-hollow/row-north-a" and game.session.state.memory.get("room_marker") == "second home", "Continue resumes inside the correct house")
	_at_exit()
	await game.leave_house()
	_at_door("home")
	await game.enter_house("home")
	_check(game.session.state.memory.get("room_marker") == "first home" and game.session.state.lamps["hearth-lamp"], "The first home retains its own changes after visiting and resuming another")
	game._confirm_reset()
	(game._modals[-1] as ConfirmDialog).confirmed.emit()
	_check(not game.session.state.lamps["hearth-lamp"] and game.session.state.memory.is_empty() and game._outer_save.state.lamps["landing-lamp"], "Resetting a room clears only that room and preserves the valley")
	game.open_build()
	_check(not game.builder.active and game._modals[-1] is RoomFinishes, "Indoors B offers materials while the outdoor building shelf stays closed")
	(game._modals[-1] as RoomFinishes).close()
	_check((game.view._body as SpriteAdventurer).skin_id == "adventurer", "Room transitions preserve the player's identity")
	_at_exit()
	await game.leave_house()
	_at_door("mira-house")
	await game.enter_house("mira-house")
	_check(game.view.villagers != null and game.view.villagers.actors.has("mira") and game.area.title == "Mira's home", "A resident's house presents its owner with the correct home identity")
	_at_exit()
	await game.leave_house()
	var placed: Dictionary = game.ledger.place("concept-cottage", Vector2(34, 5), "S", game.session.state)
	_check(placed.ok, "The outdoor builder can add the new enterable concept cottage")
	game.area = game.ledger.area
	game.view.sync_edits(game.area, false)
	game.session.replace_area(game.area, game.ledger.rules)
	_at_door(placed.edit.id)
	_check(await game.enter_house(placed.edit.id) and game._inside_id == "kindle-hollow/" + str(placed.edit.id), "A player-built house opens its own saved room through normal travel")
	_at_exit()
	await game.leave_house()
	# Existing version-1 saves have no travel block; Continue still loads them normally.
	var legacy: Dictionary = game.session.to_save()
	legacy["edits"] = []
	SaveStore.write(legacy)
	await game._return_to_title()
	SaveStore.write(legacy)
	await game.continue_game("kindle-hollow")
	_check(not game.inside_house() and game.area.id == "kindle-hollow", "An older save without instances remains loadable")
	# Travel is now triggered by walking into the door, with the real hinged mesh.
	game.session.set_physics_process(false)
	_at_door("home")
	_check(game.session.request_step(Vector2i.LEFT) and game._flow_busy, "Walking inward starts the actual door transition without F")
	var stationary: Vector3=game.view._player.position
	var hinge := game.view.building_node("home").find_child("DoorHinge*",true,false) as Node3D
	_check(hinge != null, "The adopted exterior contains a separate hinged leaf")
	await create_timer(0.08).timeout
	_check(hinge != null and absf(hinge.rotation.y)>0.01, "The hinged leaf opens before the transition")
	_check(game.view._player.position.is_equal_approx(stationary),"Exterior entry fades on the current space without phasing into the leaf")
	while game._flow_busy:await process_frame
	_check(game.inside_house() and game._inside_id=="kindle-hollow/home", "The walk-in fades to the correct saved interior")
	_at_exit()
	_check(game.session.request_step(Vector2i(0, -1)), "Walking out through the interior frame leaves the house")
	while game._flow_busy:await process_frame
	_check(not game.inside_house() and game.session.player_cell()==HouseInstances.door(game.area,"home"), "Walking out restores the same safe exterior approach")
	await create_timer(0.15).timeout
	_check(not game.inside_house() and not game._flow_busy,"Standing on the returned doorstep does not enter again")
	var landing:=HouseInstances.door(game.area,"home")
	var outward: Vector2i=HouseInstances.OUTWARD[game.area.building("home").facing]
	var outer: Vector2i=landing+outward
	game.session.prepare_travel()
	game.session.state.player=[outer.x,outer.y,0]
	game.view.sync_player(game.session.state)
	_check(game.session.request_step(-outward) and not game._flow_busy,"Walking to the landing does not open the door a tile early")
	game.session.advance_walk(.12)
	_check((game.view._body as SpriteAdventurer).animation_name.begins_with("walk_"),"The approach uses the approved walking animation")
	game.session.advance_walk(1.0)
	_check(game.session.player_cell()==landing and not game._flow_busy,"The normal step finishes on the landing")
	_check(game.session.request_step(-outward) and game._flow_busy,"The next step toward the frame opens the door")
	while game._flow_busy:await process_frame
	_at_exit()
	await game.leave_house()
	_check(game.session.player_cell()==landing and not game.session.rules.is_walkable(game.session.state,landing-outward),"Leaving returns outside the closed threshold")
	# Click routing selects an entrance before a route into an occupied building.
	_check(game.session.walk_to(Vector2i(24,6)) and game.session._route_door=="home", "Clicking a building routes to its own door")
	game.session._cancel_route()
	var away: Vector2i=landing+outward*3
	game.session.state.player=[away.x,away.y,0];game.view.sync_player(game.session.state)
	_check(game.session.walk_to_door("home") and not game.session._route.is_empty() and game.session._route[-1]==landing,"Click routing walks all the way to the door landing")
	_check(not game.session._route.has(landing-outward),"The route never walks into the closed threshold")
	game.session._cancel_route()
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	if failures.is_empty():
		print("House travel and saves: %d checks passed." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)


func _at_door(id: String) -> void:
	game.session.prepare_travel()
	var at: Vector2i = HouseInstances.door(game.area, id)
	game.session.state.player = [at.x, at.y, 0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()


func _at_exit() -> void:
	game.session.prepare_travel()
	var at: Array = game.area.interior.exit
	game.session.state.player = [int(at[0]), int(at[1]), 0]
	game.view.sync_player(game.session.state)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
