class_name LearningLesson
extends SideDrawer
## Shared lifecycle for the field notes and their independent test window.
signal closed
signal applied
signal next_lesson
var session: GameSession
var editor: CodeEditor
var test_window: LessonTestWindow

func setup(_value: GameSession, _settings: GameSettings) -> void:pass
func preview() -> void:pass
func stop() -> void:pass
func close() -> void:closed.emit()
func has_text_focus() -> bool:
	var owner: Control=get_viewport().gui_get_focus_owner()
	return owner!=null and is_ancestor_of(owner) and (owner is LineEdit or owner is TextEdit)
func drop_focus() -> void:
	var owner: Control=get_viewport().gui_get_focus_owner()
	if owner!=null and is_ancestor_of(owner):owner.release_focus()
