class_name SaveMigration
extends RefCounted
## Renamed content ids, applied to a save as it loads, so a game saved before a rename continues where it was.
## Only whole strings and dictionary keys that exactly equal a retired id change; prose never does.

## Retired id -> current id. Add a line here whenever a saved id (area, lamp, display, quest, skin) is renamed.
const RENAMED: Dictionary = {
	# 2026-11-07 naming tidy-up (docs/RENAMES_2026-11-07.md): Finch & Thread is the tailor's.
	"shop-bookshop": "shop-tailor",
	"bookshop-window-lamp": "tailor-window-lamp",
	"bookshop": "tailor",  # the square's building and door into it
}


static func upgrade(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[_renamed(key)] = upgrade(value[key])
		return result
	if value is Array:
		var list: Array = []
		for item: Variant in value:
			list.append(upgrade(item))
		return list
	return _renamed(value)


static func _renamed(value: Variant) -> Variant:
	return RENAMED.get(value, value) if value is String else value
