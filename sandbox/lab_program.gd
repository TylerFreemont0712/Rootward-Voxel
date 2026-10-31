class_name LabProgram
extends RefCounted
## Boundary adapter. Call run on a worker: the existing WASI runner deliberately blocks.

const RESULT_MARKER: String = "__VOXEL_RESULT__"
## Room for long programs and their debugger evidence. The output cap must stay above the result cap, because the
## framed result travels in the same stdout as the player's own printing. world_harness.py keeps RESULT_LIMIT equal.
const MAX_SOURCE_BYTES: int = 65536
const MAX_RESULT_BYTES: int = 65536
const TIME_MS: int = 2000
const WALL_MS: int = 7000
const MEMORY_MB: int = 96
const OUTPUT_KB: int = 128
const RESULT_KEYS: Array[String] = ["commands", "memory", "trace", "locals"]


static func starter_source() -> String:
	return """# Run shows what your code would do.
# Apply makes the preview real.

def program(world):
    # Write your changes here.
    pass
"""


static func run(source: String, world_snapshot: Dictionary) -> Dictionary:
	if source.to_utf8_buffer().size() > MAX_SOURCE_BYTES:
		return _failure("Program exceeds the %d KiB source limit." % (MAX_SOURCE_BYTES / 1024))
	var files: Dictionary[String, String] = {
		"player.py": source,
		"world_harness.py": FileAccess.get_file_as_string("res://sandbox/world_harness.py"),
	}
	if files["world_harness.py"] == "":
		return _failure("The laboratory harness is missing.")
	var job: SandboxJob = SandboxJob.of(SandboxJob.PYTHON, files, "world_harness.py")
	job.stdin = JSON.stringify(world_snapshot)
	job.time_ms = TIME_MS
	job.wall_ms = WALL_MS
	job.memory_mb = MEMORY_MB
	job.output_kb = OUTPUT_KB
	var result: SandboxResult = Sandbox.run(job)
	if not result.is_ok():
		return _failure(result.message, result.stdout, result.wall_ms, result.stderr)
	return _decode(result.stdout, result.wall_ms)


static func _decode(stdout_text: String, wall_ms: int) -> Dictionary:
	# LEARN: stdout is untrusted. A marker frames a result; pure world rules still validate every command.
	var marker_at: int = stdout_text.rfind(RESULT_MARKER)
	if marker_at < 0:
		return _failure("Program ended without returning a result from program(world).", stdout_text, wall_ms)
	var payload: String = stdout_text.substr(marker_at + RESULT_MARKER.length()).strip_edges()
	if payload.to_utf8_buffer().size() > MAX_RESULT_BYTES:
		return _failure("Returned commands exceed the %d KiB result limit." % (MAX_RESULT_BYTES / 1024), stdout_text.left(marker_at), wall_ms)
	var parser: JSON = JSON.new()
	if parser.parse(payload) != OK or not parser.data is Dictionary:
		return _failure("Program result must be a JSON object.", stdout_text.left(marker_at), wall_ms)
	var value: Dictionary = parser.data
	var unknown: bool = value.keys().any(func(key: Variant) -> bool: return not RESULT_KEYS.has(str(key)))
	if unknown or not value.get("commands") is Array or not value.get("memory") is Dictionary:
		return _failure("Return commands as a list and memory as a dictionary.", stdout_text.left(marker_at), wall_ms)
	return {
		"ok": true,
		"reason": "",
		"commands": value.commands.duplicate(true),
		"memory": value.memory.duplicate(true),
		"trace": safe_trace(value.get("trace", [])),
		"locals": safe_names(value.get("locals", {}), 16),
		"stdout": stdout_text.left(marker_at).strip_edges(),
		"wall_ms": wall_ms,
	}


static func _failure(reason: String, stdout_text: String = "", wall_ms: int = 0, stderr_text: String = "") -> Dictionary:
	var trace: Array[Dictionary]=[]
	var at: int=stdout_text.rfind("__VOXEL_TRACE__")
	if at>=0:
		var encoded: String=stdout_text.substr(at+15).strip_edges()
		if encoded.to_utf8_buffer().size()<=MAX_RESULT_BYTES:trace=safe_trace(JSON.parse_string(encoded))
		stdout_text=stdout_text.left(at).strip_edges()
	return {"ok": false, "reason": reason, "trace":trace, "commands": [], "memory": {}, "stdout": stdout_text, "wall_ms": wall_ms,
		"error": ErrorAdvice.parse(stderr_text), "stderr": stderr_text.left(2000)}


## Evidence is untrusted metadata, never a source of world commands or engine objects.
static func safe_trace(raw: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not raw is Array or raw.size()>96:return result
	for item: Variant in raw:
		if not item is Dictionary or not LabWorld._whole_number(item.get("line")) or int(item.line)<1 or int(item.line)>16384:return []
		var event: Dictionary={"line":int(item.line)}
		if item.has("command"):
			if not LabWorld._whole_number(item.command) or int(item.command)<0 or int(item.command)>=LabWorld.MAX_COMMANDS:return []
			event["command"]=int(item.command)
		if item.has("values"):
			if not item.values is Dictionary or item.values.size()>4:return []
			var values: Dictionary={}
			for key: Variant in item.values:
				if not key is String or not ["x","y","key","message"].has(key):return []
				var value: Variant=item.values[key]
				if value is String and value.length()<=60:values[key]=value
				elif LabWorld._whole_number(value) and absf(float(value))<=1000000:values[key]=int(value)
				else:return []
			event["values"]=values
		if item.has("vars"):
			if not item.vars is Dictionary:return []
			var named: Dictionary=safe_names(item.vars, 4)
			if named.size()!=(item.vars as Dictionary).size():return []
			if not named.is_empty():event["vars"]=named
		result.append(event)
	return result

## The player's own names and their short, already-rendered values: text only, bounded, never evaluated.
static func safe_names(raw: Variant, most: int) -> Dictionary:
	var names: Dictionary={}
	if not raw is Dictionary or (raw as Dictionary).size()>most:return names
	var identifier:=RegEx.create_from_string("^[A-Za-z][A-Za-z0-9_]{0,39}$")
	for key: Variant in raw:
		var value: Variant=raw[key]
		if not key is String or identifier.search(key)==null or not value is String or (value as String).length()>80:return {}
		names[key]=value
	return names
