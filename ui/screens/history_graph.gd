class_name HistoryGraph
extends Control
## A clickable commit graph: lanes, nodes, edges to parents, hash, message, branch and tag chips,
## author and age. Rows come from HistoryLanes.layout; the load modal listens for `selected`.

signal selected(id: String)

const ROW: float = 40.0
const LANE: float = 22.0
const LEFT: float = 16.0
const LANE_COLORS: Array[Color] = [Pal.BRASS, Pal.TEAL, Pal.VIOLET, Pal.GREEN, Pal.RED, Pal.BRASS_HI]

## Narrower columns for the tablet's portrait Saves app.
var min_width: float = 640.0
var compact: bool = false
var rows: Array[Dictionary] = []
var tips: Dictionary = {}
var head: Dictionary = {}
var selected_id: String = ""
var _hover: int = -1
var _index: Dictionary = {}
var _lanes: int = 1
var _now: int = int(Time.get_unix_time_from_system())


func setup(graph: Dictionary) -> void:
	rows = HistoryLanes.layout(graph.commits)
	tips = graph.tips
	head = graph.head
	_index.clear()
	for i: int in range(rows.size()):
		_index[rows[i].id] = i
	_lanes = HistoryLanes.width(rows)
	custom_minimum_size = Vector2(min_width, maxf(ROW * rows.size() + 12.0, 80.0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	if selected_id == "" and not rows.is_empty():
		selected_id = str(rows[0].id)
	queue_redraw()


func select(id: String) -> void:
	selected_id = id
	queue_redraw()
	selected.emit(id)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var row: int = _row_at(event.position)
		if row != _hover:
			_hover = row
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var row: int = _row_at(event.position)
		if row >= 0:
			select(str(rows[row].id))
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_hover = -1
		queue_redraw()


func _row_at(at: Vector2) -> int:
	var row: int = int(floor((at.y - 6.0) / ROW))
	return row if row >= 0 and row < rows.size() else -1


func _draw() -> void:
	if rows.is_empty():
		draw_string(UITheme.body_font(), Vector2(LEFT, 30), "No commits yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Pal.PARCH_DIM)
		return
	var mono: Font = UITheme.mono_font()
	var body: Font = UITheme.body_font()
	var text_x: float = LEFT + LANE * _lanes + 18.0
	for i: int in range(rows.size()):
		var y: float = 6.0 + ROW * i
		if str(head.get("id", "")) == str(rows[i].id):
			# Where the player is now: a green edge and a faint wash, whatever is selected.
			draw_rect(Rect2(0, y, size.x, ROW), Color(Pal.GREEN, 0.07))
			draw_rect(Rect2(0, y, 4, ROW), Pal.GREEN)
		if str(rows[i].id) == selected_id:
			draw_rect(Rect2(0, y, size.x, ROW), Color(Pal.BRASS, 0.14))
		elif i == _hover:
			draw_rect(Rect2(0, y, size.x, ROW), Color(1, 1, 1, 0.05))
	# Edges first, so nodes sit on top.
	for i: int in range(rows.size()):
		var row: Dictionary = rows[i]
		var from := _centre(int(row.lane), i)
		for parent: String in row.parents:
			if not _index.has(parent):
				continue
			var j: int = int(_index[parent])
			var to := _centre(int(rows[j].lane), j)
			var tint: Color = _lane_color(int(row.lane) if int(rows[j].lane) == int(row.lane) else int(rows[j].lane))
			if is_equal_approx(from.x, to.x):
				draw_line(from, to, tint, 2.0, true)
			else:
				var bend := Vector2(from.x, to.y - ROW * 0.5)
				draw_line(from, bend, tint, 2.0, true)
				draw_line(bend, to, tint, 2.0, true)
	for i: int in range(rows.size()):
		var row: Dictionary = rows[i]
		var commit: Dictionary = row.commit
		var centre := _centre(int(row.lane), i)
		var tint: Color = _lane_color(int(row.lane))
		var is_head: bool = str(head.get("id", "")) == str(row.id)
		draw_circle(centre, 7.0 if is_head else 5.5, tint)
		draw_circle(centre, 3.0 if is_head else 2.5, Pal.INK)
		if str(row.id) == selected_id:
			draw_arc(centre, 10.0, 0.0, TAU, 32, Pal.PARCHMENT, 1.5, true)
		var y: float = 6.0 + ROW * i
		var x: float = text_x
		draw_string(mono, Vector2(x, y + 17), str(commit.short), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("f5f543"))
		x += 70.0
		x = _chips(x, y + 5.0, str(row.id), body)
		var message: String = str(commit.message).split("\n")[0]
		var room: float = size.x - x - (12.0 if compact else 150.0)
		draw_string(body, Vector2(x, y + 17), _fit(body, message, 15, room), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Pal.PARCHMENT)
		var meta: String = "%s · %s" % [str(commit.author), _age(int(commit.time))]
		draw_string(body, Vector2(text_x + 70.0, y + 33), meta, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Pal.PARCH_DIM)
		if not compact:
			draw_string(body, Vector2(size.x - 148.0, y + 17), Time.get_datetime_string_from_unix_time(int(commit.time), true).replace("T", "  "), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Pal.MUTED)


## Branch and tag chips for a commit; returns the x after them.
func _chips(x: float, y: float, id: String, font: Font) -> float:
	var labels: Array[Array] = []
	if str(head.get("id", "")) == id and str(head.get("branch", "")) == "":
		labels.append(["HEAD", Pal.TEAL])
	var names: Array = tips.keys()
	names.sort()
	for ref: String in names:
		if str(tips[ref]) != id:
			continue
		if ref.begins_with("refs/heads/"):
			var name: String = ref.trim_prefix("refs/heads/")
			labels.append([("HEAD -> " if name == str(head.get("branch", "")) else "") + name, Pal.GREEN])
		elif ref.begins_with("refs/tags/"):
			labels.append(["tag: " + ref.trim_prefix("refs/tags/"), Color("f5f543")])
	for label: Array in labels:
		var width: float = font.get_string_size(label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12.0
		draw_rect(Rect2(x, y, width, 18), Color(label[1], 0.18))
		draw_rect(Rect2(x, y, width, 18), Color(label[1], 0.8), false, 1.0)
		draw_string(font, Vector2(x + 6.0, y + 13), label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, label[1])
		x += width + 6.0
	return x


func _centre(lane: int, row: int) -> Vector2:
	return Vector2(LEFT + LANE * lane + LANE * 0.5, 6.0 + ROW * row + ROW * 0.5)


func _lane_color(lane: int) -> Color:
	return LANE_COLORS[lane % LANE_COLORS.size()]


func _age(time: int) -> String:
	var seconds: int = maxi(0, _now - time)
	if seconds < 60: return "just now"
	if seconds < 3600: return "%d min ago" % (seconds / 60)
	if seconds < 86400: return "%d h ago" % (seconds / 3600)
	if seconds < 86400 * 14: return "%d days ago" % (seconds / 86400)
	return Time.get_date_string_from_unix_time(time)


static func _fit(font: Font, text: String, font_size: int, width: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= width:
		return text
	var out: String = text
	while out.length() > 3 and font.get_string_size(out + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
		out = out.left(out.length() - 1)
	return out + "…"
