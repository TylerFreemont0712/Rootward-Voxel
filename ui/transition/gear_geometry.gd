class_name GearGeometry
extends RefCounted
## A common module and pressure angle give the loading train conjugate involute flanks.
const PRESSURE_ANGLE: float = PI / 9.0
const MODULE: float = 8.0
const BACKLASH: float = .05

static func pitch(teeth: int, tooth_module: float = MODULE) -> float:
	return teeth * tooth_module * .5

static func mesh_angle(driver: float, driver_teeth: int, follower_teeth: int, bearing: float) -> float:
	return bearing * float(driver_teeth + follower_teeth) / follower_teeth - driver * float(driver_teeth) / follower_teeth + PI - PI / follower_teeth

static func outline(teeth: int, tooth_module: float = MODULE) -> PackedVector2Array:
	var radius: float = pitch(teeth, tooth_module)
	var base: float = radius * cos(PRESSURE_ANGLE)
	var root: float = radius - 1.25 * tooth_module
	var tip: float = radius + tooth_module
	var pitch_involute: float = tan(PRESSURE_ANGLE) - PRESSURE_ANGLE
	var half: float = PI / (2.0 * teeth) - BACKLASH * tooth_module / (2.0 * radius)
	var points := PackedVector2Array()
	for tooth: int in range(teeth):
		var centre: float = TAU * tooth / teeth
		var root_half: float = half + pitch_involute
		points.append(Vector2.from_angle(centre - root_half) * root)
		for step: int in range(7):
			var r: float = lerpf(maxf(base, root), tip, step / 6.0)
			var flank: float = half + pitch_involute - _involute(r / base)
			points.append(Vector2.from_angle(centre - flank) * r)
		var tip_half: float = half + pitch_involute - _involute(tip / base)
		for step: int in range(1,4):
			points.append(Vector2.from_angle(centre - tip_half + 2.0 * tip_half * step / 3.0) * tip)
		for step: int in range(5,-1,-1):
			var r: float = lerpf(maxf(base, root), tip, step / 6.0)
			var flank: float = half + pitch_involute - _involute(r / base)
			points.append(Vector2.from_angle(centre + flank) * r)
		points.append(Vector2.from_angle(centre + root_half) * root)
		var next: float = centre + TAU / teeth - root_half
		for step: int in range(1,4):
			points.append(Vector2.from_angle(lerpf(centre + root_half, next, step / 4.0)) * root)
	return points

static func _involute(ratio: float) -> float:
	var angle: float = acos(1.0 / maxf(1.0, ratio))
	return tan(angle) - angle
