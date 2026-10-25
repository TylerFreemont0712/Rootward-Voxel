class_name GameSession
extends Node
## One playthrough of one area: the authoritative world state, grid walking, Python runs, previews,
## undo and quest progress. LabWorld alone decides what can change or be walked across; this node
## sequences those decisions over time and tells the interface (through signals) what happened.

signal state_changed
signal status(title: String, detail: String, failed: bool)
signal preview_changed(has_preview: bool)
signal run_finished(result: Dictionary)
signal quest_completed(quest: Dictionary)
signal quest_changed
signal zone_changed(zone: Dictionary)
signal toast(text: String)
signal source_changed
signal progress_saved
signal busy_changed(is_busy: bool)
## A program (or its undo) changed the houses, trees or doodads. The game saves, and keeps its own area in step.
signal build_changed(label: String)
signal doorway_requested(house: String)

const SAVE_VERSION: int = 1
const MAX_SOURCE: int = 16384
const MAX_HISTORY: int = 20

var area: AreaDef
var rules: LabWorld
## Abilities granted whatever the lessons say, for trying the API out (the game reads VOXEL_CODE_ABILITIES).
var extra_abilities: Array[String] = []
## The player's building edits (the game's ledger). A program's building commands are checked against it and,
## once applied, kept in it, so they save, undo and show exactly like the builder's own edits.
var ledger: BuildLedger
var view: ClearingView
var state: Dictionary = {}
var completed: Array = []
var source: String = ""
var stats: Dictionary = {"runs": 0, "applies": 0}
var player_name: String = "Wren"
## The interface turns this off while a text field or a menu owns the keyboard.
var input_enabled: bool = true
var busy: bool = false
var last_run: Dictionary = {}
var current_zone: String = ""
var _step_candidate: Dictionary = {}
var _step_from: Vector2i
var _step_to: Vector2i
var _step_progress: float = 0.0
var _waiting_for_stop: bool = false
var _input_priority := Vector2i.ZERO
var _route: Array[Vector2i] = []
var _pending: Dictionary = {}
var _pending_tokens: Dictionary = {}
var _history: Array[Dictionary] = []
var _thread: Thread
var _program_revision: int = 0
var _session_generation: int = 0
var _run_serial: int = 0
var _selection := Vector2i(-1, -1)
## The way the character last walked or turned, as a logical direction (x east, y north).
var facing := Vector2i(1, 0)
var door_catalog: Dictionary = {}
var _route_door: String = ""
var _route_exit: bool = false
## How long a planned route has waited on a resident standing in the next cell.
var _route_wait: float = 0.0
## Where to turn at the end of a route: the resident walked up to, so the character ends up facing them.
var _route_face := Vector2i(-1, -1)


## Starts (or resumes) a playthrough. `save` is a dictionary from to_save(), or {} for a new game.
func begin(definition: AreaDef, scene_view: ClearingView, save: Dictionary = {}) -> void:
	_session_generation += 1
	_cancel_walk()
	area = definition
	rules = LabWorld.new(area)
	view = scene_view
	state = rules.initial_state()
	completed = []
	source = LabProgram.starter_source()
	stats = {"runs": 0, "applies": 0}
	_history.clear()
	_pending.clear()
	_selection = Vector2i(-1, -1)
	if not save.is_empty():
		var restored: Dictionary = rules.normalize_state(save.get("state"))
		if not restored.is_empty():
			state = restored
		for id: Variant in save.get("completed", []):
			if id is String and not area.quest(id).is_empty() and not completed.has(id):
				completed.append(id)
		var saved_source: Variant = save.get("source")
		if saved_source is String and (saved_source as String).length() <= MAX_SOURCE:
			source = saved_source
		var saved_stats: Variant = save.get("stats")
		if saved_stats is Dictionary:
			stats.runs = int((saved_stats as Dictionary).get("runs", 0))
			stats.applies = int((saved_stats as Dictionary).get("applies", 0))
	view.apply_state(state)
	view.focus_on(Vector2(float(state.player[0]), float(state.player[1])), true)
	current_zone = area.zone_at(Vector2i(int(state.player[0]), int(state.player[1])))
	_refresh_quest_marker()
	state_changed.emit()
	quest_changed.emit()
	if save.is_empty():
		report("The hollow is dark.", "Walk with WASD or click a place. Open your notebook with E when you are ready to write code.")
	else:
		report("Welcome back.", "Your world and your notebook are as you left them.")


## Swaps in the world that results from a build-mode edit. The world state (lamps, gates, bridges, where the
## player stands) carries over unchanged; anything in flight about the old world is dropped.
func replace_area(definition: AreaDef, world_rules: LabWorld) -> void:
	area = definition
	rules = world_rules
	_cancel_route()
	_session_generation += 1
	_invalidate_preview()
	state_changed.emit()


func prepare_travel() -> void:
	_cancel_walk()
	_session_generation += 1
	_invalidate_preview()


## A nearby F action uses the same typed command validation as Python; it clears stale previews first.
func use_prop(id: String) -> bool:
	if busy or is_walking():
		return false
	var allowed: Dictionary = PropInteractions.can_use(rules, state, id)
	if not allowed.ok:
		toast.emit(str(allowed.reason))
		return false
	var current: bool = bool((state.get("props", {}) as Dictionary).get(id, false))
	var result: Dictionary = rules.propose(state, [{"op": "set_field", "entity_id": id, "field": "active", "value": not current}], state.memory)
	if not result.ok:
		toast.emit(str(result.reason))
		return false
	_history.append(state.duplicate(true))
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	state = result.state
	_session_generation += 1
	_invalidate_preview()
	view.apply_state(state)
	_after_change()
	toast.emit(PropInteractions.label(area.prop(id), current))
	return true


func to_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"area": area.id,
		"area_version": area.version,
		"name": player_name,
		"state": state.duplicate(true),
		"completed": completed.duplicate(),
		"source": source,
		"stats": stats.duplicate(),
	}


# ----------------------------------------------------------------- program
func set_source(text: String) -> void:
	if text == source:
		return
	source = text
	_program_revision += 1
	_session_generation += 1
	_invalidate_preview()
	source_changed.emit()


func run_preview() -> bool:
	if busy or _waiting_for_stop:
		return false
	if source.length() > MAX_SOURCE:
		_fail_run({"ok": false, "reason": "The program is longer than %d characters." % MAX_SOURCE, "error": {"kind": "", "message": "", "line": 0}})
		return false
	_cancel_route()
	if is_walking():
		_waiting_for_stop = true
		while is_walking():
			await get_tree().physics_frame
		_waiting_for_stop = false
	view.set_player_motion(Vector2.ZERO)
	_invalidate_preview()
	busy = true
	busy_changed.emit(true)
	_run_serial += 1
	stats.runs += 1
	var tokens := _tokens()
	var program_text := source
	var snapshot: Dictionary = world_snapshot()
	report("Running your program…", "You can still explore. Moving or editing will make this run's preview out of date.")
	_thread = Thread.new()
	var started := _thread.start(func() -> Dictionary: return LabProgram.run(program_text, snapshot))
	if started != OK:
		_thread = null
		busy = false
		busy_changed.emit(false)
		_fail_run({"ok": false, "reason": error_string(started), "error": {"kind": "", "message": "", "line": 0}})
		return false
	while _thread.is_alive():
		await get_tree().process_frame
	var answer: Dictionary = _thread.wait_to_finish()
	_thread = null
	busy = false
	busy_changed.emit(false)
	last_run = answer
	# LEARN: source edits and undo can leave the same world revision behind. A generation token makes old jobs stale.
	if tokens != _tokens():
		answer["stale"] = true
		report("That preview is out of date.", "The world or program changed during the run. Run again to preview the current version.")
		run_finished.emit({"ok": false, "stale": true, "reason": "out of date", "error": {"kind": "", "message": "", "line": 0}})
		return false
	if not answer.get("ok", false):
		_fail_run(answer)
		return false
	var commands: Variant = answer.get("commands")
	var external: Array[String] = []
	if ledger != null:
		external = CodeBuild.BUILD_OPS
	var proposal: Dictionary = rules.propose(state, commands, answer.get("memory", {}), external)
	var building: Dictionary = CodeBuild.propose(ledger, state, commands, abilities()) if ledger != null and proposal.get("ok", false) and commands is Array else {"ok": true, "edits": [], "changes": []}
	if not proposal.get("ok", false) or not building.ok:
		var why: String = str(proposal.get("reason", "Unknown command")) if not proposal.get("ok", false) else str(building.reason)
		var rejected := {"ok": false, "reason": why, "rejected": true,
			"error": {"kind": "", "message": "", "line": 0}, "stdout": answer.get("stdout", "")}
		report("The world rejected this change.", rejected.reason, true)
		run_finished.emit(rejected)
		return false
	_pending = proposal
	_pending["build"] = building
	_pending_tokens = tokens
	view.apply_state(_pending.state, true)
	if not (building.edits as Array).is_empty():
		view.show_build_preview(AreaBuild.diff(ledger.area, building.area))
	var changes: Array = (_pending.get("changes", []) as Array).duplicate()
	changes.append_array(building.changes)
	report("Preview ready · %d changes · %d ms" % [changes.size(), int(answer.get("wall_ms", 0))], "\n".join(PackedStringArray(changes)))
	preview_changed.emit(true)
	run_finished.emit({"ok": true, "changes": changes, "stdout": str(answer.get("stdout", "")).strip_edges(), "wall_ms": int(answer.get("wall_ms", 0))})
	return true


## What the player's code may do to houses, trees and doodads: what the finished lessons unlock, plus any granted for trying.
func abilities() -> Array[String]:
	var result: Array[String] = Quests.capabilities(area, completed)
	for ability: String in extra_abilities:
		if not result.has(ability):
			result.append(ability)
	return result


## What a program is allowed to know right now: the lamps, gates, bridges and working props of the places visited,
## and (once the lessons have taught it) the houses, trees and doodads within reach.
func world_snapshot() -> Dictionary:
	var snapshot: Dictionary = rules.snapshot(state)
	if ledger != null:
		snapshot["build"] = CodeBuild.snapshot(ledger, state, abilities())
	return snapshot


func has_preview() -> bool:
	return not _pending.is_empty() and _pending_tokens == _tokens()


func apply_preview() -> bool:
	if is_walking() or not has_preview():
		return false
	_cancel_route()
	var entry: Dictionary = state.duplicate(true)
	var building: Dictionary = _pending.get("build", {})
	var built: bool = ledger != null and not (building.get("edits", []) as Array).is_empty()
	if built:
		# What undo needs to take the program's building away again, and only that.
		var before: int = ledger.edits.size()
		ledger.commit_code(building.edits, building.area, building.rules)
		entry["_edits"] = [before, ledger.edits.size()]
		area = ledger.area
		rules = ledger.rules
		view.sync_edits(area, true)
	_history.append(entry)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	state = (_pending.state as Dictionary).duplicate(true)
	stats.applies += 1
	_session_generation += 1
	_invalidate_preview()
	view.apply_state(state)
	_after_change()
	if built:
		build_changed.emit("Your program changed the village")
	report("Your changes are part of the world.", "Walk over the timber you placed. Edit again to try a different result.")
	return true


func can_undo() -> bool:
	return not _history.is_empty()


func undo_apply() -> bool:
	if _history.is_empty():
		return false
	var entry: Dictionary = _history[-1]
	var marks: Array = entry.get("_edits", [])
	var removed: Array = []
	var kept_area: AreaDef = area
	var kept_rules: LabWorld = rules
	if not marks.is_empty():
		# The program built something. Taking it away is only safe if nothing has been built since.
		if ledger == null or ledger.edits.size() != int(marks[1]):
			report("Undo is not possible yet.", "You have built or changed things by hand since this program ran. Undo those first (Ctrl+Z in build mode), then undo the program.", true)
			return false
		removed = ledger.edits.slice(int(marks[0]))
		if not ledger.truncate_to(int(marks[0])):
			report("Undo is not possible yet.", "The village could not be put back as it was.", true)
			return false
		area = ledger.area
		rules = ledger.rules
	var result: Dictionary = rules.revert(state, entry)
	if not result.ok:
		if not marks.is_empty():
			ledger.commit_code(removed, kept_area, kept_rules)
			area = kept_area
			rules = kept_rules
		report("Undo is not possible yet.", str(result.reason), true)
		return false
	_history.pop_back()
	_cancel_walk()
	state = result.state
	_session_generation += 1
	_invalidate_preview()
	if not marks.is_empty():
		view.sync_edits(area, true)
	view.apply_state(state)
	_after_change()
	if not marks.is_empty():
		build_changed.emit("Your program's building was undone")
	report("The last application was undone.", "The world's changes and your program's memory were restored. You stay where you are, and your source is kept.")
	return true


func reset_world() -> void:
	_cancel_walk()
	var fresh: Dictionary = rules.initial_state()
	# What you have explored stays explored; the world itself starts again.
	fresh.zones_seen = (state.zones_seen as Array).duplicate()
	state = fresh
	_history.clear()
	_session_generation += 1
	_invalidate_preview()
	view.apply_state(state)
	view.focus_on(Vector2(area.spawn), true)
	_after_change()
	if area.interior.is_empty():
		report("A fresh hollow.", "Your code and your quest progress are kept. Explore, or run it again to try another idea.")
	else:
		report("A fresh room.", "Your notebook, discoveries and the village are kept. Try another idea here.")


# ----------------------------------------------------------------- walking
func is_walking() -> bool:
	return not _step_candidate.is_empty()


func request_step(direction: Vector2i) -> bool:
	if is_walking() or _waiting_for_stop:
		return false
	var passage: Dictionary = HouseInstances.crossing(area, rules, state, direction, door_catalog)
	if not passage.is_empty():
		_cancel_route()
		_session_generation += 1
		_invalidate_preview()
		doorway_requested.emit(str(passage.house))
		return true
	if view != null and view.resident_cells().has(player_cell() + direction):
		turn_toward(direction)  # Someone stands there: face them rather than walk through them.
		return false
	var proposal: Dictionary = rules.move(state, direction)
	if not proposal.ok:
		turn_toward(direction)  # A building, water, a wall or the map's edge: face it rather than do nothing.
		return false
	facing = direction
	_step_from = Vector2i(int(state.player[0]), int(state.player[1]))
	_step_to = _step_from + direction
	_step_candidate = proposal.state
	_step_progress = 0.0
	_session_generation += 1
	_invalidate_preview()
	view.set_player_motion(Vector2(direction) / LabWorld.STEP_SECONDS)
	return true


func advance_walk(seconds: float) -> void:
	if not is_walking():
		return
	_step_progress = minf(1.0, _step_progress + seconds / LabWorld.STEP_SECONDS)
	if _step_progress >= 1.0 - 0.000001:
		_step_progress = 1.0
	view.interpolate_player(Vector2(_step_from), Vector2(_step_to), _step_progress)
	if _step_progress >= 1.0:
		var before: Array = state.zones_seen.duplicate()
		state = _step_candidate
		_step_candidate = {}
		view.sync_player(state)
		for zone_id: Variant in state.zones_seen:
			if not before.has(zone_id):
				toast.emit("Discovered %s" % area.zone(zone_id).title)
		_after_change(false)


func walk_to(goal: Vector2i) -> bool:
	_cancel_route()
	var house: String = HouseInstances.at_destination(area, goal, door_catalog)
	if house != "":
		return walk_to_door(house)
	var from: Vector2i = _step_to if is_walking() else Vector2i(int(state.player[0]), int(state.player[1]))
	var people: Dictionary = view.resident_cells() if view != null else {}
	if people.has(goal):
		# Walking to a resident means walking up beside them, then turning to face them.
		var beside: Array[Vector2i] = []
		for side: Vector2i in LabWorld.DIRECTIONS:
			var candidate: Array[Vector2i] = rules.find_path(state, goal + side, from, people) if goal + side != from else []
			if goal + side == from:
				turn_toward(-side)
				return true
			if not candidate.is_empty() and (beside.is_empty() or candidate.size() < beside.size()):
				beside = candidate
		_route = beside
		_route_face = goal
	else:
		_route = rules.find_path(state, goal, from, people)
		if _route.is_empty():
			_route = rules.find_path(state, goal, from)
	if _route.is_empty():
		if from != goal:
			turn_toward(_direction_toward(from, goal))
			report("No safe route to that cell.", "Click a walkable cell. Water, walls, buildings and closed gates block the route; blocked cells can still be inspected.")
		return from == goal
	view.show_route(_route)
	return true


func walk_to_door(house: String) -> bool:
	_cancel_route()
	var target: Vector2i
	if house == "" and not area.interior.is_empty():
		target = Vector2i(int(area.interior.exit[0]), int(area.interior.exit[1]))
		_route_exit = true
	elif HouseInstances.template_for(area, house, door_catalog) != "":
		target = HouseInstances.door(area, house)
		_route_door = house
	else:
		return false
	var from: Vector2i = _step_to if is_walking() else player_cell()
	_route = rules.find_path(state, target, from)
	if _route.is_empty() and from != target:
		_cancel_route()
		report("The doorway is out of reach.", "Open a safe route to the front steps first.")
		return false
	view.show_route(_route)
	return true


## Turns the character to face a direction without walking. Ignored mid-step: the step finishes first.
func turn_toward(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO or is_walking() or view == null:
		return
	facing = direction
	view.face_player(Vector2(direction))


## The grid direction that points most nearly from one cell toward another (east or west on a tie).
func _direction_toward(from: Vector2i, goal: Vector2i) -> Vector2i:
	var delta: Vector2i = goal - from
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


func click_cell(cell: Vector2i) -> void:
	if not area.in_bounds(cell):
		return
	_selection = cell
	view.set_selection(cell)
	walk_to(cell)


func selection() -> Vector2i:
	return _selection


func player_cell() -> Vector2i:
	return Vector2i(int(state.player[0]), int(state.player[1]))


func _cancel_route() -> void:
	_route.clear()
	_route_door = ""
	_route_exit = false
	_route_wait = 0.0
	_route_face = Vector2i(-1, -1)
	if view != null:
		view.show_route(_route)


func _cancel_walk() -> void:
	_cancel_route()
	_step_candidate = {}
	_step_progress = 0.0
	if view != null:
		view.sync_player(state)
		view.set_player_motion(Vector2.ZERO)


func _text_has_focus() -> bool:
	var owner: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	return owner is LineEdit or owner is TextEdit


func _held_direction() -> Vector2i:
	if not input_enabled or _text_has_focus() or not DisplayServer.window_is_focused():
		return Vector2i.ZERO
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.is_zero_approx():
		return Vector2i.ZERO
	var logical := Vector2(input.x, -input.y)
	if _input_priority.x != 0 and signf(logical.x) == float(_input_priority.x):
		return _input_priority
	if _input_priority.y != 0 and signf(logical.y) == float(_input_priority.y):
		return _input_priority
	return Vector2i(1 if logical.x > 0.0 else -1, 0) if absf(logical.x) > absf(logical.y) else Vector2i(0, 1 if logical.y > 0.0 else -1)


func _physics_process(delta: float) -> void:
	if view == null or rules == null:
		return
	advance_walk(delta)
	if is_walking():
		return
	if _waiting_for_stop or not input_enabled or _text_has_focus() or not DisplayServer.window_is_focused():
		_cancel_route()
		view.set_player_motion(Vector2.ZERO)
		return
	var held: Vector2i = _held_direction()
	if held != Vector2i.ZERO:
		_cancel_route()
		if request_step(held):
			return
	elif not _route.is_empty():
		if view.resident_cells().has(_route[0]):
			_wait_for_resident(delta)
			view.set_player_motion(Vector2.ZERO)
			return
		_route_wait = 0.0
		var next: Vector2i = _route.pop_front()
		view.show_route(_route)
		if request_step(next - player_cell()):
			return
		_cancel_route()
		report("The route changed.", "Click a destination again to plan a route through the current world.")
	elif _route_face.x >= 0:
		turn_toward(_direction_toward(player_cell(), _route_face))
		_route_face = Vector2i(-1, -1)
	elif _route_door != "" or _route_exit:
		var direction: Vector2i = Vector2i(0, -1) if _route_exit else -(HouseInstances.OUTWARD[area.building(_route_door).facing] as Vector2i)
		if request_step(direction):
			return
		_cancel_route()
	view.set_player_motion(Vector2.ZERO)


## A resident stands in the next cell of the route. Wait a moment for them to move on; then look for a way round;
## and if there is none for a while, give up rather than stand there forever.
func _wait_for_resident(delta: float) -> void:
	_route_wait += delta
	if _route_wait < 0.5:
		return
	var people: Dictionary = view.resident_cells()
	var detour: Array[Vector2i] = rules.find_path(state, _route[-1], player_cell(), people)
	if not detour.is_empty():
		_route = detour
		_route_wait = 0.0
		view.show_route(_route)
	elif _route_wait > 3.0:
		_cancel_route()
		toast.emit("Someone is in the way.")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not input_enabled or _text_has_focus():
		return
	var key: Key = (event as InputEventKey).keycode
	match key:
		KEY_D, KEY_RIGHT: _input_priority = Vector2i.RIGHT
		KEY_A, KEY_LEFT: _input_priority = Vector2i.LEFT
		KEY_W, KEY_UP: _input_priority = Vector2i(0, 1)
		KEY_S, KEY_DOWN: _input_priority = Vector2i(0, -1)
		_:
			return
	_cancel_route()


# ----------------------------------------------------------------- quests
func current_quest() -> Dictionary:
	return Quests.current(area, completed)


## {done, total, noun} for the current quest's goal, for the objective readout.
func quest_progress() -> Dictionary:
	var quest: Dictionary = current_quest()
	return Quests.goal_progress(area, state, quest.goal) if not quest.is_empty() else {"done": 0, "total": 0, "noun": ""}


func lamps_lit() -> int:
	var count: int = 0
	for lit: Variant in (state.lamps as Dictionary).values():
		if lit == true:
			count += 1
	return count


func _after_change(sync_view: bool = true) -> void:
	state_changed.emit()
	var zone_id: String = area.zone_at(player_cell())
	if zone_id != current_zone:
		current_zone = zone_id
		zone_changed.emit(area.zone(zone_id) if zone_id != "" else {})
	var finished: Array[String] = Quests.newly_completed(area, state, completed)
	for quest_id: String in finished:
		completed.append(quest_id)
		quest_completed.emit(area.quest(quest_id))
	if not finished.is_empty() or sync_view:
		_refresh_quest_marker()
	quest_changed.emit()
	if sync_view or not finished.is_empty():
		progress_saved.emit()


func _refresh_quest_marker() -> void:
	var quest: Dictionary = current_quest()
	var focus: Dictionary = quest.get("focus", {})
	if quest.is_empty() or focus.is_empty():
		view.set_quest_marker(null)
	else:
		view.set_quest_marker(Vector2(float(focus.at[0]), float(focus.at[1])))


# ----------------------------------------------------------------- plumbing
func report(title: String, detail: String, failed: bool = false) -> void:
	status.emit(title, detail, failed)


func _fail_run(answer: Dictionary) -> void:
	var error: Dictionary = answer.get("error", {})
	var advice: Dictionary = ErrorAdvice.explain(error, ApiReference.known_names(source))
	if str(error.get("kind", "")) == "" and not str(answer.get("reason", "")).is_empty():
		advice = {"title": "The program did not finish", "body": str(answer.reason)}
	var result := {"ok": false, "reason": str(answer.get("reason", "")), "error": error, "advice": advice, "stdout": str(answer.get("stdout", "")).strip_edges()}
	report(advice.title, advice.body, true)
	run_finished.emit(result)


func _invalidate_preview() -> void:
	var had: bool = not _pending.is_empty()
	_pending.clear()
	_pending_tokens.clear()
	if view != null:
		view.clear_preview()
	if had:
		preview_changed.emit(false)


func _tokens() -> Dictionary:
	return {"world_revision": state.revision, "program_revision": _program_revision, "session_generation": _session_generation, "run_id": _run_serial}


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		_thread.wait_to_finish()
