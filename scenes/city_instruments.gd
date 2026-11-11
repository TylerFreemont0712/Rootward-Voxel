class_name CityInstruments
extends RefCounted
## Finds semantic pivots in the adopted model; world rules never depend on meshes.
static func update(root: Node, power: Dictionary, seconds: float) -> void:
	if not root.has_meta("city_needles"):
		var needles: Array[Node] = []
		for part: Node in root.find_children("*", "Node3D",true,false):
			if part.name.to_lower().begins_with("gauge_needle"):needles.append(part)
		root.set_meta("city_needles",needles)
	for part: Node in root.get_meta("city_needles"):
		var needle := part as Node3D
		if not needle.has_meta("rest_transform"): needle.set_meta("rest_transform",needle.transform)
		var pressure: float = float(power.get("pressure",5.6))
		var value: float = minf(pressure,10.0)
		if pressure>10:value=10.0+sin(seconds*31.0)*.09+sin(seconds*47.0)*.04
		var rest: Transform3D = needle.get_meta("rest_transform")
		needle.transform = rest * Transform3D(Basis(Vector3.BACK,deg_to_rad(-27.0*(value-1.3))),Vector3.ZERO)

static func update_clock(root: Node, hour: float) -> void:
	if not root.has_meta("city_clock_hands"):
		var hands: Array[Node] = []
		for part: Node in root.find_children("*","Node3D",true,false):
			if part.name.to_lower().begins_with("clock_minute_hand") or part.name.to_lower().begins_with("clock_hour_hand"):hands.append(part)
		root.set_meta("city_clock_hands",hands)
	for part: Node in root.get_meta("city_clock_hands"):
		var hand:=part as Node3D
		if not hand.has_meta("clock_rest"):hand.set_meta("clock_rest",hand.transform)
		var fraction: float=fposmod(hour,1.0) if hand.name.to_lower().begins_with("clock_minute") else fposmod(hour/12.0,1.0)
		hand.transform=(hand.get_meta("clock_rest") as Transform3D)*Transform3D(Basis(Vector3.BACK,-TAU*fraction),Vector3.ZERO)

static func describe_pressure(pressure: float) -> String:
	if pressure>10:
		return "The needle trembles against the stop beyond 10. The scale goes no further."
	var colour: String={"green":"green","yellow":"amber","red":"red"}[CityCycle.band(pressure)]
	return "The needle holds at %.1f, in the %s part of the dial." % [pressure,colour]
