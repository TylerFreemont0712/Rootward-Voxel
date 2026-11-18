extends SceneTree
## Review of saving as version control at gameplay scale: the title's Load entry, the field tablet,
## its terminal (status, add, commit, log --graph, diff, a theme change), the load screen's commit
## graph with a fork, and the uncommitted-changes warning (docs/concept/save-vcs/PLAN.md).
## Usage: VOXEL_LAB_FRESH=1 scripts/play.sh --resolution 1600x1000 -s res://tools/reviews/save_vcs_review.gd -- <absolute output dir>

var game: Game
var output: String = ""


func _initialize() -> void:
	OS.set_environment("VOXEL_LAB_FRESH", "1")
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("usage: -- <absolute output dir>")
		quit(2)
		return
	output = args[0]
	SaveRepo.root = "user://save_vcs_review_%d" % OS.get_process_id()
	SaveRepo.force_enabled = true
	SaveRepo.wipe()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _frames(5)
	await game.start_new_game("sparks-and-machines", "Wren")
	game._pop_all_modals()
	game.close_notebook(true)
	await _frames(10)
	game.open_menu()
	await _shot("00-no-tablet-prompt")
	game._pop_all_modals()
	game.session.state.items = ["field-tablet"]
	game.open_tablet()
	await _shot("01-tablet-home")
	(game._modals[-1] as TabletShell).open_settings()
	await _shot("01b-tablet-settings")
	(game._modals[-1] as TabletShell).show_home()
	var tablet := game._modals[-1] as TabletShell
	tablet.open_terminal()
	await _frames(3)
	var terminal := tablet._app as TerminalApp
	terminal.run_line("git status")
	game.session.state.memory = {"first_light": true}
	game.session.state.player = [game.session.state.player[0], game.session.state.player[1], 0]
	terminal.run_line("git status")
	await _shot("02-terminal-status")
	terminal.run_line("git diff")
	await _shot("03-terminal-diff")
	terminal.run_line("clear")
	terminal.run_line("git add .")
	terminal.run_line("git commit -m \"Remember the first light\"")
	terminal.run_line("git switch -c evening-experiment")
	await _frames(6)
	while game._flow_busy: await process_frame
	game.session.state.memory = {"first_light": true, "evening": 19}
	game.commit_progress("Try the evening round early")
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).open_terminal()
	await _frames(2)
	terminal = (game._modals[-1] as TabletShell)._app as TerminalApp
	terminal.run_line("git switch main")
	await _frames(6)
	while game._flow_busy: await process_frame
	game.session.state.memory = {"first_light": true, "lamps": 3}
	game.commit_progress("Light the landing")
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).open_terminal()
	await _frames(2)
	terminal = (game._modals[-1] as TabletShell)._app as TerminalApp
	terminal.run_line("git log --oneline --graph --all")
	terminal.run_line("git branch")
	await _shot("04-terminal-log-graph")
	terminal.run_line("clear")
	terminal.run_line("git config theme ember")
	terminal.run_line("git config prompt.format \"{time} {user} {branch}{dirty} > \"")
	terminal.run_line("git log -n 1")
	terminal.run_line("git config --list")
	await _shot("05-terminal-config")
	game._pop_all_modals()
	game.session.state.memory = {"first_light": true, "lamps": 3, "unsaved": "yes"}
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).title_requested.emit()
	await _shot("06-uncommitted-warning")
	game._pop_all_modals()
	game.start_lesson("tablet-tutorial")
	game.open_tablet()
	await _frames(2)
	var slate := game._modals[-1] as TabletShell
	await _shot("09a-lesson-home-key")
	slate.lesson_next_pressed.emit()
	slate.open_saves()
	await _frames(2)
	slate.lesson_next_pressed.emit()
	await _shot("09b-lesson-phantom-tree")
	slate.lesson_next_pressed.emit()
	slate.lesson_next_pressed.emit()
	(slate._app as SavesBrowser)._graph.select(SavesBrowser.PHANTOM_IDS[1])
	await _shot("09c-lesson-phantom-command")
	game._lesson.finish("done")
	game._pop_all_modals()
	game.open_tablet()
	await _frames(2)
	(game._modals[-1] as TabletShell).open_saves()
	await _shot("07a-tablet-saves")
	game.settings.set_value("ui_scale", 1.3)
	await _shot("07b-tablet-scaled-1.3")
	game.settings.set_value("ui_scale", 1.0)
	game._pop_all_modals()
	game.open_load()
	await _shot("07-load-graph")
	game._pop_all_modals()
	await game._return_to_title()
	await _frames(10)
	await _shot("08-title-load")
	SaveRepo.wipe()
	quit(0)


func _shot(name: String, frames: int = 20) -> void:
	if DisplayServer.get_name() == "headless": return
	for frame: int in range(frames): await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))


func _frames(count: int) -> void:
	for i: int in range(count): await process_frame
