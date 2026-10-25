extends SceneTree
## Real keyboard and mouse travel through a door, with isolated review saves.
var game: Game
func _initialize() -> void:go.call_deferred()
func go() -> void:
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._hint_timer.stop()
	root.grab_focus()
	game.surface.grab_focus()
	_at(Vector2i(27,6))
	await create_timer(.15).timeout
	_key(KEY_A,true)
	await create_timer(.12).timeout
	_key(KEY_A,false)
	await create_timer(1.4).timeout
	var entered: bool=game.inside_house()
	if entered:
		_at(Vector2i(int(game.area.interior.exit[0]),int(game.area.interior.exit[1])+1))
		_key(KEY_S,true)
		await create_timer(.4).timeout
		_key(KEY_S,false)
		await create_timer(1.4).timeout
	var exited: bool=not game.inside_house()
	var clicked: bool=false
	if exited:
		_at(Vector2i(29,6))
		await create_timer(.15).timeout
		var screen: Vector2=game.view.camera.unproject_position(Vector3(26.43,1.15,-6))
		var point: Vector2=game.surface.global_position+screen*game.surface.size/Vector2(game.world_viewport.size)
		for pressed: bool in [true,false]:
			var event:=InputEventMouseButton.new()
			event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed
			Input.parse_input_event(event)
		await create_timer(2.5).timeout
		clicked=game.inside_house()
	print("Door input review: keyboard enter=",entered,", keyboard exit=",exited,", click door routes and enters=",clicked)
	quit(0 if entered and exited and clicked else 1)
func _at(cell: Vector2i) -> void:
	game.session.prepare_travel()
	game.session.state.player=[cell.x,cell.y,0]
	game.view.sync_player(game.session.state)
	game.view.focus_on(Vector2(cell),true)
func _key(key: Key, pressed: bool) -> void:
	var event:=InputEventKey.new()
	event.keycode=key;event.physical_keycode=key;event.pressed=pressed
	Input.parse_input_event(event)
