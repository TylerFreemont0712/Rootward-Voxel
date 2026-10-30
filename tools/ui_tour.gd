extends SceneTree
## Walks the real game through its screens and saves a PNG of each, for visual review at gameplay size.
## Usage: -- <absolute output directory> [only]   (only: a comma-separated list of shot names)

var game: Game
var out: String
var only: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "/tmp/ui_tour"
	only = args[1].split(",") if args.size() > 1 else PackedStringArray()
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(90)
	await _shot("01-title")
	game.open_settings()
	await _frames(20)
	await _shot("02-settings")
	game._modals[-1].close()
	game._open_character("new", {})
	await _frames(40)
	await _shot("03-character-new")
	game._pop_all_modals()
	game.start_new_game("kindle-hollow")
	await _frames(120)
	await _shot("04-play-start")
	game.open_notebook()
	await _frames(60)
	await _shot("05a-notebook-first-visit")
	game.notebook.show_tab("Code")
	await _frames(4)
	await _shot("05-notebook-code")
	game.notebook.show_tab("Lesson")
	await _frames(10)
	await _shot("06-notebook-lesson")
	game.notebook.show_tab("Reference")
	await _frames(10)
	await _shot("07-notebook-reference")
	game.notebook.show_tab("World")
	await _frames(10)
	await _shot("08-notebook-world")
	game.notebook.show_tab("Code")
	game.notebook.editor.replace_program("def program(world):\n    lamp = world.lamp(\"landing-lamp\")\n    lamp.set_lit(True)\n")
	await _frames(3)
	await game.session.run_preview()
	await _frames(40)
	await _shot("09-run-preview")
	game.session.apply_preview()
	await _frames(90)
	await _shot("10-applied-quest-complete")
	game.notebook.editor.replace_program("def program(world):\n    lamps = world.lamps\n    for lamp in lamps:\n        lamp.set_lit(Ture)\n")
	await _frames(3)
	await game.session.run_preview()
	await _frames(30)
	await _shot("11-run-error")
	game.close_notebook()
	await _frames(40)
	game.open_pause()
	await _frames(30)
	await _shot("12-pause")
	game._pop_all_modals()
	game.open_journal()
	await _frames(30)
	await _shot("13-journal")
	game._pop_all_modals()
	game.open_map()
	await _frames(30)
	await _shot("14-map")
	game._pop_all_modals()
	game._open_character("view", {})
	await _frames(40)
	await _shot("15-character")
	game._pop_all_modals()
	# Progress, autocomplete and the Continue screen.
	game.session.set_source("def program(world):\n    green = world.zone(\"green\")\n    for lamp in green.lamps:\n        lamp.set_lit(True)\n")
	game.open_notebook()
	game.notebook.show_tab("Code")
	game.notebook.editor.replace_program("def program(world):\n    lamp = world.lamp(\"landing-lamp\")\n    lamp.\n")
	game.notebook.editor.set_caret_line(2)
	game.notebook.editor.set_caret_column(9)
	game.notebook.editor.grab_focus()
	await _frames(3)
	game.notebook.editor._offer_completions()
	await _frames(10)
	await _shot("16-autocomplete")
	game.notebook.show_tab("Lesson")
	game.notebook.lesson._hints_shown["first-light"] = 2
	game.notebook._refresh_lesson(true)
	await _frames(4)
	await _shot("17-hints")
	game.close_notebook()
	SaveStore.save_path = "user://tour_save.json"
	SaveStore.profile_path = "user://tour_profile.json"
	SaveStore.force_enabled = true
	game.save_now()
	await game._return_to_title()
	await _frames(70)
	await _shot("18-title-continue")
	await game.continue_game("kindle-hollow")
	await _frames(30)
	game.open_map()
	await _frames(20)
	await _shot("19-map-after-progress")
	game._pop_all_modals()
	await game.start_new_game("village-morning")
	game._pop_all_modals()
	game.open_notebook()
	await _frames(30)
	await _shot("20-morning-notes")
	var movement: MovementLesson=game.movement_lesson
	for amount: SpinBox in movement.amount_fields:amount.value=1
	movement._changed()
	await movement.preview()
	movement._source_button.button_pressed=true
	movement._toggle_source()
	await _frames(20)
	await _shot("21-generated-python")
	movement._source_button.button_pressed=false
	movement._toggle_source()
	movement._work.scroll_vertical=0
	movement.amount_fields[0].value=3
	movement._changed()
	await movement.preview()
	await _frames(25)
	await _shot("22-movement-overshoot")
	movement.select_mode("python")
	movement.editor.replace_program("def program(world):\n    x = y = 0\n    y += 3\n    world.controls.bind_move(\"W\", x, y)\n")
	await movement.preview()
	await _frames(25)
	await _shot("23-python-test")
	SaveStore.delete()
	SaveStore.delete("village-morning")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://tour_profile.json"))
	quit(0)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


func _shot(name: String) -> void:
	if not only.is_empty() and not only.has(name):
		return
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(out.path_join(name + ".png"))
	print("shot ", name)
