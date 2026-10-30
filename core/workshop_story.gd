class_name WorkshopStory
extends RefCounted
## Bounded authored scenes and committed quest prerequisites; no files or nodes.

static func valid(scenes: Variant) -> bool:
	if not scenes is Dictionary or scenes.size() > 16: return false
	for id: Variant in scenes:
		var scene: Variant = scenes[id]
		if not AreaDef._id(id) or not scene is Dictionary or not scene.get("title") is String or str(scene.title).length() > 80 or not scene.get("pages") is Array or scene.pages.is_empty() or scene.pages.size() > 12: return false
		if scene.has("requires") and not AreaDef._id(scene.requires): return false
		if scene.has("area") and not AreaDef._id(scene.area): return false
		for field: String in ["narrator", "finish_label"]:
			if scene.has(field) and (not scene[field] is String or str(scene[field]).is_empty() or str(scene[field]).length() > 40): return false
		if not scene.get("lamps_on", []) is Array or scene.get("lamps_on", []).size() > 12: return false
		for lamp: Variant in scene.get("lamps_on", []):
			if not AreaDef._id(lamp): return false
		for page: Variant in scene.pages:
			if not page is Dictionary or page.get("speaker") not in ["narration", "hotaru", "ticket", "player"] or not page.get("text") is String or str(page.text).is_empty() or str(page.text).length() > 500: return false
			if not page.get("choices", []) is Array or page.get("choices", []).size() > 3: return false
			for choice: Variant in page.get("choices", []):
				if not choice is Dictionary or not choice.get("text") is String or str(choice.text).is_empty() or str(choice.text).length() > 120 or not choice.get("reply") is String or str(choice.reply).is_empty() or str(choice.reply).length() > 300: return false
	return true


static func pending(scenes: Dictionary, area: String, completed: Array, seen: Array, lamps: Dictionary = {}) -> String:
	for id: String in scenes:
		var scene: Dictionary = scenes[id]
		if scene.get("area", "workshop-floor") == area and scene.has("requires") and completed.has(str(scene.requires)) and not seen.has(id) and can_play(scene, lamps): return id
	return ""


static func can_play(scene: Dictionary, lamps: Dictionary) -> bool:
	for id: String in scene.get("lamps_on", []):
		if not lamps.get(id, false): return false
	return true


static func restore_read(raw: Variant, scenes: Dictionary) -> Array:
	var read: Array = []
	if not raw is Array: return read
	for id: Variant in raw:
		if id is String and scenes.has(id) and not read.has(id): read.append(id)
	return read


## Log tokens point to authored text; they cannot inject arbitrary saved prose.
static func log_line(scenes: Dictionary, token: Variant) -> Dictionary:
	if not token is Dictionary or not scenes.has(token.get("scene")): return {}
	var pages: Array = scenes[token.scene].pages
	if not AreaDef._whole(token.get("page")) or int(token.page) < 0 or int(token.page) >= pages.size(): return {}
	var page: Dictionary = pages[int(token.page)]
	if token.get("kind") == "page": return {"speaker":page.speaker, "text":page.text}
	if token.get("kind") not in ["choice", "reply"] or not AreaDef._whole(token.get("choice")): return {}
	var choices: Array = page.get("choices", [])
	var index: int = int(token.choice)
	if index < 0 or index >= choices.size(): return {}
	return {"speaker":"player" if token.kind == "choice" else "hotaru", "text":choices[index].text if token.kind == "choice" else choices[index].reply}


static func restore_log(raw: Variant, scenes: Dictionary) -> Array:
	var result: Array = []
	if not raw is Array: return result
	for token: Variant in raw.slice(maxi(0, raw.size()-128)):
		if log_line(scenes, token).is_empty(): continue
		var entry: Dictionary = {"scene":str(token.scene), "page":int(token.page), "kind":str(token.kind)}
		if token.kind != "page": entry["choice"] = int(token.choice)
		if result.is_empty() or result[-1] != entry: result.append(entry)
	return result
