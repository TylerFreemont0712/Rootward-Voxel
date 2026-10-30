extends SceneTree
## Main-route selection, real title/showcase controls, isolated preview and untouched legacy saves.

var checks: int=0
var failures: Array[String]=[]
var game: Game
var output: String=""

func _initialize()->void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	_run.call_deferred()

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	SaveStore.save_path="user://test_showcase_%d.json"%OS.get_process_id()
	SaveStore.profile_path="user://test_showcase_profile_%d.json"%OS.get_process_id()
	SaveStore.force_enabled=true
	for id: String in ["kindle-hollow","village-morning",LevelStore.MAIN_LEVEL]:SaveStore.delete(id)
	_check(LevelStore.default_id()=="sparks-and-machines" and LevelStore.available_entries().map(func(item: Dictionary)->String:return item.id)==["sparks-and-machines"],"Sparks is the sole main journey")
	var legacy: Dictionary={}
	for id: String in ["kindle-hollow","village-morning"]:
		_check(LevelStore.entry(id).archived,"Legacy definition retained: "+id)
		SaveStore.write({"version":GameSession.SAVE_VERSION,"area":id,"level":id,"name":"Archived traveller"},id)
		legacy[id]=FileAccess.get_file_as_bytes(SaveStore.level_path(id))
	SaveStore.set_last_level("kindle-hollow")
	_check(LevelStore.resumable()=="sparks-and-machines","An archived last journey cannot become the main Continue target")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	if args.size()>1:game.settings.values.ui_scale=float(args[1])
	root.add_child(game)
	await _frames(5)
	await create_timer(.85).timeout
	_check(game.area.id=="workshop-loft" and not game.playing,"Startup presents Sparks without entering play or another journey")
	_check(_button(game.title,"New game")!=null and _button(game.title,"Continue")==null,"Archived-only saves do not offer Continue")
	_check(_button(game.title,"Asset Showcase (Dev)")!=null,"The developer display is written directly into the title")
	await _shot("01-title")
	var setting: bool=AssetShowcase.enabled()
	ProjectSettings.set_setting(AssetShowcase.SETTING,false)
	game.show_title()
	_check(_button(game.title,"Asset Showcase (Dev)")==null,"One development setting can hide the title entry later")
	game.open_asset_showcase()
	_check(game._modals.is_empty(),"A hidden development entry cannot be opened through the handler")
	ProjectSettings.set_setting(AssetShowcase.SETTING,setting)
	game.show_title()
	await _frames(3)
	var profile:=FileAccess.get_file_as_bytes(SaveStore.profile_path)
	var state:=game.session.state.duplicate(true)
	await _click(_button(game.title,"Asset Showcase (Dev)"))
	await _frames(5)
	var screen:=game._modals[-1] as AssetShowcase
	_check(screen!=null and not screen.stage.has_model() and screen.selection.is_empty(),"The showcase opens onto an empty stage")
	_check(not game.surface.visible and not game.title.visible and not game.session.input_enabled,"The isolated display hides the journey and keeps its input disabled")
	_check(screen.models.item_count>50,"The display exposes the existing runtime model catalog")
	await _shot("02-empty-stage")
	await _click(screen.search)
	for character: String in "workshop":
		var typed:=InputEventKey.new()
		typed.unicode=character.unicode_at(0)
		typed.pressed=true
		Input.parse_input_event(typed)
	await _frames(2)
	_check(screen.models.item_count>0 and screen.models.item_count<50,"Model search narrows the catalog")
	await _click_at(screen.models.global_position+screen.models.get_item_rect(0).get_center())
	_check(screen.selection=="lane-workshop","Selecting the first filtered catalog row displays the outlined workshop")
	await _frames(5)
	_check(screen.stage.has_model() and screen.stage.subject_bounds.size.y>2 and screen.stage._guide.visible,"A complete model and the approved scale figure share the stage")
	_check(screen.stage._camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"The display uses the game’s orthographic projection")
	for _angle: int in range(4):
		_check(_fits(screen.stage),"The whole workshop fits at quarter turn %d"%_angle)
		screen.stage.turn(90)
	await _shot("03-workshop")
	var old_angle:=screen.stage._angle
	var drag:=InputEventMouseMotion.new()
	drag.position=root.get_final_transform()*screen.stage.get_global_rect().get_center()
	drag.global_position=drag.position
	drag.relative=Vector2(60,0)
	drag.button_mask=MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(drag)
	await _frames(2)
	_check(not is_equal_approx(screen.stage._angle,old_angle),"Dragging turns the displayed model through real input")
	var before:=screen.stage._angle
	await _click(_button(screen,"Turn left"))
	_check(is_equal_approx(screen.stage._angle,before+90),"The turn control exposes another side")
	var wheel:=InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	wheel.position=root.get_final_transform()*screen.stage.get_global_rect().get_center()
	wheel.global_position=wheel.position
	var previous_size:=screen.stage._camera.size
	Input.parse_input_event(wheel)
	wheel=wheel.duplicate()
	wheel.pressed=false
	Input.parse_input_event(wheel)
	await _frames(2)
	_check(screen.stage._camera.size<previous_size,"Mouse wheel zooms the showcase without changing journey zoom")
	await _click(_checkbox(screen,"Metre grid"))
	await _click(_checkbox(screen,"Scale figure"))
	_check(screen.stage._grid.visible and not screen.stage._guide.visible,"Metre grid and scale figure can be shown independently")
	var model_id:=screen.stage._pivot.get_child(0).get_instance_id()
	await _click(_button(screen,"Reload"))
	_check(screen.stage._pivot.get_child_count()==1 and screen.stage._pivot.get_child(0).get_instance_id()!=model_id,"Reload refreshes the selected model without duplicate instances")
	_check(screen.show_asset("robot-wick"),"A wheeled robot uses the same display")
	await _click(_checkbox(screen,"Scale figure"))
	await _frames(4)
	await _shot("04-robot")
	await _click(_button(screen,"Clear"))
	_check(not screen.stage.has_model() and screen.selection.is_empty() and not screen.stage._guide.visible,"Clear restores the empty display")
	var escape:=InputEventKey.new()
	escape.keycode=KEY_ESCAPE
	escape.pressed=true
	Input.parse_input_event(escape)
	await _frames(3)
	_check(game._modals.is_empty() and game.surface.visible and game.title.visible,"Escape returns to the same title")
	_check(game.session.state==state and FileAccess.get_file_as_bytes(SaveStore.profile_path)==profile,"Displaying, turning and reloading assets cannot change progress or the profile")
	await _click(_button(game.title,"New game"))
	_check(game._modals[-1] is CharacterScreen and not (game._modals[-1] is LevelSelect),"New game enters Sparks naming directly, with no legacy journey selector")
	(game._modals[-1] as CharacterScreen).begin_requested.emit()
	while game._flow_busy:await process_frame
	await _frames(2)
	_check(game.playing and game._level_id=="sparks-and-machines" and game.area.id=="workshop-loft" and game.hud is PaperHud,"The main New game route starts the Sparks loft")
	game._pop_all_modals()
	game.session.state.memory["showcase-test"]="preserved"
	game.save_now()
	SaveStore.set_last_level("village-morning")
	await game._return_to_title()
	await _frames(3)
	_check(_button(game.title,"Continue")!=null and LevelStore.resumable()=="sparks-and-machines","Continue selects the Sparks save despite an archived last-level preference")
	await create_timer(.85).timeout
	await _click(_button(game.title,"Continue"))
	while game._flow_busy:await process_frame
	await _frames(2)
	_check(game._level_id=="sparks-and-machines" and game.session.state.memory.get("showcase-test")=="preserved","Continue restores the main journey’s progress")
	for id: String in legacy:_check(FileAccess.get_file_as_bytes(SaveStore.level_path(id))==legacy[id],"Legacy save bytes remain untouched: "+id)
	game.queue_free()
	await process_frame
	for id: String in ["kindle-hollow","village-morning",LevelStore.MAIN_LEVEL]:SaveStore.delete(id)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))
	if failures.is_empty():
		print("Main title and asset showcase: %d checks passed."%checks)
		quit()
	else:
		for failure: String in failures:printerr(failure)
		quit(1)

func _button(node: Node,text: String)->Button:
	if node is Button and node.text==text:return node
	for child: Node in node.get_children():
		var found:=_button(child,text)
		if found!=null:return found
	return null

func _checkbox(node: Node,text: String)->CheckBox:
	return _button(node,text) as CheckBox

func _frames(count: int)->void:
	for _index: int in range(count):await process_frame

func _click(control: Control)->void:
	await _click_at(control.get_global_rect().get_center())

func _click_at(point: Vector2)->void:
	point=root.get_final_transform()*point
	var motion:=InputEventMouseMotion.new()
	motion.position=point
	motion.global_position=point
	Input.parse_input_event(motion)
	await process_frame
	for pressed: bool in [true,false]:
		var event:=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=point
		event.global_position=point
		event.pressed=pressed
		Input.parse_input_event(event)
		await process_frame
	await create_timer(.22).timeout

func _fits(stage: AssetShowcaseStage)->bool:
	var viewport:=Rect2(Vector2.ZERO,Vector2(stage._viewport.size))
	for index: int in range(8):
		var point: Vector3=stage._pivot.transform*stage.subject_bounds.get_endpoint(index)
		if not viewport.has_point(stage._camera.unproject_position(point)):return false
	return true

func _shot(id: String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))

func _check(value: bool,message: String)->void:
	checks+=1
	if not value:failures.append(message)
