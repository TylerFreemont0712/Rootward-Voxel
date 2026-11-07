class_name MessageSign
extends Node3D
## A committed card cycles locally; no timer ever executes player code.
var definition: Dictionary
var label: Label3D
var pages: Array = []
var _clock: float = 0.0
var _index: int = -1

func setup(view: WorldView, spec: Dictionary) -> void:
	definition=spec
	var model: Node3D=view.building_node(str(spec.object))
	if model==null: return
	var anchor: Node3D=model.find_child("SignFace",true,false) as Node3D
	if anchor==null:
		push_error("Tram sign is missing its authored SignFace anchor.")
		return
	label=Label3D.new()
	label.name="LiveMessages"
	label.font=load("res://ui/fonts/ibm-plex-mono-latin-400-normal.woff2") as Font
	label.font_size=100
	label.pixel_size=.00235
	label.outline_size=2
	label.outline_modulate=Color("1b2926")
	label.modulate=Color("ffe5a2")
	label.shaded=false
	label.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anchor.add_child(label)
	label.position.z=.012
	set_card(spec.get("default",["Welcome"]))

func set_card(messages: Array, ghost: bool=false) -> void:
	if messages!=pages:
		pages=messages.duplicate()
		_clock=0
		_index=-1
	if label!=null: label.modulate=PaperPal.GHOST if ghost else Color("ffe5a2")
	_update_text()

func _process(delta: float) -> void:
	_clock+=delta
	_update_text()

func _update_text() -> void:
	if label==null or pages.is_empty(): return
	var next: int=int(_clock/4.0)%pages.size()
	if next==_index: return
	_index=next
	label.text=DisplayCards.rows(str(pages[_index]))
