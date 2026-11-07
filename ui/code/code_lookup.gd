class_name CodeLookup
extends RefCounted
## What a name in a program is, answered the way a code editor answers it: a variable the program makes (where it is
## set, what it held when last debugged), a member of the game's API (its signature, a line of explanation, what it
## returns), a Python keyword or built-in. When the link can say, it also tells what an expression holds right now,
## such as the lamps in `workshop.lamps`. Pure: it reads the source text, ApiReference and a small picture of the
## link ({"zones": {id: [lamp ids]}, "lamps": {id: {"title", "lit"}}, "values": {name: last debugged text}}).

const KEYWORD_DOCS: Dictionary = {
	"def": "Starts a function. program(world) is the one the slate runs.",
	"for": "Runs the indented lines once for each item of a list, giving the item a name as it goes.",
	"in": "Names the list a for loop walks through.",
	"if": "Runs the indented lines only when its test is True.",
	"elif": "Another test, tried when the if above it did not run.",
	"else": "Runs when the if above it did not.",
	"while": "Repeats the indented lines for as long as its test is True.",
	"return": "Ends a function and hands back a value.",
	"True": "Python's yes.",
	"False": "Python's no.",
	"None": "Python's word for nothing at all.",
	"not": "Turns True into False and False into True.",
	"and": "True only when both sides are True.",
	"or": "True when either side is True.",
	"pass": "Does nothing. It holds a place where Python needs a line.",
	"break": "Leaves the loop it is in.",
	"continue": "Skips straight to the loop's next item.",
}
const BUILTIN_DOCS: Dictionary = {
	"print": ["print(value)", "Writes a value to OUTPUT."],
	"len": ["len(items)", "How many items a list holds."],
	"range": ["range(n)", "The numbers from 0 up to n - 1, for a loop to count with."],
	"str": ["str(value)", "The value written as text."],
	"int": ["int(value)", "The value as a whole number."],
	"min": ["min(items)", "The smallest item."],
	"max": ["max(items)", "The largest item."],
	"sum": ["sum(items)", "All the numbers added together."],
	"sorted": ["sorted(items)", "A new list in order, smallest first."],
	"enumerate": ["enumerate(items)", "Each item paired with its position: (0, first), (1, second), ..."],
}


## The dotted expression under `column` on `line`: "workshop.lamps" with the pointer on "lamps", or
## 'world.zone("workshop").lamps' through a call. Empty when the pointer is not on a name.
static func expression_at(line: String, column: int) -> String:
	var word := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
	var hit: RegExMatch = null
	for candidate: RegExMatch in word.search_all(line):
		if candidate.get_start() <= column and column <= candidate.get_end():
			hit = candidate
			break
	if hit == null or _in_string(line, hit.get_start()) or _in_comment(line, hit.get_start()):
		return ""
	var start: int = hit.get_start()
	while start > 0 and line[start - 1] == ".":
		var cursor: int = start - 1
		if cursor > 0 and line[cursor - 1] == ")":
			var depth: int = 0
			cursor -= 1
			while cursor >= 0:
				if line[cursor] == ")": depth += 1
				elif line[cursor] == "(":
					depth -= 1
					if depth == 0: break
				cursor -= 1
			if cursor < 0: break
		elif cursor > 0 and line[cursor - 1] == "]":
			cursor = line.rfind("[", cursor - 1)
			if cursor < 0: break
		var left: int = cursor
		while left > 0 and _identifier_char(line[left - 1]): left -= 1
		if left == cursor: break
		start = left
	return line.substr(start, hit.get_end() - start)


## Where a name is first set in the program: {"line" (from 0), "column", "text", and "value" for an assignment,
## "loop" for a for loop, "parameter" for a function's parameter}, or {}.
static func definition(source: String, name: String) -> Dictionary:
	if not name.is_valid_identifier(): return {}
	var found: Dictionary = {}
	var patterns: Array[Array] = [
		["value", "(?m)^[ \\t]*(" + name + ")[ \\t]*=(?!=)[ \\t]*(.+)$"],
		["loop", "(?m)^[ \\t]*for[ \\t]+(" + name + ")[ \\t]+in[ \\t]+(.+?)[ \\t]*:"],
		["parameter", "(?m)^[ \\t]*def[ \\t]+[A-Za-z_][A-Za-z0-9_]*\\([^)]*\\b(" + name + ")\\b[^)]*\\)"],
	]
	for pattern: Array in patterns:
		var hit: RegExMatch = RegEx.create_from_string(pattern[1]).search(source)
		if hit == null: continue
		var line: int = source.substr(0, hit.get_start(1)).count("\n")
		if not found.is_empty() and int(found.line) <= line: continue
		var line_start: int = source.rfind("\n", hit.get_start(1) - 1) + 1
		found = {"line": line, "column": hit.get_start(1) - line_start, "text": source.get_slice("\n", line).strip_edges()}
		if pattern[0] == "parameter": found["parameter"] = true
		else: found[pattern[0]] = _without_comment(hit.get_string(2)).strip_edges()
	return found


## What the name or expression is, for a hover card: {"kind", "title", "type", "doc", "value", "items", "line"}, or
## {} when it is nothing the program or the game knows.
static func describe(source: String, expression: String, link: Dictionary) -> Dictionary:
	var parts: PackedStringArray = _parts(expression)
	if parts.is_empty(): return {}
	var first: String = _name(parts[0])
	if parts.size() == 1:
		if KEYWORD_DOCS.has(first):
			return {"kind": "keyword", "title": first, "doc": KEYWORD_DOCS[first]}
		if BUILTIN_DOCS.has(first):
			return {"kind": "built-in function", "title": BUILTIN_DOCS[first][0], "doc": BUILTIN_DOCS[first][1]}
		if ApiReference.BUILTINS.has(first):
			return {"kind": "built-in function", "title": first + "(...)", "doc": "One of Python's built-in functions."}
		if first == "program" and definition(source, "program").is_empty():
			return {"kind": "function", "title": "def program(world)", "doc": "The routine the slate runs. Everything it does to the world happens inside it."}
	var base_type: String = "World" if first == "world" else ApiReference.infer_type(source, first)
	if parts.size() == 1:
		var where: Dictionary = definition(source, first)
		if where.is_empty() and first != "world": return {}
		var held: Dictionary = resolve(source, first, link)
		var result: Dictionary = {"kind": "variable", "name": first, "type": _type_label(base_type, held), "line": int(where.get("line", -1))}
		result["title"] = "%s: %s" % [first, result.type] if result.type != "" else first
		if first == "world":
			result["doc"] = "Given to program(world): the places you have visited and what is in them."
		else:
			result["doc"] = "Set on line %d:  %s" % [int(where.get("line", 0)) + 1, str(where.get("text", ""))]
		var values: Dictionary = link.get("values", {})
		result["value"] = str(values[first]) if values.has(first) else str(held.get("value", ""))
		result["items"] = list_items(str(result.value)) if values.has(first) else held.get("items", [])
		return result
	var owner: String = base_type
	for index: int in range(1, parts.size() - 1):
		owner = ApiReference._returns(owner, _name(parts[index])).trim_suffix("[]")
	var member_name: String = _name(parts[-1])
	for member: Dictionary in ApiReference.members_of(owner):
		if member.name != member_name: continue
		var held: Dictionary = resolve(source, expression, link)
		var returns: String = str(member.returns).replace("[]", "")
		var type: String = ("list[%s]" % returns) if str(member.returns).ends_with("[]") else returns
		return {"kind": "method" if member.kind == "method" else "attribute", "title": str(member.sig) + ((" -> " + type) if type != "" else ""),
			"type": type, "doc": str(member.doc), "owner": owner, "value": str(held.get("value", "")), "items": held.get("items", []), "line": -1}
	return {}


## What an expression holds, worked out from the program's own assignments and the link: {"value", "items",
## "kind"}, or {} when it cannot be known without running the program.
static func resolve(source: String, expression: String, link: Dictionary, depth: int = 0) -> Dictionary:
	if depth > 5: return {}
	var parts: PackedStringArray = _parts(expression)
	if parts.is_empty(): return {}
	var zones: Dictionary = link.get("zones", {})
	var lamps: Dictionary = link.get("lamps", {})
	var current: Dictionary = {}
	var first: String = _name(parts[0])
	if first == "world":
		current = {"kind": "world"}
	else:
		var where: Dictionary = definition(source, first)
		if where.has("value"):
			current = resolve(source, str(where.value), link, depth + 1)
		elif where.has("loop"):
			var walked: Dictionary = resolve(source, str(where.loop), link, depth + 1)
			if walked.get("kind", "") != "lamps": return {}
			current = {"kind": "each", "ids": walked.ids}
		if current.is_empty(): return {}
	current = _subscript(current, parts[0])
	for index: int in range(1, parts.size()):
		var name: String = _name(parts[index])
		var argument: String = _argument(parts[index])
		match str(current.get("kind", "")):
			"world":
				if name == "zone" and zones.has(argument): current = {"kind": "zone", "id": argument}
				elif name == "lamp" and lamps.has(argument): current = {"kind": "lamp", "id": argument}
				elif name == "lamps":
					var every: Array = []
					for zone: String in zones: every.append_array(zones[zone])
					current = {"kind": "lamps", "ids": every}
				else: return {}
			"zone":
				if name == "lamps": current = {"kind": "lamps", "ids": zones.get(current.id, [])}
				elif name == "id": current = {"kind": "text", "text": "'%s'" % str(current.id)}
				else: return {}
			"lamp":
				if name == "id": current = {"kind": "text", "text": "'%s'" % str(current.id)}
				elif name == "lit": current = {"kind": "text", "text": str(bool((lamps.get(current.id, {}) as Dictionary).get("lit", false))).capitalize()}
				else: return {}
			_:
				return {}
		current = _subscript(current, parts[index])
	match str(current.get("kind", "")):
		"world": return {"kind": "world", "value": "World"}
		"zone": return {"kind": "zone", "value": "Zone('%s')" % str(current.id), "id": current.id}
		"lamp": return {"kind": "lamp", "value": _lamp_text(str(current.id), lamps), "id": current.id}
		"text": return {"kind": "text", "value": str(current.text)}
		"lamps", "each":
			var ids: Array = current.ids
			var items: Array[String] = []
			for id: Variant in ids: items.append(_lamp_text(str(id), lamps))
			var shown: Array = ids.map(func(id: Variant) -> String: return "Lamp('%s')" % str(id))
			var value: String = ("[%s]" if current.kind == "lamps" else "each of [%s]") % ", ".join(PackedStringArray(shown))
			return {"kind": current.kind, "value": value, "items": items, "ids": ids}
	return {}


## The items of a list as written ("[Lamp('a'), Lamp('b')]" → two items), or [] when it is not a list.
static func list_items(value: String) -> Array[String]:
	var items: Array[String] = []
	var text: String = value.strip_edges()
	if not (text.begins_with("[") and text.ends_with("]")) or text.length() < 3: return items
	var depth: int = 0
	var quote: String = ""
	var piece: String = ""
	for character: String in text.substr(1, text.length() - 2):
		if quote != "":
			if character == quote: quote = ""
		elif character in ["'", "\""]: quote = character
		elif character in ["(", "[", "{"]: depth += 1
		elif character in [")", "]", "}"]: depth -= 1
		elif character == "," and depth == 0:
			items.append(piece.strip_edges())
			piece = ""
			continue
		piece += character
	if piece.strip_edges() != "": items.append(piece.strip_edges())
	return items


static func _lamp_text(id: String, lamps: Dictionary) -> String:
	var lamp: Dictionary = lamps.get(id, {})
	return "Lamp('%s', lit=%s)" % [id, str(bool(lamp.get("lit", false))).capitalize()]


static func _type_label(type: String, held: Dictionary) -> String:
	match str(held.get("kind", "")):
		"lamps": return "list[Lamp]"
		"each": return "Lamp"
	return type


## Splits a dotted expression at its top-level dots: 'world.zone("a").lamps' → [world, zone("a"), lamps].
static func _parts(expression: String) -> PackedStringArray:
	var parts := PackedStringArray()
	var depth: int = 0
	var quote: String = ""
	var piece: String = ""
	for character: String in expression:
		if quote != "":
			if character == quote: quote = ""
		elif character in ["'", "\""]: quote = character
		elif character in ["(", "["]: depth += 1
		elif character in [")", "]"]: depth -= 1
		elif character == "." and depth == 0:
			parts.append(piece)
			piece = ""
			continue
		piece += character
	if piece != "": parts.append(piece)
	return parts


static func _name(part: String) -> String:
	var hit: RegExMatch = RegEx.create_from_string("^[A-Za-z_][A-Za-z0-9_]*").search(part)
	return hit.get_string() if hit != null else ""


static func _argument(part: String) -> String:
	var hit: RegExMatch = RegEx.create_from_string("\\(\\s*[\"']([^\"']*)[\"']").search(part)
	return hit.get_string(1) if hit != null else ""


## Applies a written index such as lamps[0] to a resolved list.
static func _subscript(current: Dictionary, part: String) -> Dictionary:
	var hit: RegExMatch = RegEx.create_from_string("\\[\\s*(-?\\d+)\\s*\\]$").search(part)
	if hit == null or str(current.get("kind", "")) != "lamps": return current
	var ids: Array = current.ids
	var index: int = int(hit.get_string(1))
	if index < 0: index += ids.size()
	if index < 0 or index >= ids.size(): return {}
	return {"kind": "lamp", "id": ids[index]}


static func _identifier_char(character: String) -> bool:
	return character == "_" or (character >= "a" and character <= "z") or (character >= "A" and character <= "Z") or (character >= "0" and character <= "9")


static func _in_string(line: String, at: int) -> bool:
	var quote: String = ""
	for index: int in range(mini(at, line.length())):
		var character: String = line[index]
		if quote != "":
			if character == quote: quote = ""
		elif character in ["'", "\""]: quote = character
	return quote != ""


static func _in_comment(line: String, at: int) -> bool:
	var hash: int = _comment_start(line)
	return hash >= 0 and at > hash


static func _comment_start(line: String) -> int:
	var quote: String = ""
	for index: int in range(line.length()):
		var character: String = line[index]
		if quote != "":
			if character == quote: quote = ""
		elif character in ["'", "\""]: quote = character
		elif character == "#": return index
	return -1


static func _without_comment(text: String) -> String:
	var hash: int = _comment_start(text)
	return text.substr(0, hash) if hash >= 0 else text
