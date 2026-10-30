class_name SideDrawer
extends PanelContainer
## Shared notebook dock: no scrim, responsive width, a stitched spine and a short slide.
signal extent_changed(pixels: float)
const MARGIN: float = 16.0
var drawer_open: bool = false
var drawer_width: float = 600.0
var _slide: Tween

func _init() -> void:
	theme_type_variation = &"PanelDrawer"
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	get_viewport().size_changed.connect(fit_drawer)

func fit_drawer() -> void:
	drawer_width = clampf(get_viewport_rect().size.x * .38, 520.0, 620.0)
	set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	offset_top = MARGIN
	offset_bottom = -MARGIN
	if _slide != null:_slide.kill()
	_dock(drawer_open)
	if drawer_open:extent_changed.emit(drawer_width + MARGIN)

func _dock(opened: bool) -> void:
	offset_left = -drawer_width-MARGIN if opened else MARGIN
	offset_right = -MARGIN if opened else drawer_width+MARGIN

func show_drawer(opened: bool, instant: bool = false) -> void:
	drawer_open = opened
	if _slide != null:_slide.kill()
	if opened:
		if not visible:_dock(false)
		visible = true
	if instant or not is_inside_tree():
		_dock(opened)
		visible = opened
	else:
		_slide = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_slide.tween_property(self,"offset_left",-drawer_width-MARGIN if opened else MARGIN,.24)
		_slide.tween_property(self,"offset_right",-MARGIN if opened else drawer_width+MARGIN,.24)
		if not opened:_slide.chain().tween_callback(func() -> void:visible=false)
	extent_changed.emit(drawer_width+MARGIN if opened else 0.0)

func _draw() -> void:
	# A book's sewn binding rather than a floating dialogue plaque.
	draw_line(Vector2(7,26),Vector2(7,size.y-26),Color(Pal.BRASS,.55),2)
	for y: int in range(38,int(size.y)-24,18):
		draw_line(Vector2(4,y),Vector2(10,y+4),Color(Pal.PARCH_DIM,.55),1,true)
