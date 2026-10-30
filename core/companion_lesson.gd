class_name CompanionLesson
extends RefCounted
## Speech is a plain, bounded proposal like every other world command.
const STARTER: String = 'def program(world):\n    print("Hello, Hotaru!")\n'

static func has_voice(state: Dictionary, completed: Array) -> bool:
	# Learning persists even if the player undoes the words their program spoke.
	return bool(state.get("hotaru_greeted", false)) or completed.has("say-hello")

static func is_greeting(text: String) -> bool:
	var words:=text.to_lower()
	for mark: String in [",","!",".","?",":",";","\n"]:words=words.replace(mark," ")
	var parts:=words.split(" ",false)
	return parts.has("hotaru") and (parts.has("hello") or parts.has("hi") or parts.has("hey") or words.contains("good morning"))

static func apply(area: AreaDef, state: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if not area.movement_lesson and not area.voice_lesson:return "Hotaru's voice lesson belongs to Village Morning."
	if command.size()!=3 or command.get("target")!="hotaru" or not command.get("text") is String:return "Say text to Hotaru with print(\"Hello, Hotaru!\")."
	var text: String=command.text
	if text.strip_edges().is_empty() or text.length()>160:return "Say between 1 and 160 characters so Hotaru can hear you clearly."
	state["spoken"]=text
	state["hotaru_greeted"]=state.get("hotaru_greeted",false) or is_greeting(text)
	changes.append('You say: "%s"' % text)
	return ""
