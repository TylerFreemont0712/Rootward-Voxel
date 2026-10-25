class_name LabProgram
extends RefCounted
## Boundary adapter. Call run on a worker: the existing WASI runner deliberately blocks.

const RESULT_MARKER: String = "__VOXEL_RESULT__"
const MAX_SOURCE_BYTES: int = 16384
const MAX_RESULT_BYTES: int = 16384
const TIME_MS: int = 2000
const WALL_MS: int = 7000
const MEMORY_MB: int = 96
const OUTPUT_KB: int = 32


static func starter_source() -> String:
	return """# Run shows what your code would do.
# Apply makes the preview real.

def program(world):
    # Write your changes here.
    pass
"""


static func run(source: String, world_snapshot: Dictionary) -> Dictionary:
	if source.to_utf8_buffer().size() > MAX_SOURCE_BYTES:
		return _failure("Program exceeds the 16 KiB source limit.")
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
		return _failure("Returned commands exceed the 16 KiB result limit.", stdout_text.left(marker_at), wall_ms)
	var parser: JSON = JSON.new()
	if parser.parse(payload) != OK or not parser.data is Dictionary:
		return _failure("Program result must be a JSON object.", stdout_text.left(marker_at), wall_ms)
	var value: Dictionary = parser.data
	if value.size() != 2 or not value.get("commands") is Array or not value.get("memory") is Dictionary:
		return _failure("Return commands as a list and memory as a dictionary.", stdout_text.left(marker_at), wall_ms)
	return {
		"ok": true,
		"reason": "",
		"commands": value.commands.duplicate(true),
		"memory": value.memory.duplicate(true),
		"stdout": stdout_text.left(marker_at).strip_edges(),
		"wall_ms": wall_ms,
	}


static func _failure(reason: String, stdout_text: String = "", wall_ms: int = 0, stderr_text: String = "") -> Dictionary:
	return {"ok": false, "reason": reason, "commands": [], "memory": {}, "stdout": stdout_text, "wall_ms": wall_ms,
		"error": ErrorAdvice.parse(stderr_text), "stderr": stderr_text.left(2000)}
