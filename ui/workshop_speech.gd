class_name WorkshopSpeech
extends Control
## Screen-sized lettering anchored to the speaker in the live loft viewport.
## Text and timing come from the room presenter, never from source parsing.
## Speech that has really happened is a solid paper bubble with a tail. A Test is a ghost: a translucent blue bubble
## with a marching dashed outline and thought-dots, its letters fading in as they are typed.

const GHOST_TRAIL: int = 3

var view: ClearingView
var surface: Control
var world_viewport: SubViewport
var right_inset: float = 0.0
var _card: PanelContainer
var _caption: Label
var _lead: Label
var _words: Label
var _ghost_box: GhostBox
var _ghost: bool = false
var _clock: float = 0.0
var _tip := Vector2.ZERO
var _tail := Vector2.ZERO
var _inspection: Dictionary = {}

func inspect(id: String, title: String, words: String) -> void:
	if _inspection.get("id") == id:
		dismiss_inspection()
		return
	var anchor: Vector3 = view.player_node().global_position + Vector3(0, 1.1, 0)
	var object: Node3D = view.building_node(id)
	if object != null:
		var top: float = object.global_position.y
		for mesh: Node in object.find_children("*", "MeshInstance3D", true, false):
			if mesh.name == &"IllustratedOutline": continue
			top = maxf(top, BuildOverlay.world_aabb(mesh as MeshInstance3D).end.y)
		anchor = Vector3(object.global_position.x, top+.12, object.global_position.z)
	_inspection = {"id":id, "title":title, "text":words, "anchor":anchor, "area":view.area.id, "from":view.player_node().global_position}
	var stage := view.stage as WorkshopLoftStage
	if stage != null: stage.clear_speech()

func dismiss_inspection() -> bool:
	if _inspection.is_empty(): return false
	_inspection.clear()
	_card.hide()
	return true


func setup(clearing: ClearingView, world_surface: Control, viewport: SubViewport) -> void:
	view = clearing
	surface = world_surface
	world_viewport = viewport
	name = "WorkshopSpeech"
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = PaperTheme.theme()
	_card = UI.panel(&"PanelCard")
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	_ghost_box = GhostBox.make()
	var body := UI.vbox(4)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(body)
	_caption = UI.label("", &"LabelCaps", 12, PaperPal.TEAL_DEEP)
	body.add_child(_caption)
	# `_lead` lays the words out and shows every typed letter; in a ghost it is faint and `_words`, drawn over it,
	# is solid up to the last few letters, so the newest ones fade in.
	_lead = UI.label("", &"", 20, PaperPal.INK)
	_lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lead.custom_minimum_size.x = 330
	body.add_child(_lead)
	_words = UI.label("", &"", 20, PaperPal.INK)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(_words)
	_words.visible = false
	_lead.add_child(_words)
	_card.hide()


func _process(delta: float) -> void:
	var stage := view.stage as WorkshopLoftStage if is_instance_valid(view) else null
	if not _inspection.is_empty():
		if view.area.id != _inspection.area or view.player_node().global_position.distance_to(_inspection.from) > .4: dismiss_inspection()
	if stage == null or (stage.speech_text == "" and _inspection.is_empty()):
		_card.hide()
		queue_redraw()
		return
	_card.show()
	var object_text: bool = not _inspection.is_empty() and stage.speech_text == ""
	if not object_text: _inspection.clear()
	_set_ghost(stage.speech_preview and not object_text)
	_clock += delta
	var text: String = str(_inspection.text) if object_text else stage.speech_text
	var typed: int = -1 if object_text else stage.speech_characters
	_lead.text = text
	_words.text = text
	if _ghost:
		_ghost_box.phase = _clock
		_card.queue_redraw()
		_lead.visible_characters = typed
		# While typing, the newest letters are only on the faint layer; once it is all typed, all of it is solid.
		var typing: bool = typed >= 0 and typed < text.length()
		_words.visible_characters = maxi(0, typed - GHOST_TRAIL) if typing else -1
	else:
		_lead.visible_characters = typed
		_words.visible_characters = 0
	_caption.text = str(_inspection.title).to_upper() if object_text else ("TEST · GHOST" if _ghost else ("HOTARU" if stage.speech_speaker == "hotaru" else "YOU"))
	var anchor: Vector3 = _inspection.anchor if object_text else (stage.companion_anchor() if stage.speech_speaker == "hotaru" else view.player_node().global_position + Vector3(0, 1.45, 0))
	_tip = view.camera.unproject_position(anchor) * surface.size / Vector2(world_viewport.size)
	_card.reset_size()
	var usable: float = maxf(330.0, size.x - right_inset)
	var lift: float = sin(_clock * 2.0) * 2.5 if _ghost else 0.0
	_card.position = Vector2(clampf(_tip.x + 22, 12, usable - _card.size.x - 12), maxf(14, _tip.y - _card.size.y - 22) + lift)
	_tail = Vector2(clampf(_tip.x, _card.position.x + 15, _card.position.x + _card.size.x - 15), _card.position.y + _card.size.y - 2)
	queue_redraw()


## A ghost swaps the paper frame for the blue one and the ink for deep blue, and back again.
func _set_ghost(on: bool) -> void:
	if on == _ghost and _card.has_theme_stylebox_override("panel") == on: return
	_ghost = on
	if on:
		_card.add_theme_stylebox_override("panel", _ghost_box)
	else:
		_card.remove_theme_stylebox_override("panel")
	_caption.add_theme_color_override("font_color", PaperPal.GHOST_DEEP if on else PaperPal.TEAL_DEEP)
	for label: Label in [_lead, _words]:
		label.add_theme_color_override("font_color", PaperPal.GHOST_INK if on else PaperPal.INK)
	_lead.self_modulate = Color(1, 1, 1, 0.42) if on else Color.WHITE
	_words.visible = on


func _draw() -> void:
	if not is_instance_valid(_card) or not _card.visible: return
	if _ghost:
		# Thought-dots, not a tail: nothing has been said yet.
		for dot: Array in [[0.28, 5.5], [0.55, 4.0], [0.8, 2.8]]:
			var at: Vector2 = _tail.lerp(_tip, float(dot[0]))
			draw_circle(at, float(dot[1]) + 1.5, Color(PaperPal.GHOST, 0.22))
			draw_circle(at, float(dot[1]), Color(PaperPal.GHOST_FILL, 0.8))
			draw_arc(at, float(dot[1]), 0.0, TAU, 16, PaperPal.GHOST, 1.6, true)
		return
	var ink := Color(PaperPal.TEAL_DEEP, .70)
	draw_colored_polygon(PackedVector2Array([_tail + Vector2(-8,0), _tail + Vector2(8,0), _tip]), ink)
	draw_colored_polygon(PackedVector2Array([_tail + Vector2(-5,-1), _tail + Vector2(5,-1), _tip + Vector2(0,-3)]), Color(PaperPal.PAPER_HI, .9))
