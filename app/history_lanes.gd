class_name HistoryLanes
extends RefCounted
## Lays commits out in lanes for a graph (the terminal's `git log --graph` and the load modal).
## Pure over Vcs.log_all(): rows newest first, each {id, lane, parents, active: lanes open below
## this row (ids), from: lanes open above}. Lane 0 is the leftmost.


static func layout(commits: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var active: Array[String] = []  # column -> the commit id each open lane is waiting for
	for commit: Dictionary in commits:
		var id: String = str(commit.id)
		var lane: int = active.find(id)
		if lane == -1:
			lane = active.size()
			active.append(id)
		var from: Array[String] = active.duplicate()
		# Other lanes also waiting for this commit merge into it.
		var merged: Array[int] = []
		for column: int in range(active.size() - 1, lane, -1):
			if active[column] == id:
				merged.append(column)
				active.remove_at(column)
		var parents: Array[String] = []
		for parent: Variant in commit.get("parents", []):
			parents.append(str(parent))
		if parents.is_empty():
			active.remove_at(lane)
		else:
			active[lane] = parents[0]
			for parent: String in parents.slice(1):
				if not active.has(parent):
					active.append(parent)
		rows.append({"id": id, "lane": lane, "parents": parents, "from": from, "active": active.duplicate(), "merged": merged, "commit": commit})
	return rows


## How many lanes the graph needs.
static func width(rows: Array[Dictionary]) -> int:
	var most: int = 1
	for row: Dictionary in rows:
		most = maxi(most, maxi((row.from as Array).size(), (row.active as Array).size()))
		most = maxi(most, int(row.lane) + 1)
	return most


## The text graph for each row, as `git log --graph` draws it: {pre, line}. `line` has `*` on the
## commit's lane and `|` for lanes continuing below it; `pre` (often "") is the connector drawn above
## the row when other lanes merge into this commit, e.g. "|/".
static func text_rows(rows: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Dictionary in rows:
		var lane: int = int(row.lane)
		var from: Array = row.from
		var active: Array = row.active
		var merged: Array = row.merged
		var pre: String = ""
		if not merged.is_empty():
			for column: int in range(from.size()):
				pre = (pre.rstrip(" ") + "/ ") if merged.has(column) else (pre + "| ")
		var line: String = ""
		for column: int in range(maxi(active.size(), lane + 1)):
			if column == lane:
				line += "* "
			elif column < active.size():
				line += "| "
			else:
				line += "  "
		out.append({"pre": pre.rstrip(" "), "line": line.rstrip(" ")})
	return out
