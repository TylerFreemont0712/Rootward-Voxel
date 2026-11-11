class_name LessonTestWindow
extends PanelContainer
## A foreground lesson demonstration, placed over the lower free world area.
## Its extent never changes the game camera or the notebook's reserved space.
var body: VBoxContainer
var _target_size: Vector2=Vector2.ZERO

func _init() -> void:
	theme_type_variation=&"PanelTest"
	mouse_filter=Control.MOUSE_FILTER_STOP
	body=UI.vbox(6)
	add_child(body)
	minimum_size_changed.connect(_finish_fit)

func place_beside(drawer_left: float) -> void:
	var available: Vector2=get_viewport_rect().size
	var width: float=minf(clampf(drawer_left*.36,400.0,600.0),maxf(260.0,drawer_left-64.0))
	var height: float=clampf(available.y*.34,310.0,420.0)
	_target_size=Vector2(width,height)
	size=_target_size
	position=Vector2(maxf(16.0,drawer_left-width-40.0),maxf(16.0,available.y-height-32.0))
	_finish_fit.call_deferred()

func _finish_fit() -> void:
	# Wrapped text initially measures before the foreground window has a width.
	# Reapply its desired size after that minimum settles, rather than keeping
	# the transient tall minimum and magnifying the viewport off screen.
	if is_inside_tree() and _target_size!=Vector2.ZERO and size!=_target_size:size=_target_size
