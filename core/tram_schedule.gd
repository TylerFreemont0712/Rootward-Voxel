class_name TramSchedule
extends RefCounted
## One timetable for the visible tram and its passenger service. No renderer or wall clock.

static func sample(spec: Dictionary, seconds: float) -> Dictionary:
	var period: float = float(spec.get("period", 90.0))
	var absolute: float = maxf(0.0, seconds + float(spec.get("offset", 0.0)))
	var phase: float = fposmod(absolute, period)
	var travel: float = float(spec.get("travel", 11.0))
	var gone: float = float(spec.get("out", -4.6))
	var stop: float = float(spec.get("stop", 19.45))
	var x: float = gone
	if phase < travel: x = lerpf(gone, stop, ease(phase / travel, 0.4))
	elif phase < travel + 15.0: x = stop
	elif phase < travel * 2.0 + 15.0: x = lerpf(stop, gone, ease((phase - travel - 15.0) / travel, 2.4))
	return {"cycle": floori(absolute / period), "phase": phase, "x": x,
		"docked": phase >= travel and phase < travel + 15.0, "at_stop": phase - travel}
