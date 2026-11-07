class_name ClockworkGears
extends Control
## A seven-wheel train, enamel power conduits and a city-source dial. No world state is mutated.
const Wheel := preload("res://ui/transition/clockwork_wheel.gd")
const TRAIN: Array[Dictionary] = [
	{"teeth":36,"parent":-1,"bearing":0.0,"spokes":6,"copper":false},
	{"teeth":24,"parent":0,"bearing":-.38,"spokes":5,"copper":true},
	{"teeth":18,"parent":1,"bearing":-1.65,"spokes":4,"copper":false},
	{"teeth":28,"parent":0,"bearing":2.7,"spokes":5,"copper":false},
	{"teeth":18,"parent":3,"bearing":3.45,"spokes":4,"copper":true},
	{"teeth":18,"parent":0,"bearing":.99,"spokes":4,"copper":true},
	{"teeth":20,"parent":1,"bearing":.49,"spokes":4,"copper":false},
]
var power: Dictionary = {"strength":.56,"pressure":5.6,"online":true,"stability":1.0,"restored_links":0}
var wheels: Array[Node2D] = []
var centres: Array[Vector2] = []
var angles: Array[float] = []
var _stage: Node2D
var _heading: Label
var _caption: Label
var _clock: float = 0.0
var _master_angle: float = .12
var _display_strength: float = .56
var _pressure: float = 5.6
var _core: PowerCore
var _routes: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(-490,-210),Vector2(-320,-210),Vector2(-320,-110),Vector2(-160,-110),Vector2(-160,0),Vector2.ZERO]),
	PackedVector2Array([Vector2.ZERO,Vector2(0,285),Vector2(335,285),Vector2(335,150),Vector2(490,150)]),
	PackedVector2Array([Vector2.ZERO,Vector2(-120,0),Vector2(-120,250),Vector2(-430,250)]),
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage = Node2D.new()
	add_child(_stage)
	for index: int in range(TRAIN.size()):
		var spec: Dictionary = TRAIN[index]
		var centre := Vector2.ZERO
		if int(spec.parent) >= 0:
			var parent: int = int(spec.parent)
			centre = centres[parent] + Vector2.from_angle(float(spec.bearing)) * (GearGeometry.pitch(int(spec.teeth)) + GearGeometry.pitch(int(TRAIN[parent].teeth)))
		centres.append(centre)
		angles.append(0)
		var wheel: Node2D = Wheel.new()
		wheel.setup(int(spec.teeth),int(spec.spokes),bool(spec.copper))
		wheel.position = centre
		_stage.add_child(wheel)
		wheels.append(wheel)
	_core = PowerCore.new()
	_stage.add_child(_core)
	var meter_label := UI.label("C I T Y   P O W E R",&"LabelCaps",11,Color("d0bd95"))
	meter_label.position = Vector2(-116,399)
	meter_label.size = Vector2(232,16)
	meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage.add_child(meter_label)
	_heading = UI.label("H A V E R L U N D",&"LabelHeading",25,Color("edd5a4"))
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_heading)
	_caption = UI.label("Following the conduits…",&"",18,Color("adbdb4"))
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_caption)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if _stage == null: return
	var factor: float = minf(size.x/1600.0,size.y/1000.0)
	_stage.position = Vector2(size.x*.5,size.y*.42)
	_stage.scale = Vector2.ONE * factor
	_heading.position = Vector2(size.x*.2,size.y*.035)
	_heading.size = Vector2(size.x*.6,42)
	_caption.position = Vector2(size.x*.2,size.y*.94)
	_caption.size = Vector2(size.x*.6,36)

func set_power(snapshot: Dictionary) -> void:
	power = {"pressure":clampf(float(snapshot.get("pressure",5.6)),0,15),"online":bool(snapshot.get("online",true)),"strength":clampf(float(snapshot.get("strength",.56)),0,1),
		"stability":clampf(float(snapshot.get("stability",1.0)),0,1),
		"restored_links":clampi(int(snapshot.get("restored_links",0)),0,3)}

func set_status(text: String) -> void:
	if _caption != null: _caption.text = text

func advance(delta: float) -> void:
	if _stage == null: return
	_clock += delta
	_pressure = lerpf(_pressure,float(power.get("pressure",5.6)),1.0-exp(-delta*5.0))
	_display_strength = lerpf(_display_strength,float(power.strength),1.0-exp(-delta*3.5))
	_master_angle += delta * (.30 + _display_strength*.16)
	for index: int in range(wheels.size()):
		var spec: Dictionary = TRAIN[index]
		var parent: int = int(spec.parent)
		angles[index] = _master_angle if parent < 0 else GearGeometry.mesh_angle(angles[parent],int(TRAIN[parent].teeth),int(spec.teeth),float(spec.bearing))
		wheels[index].rotation = angles[index]
	_core.energy = _display_strength
	_core.stability = float(power.stability)
	_core.clock = _clock
	_core.queue_redraw()
	queue_redraw()

func _draw() -> void:
	if _stage == null: return
	var factor: float = _stage.scale.x
	draw_set_transform(_stage.position,0,Vector2.ONE*factor)
	var stable: float = float(power.stability)
	var flicker: float = lerpf(.45+.55*pow(absf(sin(_clock*2.7)*sin(_clock*5.1)),.2),1.0,stable)
	var live: float = (.12 + _display_strength*.88)*flicker
	var glow := Color("75ddc4")
	glow.a = live
	# An engraved dial, fixing the train to a workshop instrument rather than floating symbols.
	for tick: int in range(120):
		var a: float = TAU*tick/120.0
		if absf(wrapf(a+PI*.5,-PI,PI))<.36:continue
		var r: float = 372.0
		var length: float = 12.0 if tick%5 == 0 else 5.0
		draw_line(Vector2.from_angle(a)*r,Vector2.from_angle(a)*(r+length),Color("62573d"),1.2,true)
	draw_arc(Vector2.ZERO,365,-PI*.5+.36,PI*1.5-.36,240,Color("3f483c"),1.5,true)
	for index: int in range(_routes.size()):
		var path: PackedVector2Array = _routes[index]
		draw_polyline(path,Color("080f12"),12,true)
		draw_polyline(path,Color("866b42"),8,true)
		draw_polyline(path,Color("122a2c"),5,true)
		var restored: float = 1.0 if index < int(power.restored_links) else .65
		draw_polyline(path,Color(glow,glow.a*.5*restored),2.5,true)
		var total: float = 0
		for step: int in range(path.size()-1): total += path[step].distance_to(path[step+1])
		for spark: int in range(3):
			var distance: float = fposmod(_clock*(50.0+30.0*_display_strength)+spark*total/3.0+index*71.0,total)
			for step: int in range(path.size()-1):
				var length: float = path[step].distance_to(path[step+1])
				if distance <= length:
					var point: Vector2 = path[step].lerp(path[step+1],distance/length)
					draw_circle(point,7,Color(glow,live*.10))
					draw_circle(point,2.5,Color(glow,live*.9))
					break
				distance -= length
		var end: Vector2 = path[0] if index == 0 else path[-1]
		draw_circle(end,13,Color("a18452"))
		draw_circle(end,9,Color("153033"))
		draw_circle(end,5,glow)
	# A small source meter below the wheel train: all future city-state changes enter through set_power.
	var meter := Vector2(0,431)
	draw_style_box(PaperBox.make({"kind":&"enamel","fill":Color("203237"),"rim":Color("9c8150"),"rivets":true}),Rect2(meter-Vector2(132,17),Vector2(264,53)))
	var colour := Color("75ddae") if _pressure<8 else (Color("ebc25e") if _pressure<9 else Color("ee7966"))
	if not power.get("online",true):colour=Color("ee7966")
	for bar: int in range(15):
		var lit: bool = float(bar)<_pressure
		var band: Color = Color("75ddae") if bar<8 else (Color("ebc25e") if bar<9 else Color("ee7966"))
		draw_rect(Rect2(meter+Vector2(-111+bar*15,1),Vector2(8,15)),Color(band,.9 if lit else .12))
	var font: Font = ThemeDB.fallback_font
	var value: String = ("%.1f / 15" % _pressure) + (" · OFFLINE" if not power.get("online",true) else "")
	draw_string(font,meter+Vector2(-font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x*.5,29),value,HORIZONTAL_ALIGNMENT_LEFT,-1,11,colour)
	draw_set_transform(Vector2.ZERO)


class PowerCore extends Node2D:
	var energy: float = .65
	var stability: float = 1.0
	var clock: float = 0.0
	func _draw() -> void:
		var live: float = (.15+.85*energy)*lerpf(.4+.6*absf(sin(clock*3.1)*sin(clock*4.7)),1.0,stability)
		for step: int in range(12,0,-1):
			draw_circle(Vector2.ZERO,14+step*.9,Color(.35,.95,.82,live*.018))
		draw_circle(Vector2.ZERO,16,Color("112b2e"))
		draw_circle(Vector2.ZERO,13,Color(.29,.77,.69,live*.75))
		draw_arc(Vector2.ZERO,13,-2.8,-.6,32,Color(.70,1,.87,live),1.2,true)
		var rune := Color(.88,1,.89,live)
		draw_polyline(PackedVector2Array([Vector2(-3,-5),Vector2(-7,0),Vector2(-3,5)]),rune,1.8,true)
		draw_polyline(PackedVector2Array([Vector2(3,-5),Vector2(7,0),Vector2(3,5)]),rune,1.8,true)
