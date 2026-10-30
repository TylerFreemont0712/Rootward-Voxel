class_name HotaruDialogue
extends RefCounted
## Authored companion pages use the same dialogue rules and presentation as residents.
const SOURCE: String="res://content/companions/hotaru.json"
static func person(player_name: String, morning: bool=true, greeted: bool=false, introduction: String="") -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not raw is Dictionary:return {}
	var result: Dictionary=raw.duplicate(true)
	result.greeting=str(result.greeting).replace("{player}",player_name)
	result["notebook_title"]="Field notes / 01" if greeted else "Field notes / 00"
	if not morning:
		result.greeting="I’m here, "+player_name+". One small light is enough to find the next step. What’s on your mind?"
		result.notebook_title="Open notebook"
	result.topics=result.topics.filter(func(entry: Dictionary) -> bool:return entry.id!="hollow" if morning else entry.id in ["hollow","company"])
	if morning and (not greeted or introduction!=""):
		var lesson: String="hello" if not greeted else introduction
		result["sequence"]=result.get("introductions",{}).get(lesson,[]).duplicate()
		result["on_finish"]="notebook"
		result.erase("notebook_title")
	elif morning:
		result.greeting="Your voice is clear now, "+player_name+". I’m listening."
		result.topics=result.topics.filter(func(entry: Dictionary) -> bool:return entry.id!="hello")
	return result
