class_name LessonOverlay
extends Control
## A brass ring, breathing, around whatever a lesson points at. Lies over the slate and ignores the
## mouse, so the thing it rings can still be used.

var target: Control
var _pulse: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target) and target.is_visible_in_tree():
		_pulse += delta
		queue_redraw()
	elif target != null:
		queue_redraw()


func _draw() -> void:
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return
	var rect: Rect2 = get_global_transform().affine_inverse() * target.get_global_rect()
	rect = rect.grow(8.0)
	var glow := StyleBoxFlat.new()
	glow.draw_center = false
	glow.border_color = Color(Pal.BRASS_HI, 0.25 + 0.2 * sin(_pulse * 3.0))
	glow.set_border_width_all(7)
	glow.set_corner_radius_all(16)
	draw_style_box(glow, rect.grow(4.0))
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = Pal.BRASS
	ring.set_border_width_all(3)
	ring.set_corner_radius_all(12)
	draw_style_box(ring, rect)
