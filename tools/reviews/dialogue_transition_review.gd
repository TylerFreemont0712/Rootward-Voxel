extends SceneTree
## Native visual and cadence review. Scratch progress; no regular save/settings are touched.
var game: Game
var output: String
var failures: Array[String] = []
var timings: Dictionary = {}
func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	# A review window may lose OS focus while the user works. Measure the active
	# play cap without changing focus or the normal game's background policy.
	process_frame.connect(func() -> void: Engine.max_fps=Game.FRAME_RATE)
	_run.call_deferred()
func _run() -> void:
	output = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else ProjectSettings.globalize_path("res://.cache/dialogue-transitions/native")
	DirAccess.make_dir_recursive_absolute(output)
	SaveStore.save_path="user://dialogue_transition_review_%d.json" % OS.get_process_id()
	SaveStore.profile_path="user://dialogue_transition_profile_%d.json" % OS.get_process_id()
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game._pop_all_modals()
	game.close_notebook(true)
	game.settings.set_value("dialogue_speed",0)
	_check(DevelopmentMode.jump(game,"hello-end"),"Opening conversation fixture")
	game._dialogue_read.clear()
	game._show_story_scene("loft-waking")
	for frame: int in range(4): await process_frame
	var dialogue := game._modals[-1] as DialogueWindow
	await _shot("01-dialogue-hotaru")
	_check(dialogue.card.get_rect().end.y < game.size.y*.95 and dialogue.card.get_rect().end.x < game.size.x*.90,"Dialogue box is raised and inset to the marked proportions")
	_check(dialogue._portrait.size.x > dialogue._player_portrait.size.x,"Hotaru has the larger portrait stage")
	while dialogue._choices.get_child_count()==0 and dialogue.index<dialogue.pages.size()-1: dialogue.advance()
	await process_frame
	await _shot("02-dialogue-choices")
	if dialogue._choices.get_child_count()>0:
		dialogue._choose(dialogue._page.choices[0])
		await _shot("03-dialogue-player")
	game._pop_all_modals()
	var previous: int = game.world_viewport.render_target_update_mode
	game.world_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	for preset: Dictionary in [{"id":"low","strength":.16,"stability":.25,"restored_links":0},{"id":"steady","strength":.65,"stability":1.0,"restored_links":1},{"id":"restored","strength":1.0,"stability":1.0,"restored_links":3}]:
		game._veil.set_world_state({"city_power":preset})
		game._veil.set_status("City-power study · "+str(preset.id).capitalize())
		await game._veil.close(Vector2(.5,.5),.12)
		await create_timer(.5).timeout
		await _shot("04-gears-"+str(preset.id))
		if preset.id=="restored":
			for frame: int in range(48):
				await create_timer(.05).timeout
				await _shot("gears-motion-%03d" % frame)
		await game._veil.open(Vector2(.5,.5),.12)
	game.world_viewport.render_target_update_mode=previous as SubViewport.UpdateMode
	_check(DevelopmentMode.jump(game,"workshop-end"),"Natural travel fixture")
	game._dismissed_scenes=game._story.scenes.keys()
	await _cross(Vector2i(13,4),Vector2i.RIGHT,"lane")
	await _cross(Vector2i(13,26),Vector2i(0,1),"square")
	await _cross(Vector2i(0,8),Vector2i.LEFT,"return")
	game.open_development()
	for frame: int in range(3): await process_frame
	await _shot("09-dev-power-previews")
	var report := FileAccess.open(output.path_join("cadence.json"),FileAccess.WRITE)
	report.store_string(JSON.stringify({"resolution":root.size,"renderer":RenderingServer.get_video_adapter_name(),"transitions":timings,"failures":failures},"  ")+"\n")
	for failure: String in failures: printerr("FAIL: ",failure)
	print("Dialogue / loading native review: ","passed" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
func _cross(at: Vector2i, direction: Vector2i, label: String) -> void:
	game._pop_all_modals()
	game.session.state.player=[at.x,at.y,0]
	game.view.sync_player(game.session.state)
	game.session.request_step(direction)
	var previous: int = Time.get_ticks_usec()
	var cadence: Dictionary = {}
	var frames: Dictionary = {}
	var walk_correct: bool = true
	var recorded: Dictionary = {}
	var guard: int=0
	while game._flow_busy and guard<3600:
		await process_frame
		guard+=1
		var now: int=Time.get_ticks_usec()
		var phase: String=game.transition_phase
		if not cadence.has(phase): cadence[phase]=[]
		cadence[phase].append((now-previous)/1000.0)
		previous=now
		if game.view._body is SpriteActor and game.view._travel_motion!=Vector2.ZERO:
			var sprite: AnimatedSprite3D=(game.view._body as SpriteActor).sprite
			walk_correct=walk_correct and str(sprite.animation).begins_with("walk_") and sprite.is_playing()
			frames[sprite.frame]=true
			if not recorded.has(phase) and phase in ["covering","revealing"]:
				recorded[phase]=true
				await _shot("07-"+label+"-"+phase)
				previous=Time.get_ticks_usec()
	_check(walk_correct and frames.size()>2,"Real travelling walk changes animation frames: "+label)
	var measurement: Dictionary = {"warmup":game.last_transition.duplicate(),"phases":{}}
	for phase: String in cadence:
		var samples: Array=cadence[phase]
		samples.sort()
		measurement.phases[phase]={"frames":samples.size(),"p95_ms":samples[mini(samples.size()-1,floori(samples.size()*.95))],"max_ms":samples[-1]}
		print(label," ",phase,": frames=",samples.size()," p95_ms=",samples[mini(samples.size()-1,floori(samples.size()*.95))]," max_ms=",samples[-1])
	timings[label] = measurement
	print(label," warmup ",game.last_transition)
	await _shot("08-"+label+"-arrived")
func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func _check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures.append(message)
