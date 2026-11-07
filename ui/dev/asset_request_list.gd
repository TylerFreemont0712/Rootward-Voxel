class_name AssetRequestList
extends ItemList
## Keep request symbols in a reserved right-hand gutter, even for long or selected names.

const DELETE_TINT:=Color(.65,.17,.15,.24)
const UPDATE_TINT:=Color(.78,.60,.12,.22)
var _marks: Dictionary={}
var _overlay: Control

func _init()->void:
	text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_overlay=Control.new()
	_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_overlay.z_index=5
	_overlay.clip_contents=true
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_overlay.draw.connect(_draw_marks)
	resized.connect(_layout_gutter)
	get_v_scroll_bar().value_changed.connect(func(_value: float)->void:_overlay.queue_redraw())

func set_request_mark(index: int,kind: String)->void:
	if kind.is_empty():_marks.erase(index)
	else:_marks[index]=kind
	set_item_custom_bg_color(index,DELETE_TINT if kind=="delete" else UPDATE_TINT if kind=="update" else Color.TRANSPARENT)
	_overlay.queue_redraw()

func request_mark(index: int)->String:
	return str(_marks.get(index,""))

func clear_marks()->void:
	_marks.clear()
	_overlay.queue_redraw()

func _process(_delta: float)->void:
	# ItemList finishes its native row layout after setup/filter changes. Redraw the tiny
	# overlay against those final rectangles, including selection and scroll changes.
	if not _marks.is_empty():_overlay.queue_redraw()

func _layout_gutter()->void:
	fixed_column_width=maxi(40,int(size.x)-42)
	_overlay.queue_redraw()

func marker_rect(index: int)->Rect2:
	var row:=get_item_rect(index,true)
	row.position.y-=get_v_scroll_bar().value
	var right: float=size.x-get_theme_stylebox("panel").get_content_margin(SIDE_RIGHT)-get_v_scroll_bar().size.x-4
	return Rect2(Vector2(right-18,row.position.y+(row.size.y-14)*.5),Vector2(14,14))

func _draw_marks()->void:
	var panel:=get_theme_stylebox("panel")
	var top:=panel.get_content_margin(SIDE_TOP)
	var bottom:=size.y-panel.get_content_margin(SIDE_BOTTOM)
	for index: int in _marks:
		if index>=item_count:continue
		var rect:=marker_rect(index)
		if rect.position.y<top or rect.end.y>bottom:continue
		var colour:=Color("f19a90") if _marks[index]=="delete" else Color("edce64")
		if is_selected(index):
			var row:=get_item_rect(index,true)
			row.position.y-=get_v_scroll_bar().value
			_overlay.draw_rect(row,DELETE_TINT if _marks[index]=="delete" else UPDATE_TINT)
		var gutter:=Rect2(Vector2(rect.position.x-3,rect.position.y-3),Vector2(20,20))
		_overlay.draw_style_box(_badge_style(),gutter)
		if _marks[index]=="delete":
			_overlay.draw_line(rect.position+Vector2(3,3),rect.end-Vector2(3,3),colour,2,true)
			_overlay.draw_line(Vector2(rect.end.x-3,rect.position.y+3),Vector2(rect.position.x+3,rect.end.y-3),colour,2,true)
		else:_overlay.draw_rect(rect.grow(-3),colour,false,2,true)

func _badge_style()->StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color(.12,.10,.08,.95)
	box.set_corner_radius_all(3)
	return box
