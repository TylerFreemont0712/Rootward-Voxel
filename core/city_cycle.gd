class_name CityCycle
extends RefCounted
## Journey-wide time and supply. Pure data; never part of program Undo or room-local memory.
const MINUTES_PER_SECOND: float = 1.0 # A complete day takes 24 minutes of exploration.
const PHASES: Array[String] = ["Night", "Morning", "Day", "Evening"]

static func fresh() -> Dictionary:
	return {"day":1,"minute":554.0,"pressure":5.6,"tripped":false,"evening_started":false}

static func restore(raw: Variant) -> Dictionary:
	var result: Dictionary = fresh()
	if not raw is Dictionary: return result
	for key: String in ["minute","pressure"]:
		if raw.get(key) is float or raw.get(key) is int:
			if is_finite(float(raw[key])): result[key] = clampf(float(raw[key]),0,1439.999 if key=="minute" else 15.0)
	if AreaDef._whole(raw.get("day")): result.day = clampi(int(raw.day),1,99999)
	for key: String in ["tripped","evening_started"]:
		if raw.get(key) is bool: result[key] = raw[key]
	if result.pressure >= 15: result.tripped = true
	return result

static func advance(cycle: Dictionary, seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0: return
	var minutes: float = float(cycle.minute) + seconds * MINUTES_PER_SECOND
	cycle.day = int(cycle.day) + floori(minutes/1440.0)
	cycle.minute = fposmod(minutes,1440.0)

static func at_hour(cycle: Dictionary, hour: float) -> void:
	if not is_finite(hour): return
	cycle.minute = fposmod(hour*60,1440.0)

static func time(cycle: Dictionary) -> Dictionary:
	var hour: float = float(cycle.minute)/60.0
	var phase: String = "Night" if hour < 6 or hour >= 21 else ("Morning" if hour < 11 else ("Day" if hour < 18 else "Evening"))
	return {"day":int(cycle.day),"hour":hour,"phase":phase,"is_dark":hour < 6 or hour >= 18,
		"daylight":smoothstep(5.0,7.5,hour)*(1.0-smoothstep(16.5,20.5,hour))}

static func set_pressure(cycle: Dictionary, pressure: float) -> void:
	if not is_finite(pressure): return
	cycle.pressure = clampf(pressure,0,15)
	if pressure >= 15: cycle.tripped = true # A breaker stays tripped until an explicit repair.

static func band(pressure: float) -> String:
	return "red" if pressure >= 9 else ("yellow" if pressure >= 8 else "green")

static func power(cycle: Dictionary) -> Dictionary:
	return {"pressure":float(cycle.pressure),"band":band(float(cycle.pressure)),"online":not cycle.tripped,
		"strength":0.0 if cycle.tripped else clampf(float(cycle.pressure)/10.0,0,1),
		"stability":0.1 if cycle.tripped else (0.6 if cycle.pressure>10 else 1.0),"restored_links":0}
