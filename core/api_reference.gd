class_name ApiReference
extends RefCounted
## The player-visible programming API as data: the Reference tab, code completion and error suggestions
## all read this one list, so documentation, hints and behavior cannot drift apart. The authoritative
## implementation is sandbox/world_harness.py; docs/PROGRAMMING.md describes the same surface.

## Member kinds: "method" takes arguments, "attribute" is read, "global" is a name usable anywhere.
const TYPES: Dictionary = {
	"World": {
		"summary": "The village as Python sees it. It is the one value passed to program(world).",
		"members": [
			{"name":"controls","kind":"attribute","sig":"world.controls","doc":"Village Morning: connect movement keys to the character. Other levels keep their existing controls.","returns":"Controls"},
			{"name": "lamp", "kind": "method", "sig": "world.lamp(name)", "doc": "The lamp with that id. Ids are in the World tab.", "returns": "Lamp"},
			{"name": "lamps", "kind": "attribute", "sig": "world.lamps", "doc": "A list of every lamp in the places you have visited.", "returns": "Lamp[]"},
			{"name": "gate", "kind": "method", "sig": "world.gate(name)", "doc": "The gate with that id.", "returns": "Gate"},
			{"name": "gates", "kind": "attribute", "sig": "world.gates", "doc": "A list of every gate you can reach.", "returns": "Gate[]"},
			{"name": "bridge", "kind": "method", "sig": "world.bridge(name)", "doc": "The bridge with that id.", "returns": "Bridge"},
			{"name": "bridges", "kind": "attribute", "sig": "world.bridges", "doc": "A list of every bridge you can reach.", "returns": "Bridge[]"},
			{"name": "prop", "kind": "method", "sig": "world.prop(name)", "doc": "A working builder object by its placed id, such as prop-1.", "returns": "Prop"},
			{"name": "props", "kind": "attribute", "sig": "world.props", "doc": "Working objects in places you have visited. Decorations without a capability are not listed.", "returns": "Prop[]"},
			{"name": "house", "kind": "method", "sig": "world.house(id)", "doc": "The house with that id, such as \"home\". Ids are in the World tab.", "returns": "House", "ability": "read"},
			{"name": "houses", "kind": "attribute", "sig": "world.houses", "doc": "A list of the houses within reach: in places you have visited, or within 12 cells of you.", "returns": "House[]", "ability": "read"},
			{"name": "tree", "kind": "method", "sig": "world.tree(x, y)", "doc": "The tree standing at that place, such as world.tree(31.5, 6). Trees stand on whole and half cells.", "returns": "Tree", "ability": "read"},
			{"name": "trees", "kind": "attribute", "sig": "world.trees", "doc": "A list of the trees within reach.", "returns": "Tree[]", "ability": "read"},
			{"name": "doodad", "kind": "method", "sig": "world.doodad(id)", "doc": "The furniture, tool or decoration with that placed id, such as prop-1.", "returns": "Doodad", "ability": "read"},
			{"name": "doodads", "kind": "attribute", "sig": "world.doodads", "doc": "A list of the doodads within reach: everything placed, working or not.", "returns": "Doodad[]", "ability": "read"},
			{"name": "zone", "kind": "method", "sig": "world.zone(name)", "doc": "A place by id, such as \"green\". Only places you have visited exist.", "returns": "Zone"},
			{"name": "zones", "kind": "attribute", "sig": "world.zones", "doc": "A list of every place you have visited.", "returns": "Zone[]"},
			{"name": "here", "kind": "attribute", "sig": "world.here", "doc": "The zone you are standing in right now.", "returns": "Zone"},
			{"name": "player", "kind": "attribute", "sig": "world.player", "doc": "Your cell as [x, y, 0].", "returns": "list"},
			{"name": "memory", "kind": "attribute", "sig": "world.memory", "doc": "A dictionary that keeps small notes between runs once you Apply.", "returns": "dict"},
		],
	},
	"Controls": {
		"summary":"Village Morning's movement keys. A binding records a direction; Preview and Apply install it.",
		"members":[
			{"name":"bind_move","kind":"method","sig":"world.controls.bind_move(\"W\", x, y)","doc":"Bind the result of x/y arithmetic to a key. Start at x = y = 0; y += 1 moves north. Test shows zero movement, overshoots and blocked paths; only one cardinal cell can be applied.","returns":""},
			{"name":"bind","kind":"method","sig":"world.controls.bind(\"W\", \"north\")","doc":"Connect W/A/S/D or UP/LEFT/DOWN/RIGHT to north, west, south or east. Only successful steps with these keys count toward the first lesson.","returns":""},
			{"name":"bindings","kind":"attribute","sig":"world.controls.bindings","doc":"Your applied key-to-direction map, as a Python dictionary.","returns":"dict"},
		],
	},
	"Zone": {
		"summary": "A named place with things in it.",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "zone.id", "doc": "Its short name, such as \"green\".", "returns": "str"},
			{"name": "name", "kind": "attribute", "sig": "zone.name", "doc": "Its title, such as \"The Green\".", "returns": "str"},
			{"name": "lamps", "kind": "attribute", "sig": "zone.lamps", "doc": "A list of the lamps in this zone.", "returns": "Lamp[]"},
			{"name": "gates", "kind": "attribute", "sig": "zone.gates", "doc": "A list of the gates in this zone.", "returns": "Gate[]"},
			{"name": "bridges", "kind": "attribute", "sig": "zone.bridges", "doc": "A list of the bridges in this zone.", "returns": "Bridge[]"},
			{"name": "props", "kind": "attribute", "sig": "zone.props", "doc": "The working builder objects in this zone.", "returns": "Prop[]"},
			{"name": "houses", "kind": "attribute", "sig": "zone.houses", "doc": "A list of the houses in this zone.", "returns": "House[]", "ability": "read"},
			{"name": "trees", "kind": "attribute", "sig": "zone.trees", "doc": "A list of the trees in this zone.", "returns": "Tree[]", "ability": "read"},
			{"name": "doodads", "kind": "attribute", "sig": "zone.doodads", "doc": "A list of the doodads in this zone.", "returns": "Doodad[]", "ability": "read"},
		],
	},
	"House": {
		"summary": "A house. Your code can see where it stands and which way it faces, and turn it.",
		"ability": "read",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "house.id", "doc": "Its name, such as \"home\" or \"build-3\".", "returns": "str"},
			{"name": "kind", "kind": "attribute", "sig": "house.kind", "doc": "What sort of house, such as \"house-hollow\". The same names the builder's tray uses.", "returns": "str"},
			{"name": "name", "kind": "attribute", "sig": "house.name", "doc": "Its title, such as \"Hollow House\".", "returns": "str"},
			{"name": "at", "kind": "attribute", "sig": "house.at", "doc": "Its centre as [x, y]. x grows eastward and y northward.", "returns": "list"},
			{"name": "cell", "kind": "attribute", "sig": "house.cell", "doc": "Its nearest cell as [x, y, 0]. house.cell[1] is how far north it stands.", "returns": "list"},
			{"name": "facing", "kind": "attribute", "sig": "house.facing", "doc": "Which way its door faces: \"north\", \"east\", \"south\" or \"west\". Updates as soon as you call face.", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "house.zone", "doc": "The id of the place it stands in, or an empty string between places.", "returns": "str"},
			{"name": "locked", "kind": "attribute", "sig": "house.locked", "doc": "True if it belongs to the lessons (like the mill) and can never be changed.", "returns": "bool"},
			{"name": "face", "kind": "method", "sig": "house.face(\"north\")", "doc": "Turn it to face north, east, south or west. Refused if the door would then have no ground in front of it.", "returns": "", "ability": "turn"},
		],
	},
	"Doodad": {
		"summary": "Something placed in the village: a chair, a barrel, a lever. Working ones (see Prop) are doodads too, with the same id.",
		"ability": "read",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "doodad.id", "doc": "Its placed id, such as prop-1.", "returns": "str"},
			{"name": "kind", "kind": "attribute", "sig": "doodad.kind", "doc": "What it is, such as \"park-bench\". The same names the builder's tray uses.", "returns": "str"},
			{"name": "name", "kind": "attribute", "sig": "doodad.name", "doc": "Its title, such as \"Park Bench\".", "returns": "str"},
			{"name": "at", "kind": "attribute", "sig": "doodad.at", "doc": "Where it stands as [x, y]. x grows eastward and y northward.", "returns": "list"},
			{"name": "cell", "kind": "attribute", "sig": "doodad.cell", "doc": "Its nearest cell as [x, y, 0].", "returns": "list"},
			{"name": "facing", "kind": "attribute", "sig": "doodad.facing", "doc": "Which way its front faces: \"north\", \"east\", \"south\" or \"west\".", "returns": "str"},
			{"name": "solid", "kind": "attribute", "sig": "doodad.solid", "doc": "True if it blocks walking where it stands.", "returns": "bool"},
			{"name": "zone", "kind": "attribute", "sig": "doodad.zone", "doc": "The id of the place it stands in, or an empty string between places.", "returns": "str"},
			{"name": "face", "kind": "method", "sig": "doodad.face(\"east\")", "doc": "Turn it to face north, east, south or west. Refused if it would no longer fit.", "returns": "", "ability": "turn"},
		],
	},
	"Tree": {
		"summary": "A tree. Your code can see where it stands and how big it is.",
		"ability": "read",
		"members": [
			{"name": "at", "kind": "attribute", "sig": "tree.at", "doc": "Where it stands as [x, y], on a whole or half cell.", "returns": "list"},
			{"name": "cell", "kind": "attribute", "sig": "tree.cell", "doc": "Its nearest cell as [x, y, 0].", "returns": "list"},
			{"name": "size", "kind": "attribute", "sig": "tree.size", "doc": "How big it is: 1.0 is an ordinary oak.", "returns": "float"},
			{"name": "kind", "kind": "attribute", "sig": "tree.kind", "doc": "What sort of tree, such as \"tree-oak\", or \"tree\" for one that is none of the builder's kinds.", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "tree.zone", "doc": "The id of the place it stands in, or an empty string in the forest between places.", "returns": "str"},
		],
	},
	"Prop": {
		"summary": "A working builder object: a lamp, chest, lever, bell, pump or craft machine. Its ground footprint stays fixed.",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "prop.id", "doc": "Its placed id, such as prop-1; find it in the builder details or World tab.", "returns": "str"},
			{"name": "asset", "kind": "attribute", "sig": "prop.asset", "doc": "The kind of object, such as hollow-brass-lever.", "returns": "str"},
			{"name": "name", "kind": "attribute", "sig": "prop.name", "doc": "Its readable catalog title.", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "prop.zone", "doc": "The district it stands in, or an empty string outside named places.", "returns": "str"},
			{"name": "cell", "kind": "attribute", "sig": "prop.cell", "doc": "Its nearest logical cell as [x, y, 0].", "returns": "list"},
			{"name": "active", "kind": "attribute", "sig": "prop.active", "doc": "True when lit, open, running, pulled or ringing, depending on the object.", "returns": "bool"},
			{"name": "set_active", "kind": "method", "sig": "prop.set_active(True)", "doc": "Use True to activate, False to stop or close. Run previews; Apply commits the same proposal.", "returns": ""},
		],
	},
	"Lamp": {
		"summary": "A lantern you can light or put out.",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "lamp.id", "doc": "Its name, such as \"landing-lamp\".", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "lamp.zone", "doc": "The id of the zone it stands in.", "returns": "str"},
			{"name": "cell", "kind": "attribute", "sig": "lamp.cell", "doc": "Its cell as [x, y, 0].", "returns": "list"},
			{"name": "lit", "kind": "attribute", "sig": "lamp.lit", "doc": "True if the lamp is burning. Updates as soon as you call set_lit.", "returns": "bool"},
			{"name": "set_lit", "kind": "method", "sig": "lamp.set_lit(True)", "doc": "Light the lamp with True, put it out with False.", "returns": ""},
		],
	},
	"Gate": {
		"summary": "A gate that can swing open or shut.",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "gate.id", "doc": "Its name, such as \"night-gate\".", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "gate.zone", "doc": "The id of the zone it stands in.", "returns": "str"},
			{"name": "cell", "kind": "attribute", "sig": "gate.cell", "doc": "Its cell as [x, y, 0].", "returns": "list"},
			{"name": "is_open", "kind": "attribute", "sig": "gate.is_open", "doc": "True if the gate is open.", "returns": "bool"},
			{"name": "set_open", "kind": "method", "sig": "gate.set_open(True)", "doc": "Open the gate with True, shut it with False. You cannot shut it on someone standing in it.", "returns": ""},
		],
	},
	"Bridge": {
		"summary": "A row of timber decks over water. Decks go down in order from the first socket.",
		"members": [
			{"name": "id", "kind": "attribute", "sig": "bridge.id", "doc": "Its name, such as \"mill-bridge\".", "returns": "str"},
			{"name": "zone", "kind": "attribute", "sig": "bridge.zone", "doc": "The id of the zone it belongs to.", "returns": "str"},
			{"name": "cells", "kind": "attribute", "sig": "bridge.cells", "doc": "The sockets, in building order. Each is a cell [x, y, 0].", "returns": "list"},
			{"name": "built", "kind": "attribute", "sig": "bridge.built", "doc": "How many decks are down.", "returns": "int"},
			{"name": "place_deck", "kind": "method", "sig": "bridge.place_deck(cell)", "doc": "Put a deck in the next socket. A socket out of order is refused.", "returns": ""},
			{"name": "remove_deck", "kind": "method", "sig": "bridge.remove_deck(cell)", "doc": "Take the last deck away. You cannot remove one under your feet.", "returns": ""},
		],
	},
}

## Short Python reminders that sit beside the game API in the Reference tab.
const PYTHON_NOTES: Array[Dictionary] = [
	{"title": "Names and values", "sig": "count = 3", "doc": "A name holds a value. Use = to give it one, and the name stands in for the value afterwards.", "example": "deck_count = 4\nname = \"green\""},
	{"title": "True and False", "sig": "True / False", "doc": "Booleans are yes and no. Capital T and F. Combine them with and, or, not.", "example": "if west.lit and east.lit:\n    print(\"both burning\")"},
	{"title": "for loops", "sig": "for item in items:", "doc": "Repeat the indented lines once for every item in a list.", "example": "for lamp in green.lamps:\n    lamp.set_lit(True)"},
	{"title": "if and else", "sig": "if condition:", "doc": "Run the indented lines only when the condition is True. else runs when it is not.", "example": "if lamp.lit:\n    print(\"burning\")\nelse:\n    print(\"dark\")"},
	{"title": "Defining a function", "sig": "def name(parameter):", "doc": "Give a few lines a name so you can reuse them. return hands back an answer.", "example": "def light_all(lamps):\n    for lamp in lamps:\n        lamp.set_lit(True)"},
	{"title": "Lists and slices", "sig": "items[:3]", "doc": "A list holds items in order. items[:3] is the first three, items[0] the first one, len(items) how many.", "example": "cells = bridge.cells[:2]\nprint(len(cells))"},
	{"title": "range", "sig": "range(4)", "doc": "range(4) counts 0, 1, 2, 3. Handy for repeating something a set number of times.", "example": "for number in range(3):\n    print(number)"},
	{"title": "print", "sig": "print(value)", "doc": "Shows a value in the output box under the editor. A good way to look inside your program.", "example": "print(world.here.name)"},
	{"title": "Comments", "sig": "# note", "doc": "Everything after # on a line is ignored. Use it to leave yourself notes.", "example": "# light the first lamp\nlamp.set_lit(True)"},
]

const KEYWORDS: Array[String] = ["def", "for", "in", "if", "elif", "else", "while", "return", "and", "or", "not", "True", "False", "None", "pass", "break", "continue"]
const BUILTINS: Array[String] = ["print", "len", "range", "str", "int", "float", "list", "dict", "bool", "min", "max", "sum", "sorted", "enumerate", "zip", "abs", "round", "any", "all"]


## The members of one API type, or [] for an unknown type.
static func members_of(type_name: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not TYPES.has(type_name):
		return result
	for member: Variant in TYPES[type_name].members:
		result.append(member)
	return result


static func is_type(type_name: String) -> bool:
	return TYPES.has(type_name)


## Best-effort guess of which API type a variable holds, from how the program assigns it. Python is
## dynamic, so this only has to be good enough to offer useful completions.
static func infer_type(source: String, variable: String, depth: int = 0) -> String:
	if depth > 4:
		return ""
	if variable == "world":
		return "World"
	var assigned := RegEx.new()
	assigned.compile("(?m)^\\s*" + variable + "\\s*=\\s*([A-Za-z_][A-Za-z0-9_]*)\\.([A-Za-z_]+)")
	var hit: RegExMatch = assigned.search(source)
	if hit != null:
		var from_type: String = infer_type(source, hit.get_string(1), depth + 1) if hit.get_string(1) != variable else ""
		var kind: String = _returns(from_type, hit.get_string(2))
		if kind != "":
			return kind.trim_suffix("[]")
	var looped := RegEx.new()
	looped.compile("(?m)^\\s*for\\s+" + variable + "\\s+in\\s+([A-Za-z_][A-Za-z0-9_]*)\\.([A-Za-z_]+)")
	hit = looped.search(source)
	if hit != null:
		var container: String = infer_type(source, hit.get_string(1), depth + 1)
		var element: String = _returns(container, hit.get_string(2))
		if element.ends_with("[]"):
			return element.trim_suffix("[]")
	var by_name: String = variable.capitalize()
	if variable.ends_with("s") and TYPES.has(variable.trim_suffix("s").capitalize()):
		return ""
	for candidate: String in ["Lamp", "Gate", "Bridge", "Zone", "Prop", "House", "Doodad", "Tree"]:
		if variable == candidate.to_lower() or variable.begins_with(candidate.to_lower() + "_") or variable.ends_with("_" + candidate.to_lower()):
			return candidate
	return by_name if TYPES.has(by_name) else ""


## Every name worth suggesting for a "did you mean" hint: keywords, builtins, API members and the
## player's own identifiers.
static func known_names(source: String) -> Array[String]:
	var names: Array[String] = ["world", "program"]
	names.append_array(KEYWORDS)
	names.append_array(BUILTINS)
	for type_name: String in TYPES:
		for member: Dictionary in TYPES[type_name].members:
			if not names.has(member.name):
				names.append(member.name)
	var identifier := RegEx.new()
	identifier.compile("\\b([A-Za-z_][A-Za-z0-9_]*)\\b")
	for hit: RegExMatch in identifier.search_all(source):
		var word: String = hit.get_string(1)
		if not names.has(word):
			names.append(word)
	return names


static func _returns(type_name: String, member_name: String) -> String:
	for member: Dictionary in members_of(type_name):
		if member.name == member_name:
			return str(member.returns)
	return ""
