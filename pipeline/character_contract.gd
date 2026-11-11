extends RefCounted
## One owner for frame layout, motion timing, idle and scale across painted skins.

const TEMPLATE := "res://pipeline/character-template.json"
const SHARED_KEYS: Array[String] = ["grid", "directions", "walk_columns", "idle_column", "idle_columns", "fps", "world_height", "alpha_threshold", "facing_space", "projection", "row_edges", "frame_anchor", "authored_keyframes_per_direction", "idle"]


static func template_errors(template: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if template.get("schema") != 1 or template.get("kind") != "painted_frame_skin" or not template.has("settings"):
		return PackedStringArray(["Expected a versioned painted-frame template."])
	var settings: Dictionary = template.settings
	for key: String in SHARED_KEYS:
		if not settings.has(key):
			errors.append("Missing shared setting: " + key)
	if not errors.is_empty():
		return errors
	if settings.directions.keys() != ["se", "sw", "ne", "nw"] or settings.walk_columns != [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]:
		errors.append("Template must retain SE/SW/NE/NW and all eight ordered walk poses.")
	if template.cell_size != [384.0, 448.0] or settings.grid != [4.0, 12.0] or settings.frame_anchor != [192.0, 420.0]:
		errors.append("Template must retain the approved cell layout and foot origin.")
	if not is_equal_approx(float(settings.fps), 240.0 / 13.0) or float(settings.world_height) != 1.45 or int(settings.idle_column) != 8 or settings.idle_columns != [8.0, 9.0]:
		errors.append("Template must retain approved walk timing, scale and neutral/blink slots.")
	var idle: Dictionary = settings.idle
	if float(idle.get("breath_period", 0)) <= 0 or idle.get("blink_interval", []) != [6.0, 7.0] or float(idle.get("blink_duration", 0)) != 0.12 or idle.get("blink_directions", []) != ["se", "sw"]:
		errors.append("Template must retain a valid breath and the approved front blink cadence.")
	if settings.row_edges.size() != 13:
		errors.append("Template must define all atlas row edges.")
	else:
		for i in range(13):
			if int(settings.row_edges[i]) != i * 448:
				errors.append("Atlas row edges do not match the shared cells.")
				break
	return errors


static func resolve(spec: Dictionary) -> Dictionary:
	var path: String = spec.get("template", TEMPLATE)
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var errors := template_errors(template)
	for key: String in SHARED_KEYS:
		if spec.has(key):
			errors.append("Per-character overrides are forbidden for shared setting: " + key)
	if not errors.is_empty():
		for message: String in errors:
			push_error(message)
		return {}
	var resolved: Dictionary = template.settings.duplicate(true)
	resolved.merge(spec, true)
	resolved.template_id = template.id
	resolved.template_sha256 = FileAccess.get_sha256(path)
	return resolved
