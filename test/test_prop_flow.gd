extends SceneTree
## The player's real builder, nearby F action, Python preview/Apply, movement and saved working state.

var checks: int = 0
var failures: Array[String] = []
var game: Game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveStore.save_path = "user://test_working_props.json"
	SaveStore.profile_path = "user://test_working_props_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game.session.state.player = [35,5,0]
	game.view.sync_player(game.session.state)
	game.open_build()
	game.builder.choose_item("hollow-wayfarers-chest")
	_check(game.builder.hud._cards.has("hollow-wayfarers-chest") and game.builder.hud._category == "village-magic", "The real builder offers the new chest in its category")
	var placed: Dictionary = game.ledger.place("hollow-wayfarers-chest",Vector2(34,5),"S",game.session.state)
	_check(placed.ok,"The builder rules allow its footprint in the meadow")
	game.builder._after_edit("Placed Wayfarer's Chest")
	var id: String = placed.edit.id
	game.builder._select({"kind":"prop","id":id,"at":Vector2(34,5),"facing":"S","locked":false})
	var details: Dictionary = game.builder._object_subject(game.builder.selected)
	_check(details.has("code") and details.code.snippet.contains(id) and details.code.reachable,"Its standing details expose the real Python API")
	game.close_build()
	var source: String = "def program(world):\n    world.prop('%s').set_active(True)\n" % id
	game.session.set_source(source)
	await game.session.run_preview()
	_check(game.session.has_preview() and not game.session.state.props.get(id,false),"Run is a proposal and does not activate the committed object")
	_check(game.view._ghost.get_child_count()>0 and not (game.view._prop_visuals[id] as PropVisual).active,"The proposal is shown without moving the real model")
	game._refresh_interaction()
	_check(game._interaction.get("kind")=="prop" and game._interaction.label.contains("Open"),"F offers the nearby chest's declared action")
	game.interact()
	_check(game.session.state.props.get(id,false) and not game.session.has_preview(),"A manual action commits through validation and clears the stale code preview")
	_check((game.view._prop_visuals[id] as PropVisual).active,"The saved result drives the visual")
	game.interact()
	_check(not game.session.state.props.get(id,false),"F closes it again")
	await game.session.run_preview()
	_check(game.session.apply_preview() and game.session.state.props.get(id,false),"Apply commits the exact Python proposal")
	_check(game.session.undo_apply() and not game.session.state.props.get(id,false),"Program undo restores its prior state")
	game.interact()
	game.open_build()
	var moved: Dictionary = game.ledger.move_prop(id,Vector2(38,5),"E",game.session.state)
	_check(moved.ok,"An active object can be moved and turned")
	game.builder._after_edit("Moved chest")
	_check((game.view._prop_visuals[id] as PropVisual).active,"Replacing the visual during a move preserves the object's active state")
	game.close_build()
	game.save_now()
	_check(SaveStore.read().state.props.get(id,false),"Autosave stores the working state beside build edits")
	await game._return_to_title()
	await game.continue_game()
	_check(game.area.prop(id).facing=="E" and game.session.state.props.get(id,false) and (game.view._prop_visuals[id] as PropVisual).active,"Continue restores the moved object, facing and active visual")
	game.session.reset_world()
	_check(not game.session.state.props.get(id,false) and not (game.view._prop_visuals[id] as PropVisual).active,"Reset restores all working objects to their inactive state")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	if failures.is_empty():
		print("Working prop flow: %d checks passed (builder, F, Python proposal, undo, move and Continue)." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
