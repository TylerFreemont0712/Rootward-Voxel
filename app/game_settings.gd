class_name GameSettings
extends RefCounted
## Player preferences, saved as a small config file. Every setter saves and emits `changed`.

signal changed(key: String)

const PATH: String = "user://settings.cfg"
const LAYOUT_VERSION: int=2
const Skins := preload("res://art/frame_skin.gd")
const DEFAULTS: Dictionary = {
	"fullscreen": true,
	"ui_scale": 1.0,
	"zoom": 13.0,
	"show_controls": true,
	"font_size": 15,
	"completion": true,
	"auto_brackets": true,
	"character_skin": "adventurer",
	"dialogue_speed": 45,
	"dialogue_delay": 2.5,
}

var values: Dictionary = DEFAULTS.duplicate()


func load_file() -> void:
	if OS.get_environment("VOXEL_LAB_FRESH") == "1":
		# Isolated review runs honor their requested window resolution.
		values.fullscreen=false
		return
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	for key: String in DEFAULTS:
		var value: Variant = config.get_value("settings", key, DEFAULTS[key])
		if typeof(value) == typeof(DEFAULTS[key]):
			values[key] = value
	values.zoom = clampf(float(values.zoom), 8.0, 20.0)
	values.ui_scale = clampf(float(values.ui_scale), 0.6, 1.5)
	values.font_size = clampi(int(values.font_size), 10, 26)
	values.dialogue_speed = clampi(int(values.dialogue_speed), 0, 80)
	values.dialogue_delay = clampf(float(values.dialogue_delay), 1.0, 8.0)
	var migrate: bool=int(config.get_value("meta","layout_version",1))<LAYOUT_VERSION
	var migrate_dialogue: bool = int(config.get_value("meta", "dialogue_speed_revision", 0)) < 1
	if migrate_dialogue and values.dialogue_speed == 36:
		values.dialogue_speed = DEFAULTS.dialogue_speed
	if migrate:
		values.fullscreen=true
		if values.font_size==18:values.font_size=DEFAULTS.font_size
	if not _available_skin(values.character_skin):
		values.character_skin = DEFAULTS.character_skin
	if migrate or migrate_dialogue:_save()


func get_value(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key) or values[key] == value:
		return
	if key == "character_skin" and not _available_skin(value):
		return
	if key=="ui_scale":value=clampf(float(value),.6,1.5)
	elif key=="font_size":value=clampi(int(value),10,26)
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
	config.set_value("meta","layout_version",LAYOUT_VERSION)
	config.set_value("meta", "dialogue_speed_revision", 1)
	for key: String in values:
		config.set_value("settings", key, values[key])
	config.save(PATH)
