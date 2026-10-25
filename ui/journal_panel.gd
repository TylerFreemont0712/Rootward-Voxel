class_name JournalPanel
extends Modal
## Every quest with its lesson: finished ones to reread, the current one to act on, later ones locked.

signal notebook_requested

var _lesson: LessonView
var _area: AreaDef
var _completed: Array = []
var _buttons: Dictionary = {}
var _selected: String = ""
var _state: Dictionary = {}
var _session: GameSession


func setup(session: GameSession) -> void:
	_session = session
	_area = session.area
	_completed = session.completed
	card.custom_minimum_size = Vector2(1060, 640)
	title_row("Journal", "Each quest teaches one idea of programming. Finished lessons stay here to reread.")
	var layout := UI.hbox(24)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(layout)
	var list := UI.vbox(8)
	list.custom_minimum_size = Vector2(340, 0)
	layout.add_child(list)
	var group := ButtonGroup.new()
	var current: Dictionary = session.current_quest()
	var chapter: String = ""
	for quest: Dictionary in Quests.listed(_area, _completed):
		# A later chapter gets its own heading in the list, once it has been reached.
		if str(quest.chapter) != "" and str(quest.chapter) != chapter:
			chapter = str(quest.chapter)
			list.add_child(UI.caps(chapter, Pal.VIOLET))
		var done: bool = _completed.has(quest.id)
		var unlocked: bool = done or quest.id == str(current.get("id", ""))
		var icon: StringName = &"check" if done else (&"star" if unlocked else &"lock")
		var button := UI.button(str(quest.title), icon, &"ButtonTab")
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size = Vector2(0, 56)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.disabled = not unlocked
		button.pressed.connect(_select.bind(str(quest.id)))
		list.add_child(button)
		_buttons[quest.id] = button
		var concept := UI.label("   " + str(quest.concept), &"LabelDim", 14)
		list.add_child(concept)
	list.add_child(UI.spacer(0, true))
	_lesson = LessonView.new()
	_lesson.custom_minimum_size = Vector2(620, 440)
	layout.add_child(_lesson)
	body.add_child(UI.rule())
	var row := UI.hbox(12)
	body.add_child(row)
	var notebook := UI.button("Open the notebook", &"book", &"", func() -> void:
		close()
		notebook_requested.emit())
	notebook.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(notebook)
	var done_button := UI.button("Close", &"check", &"ButtonPrimary", close)
	done_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(done_button)
	var start: String = str(current.get("id", ""))
	if start == "" and not _area.quests.is_empty():
		start = str(_area.quests[-1].id)
	_select(start)


func _select(quest_id: String) -> void:
	_selected = quest_id
	var quest: Dictionary = _area.quest(quest_id)
	if _buttons.has(quest_id):
		(_buttons[quest_id] as Button).set_pressed_no_signal(true)
	_lesson.show_quest(quest, _completed.has(quest_id), Quests.goal_progress(_area, _session.state, quest.get("goal", {})), false)
