extends SceneTree
## All six current models beside the approved boy at the square's size-16 camera.

func _initialize()->void:run.call_deferred()

func run()->void:
	root.content_scale_size=root.size
	var args:=OS.get_cmdline_user_args()
	if args.is_empty():quit(2);return
	var stage:=AssetShowcaseStage.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(stage)
	stage.set_guide(false)
	var group:=Node3D.new()
	var names: Array[String]=["pip","wick","trowel","heron","tender","tally"]
	var models: Array[Node3D]=[]
	for index: int in range(names.size()):
		var model: Node3D=load("res://art/world_assets.gd").instantiate("robot-"+names[index])
		model.position=Vector3(1,0,-1).normalized()*(index-2.5)*1.5
		group.add_child(model)
		models.append(model)
	var boy:=SpriteAdventurer.new()
	boy.skin_id="adventurer"
	boy.position=Vector3(1,0,-1).normalized()*5.5
	group.add_child(boy)
	stage.display(group)
	for index: int in range(4):await process_frame
	stage._camera.size=16
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(str(args[0]))
	root.get_texture().get_image().save_png(str(args[0]).path_join("lineup-gameplay.png"))
	stage._camera.size=9
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(str(args[0]).path_join("lineup-detail.png"))
	for model: Node3D in models:
		var blink:=model.get_node("SparkBlink") as RobotBlink
		blink.set_process(false);blink.blink();blink._process(.065)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(str(args[0]).path_join("lineup-blink.png"))
	quit()
