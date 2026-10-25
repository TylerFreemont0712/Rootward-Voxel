extends SceneTree
## Renders the interface kit on a neutral backdrop so buttons, panels and icons can be judged by eye.
## Usage: -- <absolute PNG path>

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp/ui_gallery.png"
	var root_control := Control.new()
	root_control.theme = UITheme.theme()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(root_control)
	var backdrop := ColorRect.new()
	backdrop.color = Color("39512f")
	UI.full_rect(backdrop)
	root_control.add_child(backdrop)
	var column := UI.vbox(14)
	column.position = Vector2(30, 24)
	column.custom_minimum_size = Vector2(760, 0)
	root_control.add_child(column)
	column.add_child(UI.label("Kindle Hollow", &"LabelHeading", 40))
	column.add_child(UI.caps("A programming adventure"))
	column.add_child(UI.rule())
	var row := UI.hbox(12)
	column.add_child(row)
	row.add_child(UI.button("Continue", &"play", &"ButtonPrimary"))
	row.add_child(UI.button("New game", &"star"))
	row.add_child(UI.button("Settings", &"gear"))
	var disabled := UI.button("Locked", &"lock")
	disabled.disabled = true
	row.add_child(disabled)
	row.add_child(UI.button("Quit", &"door", &"ButtonDanger"))
	var row2 := UI.hbox(8)
	column.add_child(row2)
	for icon: StringName in [&"book", &"scroll", &"map", &"menu", &"undo", &"reset", &"lamp", &"check", &"cross", &"person", &"flame", &"bridge", &"gate", &"keys", &"info", &"warning"]:
		row2.add_child(UI.icon_button(icon, String(icon)))
	var tabs := UI.hbox(6)
	column.add_child(tabs)
	var group := ButtonGroup.new()
	for name: String in ["Code", "Lesson", "Reference", "World"]:
		var tab := UI.button(name, &"", &"ButtonTab")
		tab.toggle_mode = true
		tab.button_group = group
		tab.custom_minimum_size.y = 36
		tabs.add_child(tab)
	(tabs.get_child(0) as Button).button_pressed = true
	var panel := UI.panel(&"PanelDrawer")
	panel.custom_minimum_size = Vector2(600, 210)
	column.add_child(panel)
	var inner := UI.vbox(8)
	panel.add_child(inner)
	inner.add_child(UI.heading("The Village Notebook", 24))
	inner.add_child(UI.dim("Change the world with a small piece of Python. Nothing is real until you press Apply."))
	var line := LineEdit.new()
	line.text = "Wren"
	inner.add_child(line)
	var toggle := Toggle.make("Auto-complete suggestions", true)
	inner.add_child(toggle)
	var slider := HSlider.new()
	slider.value = 40
	inner.add_child(slider)
	var pills := UI.hbox(14)
	pills.position = Vector2(800, 30)
	root_control.add_child(pills)
	for text: String in ["Kindle Hollow · The Green", "Light the green  2 / 4"]:
		var pill := UI.panel(&"PanelPill")
		pill.add_child(UI.label(text, &"", 18))
		pills.add_child(pill)
	for _i: int in range(40):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if args.size() >= 6:
		image = image.get_region(Rect2i(int(args[1]), int(args[2]), int(args[3]), int(args[4])))
		image.resize(image.get_width() * int(args[5]), image.get_height() * int(args[5]), Image.INTERPOLATE_NEAREST)
	image.save_png(out)
	print("gallery -> ", out)
	quit(0)
