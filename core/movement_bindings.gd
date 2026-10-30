class_name MovementBindings
extends RefCounted
## Bounded, declarative input rules. Python records bindings; it never receives
## input events, engine objects or executable callbacks in the engine process.

const KEYS: Array[String] = ["W", "A", "S", "D", "UP", "LEFT", "DOWN", "RIGHT"]
const DIRECTIONS: Dictionary = {"north": Vector2i(0, 1), "west": Vector2i(-1, 0), "south": Vector2i(0, -1), "east": Vector2i(1, 0)}
const LABELS: Dictionary = {"north": "North ↗", "west": "West ↖", "south": "South ↙", "east": "East ↘"}
const STARTER: String = "# One key press adds one step to x or y. Test, then Apply.\n\ndef program(world):\n    x = y = 0\n    y += 1\n    world.controls.bind_move(\"W\", x, y)\n    # Add A: x -= 1, S: y -= 1, D: x += 1.\n    # Start each key's x and y at zero.\n"


static func valid(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() > KEYS.size():
		return false
	for key: Variant in raw:
		if not key is String or not KEYS.has(key) or not raw[key] is String or not DIRECTIONS.has(raw[key]):
			return false
	return true


static func direction(bindings: Dictionary, key: String) -> Vector2i:
	return DIRECTIONS.get(str(bindings.get(key, "")), Vector2i.ZERO)


static func mapped(state: Dictionary) -> int:
	var unique: Dictionary = {}
	for value: Variant in (state.get("controls", {}) as Dictionary).values():
		if DIRECTIONS.has(value):unique[value] = true
	return unique.size()


static func tried(state: Dictionary) -> int:
	var done: Dictionary = {}
	for value: Variant in state.get("movement_used", []):
		if DIRECTIONS.has(value) and (state.get("controls", {}) as Dictionary).values().has(value):done[value] = true
	return done.size()


static func finished(state: Dictionary) -> bool:
	return mapped(state) == 4 and tried(state) == 4


static func apply(area: AreaDef, candidate: Dictionary, command: Dictionary, changes: Array[String]) -> String:
	if not area.movement_lesson:
		return "Movement bindings belong to the Village Morning lesson."
	var decoded: Dictionary = instruction(command)
	if not decoded.ok:return decoded.reason
	var name: String = direction_name(decoded.delta)
	if candidate.controls.get(command.key, "") != name:
		candidate.controls[command.key] = name
		candidate.movement_used = []
		changes.append("%s → %s" % [command.key, LABELS[name]])
	return ""


## Decode only bounded plain data. A safe but incorrect distance can be demonstrated
## without ever installing it. Existing direction-based programs remain compatible.
static func instruction(command: Dictionary) -> Dictionary:
	var out: Dictionary = {"ok":false,"reason":"A binding needs op, target: player, key and either delta or direction.","delta":Vector2i.ZERO,"bounded":false}
	if command.size()!=4 or not command.has_all(["op","target","key"]) or command.get("op")!="bind_key" or command.target!="player":return out
	if not command.key is String or not KEYS.has(command.key):
		out.reason="Choose W, A, S, D or an arrow key (UP, LEFT, DOWN, RIGHT)."
		return out
	if command.has("direction"):
		if not command.direction is String or not DIRECTIONS.has(command.direction):
			out.reason="Choose north, west, south or east, written in lowercase."
			return out
		out.delta=DIRECTIONS[command.direction]
	elif command.has("delta"):
		if not command.delta is Array or command.delta.size()!=2:return out
		for value: Variant in command.delta:
			if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)) or absf(float(value))>4:
				out.reason="Use whole movement amounts from -4 to 4 in the test bench. The room needs one step per key."
				return out
		out.delta=Vector2i(int(command.delta[0]),int(command.delta[1]))
	else:return out
	out.bounded=true
	var delta: Vector2i=out.delta
	if delta==Vector2i.ZERO:
		out.reason="%s adds 0: the character stays still. Change the amount to 1." % command.key
	elif delta.x!=0 and delta.y!=0:
		out.reason="%s changes both x and y. Change one axis for a single grid step." % command.key
	elif absi(delta.x)+absi(delta.y)!=1:
		out.reason="%s moves %d cells in one press and overshoots the one-cell target. Try 1 instead." % [command.key,absi(delta.x)+absi(delta.y)]
	else:
		out.ok=true
		out.reason="One key press, one grid step."
	return out


static func direction_name(delta: Vector2i) -> String:
	for name: String in DIRECTIONS:
		if DIRECTIONS[name]==delta:return name
	return ""


## A disposable, deterministic trace of attempted key events, never player state.
static func demonstrations(area: AreaDef, state: Dictionary, commands: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not area.movement_lesson or not commands is Array:return result
	var rules:=LabWorld.new(area)
	var start:=Vector2i(int(state.player[0]),int(state.player[1]))
	var keys: Dictionary={}
	for index: int in range(mini(commands.size(),LabWorld.MAX_COMMANDS)):
		var raw: Variant=commands[index]
		if not raw is Dictionary or raw.get("op")!="bind_key":continue
		var decoded: Dictionary=instruction(raw)
		if not decoded.bounded:continue
		var delta: Vector2i=decoded.delta
		var unit:=Vector2i(signi(delta.x),signi(delta.y))
		var path: Array[Vector2i]=[start]
		var blocked: bool=false
		if unit.x==0 or unit.y==0:
			for step: int in range(maxi(absi(delta.x),absi(delta.y))):
				var next: Vector2i=path[-1]+unit
				if not rules.can_step(state,path[-1],next):
					blocked=true
					break
				path.append(next)
		var expected: Vector2i=start+(Vector2i(unit.x,0) if unit.x!=0 and unit.y!=0 else unit)
		var trial: Dictionary={"key":str(raw.key),"delta":delta,"from":start,"target":start+delta,"expected":expected,"path":path,"blocked":blocked,"valid":decoded.ok,"ok":decoded.ok and not blocked,"reason":str(decoded.reason)+(" Furniture or the edge blocks this path." if blocked else "")}
		if keys.has(raw.key):
			# Valid rebinding uses the final instruction. Preserve a failed earlier
			# instruction because the whole program will be refused atomically.
			if result[keys[raw.key]].valid:result[keys[raw.key]]=trial
		else:
			keys[raw.key]=result.size()
			result.append(trial)
	return result


static func block_source(keys: Array[String], directions: Array[String], amounts: Array[int] = [], only_index: int = -1) -> Dictionary:
	if keys.size() != 4 or directions.size() != 4:
		return {"ok": false, "reason": "Connect all four blocks first."}
	var used: Dictionary = {}
	if not amounts.is_empty() and amounts.size()!=4:return {"ok":false,"reason":"Each event needs a movement amount."}
	var lines: PackedStringArray = ["# Compiled from your event blocks. Each key starts at x = y = 0.", "", "def program(world):"]
	if only_index < -1 or only_index > 3:return {"ok":false,"reason":"Choose one of the four events."}
	for index: int in range(4):
		if only_index!=-1 and index!=only_index:continue
		if not KEYS.has(keys[index]) or not DIRECTIONS.has(directions[index]):
			return {"ok": false, "reason": "Choose a key and a movement for every block."}
		if used.has(keys[index]):
			return {"ok": false, "reason": "Each block needs a different key."}
		used[keys[index]] = true
		var amount: int=1 if amounts.is_empty() else amounts[index]
		if amount<0 or amount>4:return {"ok":false,"reason":"Choose a whole amount from 0 to 4."}
		var delta: Vector2i=DIRECTIONS[directions[index]]
		lines.append("    # When %s is pressed" % keys[index])
		lines.append("    x = y = 0")
		lines.append("    %s %s %d" % ["x" if delta.x!=0 else "y","+=" if delta.x+delta.y>0 else "-=",amount])
		lines.append("    world.controls.bind_move(%s, x, y)" % JSON.stringify(keys[index]))
		lines.append("")
	return {"ok": true, "source": "\n".join(lines) + "\n"}
