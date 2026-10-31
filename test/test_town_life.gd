extends SceneTree
## Authored crowd coverage, no Nell/clones, shared tram service, asymmetric player collision and coherent local rounds.
const Skins := preload("res://art/frame_skin.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var skins: Dictionary = Skins.read_library().skins
	var cast: Array[String] = []
	var models: Dictionary = {}
	var phantoms: int = 0
	for id: String in ["workshop-loft", "workshop-floor", "haverlund-lane", "haverlund-square"]:
		var area: AreaDef = AreaStore.load_area(id)
		_check(area != null, id + " loads")
		if area == null: continue
		var rules := LabWorld.new(area)
		var world: Dictionary = rules.initial_state()
		var reserved: Dictionary = VillageLife.reserved(area)
		for person: Dictionary in area.villagers:
			_check(rules.is_walkable(world, person.at) and not reserved.has(person.at), str(person.id) + " has an open start")
			_check(person.id != "sparks-nell" and person.get("skin", "") not in ["nell", "sparks_nell"], "Nell is absent until the story introduces her")
			if person.has("skin"):
				_check(skins.has(person.skin) and str(person.skin).begins_with("sparks_") and not cast.has(person.skin), "Only one of each Sparks cast sprite is placed")
				cast.append(person.skin)
			elif person.has("phantom"): phantoms += 1
			else:
				for item: Dictionary in area.interior.assets:
					if item.id == person.object: models[item.asset] = true
			var avoid: Dictionary = reserved.duplicate()
			if person.has("arrival"):
				for cell: Vector2i in VillageLife.departure_cells(area, person.arrival.exit): avoid.erase(cell)
			var from: Vector2i = person.at
			for target: Vector2i in person.route:
				var path: Array[Vector2i] = rules.find_path(world, target, from, avoid)
				_check(not avoid.has(target) and (target == from or not path.is_empty()), person.id + " reaches stop " + str(target))
				for cell: Vector2i in path:
					_check(rules.can_step(world, from, cell), "Every route uses legal passages")
					from = cell
		var life: Dictionary = VillageLife.initial(area)
		var twin: Dictionary = life.duplicate(true)
		var safe: bool = true
		var moving: Dictionary = {}
		for tick: int in range(1800):
			VillageLife.advance(area, rules, world, life, .05)
			VillageLife.advance(area, rules, world, twin, .05)
			var occupied: Dictionary = {}
			for person_id: String in life:
				var person: Dictionary = life[person_id]
				for cell: Vector2i in VillageLife.cells(person):
					safe = safe and not occupied.has(cell) and rules.is_walkable(world, cell)
					occupied[cell] = true
				if person.active and person.phase < 1.0: moving[person_id] = true
		_check(safe and life == twin, id + " has deterministic collision-free motion for 90 seconds")
		for person: Dictionary in area.villagers: _check(moving.has(person.id), person.id + " actually moves")
		var initial: Dictionary = VillageLife.initial(area)
		if not area.villagers.is_empty():
			world.player = [area.villagers[0].at.x, area.villagers[0].at.y, 0]
			var before: Dictionary = world.duplicate(true)
			VillageLife.clear_arrival(area, rules, world, initial, {})
			_check(world == before and not VillageLife.occupied(initial, true).has(Vector2i(world.player[0], world.player[1])), "Continue moves a solid resident aside without changing player progress")
	_check(cast.size() == 2 and cast.has("sparks_mira") and cast.has("sparks_rowan") and phantoms == 23 and models.size() == 6, "Mira/Rowan only in the square, eighteen square phantoms, two lane kids and a three-adult passenger pool")
	_service()
	_art()
	_invalid()
	if failures.is_empty(): print("Town life: %d checks passed." % checks)
	else:
		for failure: String in failures: printerr("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _service() -> void:
	var area: AreaDef = AreaStore.load_area("haverlund-lane")
	_check(not area.villagers.any(func(person: Dictionary) -> bool: return person.has("skin")), "The lane has no named characters")
	var rules := LabWorld.new(area)
	var world: Dictionary = rules.initial_state()
	var life: Dictionary = VillageLife.initial(area)
	var arrivals: Dictionary = {}
	var departed: int = 0
	var correct: bool = true
	var safe: bool = true
	var non_solid: bool = true
	for tick: int in range(7200):
		var before: Dictionary = life.duplicate(true)
		VillageLife.advance(area, rules, world, life, .05)
		var occupied: Dictionary = {}
		for id: String in life:
			var resident: Dictionary = life[id]
			for cell: Vector2i in VillageLife.cells(resident):
				safe = safe and not occupied.has(cell)
				occupied[cell] = true
			if not resident.player_solid:
				for cell: Vector2i in VillageLife.cells(resident): non_solid = non_solid and not VillageLife.occupied(life, true).has(cell)
			if not id.begins_with("tram-"): continue
			if not before[id].active and resident.active:
				var schedule: Dictionary = TramSchedule.sample(area.interior.life.tram, resident.clock)
				correct = correct and schedule.docked and is_equal_approx(float(schedule.x), 19.45)
				arrivals[resident.cycle] = int(arrivals.get(resident.cycle, 0)) + 1
			if before[id].active and not resident.active:
				departed += 1
				correct = correct and resident.at in [Vector2i(12,26), Vector2i(13,26)] and resident.presence == 0.0
	_check(correct and arrivals.get(0,0) == 3 and arrivals.get(1,0) == 2 and arrivals.get(2,0) == 3 and arrivals.get(3,0) == 2, "Docked trams deliver staggered groups of three, two, three, two adults")
	_check(departed >= 10, "Passengers reach the gate and disappear before the next service")
	_check(safe and non_solid, "Passengers and kids never overlap other residents/robots, and never block the player")
	var kids: Array = area.villagers.filter(func(person: Dictionary) -> bool: return person.get("phantom") == "child")
	_check(kids.size() == 2, "Exactly two resident phantom kids on the lane")
	var initial: Dictionary = VillageLife.initial(area)
	world.player = [kids[0].at.x, kids[0].at.y, 0]
	var blocked: Dictionary = {kids[0].at:true, kids[0].at+Vector2i.RIGHT:true}
	VillageLife.clear_arrival(area, rules, world, initial, blocked)
	_check(initial[kids[0].id].at == kids[0].at and not VillageLife.occupied(initial,true).has(kids[0].at), "The player may stand inside a phantom without displacement or collision")
	var schedule: Dictionary = TramSchedule.sample(area.interior.life.tram, 0)
	_check(schedule.docked and schedule.at_stop == 3.0, "The first visit uses the existing tram offset, not an unrelated timer")

func _art() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/phantoms/manifest.json"))
	_check(manifest.profiles.size() == 3 and manifest.opacity >= .94 and manifest.opacity <= 1.0, "Three gray painted appearances are almost opaque, without a ghost effect")
	var hashes: Array[String] = []
	for id: String in manifest.profiles:
		var profile: Dictionary = manifest.profiles[id]
		_check(not hashes.has(profile.atlas_sha256), id + " has a distinct silhouette")
		hashes.append(profile.atlas_sha256)
		var frames := load(profile.frames) as SpriteFrames
		_check(frames != null and frames.get_animation_names().size() == 8, id + " has four walking and four idle animations")
		for direction: String in ["se","sw","ne","nw"]:
			_check(frames.get_frame_count("walk_"+direction) == 8 and frames.get_frame_count("idle_"+direction) == (2 if direction in ["se","sw"] else 1), "Original painted gait and idle layout")
		var original := Image.load_from_file(ProjectSettings.globalize_path(profile.painted_source))
		var mask := Image.load_from_file(ProjectSettings.globalize_path(profile.atlas))
		original.convert(Image.FORMAT_RGBA8)
		mask.convert(Image.FORMAT_RGBA8)
		var source_pixels: PackedByteArray = original.get_data()
		var mask_pixels: PackedByteArray = mask.get_data()
		var exact: bool = source_pixels.size() == mask_pixels.size()
		var flat: bool = true
		for index: int in range(0, mini(source_pixels.size(),mask_pixels.size()), 4):
			exact = exact and source_pixels[index+3] == mask_pixels[index+3]
			flat = flat and mask_pixels[index] == 255 and mask_pixels[index+1] == 255 and mask_pixels[index+2] == 255
		_check(exact and flat, id + " preserves every source alpha pixel and only flattens the colors")
		var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/adventurer/manifest.json"))
		_check(profile.animations == template.animations and profile.fps == template.fps and profile.pixel_size == template.pixel_size, "Exact common timing, regions and anchors are retained")

func _invalid() -> void:
	var source: Dictionary = AreaStore.read_source("haverlund-lane")
	for fields: Dictionary in [{"phantom":"unknown"},{"phantom":"man","skin":"sparks_bram"},{"phantom":"child","arrival":{"delay":2,"exit":"town-steps"}},
		{"phantom":"man","arrival":{"delay":99,"exit":"town-steps"}},{"phantom":"woman","arrival":{"delay":2,"exit":"missing"}},
		{"skin":"sparks_bram","speed":2},{"phantom":"man","wander":"yes"}]:
		var bad: Dictionary = source.document.duplicate(true)
		var person: Dictionary = {"id":"bad", "at":[20,2], "route":[[13,26]]}
		person.merge(fields,true)
		bad.villagers = [person]
		_check(not AreaDef.parse(bad,source.assets,source.quests).ok, "Invalid phantom appearance, timetable or motion is rejected")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
