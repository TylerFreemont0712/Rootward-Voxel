class_name TabletLesson
extends RefCounted
## Runs one hand-held lesson over the field tablet (docs/concept/v0.9/tablet-tutorial.md). A lesson
## is data in the journey file (`lessons`): steps with what the speaker says, what to ring, a command
## to suggest, and what has to happen before the next step. The runner outlives the slate: close it
## and open it again and the lesson resumes on the same step. Nothing here blocks the player; it waits.

var game: Game
var id: String = ""
var data: Dictionary = {}
var step: int = 0
var active: bool = false
var tablet: TabletShell


func start(owner: Game, lesson_id: String, lesson: Dictionary, from_step: int = 0) -> void:
	game = owner
	id = lesson_id
	data = lesson
	step = clampi(from_step, 0, steps().size() - 1)
	active = true
	if tablet == null:
		_say_outside()


func steps() -> Array:
	return data.get("steps", [])


func current() -> Dictionary:
	return steps()[step] if step < steps().size() else {}


func speaker() -> String:
	return str(data.get("speaker_name", data.get("speaker", "Hotaru"))).capitalize()


## The slate was taken out: listen to it and show the step there.
func attach(shell: TabletShell) -> void:
	tablet = shell
	tablet.app_opened.connect(_on_app)
	tablet.home_shown.connect(func() -> void: _event("home"))
	tablet.command_ran.connect(_on_command)
	tablet.graph_tapped.connect(func(_id: String) -> void: _event("graph_tap"))
	tablet.lesson_next_pressed.connect(func() -> void: _event("continue"))
	tablet.lesson_skip_pressed.connect(func() -> void: finish("done"))
	tablet.closed.connect(detach)
	_event("tablet_open")
	_apply()


func detach() -> void:
	tablet = null
	if active:
		_say_outside()


func finish(status: String) -> void:
	if not active:
		return
	active = false
	if tablet != null:
		tablet.clear_lesson()
	game.lesson_finished(id, status)


# --- Steps ------------------------------------------------------------------------------------

func _apply() -> void:
	if not active or tablet == null:
		return
	var now: Dictionary = current()
	if now.is_empty():
		finish("done")
		return
	var wait: String = str(now.get("wait", "continue"))
	tablet.show_lesson(speaker(), str(now.get("say", "")), wait == "continue")
	tablet.set_phantom(bool(now.get("phantom", false)))
	tablet.set_ghost(str(now.get("command", "")))
	tablet.point(str(now.get("point", "")))
	# A step that waits for a screen already on show is done already.
	if wait == "app:" + tablet.app_name and tablet.app_name != "":
		_advance()
	elif wait == "home" and tablet.app_name == "":
		_advance()


func _advance() -> void:
	step += 1
	if step >= steps().size():
		finish("done")
		return
	_apply()


func _event(kind: String) -> void:
	if not active:
		return
	var wait: String = str(current().get("wait", "continue"))
	if wait == kind:
		_advance()
	elif kind in ["home"] or kind.begins_with("app:"):
		_apply()  # The screen changed: re-point, re-ghost, re-phantom for the same step.


func _on_app(name: String) -> void:
	_event("app:" + name)


func _on_command(line: String, ok: bool) -> void:
	if not active:
		return
	var now: Dictionary = current()
	var wait: String = str(now.get("wait", "continue"))
	var expected: String = str(now.get("command", ""))
	var matched: bool = false
	if wait == "committed":
		matched = ok and line.begins_with("git commit")
	elif wait.begins_with("ran:"):
		matched = ok and line.begins_with(wait.trim_prefix("ran:"))
	if matched:
		_advance()
	elif (wait == "committed" or wait.begins_with("ran:")) and tablet != null:
		tablet.lesson_note(str(now.get("if_wrong", "Not that one yet. Try:  " + expected)))


## While the slate is away, the step's line goes to the HUD, so the player knows what to do next.
func _say_outside() -> void:
	var now: Dictionary = current()
	if game != null and game.hud != null and not now.is_empty() and str(now.get("say", "")) != "":
		game.hud.show_toast("%s · %s" % [speaker(), str(now.say).replace("`", "")])
