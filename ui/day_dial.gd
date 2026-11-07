class_name DayDial
extends Control
## Quiet shared clock: one full orbit per day, with named phases for the first lesson.
var session: GameSession
var _label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(244,50)
	_label = UI.label("",&"LabelHeading",17,PaperPal.INK)
	_label.position = Vector2(61,7)
	_label.size = Vector2(175,38)
	add_child(_label)

func _process(_delta: float) -> void:
	if session==null:return
	var time: Dictionary = CityCycle.time(session.cycle)
	var minute: int = floori(float(session.cycle.minute))
	_label.text = "%s · %02d:%02d" % [time.phase,minute/60,minute%60]
	tooltip_text = "Day %d · Time rests while you read, code or talk." % time.day
	queue_redraw()

func _draw() -> void:
	draw_style_box(PaperBox.make({"kind":&"enamel","fill":Color("f4ebd5"),"rim":Color("528b86")}),Rect2(Vector2.ZERO,size))
	var centre := Vector2(30,25)
	draw_circle(centre,18,Color("243f51"))
	draw_arc(centre,16,-PI,0,36,Color("e6b65f"),6,true)
	for index: int in range(8):
		var angle: float = TAU*index/8.0
		draw_line(centre+Vector2.from_angle(angle)*20,centre+Vector2.from_angle(angle)*22,Color("aa8a53"),1,true)
	var hour: float = CityCycle.time(session.cycle).hour if session!=null else 9.0
	var angle: float = (hour-6)/24.0*TAU+PI
	var point: Vector2 = centre+Vector2.from_angle(angle)*14
	draw_line(centre,point,Color("e7d29b"),1.5,true)
	draw_circle(point,4,Color("ffe2a0") if hour>=6 and hour<18 else Color("d0e8f3"))
	draw_circle(centre,2,Color("aa8a53"))
