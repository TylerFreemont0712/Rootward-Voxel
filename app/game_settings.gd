class_name GameSettings
extends RefCounted
## Player preferences, saved as a small config file. Every setter saves and emits `changed`.

signal changed(key: String)

const PATH: String = "user://settings.cfg"
const Skins := preload("res://art/frame_skin.gd")
const DEFAULTS: Dictionary = {
	"fullscreen": false,
	"ui_scale": 1.0,
	"zoom": 13.0,
	"show_controls": true,
	"font_size": 18,
	"completion": true,
	"auto_brackets": true,
	"character_skin": "adventurer",
	"dialogue_speed": 36,
	"dialogue_delay": 2.5,
}

var values: Dictionary = DEFAULTS.duplicate()


func load_file() -> void:
	if OS.get_environment("VOXEL_LAB_FRESH") == "1":
		return
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for key: String in DEFAULTS:
		var value: Variant = config.get_value("settings", key, DEFAULTS[key])
		if typeof(value) == typeof(DEFAULTS[key]):
			values[key] = value
	values.zoom = clampf(float(values.zoom), 8.0, 20.0)
	values.ui_scale = clampf(float(values.ui_scale), 0.8, 1.5)
	values.font_size = clampi(int(values.font_size), 12, 26)
	values.dialogue_speed = clampi(int(values.dialogue_speed), 0, 80)
	values.dialogue_delay = clampf(float(values.dialogue_delay), 1.0, 8.0)
	if not _available_skin(values.character_skin):
		values.character_skin = DEFAULTS.character_skin


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key) or values[key] == value:
		return
	if key == "character_skin" and not _available_skin(value):
		return
	values[key] = value
	_save()
	changed.emit(key)


func _available_skin(value: Variant) -> bool:
	return value is String and value == "adventurer"


func reset() -> void:
	for key: String in DEFAULTS:
		set_value(key, DEFAULTS[key])


func _save() -> void:
	if OS.get_environment("VOXEL_LAB_FRESH") == "1":
		return
	var config := ConfigFile.new()
	for key: String in values:
		config.set_value("settings", key, values[key])
	config.save(PATH)
