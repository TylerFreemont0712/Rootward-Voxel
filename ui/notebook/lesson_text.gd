class_name LessonText
extends RefCounted
## Tiny markup for lesson text: blank-line paragraphs, ``` fenced code blocks, **bold** and `code`.
## Pure string work, so it is easy to test.


## [{type: "p"|"code", text}] in reading order.
static func blocks(source: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var paragraph: PackedStringArray = []
	var code: PackedStringArray = []
	var in_code: bool = false
	for line: String in source.split("\n"):
		if line.strip_edges().begins_with("```"):
			if in_code:
				result.append({"type": "code", "text": "\n".join(code)})
				code = PackedStringArray()
			else:
				_flush(result, paragraph)
				paragraph = PackedStringArray()
			in_code = not in_code
		elif in_code:
			code.append(line)
		elif line.strip_edges() == "":
			_flush(result, paragraph)
			paragraph = PackedStringArray()
		else:
			paragraph.append(line.strip_edges())
	if in_code and not code.is_empty():
		result.append({"type": "code", "text": "\n".join(code)})
	_flush(result, paragraph)
	return result


static func to_bbcode(text: String) -> String:
	var escaped: String = text.replace("[", "[lb]")
	var inline_code := RegEx.new()
	inline_code.compile("`([^`]+)`")
	escaped = inline_code.sub(escaped, "[color=#e8d7a8][code]$1[/code][/color]", true)
	var bold := RegEx.new()
	bold.compile("\\*\\*([^*]+)\\*\\*")
	return bold.sub(escaped, "[b][color=#f4d186]$1[/color][/b]", true)


static func _flush(result: Array[Dictionary], paragraph: PackedStringArray) -> void:
	if not paragraph.is_empty():
		result.append({"type": "p", "text": " ".join(paragraph)})
