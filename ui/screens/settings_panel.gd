class_name SettingsPanel
extends Modal
## The settings as a modal, for the title screen. In play they are an app on the field tablet
## (SettingsSheet is the shared content).

var settings: GameSettings


func setup(game_settings: GameSettings) -> void:
	settings = game_settings
	card.custom_minimum_size = Vector2(660, 0)
	title_row("Settings", "Changes apply right away and are remembered.")
	var sheet := SettingsSheet.new()
	sheet.setup(settings, close)
	body.add_child(sheet)
