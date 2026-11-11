class_name SelfTest
extends RefCounted
## `RootwardVoxel -- --self-test` (on Windows `RootwardVoxel.console.exe -- --self-test`, which keeps a console):
## proves a build works on this machine without playing it. It reads every area document from wherever this build
## keeps them (the .pck when exported), checks that every catalogued model is packed, loads one, finds the sandbox
## beside the game and runs real Python in it, then quits with 0 when all of that worked and 1 otherwise.
## scripts/build.py, the installer and the Windows check in .github/workflows/ all run it.

const FLAG := "--self-test"
const CHECK_AREA := "workshop-loft"
const CHECK_MODEL := "res://assets/world/loft-bed/model.glb"

static var _failures: PackedStringArray = []
static var _checks := 0


static func requested() -> bool:
	return OS.get_cmdline_user_args().has(FLAG)


static func run() -> int:
	var started := Time.get_ticks_msec()
	_failures.clear()
	_checks = 0
	var version := str(ProjectSettings.get_setting("application/config/version", "?"))
	print("Rootward Voxel %s self-test on %s (%s)" % [version, OS.get_name(),
		"exported" if OS.has_feature("template") else "from source"])
	print("sandbox runtime: %s" % Sandbox.runtime_dir())
	print("stdlib files marked read-only now: %d" % Sandbox.protect_stdlib())
	_content()
	_sandbox()
	var failed := not _failures.is_empty()
	for failure in _failures:
		print("  FAIL: " + failure)
	print("%d checks, %d failed in %.1fs -> %s" % [_checks, _failures.size(),
		(Time.get_ticks_msec() - started) / 1000.0, "FAILED" if failed else "OK"])
	return 1 if failed else 0


static func _check(ok: bool, what: String) -> bool:
	_checks += 1
	if not ok:
		_failures.append(what)
	return ok


static func _content() -> void:
	var areas := 0
	for name in DirAccess.get_files_at("res://content/areas"):
		# An exported .pck lists the plain files it carries under their own names.
		if not name.ends_with(".json") or name.ends_with(".quests.json"):
			continue
		var id := name.get_basename()
		_check(AreaStore.load_area(id) != null, "area %s loads and validates" % id)
		areas += 1
	_check(areas > 0, "the area documents are in this build")
	var models: Dictionary = AreaStore.catalog_assets()
	var missing := 0
	for id: String in models:
		var runtime := str((models[id] as Dictionary).get("runtime", ""))
		if runtime != "" and not ResourceLoader.exists("res://" + runtime):
			missing += 1
			if missing <= 5:
				_check(false, "model %s is packed (%s)" % [id, runtime])
	_check(missing == 0, "every catalogued model is packed (%d missing)" % missing)
	_check(load(CHECK_MODEL) is PackedScene, "a model loads: %s" % CHECK_MODEL)
	print("content: %d areas, %d models" % [areas, models.size()])


static func _sandbox() -> void:
	if not _check(Sandbox.is_available(SandboxJob.PYTHON), "the Python sandbox is beside the game"):
		return
	var area := AreaStore.load_area(CHECK_AREA)
	if not _check(area != null, "area %s loads" % CHECK_AREA):
		return
	var rules := LabWorld.new(area)
	var snapshot: Dictionary = rules.snapshot(rules.initial_state())
	var hello := LabProgram.run("def program(world):\n    print('Hello, Hotaru!')\n", snapshot)
	_check(hello.ok and str(hello.stdout).contains("Hello, Hotaru!"), "real Python runs: %s" % hello.get("reason", ""))
	var broken := LabProgram.run("def program(:\n    pass\n", snapshot)
	_check(not broken.ok and str(broken.reason).contains("SyntaxError"), "a syntax error is reported in plain words")
	print("python: %s in %d ms" % ["ok" if hello.ok else "FAILED", int(hello.get("wall_ms", 0))])
