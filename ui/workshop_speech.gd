class_name WorkshopSpeech
extends Control
## Screen-sized lettering anchored to the speaker in the live loft viewport.
## Text and timing come from the room presenter, never from source parsing.

var view: ClearingView
var surface: Control
var world_viewport: SubViewport
var right_inset: float = 0.0
var _card: PanelContainer
var _caption: Label
var _words: Label
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
	var body := UI.vbox(4)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(body)
	_caption = UI.label("", &"LabelCaps", 12, PaperPal.TEAL_DEEP)
	body.add_child(_caption)
	_words = UI.label("", &"", 20, PaperPal.INK)
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.custom_minimum_size.x = 330
	body.add_child(_words)
	_card.hide()


func _process(_delta: float) -> void:
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
	_words.text = str(_inspection.text) if object_text else stage.speech_text
	_words.visible_characters = -1 if object_text else stage.speech_characters
	_caption.text = str(_inspection.title).to_upper() if object_text else ("GHOST PRINT · TEST" if stage.speech_preview else ("HOTARU" if stage.speech_speaker == "hotaru" else "YOU"))
	_card.modulate.a = .80 if stage.speech_preview and not object_text else 1.0
	var anchor: Vector3 = _inspection.anchor if object_text else (stage.companion_anchor() if stage.speech_speaker == "hotaru" else view.player_node().global_position + Vector3(0, 1.45, 0))
	_tip = view.camera.unproject_position(anchor) * surface.size / Vector2(world_viewport.size)
	_card.reset_size()
	var usable: float = maxf(330.0, size.x - right_inset)
	_card.position = Vector2(clampf(_tip.x + 22, 12, usable - _card.size.x - 12), maxf(14, _tip.y - _card.size.y - 22))
	_tail = Vector2(clampf(_tip.x, _card.position.x + 15, _card.position.x + _card.size.x - 15), _card.position.y + _card.size.y - 2)
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(_card) or not _card.visible: return
	var ink := Color(PaperPal.TEAL_DEEP, .70)
	draw_colored_polygon(PackedVector2Array([_tail + Vector2(-8,0), _tail + Vector2(8,0), _tip]), ink)
	draw_colored_polygon(PackedVector2Array([_tail + Vector2(-5,-1), _tail + Vector2(5,-1), _tip + Vector2(0,-3)]), Color(PaperPal.PAPER_HI, .9))
