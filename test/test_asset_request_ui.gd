extends SceneTree
## Input-driven authoring lifecycle, with every write/delete confined to a disposable source fixture.

var checks: int=0
var failures: Array[String]=[]
var game: Game
var screen: AssetShowcase
var fixture: String
var output: String=""

func _initialize()->void:
	OS.set_environment("VOXEL_LAB_FRESH","1")
	_run.call_deferred()

func _run()->void:
	var args:=OS.get_cmdline_user_args()
	if not args.is_empty():output=args[0]
	fixture=ProjectSettings.globalize_path("res://.cache/asset-workflow-ui-%d"%OS.get_process_id())
	var result: Array=[]
	var code:=OS.execute("python3",[ProjectSettings.globalize_path("res://tools/asset_workflow_fixture.py"),fixture],result,true)
	_check(code==0,"Create a disposable source checkout for real filesystem operations")
	game=(load("res://scenes/game.tscn") as PackedScene).instantiate()
	if args.size()>1:game.settings.values.ui_scale=float(args[1])
	root.add_child(game)
	await create_timer(.9).timeout
	game.open_asset_showcase()
	screen=game._modals[-1] as AssetShowcase
	screen.workflow.project_root=fixture
	screen.refresh_workflow()
	await _frames(4)
	_check(screen.show_asset("robot-wick"),"A real robot stays visible while using an isolated request store")
	await _click(_button(screen,"Request update"))
	var form:=screen._dialog as AssetRequestDialog
	_check(form!=null and form.notes.text.is_empty(),"Update opens with optional notes")
	form.notes.text="Lower the lamp arm slightly. Keep the pole in Wick’s own left hand.\nPreserve the wheel base."
	for index: int in range(form.reference_picker.item_count):
		if str(form.reference_picker.get_item_metadata(index))=="lane-workshop":form.reference_picker.select(index)
	await _click(_button(form,"Add"))
	_check(form.references.item_count==1,"A dropdown reference can be added to a request")
	await _shot("01-update-request")
	await _click(form.submit_button)
	if screen._requests.is_empty():printerr(form._error.text);quit(1);return
	_check(screen._dialog==null and screen._requests.size()==1,"Saving writes and closes the request form")
	var update: Dictionary=screen._requests[0]
	_check(update.notes.contains("own left hand") and update.references[0].id=="lane-workshop","Notes and style references reach the agent record exactly")
	_check(FileAccess.file_exists(fixture.path_join("asset-requests/requests/"+str(update.id)+".md")),"A main-folder agent brief exists")
	screen.filter.select(1)
	screen.filter.item_selected.emit(1)
	_check(screen.models.item_count==1 and screen.models.get_item_metadata(0)=="robot-wick","Requested filter shows the asset awaiting changes")
	_check(screen.models.request_mark(0)=="update" and screen.models.get_item_custom_bg_color(0)==AssetRequestList.UPDATE_TINT,"Updates have a yellow row and a right-hand square")
	await _shot("02a-update-marker")
	await _click(_button(screen,"Request new"))
	form=screen._dialog as AssetRequestDialog
	form.asset_name.text="Seaside repair kiosk"
	form.notes.text="A narrow open-front stall, warm timber and brass, with a little tool hatch."
	for index: int in range(form.reference_picker.item_count):
		if str(form.reference_picker.get_item_metadata(index))=="lane-workshop":form.reference_picker.select(index)
	await _click(_button(form,"Add"))
	await _shot("02-new-request")
	await _click(form.submit_button)
	_check(screen._requests.size()==2,"New asset requests join the same persistent queue")
	var finished:=screen.workflow.call_operation("finish",[str(update.id),"--assets","robot-wick","--summary","Fixture build and review verified","--review","pipeline/reviews/fixture-review.md"])
	_check(finished.ok,"The authoring tool can deliver audited assets to Finished")
	screen.refresh_workflow()
	screen.filter.select(2)
	screen.filter.item_selected.emit(2)
	_check(screen.models.item_count==1 and screen.models.get_item_metadata(0)=="robot-wick","Finished assets have a separate list in the same menu")
	_check(screen.models.request_mark(0).is_empty(),"Finished work clears its update marker")
	screen.show_asset("robot-wick")
	await _shot("03-finished-assets")
	await _click(_button(screen,"Requests"))
	var queue:=screen._dialog as AssetRequestQueue
	_check(queue!=null and queue.requests.item_count==2,"The request list includes new work and finished updates")
	for index: int in range(queue.requests.item_count):
		if queue.requests.get_item_metadata(index).id==update.id:
			queue.requests.select(index)
			queue.requests.item_selected.emit(index)
	_check(queue.details.get_parsed_text().contains("Lower the lamp arm") and not queue.accept_button.disabled,"Queue details retain the prose notes and expose finished acceptance")
	await _shot("04-request-queue")
	await _click(queue.accept_button)
	_check(screen.models.item_count==0,"Accepting removes the asset from the Finished queue")
	await _click(_button(queue,"Close"))
	screen.filter.select(0)
	screen.filter.item_selected.emit(0)
	screen.show_asset("robot-wick")
	await _click(_button(screen,"Delete"))
	form=screen._dialog as AssetRequestDialog
	_check(form.submit_button.text=="Request deletion","In-use assets offer a dependency-linked deletion request")
	form.notes.text="Review the placement before removing this model."
	await _shot("05-in-use-delete")
	await _click(form.submit_button)
	_check(FileAccess.file_exists(fixture.path_join("assets/world/robot-wick/model.glb")),"Requesting deletion keeps a referenced model intact")
	for index: int in range(screen.models.item_count):
		if screen.models.get_item_metadata(index)=="robot-wick":
			_check(screen.models.request_mark(index)=="delete" and screen.models.get_item_custom_bg_color(index)==AssetRequestList.DELETE_TINT,"Deletion requests have a red row and a right-hand X")
	screen._requests.push_front({"kind":"update","status":"requested","asset":{"id":"robot-wick"}})
	_check(screen._request_marker("robot-wick")=="delete","A deletion request takes priority when the same asset also has an open update")
	screen._requests.pop_front()
	screen.search.text="robot-wick"
	screen.search.text_changed.emit("robot-wick")
	await _frames(3)
	await _shot("05a-delete-marker")
	screen.selection="review-candidate"
	screen._update_actions()
	await _click(_button(screen,"Delete"))
	form=screen._dialog as AssetRequestDialog
	_check(form.submit_button.text=="Delete asset","An unused, exclusively owned asset offers actual deletion")
	form.notes.text="Remove this unused review fixture."
	await _shot("06-delete-confirmation")
	await _click(form.submit_button)
	_check(not DirAccess.dir_exists_absolute(fixture.path_join("art/source/world/review-candidate")) and not DirAccess.dir_exists_absolute(fixture.path_join("assets/world/review-candidate")),"Delete removes both source and runtime folders from the project")
	_check(not screen._assets.has("review-candidate") and screen.selection.is_empty(),"Deletion removes the catalog entry and clears the stage")
	var observer:=AssetWorkflowClient.new()
	observer.project_root=fixture
	var persisted:=observer.call_operation("overview")
	_check(persisted.ok and persisted.data.requests.size()==4,"A fresh client sees requests, acceptance and deletion after reopening")
	_check(FileAccess.file_exists("res://assets/world/robot-wick/model.glb") and FileAccess.file_exists("res://art/source/world/robot-wick/v1/model.blend"),"Production artwork remains untouched by the lifecycle review")
	game.queue_free()
	await _frames(2)
	_remove_tree(fixture)
	if failures.is_empty():print("Asset request UI: %d checks passed."%checks);quit()
	else:
		for failure: String in failures:printerr(failure)
		quit(1)

func _button(node: Node,label: String)->Button:
	if node is Button and node.text==label:return node
	for child: Node in node.get_children():
		var found:=_button(child,label)
		if found!=null:return found
	return null

func _click(control: Control)->void:
	await _frames(2)
	var point:=root.get_final_transform()*control.get_global_rect().get_center()
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
	await create_timer(.23).timeout

func _frames(count: int)->void:
	for index: int in range(count):await process_frame

func _shot(id: String)->void:
	if output.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(output)
	await create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))

func _remove_tree(path: String)->void:
	var directory:=DirAccess.open(path)
	if directory==null:return
	for file: String in directory.get_files():directory.remove(file)
	for folder: String in directory.get_directories():_remove_tree(path.path_join(folder))
	DirAccess.remove_absolute(path)

func _check(condition: bool,message: String)->void:
	checks+=1
	if not condition:failures.append(message)
