class_name DisplayCards
extends RefCounted
## Plain display data and atomic replacement rules. The presenter never executes Python.
const MAX_PAGES: int = 3
const COLUMNS: int = 16
const MAX_TEXT: int = 32

static func find(area: AreaDef, id: String) -> Dictionary:
	for display: Dictionary in area.displays:
		if display.id == id: return display
	return {}

static func text_error(pages: Variant) -> String:
	if not pages is Array or pages.is_empty() or pages.size()>MAX_PAGES: return "Use one to three printed messages on this card."
	for index: int in range(pages.size()):
		var page: Variant = pages[index]
		if not page is String or page.strip_edges().is_empty(): return "Message %d is empty. Give it some words." % (index+1)
		if page.length()>MAX_TEXT: return "Message %d is too long. Use at most %d characters." % [index+1,MAX_TEXT]
		for character: String in page:
			var code: int = character.unicode_at(0)
			if code<32 or (code>=127 and code<160) or code>255: return "Message %d uses a character this sign cannot display. Use Latin letters, numbers and punctuation." % (index+1)
	return ""

static func in_reach(area: AreaDef, state: Dictionary, display: Dictionary) -> bool:
	return not display.is_empty() and (state.get("zones_seen",[]) as Array).has(display.zone) and PlayerItems.has(state,"field-tablet") and FieldAccess.near(state,display.at) and (state.get("inspections_read",[]) as Array).has(str(display.commission))

static func apply(area: AreaDef, state: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if command.size()!=3 or not command.get("target") is String: return "A display card needs a target and messages."
	var display: Dictionary = find(area,str(command.target))
	if display.is_empty(): return "That display is not in this area."
	if not in_reach(area,state,display): return "Accept the sign commission and stand at the display with Nell's slate to write its card."
	var error: String = text_error(command.get("messages"))
	if error!="": return error
	state.display_cards[display.id] = command.messages.duplicate()
	changes.append("%s: %d messages on the card." % [display.title,command.messages.size()])
	return ""

static func distinct(pages: Array) -> int:
	var unique: Dictionary = {}
	for page: String in pages: unique[page.strip_edges()] = true
	return unique.size()

static func rows(text: String) -> String:
	# Fixed-advance font, hard width bound. Word breaks where possible, otherwise
	# split a long word. Validation above makes two rows sufficient.
	if text.length()<=COLUMNS: return text
	var split: int = text.rfind(" ",COLUMNS)
	if split<text.length()-COLUMNS or split<1: split=COLUMNS
	return text.left(split).strip_edges()+"\n"+text.substr(split).strip_edges()
