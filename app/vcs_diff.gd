class_name VcsDiff
extends RefCounted
## Unified line diffs for the in-game version-control system (docs/concept/save-vcs/PLAN.md).
## Output copies `git diff` wording and shape so what the player reads matches the real tool.


## A unified diff between two texts, or "" when they are equal. Labels are repo-relative paths.
static func unified(a_text: String, b_text: String, a_label: String, b_label: String, context: int = 3) -> String:
	if a_text == b_text:
		return ""
	var a: PackedStringArray = _lines(a_text)
	var b: PackedStringArray = _lines(b_text)
	var ops: Array[Dictionary] = _opcodes(a, b)
	var header: String = "diff --rvc a/%s b/%s\n" % [a_label, b_label]
	header += "--- %s\n" % ("a/" + a_label if a_text != "" else "/dev/null")
	header += "+++ %s\n" % ("b/" + b_label if b_text != "" else "/dev/null")
	return header + _hunks(a, b, ops, context)


static func _lines(text: String) -> PackedStringArray:
	if text == "":
		return PackedStringArray()
	var lines: PackedStringArray = text.split("\n")
	if lines[-1] == "":
		lines.remove_at(lines.size() - 1)
	return lines


## Longest-common-subsequence opcodes: {op: "equal"|"delete"|"insert", a_start, a_end, b_start, b_end}.
static func _opcodes(a: PackedStringArray, b: PackedStringArray) -> Array[Dictionary]:
	var n: int = a.size()
	var m: int = b.size()
	# LCS lengths, rows of (m+1). Save files are small; the quadratic table is fine.
	var table := PackedInt32Array()
	table.resize((n + 1) * (m + 1))
	for i: int in range(n - 1, -1, -1):
		for j: int in range(m - 1, -1, -1):
			var at: int = i * (m + 1) + j
			if a[i] == b[j]:
				table[at] = table[at + m + 2] + 1
			else:
				table[at] = maxi(table[at + m + 1], table[at + 1])
	var ops: Array[Dictionary] = []
	var i2: int = 0
	var j2: int = 0
	while i2 < n and j2 < m:
		if a[i2] == b[j2]:
			_extend(ops, "equal", i2, j2)
			i2 += 1
			j2 += 1
		elif table[(i2 + 1) * (m + 1) + j2] >= table[i2 * (m + 1) + j2 + 1]:
			_extend(ops, "delete", i2, j2)
			i2 += 1
		else:
			_extend(ops, "insert", i2, j2)
			j2 += 1
	while i2 < n:
		_extend(ops, "delete", i2, j2)
		i2 += 1
	while j2 < m:
		_extend(ops, "insert", i2, j2)
		j2 += 1
	return ops


static func _extend(ops: Array[Dictionary], op: String, i: int, j: int) -> void:
	if not ops.is_empty() and ops[-1].op == op and ops[-1].a_end == i and ops[-1].b_end == j:
		ops[-1].a_end = i + 1 if op != "insert" else i
		ops[-1].b_end = j + 1 if op != "delete" else j
		if op == "equal":
			ops[-1].a_end = i + 1
			ops[-1].b_end = j + 1
		return
	var a_end: int = i + 1 if op != "insert" else i
	var b_end: int = j + 1 if op != "delete" else j
	if op == "equal":
		a_end = i + 1
		b_end = j + 1
	ops.append({"op": op, "a_start": i, "a_end": a_end, "b_start": j, "b_end": b_end})


static func _hunks(a: PackedStringArray, b: PackedStringArray, ops: Array[Dictionary], context: int) -> String:
	# Group changed opcodes into hunks with up to `context` equal lines around them.
	var out: String = ""
	var index: int = 0
	while index < ops.size():
		if ops[index].op == "equal":
			index += 1
			continue
		var first: int = index
		var last: int = index
		var scan: int = index + 1
		while scan < ops.size():
			if ops[scan].op != "equal":
				last = scan
				scan += 1
			elif int(ops[scan].a_end) - int(ops[scan].a_start) <= context * 2 and scan + 1 < ops.size():
				scan += 1
			else:
				break
		var a_from: int = int(ops[first].a_start)
		var b_from: int = int(ops[first].b_start)
		var lead: int = mini(context, a_from)
		a_from -= lead
		b_from -= lead
		var a_to: int = int(ops[last].a_end)
		var b_to: int = int(ops[last].b_end)
		var tail: int = mini(context, a.size() - a_to)
		a_to += tail
		b_to += tail
		out += "@@ -%s +%s @@\n" % [_range(a_from, a_to), _range(b_from, b_to)]
		var ai: int = a_from
		var bi: int = b_from
		for k: int in range(first, last + 1):
			var op: Dictionary = ops[k]
			while ai < int(op.a_start):
				out += " " + a[ai] + "\n"
				ai += 1
				bi += 1
			match str(op.op):
				"equal":
					while ai < int(op.a_end):
						out += " " + a[ai] + "\n"
						ai += 1
						bi += 1
				"delete":
					while ai < int(op.a_end):
						out += "-" + a[ai] + "\n"
						ai += 1
				"insert":
					while bi < int(op.b_end):
						out += "+" + b[bi] + "\n"
						bi += 1
		while ai < a_to:
			out += " " + a[ai] + "\n"
			ai += 1
			bi += 1
		index = last + 1
	return out


static func _range(from: int, to: int) -> String:
	var count: int = to - from
	if count == 1:
		return str(from + 1)
	return "%d,%d" % [from + 1 if count > 0 else from, count]
