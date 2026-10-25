class_name WorldPrompts
extends Control
## What F would do, shown in the world rather than as a button: a speech bubble over the resident you would talk to
## and a hand over the thing you would use, each with a small F key. Residents with something to say wear a mark
## over their heads: "!" (something new) or "?" (they can help with the current lesson; see VillageDialogue.marker).
## Presentation only. The game decides the target and the marks; clicking the bubble does what F does.

signal pressed

const BOB_SPEED: float = 2.6
const BUBBLE_SIZE := Vector2(46, 34)
const BADGE_RADIUS: float = 15.0
## How far above a resident's head, or the top of a thing, a mark floats.
const LIFT: float = 14.0

var view: ClearingView
var surface: Control
var world_viewport: SubViewport
## {kind: "talk" | "prop" | "", id, mark}: what F would act on, and for talk the mark to show in the bubble.
var target: Dictionary = {}
## {resident id: "!" | "?"} for residents with something to say.
var markers: Dictionary = {}
var _elapsed: float = 0.0
var _heads: Dictionary = {}
## Where things are drawn this frame (worked out in _process, drawn in _draw): the marks as [centre, mark], the
## prompt's anchor tip, and the clickable rectangle of the bubble or hand.
var _marks: Array = []
var _tip: Variant = null
var _bubble_rect := Rect2()


func setup(clearing: ClearingView, world_surface: Control, viewport: SubViewport) -> void:
	view = clearing
	surface = world_surface
	world_viewport = viewport
	name = "WorldPrompts"
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_target(kind: String, id: String = "", mark: String = "", tip: String = "") -> void:
	target = {} if kind == "" else {"kind": kind, "id": id, "mark": mark}
	tooltip_text = tip


func set_markers(marks: Dictionary) -> void:
	markers = marks.duplicate()


## Only the bubble or hand takes clicks; everywhere else the pointer falls through to the world.
func _has_point(point: Vector2) -> bool:
	return not target.is_empty() and _bubble_rect.grow(4.0).has_point(point)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit()


func _process(delta: float) -> void:
	_elapsed += delta
	_layout()
	queue_redraw()


func _layout() -> void:
	_marks.clear()
	_tip = null
	_bubble_rect = Rect2()
	if view == null or view.camera == null:
		return
	var bob: float = sin(_elapsed * BOB_SPEED) * 2.5
	var talking_to: String = str(target.get("id", "")) if target.get("kind") == "talk" else ""
	for id: String in markers:
		if id == talking_to:
			continue
		var head: Variant = _head(id)
		if head is Vector2 and get_rect().grow(40.0).has_point(head):
			_marks.append([(head as Vector2) + Vector2(0, -LIFT - BADGE_RADIUS + bob), str(markers[id])])
	if target.is_empty():
		return
	var anchor: Variant = _head(talking_to) if talking_to != "" else _top_of_prop(str(target.get("id", "")))
	if not anchor is Vector2:
		return
	_tip = (anchor as Vector2) + Vector2(0, -LIFT * 0.6 + bob)
	if talking_to != "":
		_bubble_rect = Rect2((_tip as Vector2) - Vector2(BUBBLE_SIZE.x * 0.5, BUBBLE_SIZE.y + 9.0), BUBBLE_SIZE)
	else:
		_bubble_rect = Rect2((_tip as Vector2) + Vector2(-19, -38), Vector2(38, 38))


## A world point as a point on this control (the world is drawn in a viewport stretched over the same rectangle).
func _to_screen(world: Vector3) -> Vector2:
	return view.camera.unproject_position(world) * surface.size / Vector2(world_viewport.size)


## The top of a resident's head on screen, smoothed so changing animation frames do not make the mark jitter.
func _head(id: String) -> Variant:
	if view == null or view.villagers == null or not view.villagers.actors.has(id):
		return null
	var actor: SpriteAdventurer = view.villagers.actors[id]
	var top: float = actor.global_position.y + 1.5
	if actor.sprite != null and actor.sprite.sprite_frames != null:
		top = (actor.sprite.global_transform * actor.sprite.get_aabb()).end.y
	var smoothed: float = lerpf(float(_heads.get(id, top)), top, 0.2)
	_heads[id] = smoothed
	return _to_screen(Vector3(actor.global_position.x, smoothed, actor.global_position.z))


## The top of a placed thing on screen, or null if it is not drawn.
func _top_of_prop(id: String) -> Variant:
	var node: Node3D = view.building_node(id) if view != null else null
	if node == null:
		return null
	var box: AABB = BuildOverlay.world_aabb(node)
	return _to_screen(Vector3(box.get_center().x, box.end.y, box.get_center().z))


func _draw() -> void:
	for mark: Array in _marks:
		_badge(mark[0], mark[1])
	if _tip == null:
		return
	if target.get("kind") == "talk":
		_speech_bubble(_tip, str(target.get("mark", "")))
	else:
		_use_badge(_tip)


## A round mark: gold with "!" for something new, teal with "?" for help with the current lesson.
func _badge(centre: Vector2, mark: String) -> void:
	var fill: Color = Pal.TEAL if mark == "?" else Pal.BRASS_HI
	draw_circle(centre + Vector2(0, 2), BADGE_RADIUS + 1.0, Color(0, 0, 0, 0.35))
	draw_circle(centre, BADGE_RADIUS + 1.5, Pal.INK)
	draw_circle(centre, BADGE_RADIUS, fill)
	draw_arc(centre, BADGE_RADIUS - 2.5, PI * 1.1, PI * 1.6, 8, Color(1, 1, 1, 0.45), 2.0, true)
	_centred_text(centre, mark, 22, Pal.INK)


## A parchment speech bubble whose tail points at the head below `tip`, with "…" (or the resident's mark) inside
## and an F key on its corner.
func _speech_bubble(tip: Vector2, mark: String) -> void:
	var body: Rect2 = _bubble_rect
	var shadow := Vector2(0, 3)
	for pass_index: int in range(2):
		var grow: float = 2.0 if pass_index == 0 else 0.0
		var colour: Color = Pal.INK if pass_index == 0 else Pal.PARCHMENT
		var offset: Vector2 = Vector2.ZERO
		if pass_index == 0:
			_rounded(body.grow(grow + 0.5), 11.0, Color(0, 0, 0, 0.35), shadow)
		_rounded(body.grow(grow), 11.0 + grow, colour, offset)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(0, -1.0 + grow), body.position + Vector2(body.size.x * 0.5 - 7.0 - grow, body.size.y - 1.0), body.position + Vector2(body.size.x * 0.5 + 7.0 + grow, body.size.y - 1.0)]), colour)
	var middle: Vector2 = body.get_center()
	if mark == "":
		for dot: int in range(3):
			draw_circle(middle + Vector2(-10.0 + 10.0 * float(dot), 1.0 + sin(_elapsed * 5.0 + float(dot) * 0.9) * 1.5), 3.2, Pal.INK)
	else:
		_centred_text(middle + Vector2(0, 1), mark, 22, Pal.TEAL.darkened(0.45) if mark == "?" else Pal.BRASS_LO)
	_key(body.position + Vector2(body.size.x - 2.0, 1.0))


## A dark round badge with a hand: F would use the thing below it.
func _use_badge(tip: Vector2) -> void:
	var centre: Vector2 = tip + Vector2(0, -19.0)
	draw_circle(centre + Vector2(0, 3), 18.0, Color(0, 0, 0, 0.35))
	draw_circle(centre, 18.5, Pal.BRASS)
	draw_circle(centre, 16.5, Pal.PANEL)
	Glyph.paint(self, &"hand", Rect2(centre - Vector2(11, 11), Vector2(22, 22)), Pal.PARCHMENT)
	_key(centre + Vector2(15, -14))


## The F key, a small brass cap on the corner of a prompt.
func _key(centre: Vector2) -> void:
	draw_circle(centre, 10.5, Pal.INK)
	draw_circle(centre, 9.0, Pal.BRASS_HI)
	_centred_text(centre + Vector2(0, 0.5), "F", 13, Pal.INK)


func _rounded(rect: Rect2, radius: float, colour: Color, offset: Vector2) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(int(radius))
	box.anti_aliasing = true
	draw_style_box(box, Rect2(rect.position + offset, rect.size))


func _centred_text(centre: Vector2, text: String, font_size: int, colour: Color) -> void:
	var font: Font = get_theme_default_font()
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, centre + Vector2(-size.x * 0.5, font.get_ascent(font_size) * 0.5 - font.get_descent(font_size) * 0.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
