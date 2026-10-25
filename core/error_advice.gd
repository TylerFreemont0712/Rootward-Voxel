class_name ErrorAdvice
extends RefCounted
## Turns a Python traceback into something a learner can act on. Pure text work: it never runs code.
## The raw error is always kept beside the advice, so the player still learns to read real tracebacks.


## Pulls the player's own frame out of a traceback. {kind, message, line}; line is 0 when the error was
## not in player.py (for example a missing program function).
static func parse(stderr: String) -> Dictionary:
	var line_number: int = 0
	var kind: String = ""
	var message: String = ""
	var lines: PackedStringArray = stderr.strip_edges().split("\n")
	var frame := RegEx.new()
	frame.compile("File \"(?:/work/)?player\\.py\", line (\\d+)")
	for text: String in lines:
		var hit: RegExMatch = frame.search(text)
		if hit != null:
			line_number = int(hit.get_string(1))
	for index: int in range(lines.size() - 1, -1, -1):
		var text: String = lines[index].strip_edges()
		if text == "" or text.begins_with("^") or text.begins_with("File ") or text.begins_with("~"):
			continue
		var split: int = text.find(": ")
		if split > 0 and text.substr(0, split).replace(".", "").replace("_", "").is_valid_identifier():
			kind = text.substr(0, split)
			message = text.substr(split + 2)
		else:
			kind = text
		break
	return {"kind": kind, "message": message, "line": line_number}


## {title, body}: plain-language help. `known` lists names the learner could have meant.
static func explain(error: Dictionary, known: Array[String]) -> Dictionary:
	var kind: String = str(error.get("kind", ""))
	var message: String = str(error.get("message", ""))
	var line: int = int(error.get("line", 0))
	var where: String = "Line %d: " % line if line > 0 else ""
	match kind:
		"IndentationError":
			return {"title": where + "The indentation is off", "body": _indentation(message)}
		"SyntaxError", "TabError":
			return {"title": where + "Python could not read this line", "body": _syntax(message)}
		"NameError":
			var name: String = _quoted(message)
			var body: String = "Python does not know the name '%s'. Spelling and capital letters must match exactly, and a name made with = has to appear before the line that uses it." % name
			var guess: String = closest(name, known)
			if guess != "":
				body += " Did you mean '%s'?" % guess
			return {"title": where + "Unknown name '%s'" % name, "body": body}
		"AttributeError":
			var attribute: String = _last_quoted(message)
			var body: String = "That object has no '%s'. Check the Reference tab for what it offers." % attribute
			var guess: String = closest(attribute, known)
			if guess != "":
				body += " Did you mean '%s'?" % guess
			return {"title": where + "No such feature: '%s'" % attribute, "body": body}
		"TypeError":
			var body: String = "A value or a call has the wrong shape. Read the message: it says what was expected."
			if message.contains("positional argument"):
				body = "A call has too many or too few values between its brackets. Look at the example in the Reference tab."
			elif message.contains("not subscriptable") or message.contains("not iterable"):
				body = "You tried to loop over or index something that is not a list. Loop over lists such as zone.lamps."
			return {"title": where + "Wrong kind of value", "body": body}
		"IndexError":
			return {"title": where + "That item is not in the list", "body": "Lists count from 0, and the last item is one less than the length. Asking for an item past the end fails."}
		"KeyError":
			return {"title": where + "That key is missing", "body": "A dictionary does not have the key %s. Print the dictionary to see what it holds." % message}
		"WorldError":
			return {"title": where + "The notebook could not find that", "body": message}
		"ZeroDivisionError":
			return {"title": where + "Divided by zero", "body": "Some number on the right of / or % was zero."}
		"ValueError":
			return {"title": where + "Value not allowed", "body": message}
	if kind == "":
		return {"title": "The program stopped", "body": message}
	return {"title": where + kind, "body": message if message != "" else "Read the error text above: its last line names the mistake."}


## The nearest candidate by edit distance, or "" if nothing is close.
static func closest(word: String, candidates: Array[String]) -> String:
	var best: String = ""
	var best_distance: int = 1000
	var limit: int = maxi(1, word.length() / 3 + 1)
	for candidate: String in candidates:
		if candidate == word:
			continue
		var distance: int = _distance(word.to_lower(), candidate.to_lower())
		if distance < best_distance and distance <= limit:
			best_distance = distance
			best = candidate
	return best


static func _distance(a: String, b: String) -> int:
	var previous: Array[int] = []
	for j: int in range(b.length() + 1):
		previous.append(j)
	for i: int in range(1, a.length() + 1):
		var row: Array[int] = [i]
		for j: int in range(1, b.length() + 1):
			var cost: int = 0 if a[i - 1] == b[j - 1] else 1
			row.append(mini(mini(previous[j] + 1, row[j - 1] + 1), previous[j - 1] + cost))
		previous = row
	return previous[b.length()]


static func _indentation(message: String) -> String:
	if message.contains("expected an indented block"):
		return "A line that ends with ':' starts a block. The lines inside it must be indented by 4 spaces."
	if message.contains("unexpected indent"):
		return "This line is pushed in further than the line above it, and nothing opened a block. Line up with the line above."
	if message.contains("unindent"):
		return "Lines in the same block must start at exactly the same column. Check the spaces on this and the lines above."
	return "Python groups lines by indentation. Keep lines in one block at the same column, with 4 spaces for each level."


static func _syntax(message: String) -> String:
	if message.contains("expected ':'"):
		return "A line that starts a block (def, for, if, else) must end with a colon ':'."
	if message.contains("never closed"):
		return "A bracket or parenthesis was opened but never closed. Count the pairs: ( ) [ ] { }."
	if message.contains("unterminated string") or message.contains("EOL"):
		return "A quote was opened but not closed on the same line."
	if message.contains("invalid syntax"):
		return "Check this line and the one above it for a missing colon, comma, bracket or an extra word. Python often notices one line late."
	if message.contains("Missing parentheses") or message.contains("unmatched"):
		return "A bracket is missing or extra. Count the pairs: ( ) [ ] { }."
	return message if message != "" else "Check this line for a missing colon, bracket or quote."


static func _quoted(message: String) -> String:
	var start: int = message.find("'")
	var end: int = message.find("'", start + 1)
	return message.substr(start + 1, end - start - 1) if start >= 0 and end > start else ""


static func _last_quoted(message: String) -> String:
	var end: int = message.rfind("'")
	var start: int = message.rfind("'", end - 1)
	return message.substr(start + 1, end - start - 1) if start >= 0 and end > start else ""
