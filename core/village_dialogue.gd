class_name VillageDialogue
extends RefCounted
## Plain-data conversation navigation and read tracking. No renderer, files or program execution.

const MAX_HISTORY: int = 128
var person: Dictionary
var issues: Array[String] = []
var read_pages: Dictionary = {}
var history: Array[Dictionary] = []
var topic: String = ""
var line_index: int = 0
var stage: String = "greeting"
var closed: bool = false
var read_before_enter: bool = false
var _sequence_index: int = 0


func _init(definition: Dictionary = {}, previously_read: Array = []) -> void:
	person = definition.duplicate(true)
	issues = validate(person)
	if not issues.is_empty():
		return
	var permitted: Array[String] = page_keys(person)
	for key: Variant in previously_read:
		if key is String and permitted.has(key):
			read_pages[key] = true
	if is_guided():
		_enter_sequence_part()
	_enter()


static func validate(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for key: String in ["name", "role", "skin", "greeting"]:
		if not definition.get(key) is String or str(definition[key]).strip_edges() == "":
			errors.append("A conversation needs a nonempty " + key + ".")
	var topics: Variant = definition.get("topics", [])
	if not topics is Array or topics.is_empty() or topics.size() > 8:
		errors.append("A conversation needs between one and eight topics.")
		return errors
	var ids: Array[String] = []
	for entry: Variant in topics:
		if not entry is Dictionary:
			errors.append("A topic must be a dictionary.")
			continue
		var id: String = str(entry.get("id", ""))
		if not AreaDef._id(id) or id in ids or id in ["leave", "greeting", "menu"]:
			errors.append("A topic needs a unique id, distinct from the greeting, menu and leave action.")
		ids.append(id)
		if not entry.get("title") is String or str(entry.title).strip_edges() == "":
			errors.append("A topic needs a response title.")
		var lines: Variant = entry.get("lines")
		if not lines is Array or lines.is_empty() or lines.size() > 12:
			errors.append("A topic needs between one and twelve dialogue pages.")
		else:
			for line: Variant in lines:
				if not line is String or line.strip_edges() == "" or line.length() > 500:
					errors.append("A dialogue page must contain one to 500 characters.")
		var helps: Variant = entry.get("helps", [])
		if not helps is Array or helps.size() > 8 or not (helps as Array).all(func(quest: Variant) -> bool: return quest is String and AreaDef._id(quest)):
			errors.append("A topic's helps must list up to eight quest ids.")
		var lesson: Variant = entry.get("lesson", {})
		if not lesson is Dictionary:
			errors.append("An optional lesson must be a dictionary.")
		elif not lesson.is_empty():
			for key: String in ["title", "concept", "explanation", "source"]:
				if not lesson.get(key) is String or str(lesson[key]).strip_edges() == "":
					errors.append("An optional lesson needs " + key + ".")
			if str(lesson.get("source", "")).to_utf8_buffer().size() > 16384:
				errors.append("A lesson example must fit the notebook's source limit.")
	if definition.has("sequence"):
		var sequence: Variant = definition.sequence
		if not sequence is Array or sequence.is_empty() or sequence.size() > 9:
			errors.append("A guided conversation needs one to nine pages or topics in its sequence.")
		else:
			var used: Array[String] = []
			for part: Variant in sequence:
				if not part is String or (part != "greeting" and not ids.has(part)) or used.has(part):
					errors.append("A guided sequence needs distinct greeting/topic ids from this conversation.")
				else:
					used.append(part)
	var finish: Variant = definition.get("on_finish", "")
	if not finish is String or finish not in ["", "notebook"] or (finish != "" and not definition.has("sequence")):
		errors.append("Only a guided conversation can request the notebook when it finishes.")
	return errors


func is_guided() -> bool:
	return person.has("sequence")


func _enter_sequence_part() -> void:
	var part: String = person.sequence[_sequence_index]
	stage = "greeting" if part == "greeting" else "topic"
	topic = "" if part == "greeting" else part
	line_index = 0


static func page_keys(definition: Dictionary) -> Array[String]:
	var keys: Array[String] = ["greeting", "menu"]
	for entry: Dictionary in definition.get("topics", []):
		for index: int in range(entry.lines.size()):
			keys.append("%s:%d" % [entry.id, index])
	return keys


## The mark over a resident's head: "?" while one of their topics helps with the current quest (its `helps` lists
## the quest) and you have not heard it all; else "!" if you have never spoken or they have pages you have not
## read; else "" (nothing new to say).
static func marker(definition: Dictionary, read: Array, met: bool, quest_id: String) -> String:
	if not validate(definition).is_empty():
		return ""
	var unread := func(entry: Dictionary) -> bool:
		for index: int in range((entry.lines as Array).size()):
			if not read.has("%s:%d" % [entry.id, index]):
				return true
		return false
	for entry: Dictionary in definition.topics:
		if quest_id != "" and (entry.get("helps", []) as Array).has(quest_id) and unread.call(entry):
			return "?"
	if not met:
		return "!"
	for entry: Dictionary in definition.topics:
		if unread.call(entry):
			return "!"
	return ""


static func restore_read(raw: Variant, people: Dictionary) -> Dictionary:
	var restored: Dictionary = {}
	if not raw is Dictionary:
		return restored
	for id: String in people:
		if not raw.get(id) is Array or not validate(people[id]).is_empty():
			continue
		var permitted: Array[String] = page_keys(people[id])
		var keys: Array[String] = []
		for key: Variant in raw[id]:
			if key is String and key in permitted and key not in keys:
				keys.append(key)
		restored[id] = keys
	return restored


func current() -> Dictionary:
	if closed or not issues.is_empty():
		return {}
	var page: Dictionary = {"key": stage, "speaker": person.name, "role": person.role, "text": "", "choices": [], "lesson": {}}
	match stage:
		"greeting":
			page.text = person.greeting
		"menu":
			page.text = str(person.get("prompt", "What would you like to talk about?"))
			for entry: Dictionary in person.topics:
				page.choices.append({"id": entry.id, "title": entry.title})
			page.choices.append({"id": "leave", "title": "See you around."})
		"topic":
			var entry: Dictionary = _topic()
			page.key = "%s:%d" % [topic, line_index]
			page.text = entry.lines[line_index]
			if line_index == entry.lines.size() - 1:
				page.lesson = entry.get("lesson", {}).duplicate(true)
	return page


func mark_read() -> void:
	var page: Dictionary = current()
	if not page.is_empty():
		read_pages[page.key] = true


func advance() -> bool:
	if closed or not issues.is_empty() or stage == "menu":
		return false
	mark_read()
	if is_guided():
		if stage == "topic" and line_index + 1 < (_topic().lines as Array).size():
			line_index += 1
		else:
			_sequence_index += 1
			if _sequence_index >= (person.sequence as Array).size():
				closed = true
				return true
			_enter_sequence_part()
		_enter()
		return true
	if stage == "greeting":
		stage = "menu"
	elif line_index + 1 < (_topic().lines as Array).size():
		line_index += 1
	else:
		stage = "menu"
	_enter()
	return true


func choose(id: String) -> bool:
	if closed or not issues.is_empty() or is_guided() or stage != "menu":
		return false
	for choice: Dictionary in current().choices:
		if choice.id != id:
			continue
		mark_read()
		_log({"speaker": "You", "text": choice.title})
		if id == "leave":
			closed = true
		else:
			stage = "topic"
			topic = id
			line_index = 0
			_enter()
		return true
	return false


func _topic() -> Dictionary:
	for entry: Dictionary in person.topics:
		if entry.id == topic:
			return entry
	return {}


func _enter() -> void:
	var page: Dictionary = current()
	read_before_enter = read_pages.has(page.key)
	_log({"speaker": page.speaker, "text": page.text})


func _log(entry: Dictionary) -> void:
	history.append(entry)
	if history.size() > MAX_HISTORY:
		history.pop_front()
