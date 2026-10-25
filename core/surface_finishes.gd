class_name SurfaceFinishes
extends RefCounted
## Explicit cosmetic material capabilities. These rules never change collision, support or world commands.

const OPTIONS: Dictionary = {
	"walls": ["limewash", "sage_wallpaper", "timber_panels", "red_brick", "riverstone", "limestone_flags"],
	"roof": ["slate_shingles", "cedar_shingles", "copper_patina"],
	"timber": ["timber_panels", "herringbone_oak"],
	"masonry": ["limestone_flags", "red_brick", "riverstone", "terracotta_tile", "encaustic_tile"],
	"metal": ["copper_patina"],
	"fabric": ["woven_linen", "violet_quilt", "tooled_leather"],
	"floor": ["herringbone_oak", "terracotta_tile", "encaustic_tile", "limestone_flags"],
}
const TITLES: Dictionary = {"walls":"Walls", "roof":"Roof", "timber":"Timber", "masonry":"Masonry", "metal":"Metalwork", "fabric":"Upholstery", "floor":"Floor", "hearth":"Hearth", "cloth":"Textiles", "rug":"Rugs"}
const ROOM_SLOTS: Dictionary = {"floor":"floor", "walls":"walls", "timber":"timber", "hearth":"masonry", "cloth":"fabric", "rug":"fabric"}


static func validate(raw: Variant, slots: Dictionary) -> String:
	if not raw is Dictionary:
		return "Surface finishes must be a dictionary of part names and material ids."
	for slot: Variant in raw:
		if not slot is String or not slots.has(slot) or not raw[slot] is String:
			return "Choose a supported part and material."
		var group: String = str(slots[slot])
		if not OPTIONS.has(group) or not (OPTIONS[group] as Array).has(raw[slot]):
			return "That material is not offered for %s." % str(slot)
	return ""


static func asset_slots(asset: Dictionary) -> Dictionary:
	var slots: Dictionary = {}
	for slot: String in asset.get("finish_slots", {}):
		if OPTIONS.has(slot):
			slots[slot] = slot
	return slots


static func check(area: AreaDef, assets: Dictionary, kind: String, id: String, slot: String, material: String) -> Dictionary:
	var slots: Dictionary
	if kind == "room":
		if area.interior.is_empty() or id != "":
			return {"ok":false,"reason":"Enter a home to change its interior finishes."}
		slots = ROOM_SLOTS
	elif kind in ["building", "prop"]:
		var body: Dictionary = area.building(id) if kind == "building" else area.prop(id)
		if body.is_empty():
			return {"ok":false,"reason":"Choose a standing house or prop first."}
		slots = asset_slots(assets.get(body.asset, {}))
	else:
		return {"ok":false,"reason":"Finishes belong to houses, props or rooms."}
	if not slots.has(slot):
		return {"ok":false,"reason":"That object has no editable %s part." % slot}
	var problem: String = "" if material == "" else validate({slot:material}, slots)
	return {"ok":problem == "", "reason":problem}
