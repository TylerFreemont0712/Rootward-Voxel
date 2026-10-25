extends SceneTree
## Conversation rules, all authored examples in real WASI, portrait provenance and the actual modal flow.

var checks: int = 0
var failures: Array[String] = []
var game: Game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var people: Dictionary = AreaStore.read_villagers()
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://pipeline/art-catalog.json")).portraits
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art.manifest))
	_check(art.items.size() == 5 and library.portraits.size() == 5, "Every villager has a separately registered portrait")
	var definition: AreaDef = AreaStore.read("kindle-hollow").area
	var rules := LabWorld.new(definition)
	var hashes: Array[String] = []
	var provenance: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art.provenance))
	_check(FileAccess.get_sha256(art.prompt) == provenance.prompt_sha256, "The exact portrait prompts are preserved")
	for record: Dictionary in provenance.portraits:
		for reference: String in record.reference_sha256:
			_check(FileAccess.get_sha256("res://" + reference) == record.reference_sha256[reference], "Portrait identity/style reference remains unchanged: " + reference)
	for id: String in people:
		var person: Dictionary = people[id]
		_check(VillageDialogue.validate(person).is_empty(), "Valid authored topics: " + id)
		var flow := VillageDialogue.new(person, ["greeting", "made-up", 17])
		_check(flow.read_before_enter and not flow.read_pages.has("made-up"), "Read tracking filters unknown pages: " + id)
		_check(not flow.choose(str(person.topics[0].id)), "Responses cannot be chosen outside a choice page")
		_check(flow.advance() and flow.current().choices.size() == 3, "Greeting leads to two topics and Leave")
		_check(not flow.advance() and not flow.choose("invented"), "Advancing and unknown choices never bypass a reply")
		_check(flow.choose(str(person.topics[0].id)) and flow.current().lesson.is_empty(), "Ordinary conversation has no forced lesson")
		while flow.stage == "topic":
			flow.advance()
		_check(flow.choose(str(person.topics[1].id)) and flow.current().lesson.is_empty(), "The explanation starts without exposing code prematurely")
		flow.advance()
		var lesson: Dictionary = flow.current().lesson
		_check(not lesson.is_empty() and flow.stage == "topic", "The relevant explanation offers optional code: " + id)
		var state: Dictionary = rules.initial_state()
		var answer: Dictionary = LabProgram.run(str(lesson.source), rules.snapshot(state))
		_check(answer.ok, "The optional example really runs in WASI: " + id + " " + str(answer.reason))
		if answer.ok:
			var result: Dictionary = rules.propose(state, answer.commands, answer.memory)
			_check(result.ok and state == rules.initial_state(), "Its validated proposal leaves committed state unchanged: " + id)
		flow.advance()
		_check(flow.choose("leave") and flow.closed, "Every topic returns to choices and the conversation can end")
		var entry: Dictionary = art.items[id]
		_check(FileAccess.get_sha256(entry.source) == entry.source_sha256 and FileAccess.get_sha256(entry.runtime) == entry.source_sha256, "Source and runtime portrait match: " + id)
		_check(not hashes.has(entry.source_sha256), "Each resident has unique portrait artwork")
		hashes.append(entry.source_sha256)
		var portrait := Image.load_from_file(ProjectSettings.globalize_path(entry.runtime))
		_check(portrait.get_width() >= 1000 and portrait.get_height() >= 1500 and portrait.detect_alpha(), "Portrait is high-definition and transparent: " + id)
		_check(portrait.get_pixel(0,0).a < 0.02, "A transparent corner reveals the live village")
		var imported := ConfigFile.new()
		imported.load(str(entry.runtime) + ".import")
		_check(imported.get_value("params","compress/mode") == 0 and imported.get_value("params","mipmaps/generate") == false, "Lossless UI import: " + id)
	var restored: Dictionary = VillageDialogue.restore_read({"mira":["greeting","bad",8],"ghost":["menu"],"nell":"bad"}, people)
	_check(restored == {"mira":["greeting"]}, "Malformed and obsolete saved read flags are filtered")
	var bad: Dictionary = people.mira.duplicate(true)
	bad.topics[1].id = bad.topics[0].id
	_check(not VillageDialogue.validate(bad).is_empty(), "Duplicate topic ids are refused")
	bad = people.mira.duplicate(true)
	bad.topics[1].lesson.source = 12
	_check(not VillageDialogue.validate(bad).is_empty(), "A malformed optional example is refused")
	var long_talk := VillageDialogue.new(people.mira)
	long_talk.advance()
	for _repeat: int in range(100):
		long_talk.choose("explore")
		while long_talk.stage == "topic":
			long_talk.advance()
	_check(long_talk.history.size() == VillageDialogue.MAX_HISTORY, "A long conversation keeps a bounded history")
	await _game_flow()
	await _prompts_flow(people)
	if failures.is_empty():
		print("Village dialogue: %d checks passed (five portraits, branching, optional real WASI examples, controls, modal flow and saved reads)." % checks)
	else:
		for failure: String in failures:
			printerr("FAIL: ",failure)
	quit(0 if failures.is_empty() else 1)


func _game_flow() -> void:
	SaveStore.save_path = "user://test_dialogue.json"
	SaveStore.profile_path = "user://test_dialogue_profile.json"
	SaveStore.force_enabled = true
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game.view.villagers.set_process(false)
	var actor: SpriteAdventurer = game.view.villagers.actors.mira
	game.session.state.player = [roundi(actor.position.x), roundi(-actor.position.z)-1, 0]
	game.view.sync_player(game.session.state)
	var before: Dictionary = game.session.state.duplicate(true)
	var program: String = game.session.source
	game.interact()
	_check(not game._modals.is_empty() and game._modals[-1] is VillageConversation, "F opens the real conversation scene")
	if game._modals.is_empty():
		return
	var conversation: VillageConversation = game._modals[-1]
	await process_frame
	_check(not game.session.input_enabled and not game.hud.visible and game.view.villagers.paused, "Conversation owns input, hides the play HUD and pauses residents")
	_check(conversation.portrait.texture.resource_path.ends_with("mira.png") and conversation.portrait.position.y <= conversation.size.y * 0.375 and conversation.portrait.size.y <= conversation.size.y * 0.5 + 1, "The speaker's smaller portrait is lifted at least 125 px at the standard size to show the upper body")
	_check(conversation.text.visible_characters != -1 and not conversation.choices.visible, "A page reveals progressively before choices")
	conversation.advance()
	_check(conversation.text.visible_characters == -1 and conversation.dialogue.stage == "greeting", "First Next reveals; it does not skip the current page")
	conversation.advance()
	conversation.reveal()
	conversation.auto = true
	conversation._process(100)
	_check(conversation.dialogue.stage == "menu", "Auto never chooses a reply")
	conversation.choose("map-notes")
	conversation.reveal()
	conversation.advance()
	conversation.reveal()
	_check(conversation.code_button.visible and conversation.mode == "", "Code is offered on the relevant page, hidden by default")
	conversation.show_panel("code")
	_check(conversation.code != null and not conversation.code.editable and conversation.code.text.contains("place_name"), "Show code opens a real highlighted read-only example")
	conversation._process(100)
	_check(conversation.dialogue.stage == "topic" and conversation.dialogue.line_index == 1, "Reading code pauses Auto")
	_check(game.session.source == program and game.session.state == before and not game.session.has_preview(), "Conversation/examples do not run or replace the player's draft")
	conversation.show_panel("history")
	_check(conversation.dialogue.history.any(func(item: Dictionary) -> bool: return item.speaker == "You"), "History includes the player's chosen response")
	conversation.show_panel("")
	conversation.toggle_ui()
	_check(conversation.ui_hidden and not conversation.card.visible and not conversation.portrait.visible and not game.session.input_enabled, "Hide UI reveals the village without enabling walking")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	conversation._input(escape)
	_check(not conversation.ui_hidden and game._modals.size() == 1, "Escape first restores hidden dialogue")
	conversation.show_panel("settings")
	game.open_settings()
	_check(not conversation.visible and game._modals.size() == 2, "Game settings stack over dialogue")
	(game._modals[-1] as Modal).close()
	_check(conversation.visible and not game.session.input_enabled, "Returning from settings restores dialogue with input still blocked")
	game.save_now()
	_check(SaveStore.read().dialogue_read.mira.has("map-notes:1"), "Read pages are stored with the journey")
	conversation.notebook_requested.emit()
	_check(game.notebook_open and game._modals.is_empty() and game.hud.visible and game.session.source == program, "Open notebook preserves the existing draft and restores play presentation")
	game.close_notebook(true)
	await game._return_to_title()
	await game.continue_game()
	_check(game._dialogue_read.mira.has("map-notes:1"), "Continue restores read flags for Skip read")
	game.view.villagers.set_process(false)
	actor = game.view.villagers.actors.mira
	game.session.state.player = [roundi(actor.position.x), roundi(-actor.position.z)-1, 0]
	game.interact()
	conversation = game._modals[-1]
	conversation._toggle_skip()
	conversation._process(1)
	conversation.reveal()
	_check(conversation.dialogue.stage == "menu" and not conversation.skipping, "Skip read fast-forwards a saved page and stops at choices")
	conversation.choose("explore")
	conversation._toggle_skip()
	_check(not conversation.skipping and conversation.text.visible_characters != -1, "Skip read stops on an unread topic")
	conversation.close()
	var door: Vector2i = HouseInstances.door(game.area, "mira-house")
	game.session.state.player = [door.x, door.y, 0]
	game.view.sync_player(game.session.state)
	_check(await game.enter_house("mira-house"), "The same conversation system works in a saved home")
	game.view.villagers.set_process(false)
	actor = game.view.villagers.actors.mira
	game.session.state.player = [roundi(actor.position.x), roundi(-actor.position.z)-1, 0]
	game._refresh_interaction()
	_check(game._interaction.get("kind") == "talk", "The indoor host offers the ordinary F conversation")
	game.interact()
	conversation = game._modals[-1]
	_check(conversation.portrait.texture.resource_path.ends_with("mira.png") and game.inside_house(), "An indoor conversation shows the host's matching portrait without leaving the room")
	conversation.close()
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))


## F's prompts live in the world: a speech bubble over the resident F would talk to, a hand over a thing F would
## use, and marks over residents with something to say. Residents are solid: nobody walks through anybody.
func _prompts_flow(people: Dictionary) -> void:
	var mira: Dictionary = people.mira
	var every_page: Array = VillageDialogue.page_keys(mira)
	_check(VillageDialogue.marker(mira, [], false, "") == "!", "A resident you have never met has something to say: !")
	_check(VillageDialogue.marker(mira, ["greeting", "menu"], true, "") == "!", "Unheard topics keep the !")
	_check(VillageDialogue.marker(mira, every_page, true, "") == "", "Once every page is heard there is no mark")
	_check(VillageDialogue.marker(mira, [], false, "mill-bridge") == "?", "A resident whose topic helps with the current quest shows ?")
	_check(VillageDialogue.marker(mira, every_page, true, "mill-bridge") == "", "Once that help has been heard, the ? goes")
	var bad: Dictionary = mira.duplicate(true)
	bad.topics[1].helps = [12]
	_check(not VillageDialogue.validate(bad).is_empty(), "A topic's helps must list quest ids")
	var quests: AreaDef = AreaStore.read("kindle-hollow").area
	for id: String in people:
		for topic: Dictionary in people[id].topics:
			for quest: Variant in topic.get("helps", []):
				_check(not quests.quest(str(quest)).is_empty(), "%s's topic %s helps a real quest: %s" % [id, topic.id, quest])
	SaveStore.delete()
	game = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	await game.start_new_game()
	game.session.set_physics_process(false)
	game.view.villagers.set_process(false)
	_check(game.hud.get("_interaction") == null and game.prompts != null and game.prompts.get_parent() == game.hud, "The F button is gone; F's prompts are drawn in the world, with the HUD")
	var actor: SpriteAdventurer = game.view.villagers.actors.mira
	var cell := Vector2i(Vector2(actor.position.x, -actor.position.z).round())
	game.session.state.player = [cell.x, cell.y - 1, 0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(game.prompts.target.get("kind") == "talk" and game.prompts.target.get("id") == "mira", "Beside a resident, the bubble goes over the one F would talk to")
	_check(game.prompts.markers.get("mira") in ["!", "?"] and game.prompts.target.get("mark") == game.prompts.markers.get("mira"), "A resident not yet met wears a mark, and the bubble carries it")
	var head: Variant = game.prompts._head("mira")
	var feet: Vector2 = game.prompts._to_screen(actor.global_position)
	_check(head is Vector2 and (head as Vector2).y < feet.y - 20.0 and absf((head as Vector2).x - feet.x) < 4.0, "The bubble is anchored above the resident's head")
	game.prompts._layout()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_check(game.prompts._has_point(game.prompts._bubble_rect.get_center()) and not game.prompts._has_point(Vector2(5, 5)), "Only the bubble takes clicks; the rest of the screen still reaches the world")
	game.prompts._gui_input(click)
	_check(not game._modals.is_empty() and game._modals[-1] is VillageConversation, "Clicking the bubble does what F does")
	_check(game.session.facing == Vector2i(0, 1), "The apprentice turns to face the resident they talk to")
	(game._modals[-1] as VillageConversation).close()
	await process_frame
	# Solid residents.
	var from: Vector2i = game.session.player_cell()
	_check(not game.session.request_step(Vector2i(0, 1)) and game.session.player_cell() == from and game.session.facing == Vector2i(0, 1), "Walking into a resident stops and faces them")
	_check(game.view.resident_cells().has(cell), "A resident's cell is taken")
	game.session.state.player = [cell.x - 3, cell.y, 0]
	game.view.sync_player(game.session.state)
	game.session.walk_to(cell)
	_check(not game.session._route.is_empty() and game.session._route[-1] != cell and (game.session._route[-1] - cell).length() == 1 and game.session._route_face == cell, "Clicking a resident walks up beside them, not into them")
	game.session._cancel_route()
	# Every resident wears a mark until they have nothing new; talking it all through clears it.
	game._dialogue_read["mira"] = every_page.duplicate()
	game._met_villagers["mira"] = true
	game.session.state.player = [cell.x, cell.y - 1, 0]
	game.view.sync_player(game.session.state)
	game._refresh_interaction()
	_check(not game.prompts.markers.has("mira") and game.prompts.target.get("mark") == "", "A resident with nothing new wears no mark; the bubble shows only that F talks")
	# A working thing gets a hand instead.
	game.session.state.player = [cell.x + 6, cell.y - 3, 0]
	var spot := Vector2(cell.x + 6, cell.y - 2)
	game.open_build()
	var placed: Dictionary = game.ledger.place("hollow-wayfarers-chest", spot, "S", game.session.state)
	_check(placed.ok, "A working chest can stand in the meadow")
	if placed.ok:
		game.builder._after_edit("Placed a chest")
		game.close_build()
		game.view.sync_player(game.session.state)
		game._refresh_interaction()
		_check(game.prompts.target.get("kind") == "prop" and game.prompts.target.get("id") == placed.edit.id and game.prompts.tooltip_text.contains("Open"), "Beside a working thing, the hand goes over it and says what F does")
		_check(game.prompts._top_of_prop(str(placed.edit.id)) is Vector2, "The hand is anchored on top of the thing")
	game.queue_free()
	await process_frame
	SaveStore.delete()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveStore.profile_path))


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
