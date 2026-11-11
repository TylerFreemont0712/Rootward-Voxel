extends RefCounted
## One-time seed recipes for the concept-matched log cabin and lamppost. world_seed.gd calls these to bootstrap
## the first editable Blender source (`scripts/world-art.sh seed|init`); after adoption each `.blend` is the master
## and these recipes are history, never a way to overwrite it.
##
## Both are drawn from reference/voxel-isometric.png (the violet-roofed cabin and a hanging-lantern post), built
## from rotated boxes like the other seeds. Local frame: ground origin, the cabin's door and lamp arm point +Z,
## the cabin's ridge runs along Z. One unit is one world cell.
##
## A cabin is a handful of sizes. The defaults are the first, 3-cell cabin (`log-cabin`, which must keep
## reproducing its adopted seed); `LARGE` is the 5-cell house (`log-cabin-large`), which only differs in numbers
## and in how many windows, tile rows and roof columns they need.

const COURSE: float = 0.2  ## one log

## The 5-cell house. Each key overrides one default below.
const LARGE: Dictionary = {
	"half_x": 2.26, "half_z": 2.22, "eave": 2.6, "rise": 1.95, "tile_rows": 10, "columns": 12, "ridge_caps": 14,
	"spring": 1.2, "door_radius": 0.43, "window_y": 1.5, "long_windows": [-1.15, 1.15], "front_windows": [-1.45, 1.45],
	"oculus_y": 0.7, "oculus_scale": 1.6, "chimney_scale": 1.3, "chimney_z": -1.1, "gable_courses": 9,
	"purlins": [0.86, 0.63, 0.4, 0.18],
}

var base: float = 0.4  ## top of the limestone foundation, floor of the log walls
var eave: float = 2.2  ## top of the walls
var rise: float = 1.4  ## ridge above the eave
var half_x: float = 1.36  ## outside face of the long walls
var half_z: float = 1.34  ## outside face of the gable walls
var overhang: float = 0.28  ## roof beyond the wall, measured along the slope
var verge: float = 0.26  ## roof beyond the gable walls
var tile_rows: int = 7
var columns: int = 7  ## roof tiles along the ridge
var ridge_caps: int = 9
var spring: float = 1.04  ## where the door's round top begins
var door_radius: float = 0.37
var window_y: float = 1.3
var long_windows: Array = [0.3]  ## z of a window on each long wall
var front_windows: Array = []  ## x of a window each side of the door, front and back
var oculus_y: float = 0.5  ## round window height above the eave
var oculus_scale: float = 1.25
var chimney_scale: float = 1.0
var chimney_z: float = -0.62
var gable_courses: int = 6
var purlins: Array = [0.79, 0.49, 0.21]
var roof: String = "roof"  ## "roof" (violet) or "teal"

var _block: Callable


## `block` is Callable(at: Vector3, size: Vector3, material_id: String, rotation: Vector3 = Vector3.ZERO).
## `style` overrides any of the sizes above (see LARGE); `roof` may be "roof" or "teal".
func _init(block: Callable, style: Dictionary = {}) -> void:
	_block = block
	for key: String in style:
		set(key, style[key])


func _b(at: Vector3, size: Vector3, material_id: String, rotation: Vector3 = Vector3.ZERO) -> void:
	_block.call(at, size, material_id, rotation)


func _foot_x() -> float:
	return half_x + 0.09  # the limestone foundation stands slightly proud of the logs


func _foot_z() -> float:
	return half_z + 0.09


## A palette id for the roof: "" is the base tile, "_light" and "_dark" its tones.
func _tile(tone: String) -> String:
	return roof + tone


## A log lies along x or z. Turned a quarter so the wood grain runs the length of the log, not across it. A pale strip
## along the top edge and a dark one under it, on the side `out` (+1 or -1) faces, round the log off: that is what makes
## a wall read as logs rather than boards.
func _log(at: Vector3, length: float, along_x: bool, material_id: String, out: float, thick: float = 0.14, height: float = COURSE - 0.012) -> void:
	if along_x:
		_b(at, Vector3(height, length, thick), material_id, Vector3(0, 0, PI / 2.0))
		_b(at + Vector3(0, height * 0.36, out * thick * 0.5), Vector3(0.05, length - 0.03, 0.02), "oak_light", Vector3(0, 0, PI / 2.0))
		_b(at + Vector3(0, -height * 0.42, out * thick * 0.5), Vector3(0.04, length - 0.03, 0.014), "wood", Vector3(0, 0, PI / 2.0))
	else:
		_b(at, Vector3(thick, length, height), material_id, Vector3(PI / 2.0, 0, 0))
		_b(at + Vector3(out * thick * 0.5, height * 0.36, 0), Vector3(0.02, length - 0.03, 0.05), "oak_light", Vector3(PI / 2.0, 0, 0))
		_b(at + Vector3(out * thick * 0.5, -height * 0.42, 0), Vector3(0.014, length - 0.03, 0.04), "wood", Vector3(PI / 2.0, 0, 0))


func _pick(index: int) -> String:
	return ["oak_light", "wood_light", "oak", "oak", "oak", "oak", "oak"][absi(index * 7 + index / 3) % 7]


# ====================================================================================================
# Log cabin
# ====================================================================================================
func cabin() -> void:
	_foundation()
	_log_walls()
	_front_door()
	_oculus(Vector3(0, eave + oculus_y, half_z), oculus_scale, 1.0)
	_oculus(Vector3(0, eave + oculus_y, -half_z), oculus_scale * 0.76, -1.0)
	for side: float in [-1.0, 1.0]:
		for z: float in long_windows:
			_side_window(Vector3(side * half_x, window_y, z), side)
	for x: float in front_windows:
		_side_window(Vector3(x, window_y, half_z), 0.0)
		_side_window(Vector3(x, window_y, -half_z), 2.0)
	_roof()
	_chimney()


## Two courses of warm limestone with larger corner quoins, a dark plinth and a two-slab doorstep.
func _foundation() -> void:
	var foot_x: float = _foot_x()
	var foot_z: float = _foot_z()
	_b(Vector3(0, 0.05, 0), Vector3(foot_x * 2.0 + 0.08, 0.1, foot_z * 2.0 + 0.08), "stone_dark")
	_b(Vector3(0, 0.25, 0), Vector3(foot_x * 2.0 - 0.12, 0.3, foot_z * 2.0 - 0.12), "stone_dark")
	var lengths: Array[float] = [0.46, 0.34, 0.52, 0.38, 0.44, 0.3, 0.5, 0.36]
	for course: int in range(2):
		var y: float = 0.17 + float(course) * 0.155
		var h: float = 0.14 + float(course) * 0.01
		for side: float in [-1.0, 1.0]:
			_stone_run(true, side * (foot_z - 0.085), -(foot_x - 0.45), foot_x - 0.45, y, h, lengths, course * 3 + (1 if side > 0.0 else 0), side > 0.0)
			_stone_run(false, side * (foot_x - 0.085), -(foot_z - 0.4), foot_z - 0.4, y, h, lengths, course * 2 + (2 if side > 0.0 else 5), false)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var wide: bool = (course + (1 if sx * sz > 0.0 else 0)) % 2 == 0
				var size := Vector3(0.5 if wide else 0.4, h, 0.4 if wide else 0.5)
				_b(Vector3(sx * (foot_x - size.x * 0.5 + 0.02), y, sz * (foot_z - size.z * 0.5 + 0.02)), size, "stone_warm" if wide else "stone_light")
	var k: float = door_radius / 0.37
	for step: int in range(2):
		_b(Vector3(0, 0.05 + float(step) * 0.1, foot_z + 0.2 - float(step) * 0.08), Vector3((1.2 - float(step) * 0.24) * k, 0.1, 0.4 - float(step) * 0.16), "stone_light" if step == 0 else "stone_warm")


## Blocks of random length laid along one foundation face. The doorway on the front face is left open.
func _stone_run(along_x: bool, fixed: float, start: float, finish: float, y: float, h: float, lengths: Array[float], offset: int, door: bool) -> void:
	var at: float = start
	var index: int = offset
	while at < finish - 0.05:
		var length: float = minf(lengths[index % lengths.size()], finish - at)
		index += 1
		var middle: float = at + length * 0.5
		at += length
		if door and absf(middle) < door_radius + 0.3:
			continue
		var material_id: String = "stone_warm" if index % 3 != 0 else "stone_light"
		if along_x:
			_b(Vector3(middle, y, fixed), Vector3(length - 0.02, h, 0.17), material_id)
		else:
			_b(Vector3(fixed, y, middle), Vector3(0.17, h, length - 0.02), material_id)


## Horizontal log courses with dark chinking between them, set between tall corner posts, and a log-filled gable.
func _log_walls() -> void:
	var rows: int = int(round((eave - base) / COURSE))
	_b(Vector3(0, base + (eave - base) * 0.5, 0), Vector3((half_x - 0.14) * 2.0, eave - base, (half_z - 0.12) * 2.0), "wood_dark")
	for course: int in range(rows):
		var y: float = base + COURSE * (float(course) + 0.5)
		for side: float in [-1.0, 1.0]:
			_log_course(y, true, side * (half_z - 0.07), -(half_x - 0.14), half_x - 0.14, course + (3 if side > 0.0 else 0))
			_log_course(y, false, side * (half_x - 0.07), -half_z, half_z, course * 2 + (1 if side > 0.0 else 4))
	# Gable triangles: each course is shorter than the one below, ending under the roof.
	for course: int in range(gable_courses):
		var low: float = COURSE * float(course)
		var half: float = half_x * (1.0 - (low + COURSE * 0.55) / rise)
		if half < 0.1:
			break
		var y: float = eave + low + COURSE * 0.5
		for side: float in [-1.0, 1.0]:
			_log_course(y, true, side * (half_z - 0.07), -half, half, course + 2 + (4 if side > 0.0 else 0))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_b(Vector3(sx * (half_x - 0.07), (base + eave + 0.06) * 0.5, sz * (half_z - 0.07)), Vector3(0.22, eave - base + 0.06, 0.22), "wood_dark")
			_b(Vector3(sx * (half_x - 0.07), eave + 0.04, sz * (half_z - 0.07)), Vector3(0.26, 0.07, 0.26), "wood")
	# Eave plates carry the roof.
	for side: float in [-1.0, 1.0]:
		_b(Vector3(side * (half_x - 0.02), eave - 0.07, 0), Vector3(0.24, 0.16, half_z * 2.0 + 0.16), "wood_dark")
	# Purlin ends: round log tips poking out beneath each rake, as the concept shows along the gable edges.
	for fraction: float in purlins:
		var x: float = half_x * fraction
		var y: float = eave + rise * (1.0 - fraction) - 0.17
		for side: float in [-1.0, 1.0]:
			for end: float in [-1.0, 1.0]:
				var at := Vector3(side * x, y, end * (half_z + 0.15))
				_b(at, Vector3(0.15, 0.15, 0.34), "oak_light")
				_b(at + Vector3(0, 0, end * 0.001), Vector3(0.15, 0.15, 0.34), "oak_light", Vector3(0, 0, PI / 4.0))


## One course of one wall, cut into logs. Break points move from course to course.
func _log_course(y: float, along_x: bool, fixed: float, start: float, finish: float, variant: int) -> void:
	var span: float = finish - start
	var plan: Array = [[0.34, 0.68], [0.42, 0.7], [0.3, 0.62], [0.38, 0.74]][absi(variant) % 4]
	var cuts: Array[float] = [start]
	if span > 3.4:
		# A long wall needs more joints than a log can span: four logs, the joints sliding course to course.
		for fraction: float in [0.25 + 0.04 * float(absi(variant) % 3), 0.5 + 0.03 * float(absi(variant) % 2), 0.75 - 0.04 * float(absi(variant + 1) % 3)]:
			cuts.append(start + span * fraction)
	elif span > 1.9:
		cuts.append(start + span * float(plan[0]))
		cuts.append(start + span * float(plan[1]))
	elif span > 0.9:
		cuts.append(start + span * (0.4 + 0.1 * float(absi(variant) % 3)))
	cuts.append(finish)
	for index: int in range(cuts.size() - 1):
		var length: float = cuts[index + 1] - cuts[index] - 0.02
		var middle: float = (cuts[index] + cuts[index + 1]) * 0.5
		var at := Vector3(middle, y, fixed) if along_x else Vector3(fixed, y, middle)
		_log(at, length, along_x, _pick(variant * 3 + index), 1.0 if fixed > 0.0 else -1.0)


## Planked door with a four-pane window in its round head, a limestone arch of voussoirs, jambs and an iron latch.
## Everything scales with the door's radius (k across, kv up).
func _front_door() -> void:
	var z: float = half_z + 0.02
	var k: float = door_radius / 0.37
	var kv: float = spring / 1.04
	var planks: int = int(round(door_radius * 2.0 / 0.15))
	for plank: int in range(planks):
		var x: float = (float(plank) - float(planks - 1) * 0.5) * 0.15
		var top: float = spring + sqrt(maxf(0.0, door_radius * door_radius - x * x)) - 0.015
		var bottom: float = 0.14
		_b(Vector3(x, (top + bottom) * 0.5, z), Vector3(0.14, top - bottom, 0.1), "oak_light" if plank % 2 == 0 else "wood_light")
	for y: float in [0.4, 0.84]:
		_b(Vector3(0, y * kv, z + 0.055), Vector3(0.72 * k, 0.05, 0.03), "iron")
	for x: float in [-0.105, 0.105]:
		for y: float in [0.02, 0.18]:
			_b(Vector3(x * k, spring + y * kv, z + 0.055), Vector3(0.16 * k, (0.13 if y < 0.1 else 0.1) * kv, 0.02), "window")
	_b(Vector3(0, spring + 0.11 * kv, z + 0.062), Vector3(0.035, 0.36 * kv, 0.022), "oak")
	_b(Vector3(0, spring + 0.105 * kv, z + 0.062), Vector3(0.38 * k, 0.035, 0.022), "oak")
	_b(Vector3(0.26 * k, 0.64 * kv, z + 0.075), Vector3(0.05, 0.12, 0.04), "gold")
	_b(Vector3(0.26 * k, 0.56 * kv, z + 0.07), Vector3(0.09, 0.03, 0.03), "iron")
	# Jambs: alternating long and short stones up to the springline.
	var rows: int = int(round(spring / 0.208))
	var row_height: float = spring / float(rows)
	for side: float in [-1.0, 1.0]:
		for row: int in range(rows):
			var long: bool = row % 2 == 0
			var width: float = 0.27 if long else 0.2
			_b(Vector3(side * (door_radius + width * 0.5 + 0.005), row_height * 0.5 + float(row) * row_height, half_z + 0.07), Vector3(width, row_height - 0.008, 0.2), "stone_warm" if long else "stone_light")
	# Arch: seven wedge stones round the door's head.
	for index: int in range(7):
		var angle: float = PI * (float(index) + 0.5) / 7.0
		var inner: float = door_radius + 0.115
		var odd: int = index % 2
		var at := Vector3(cos(angle) * inner, spring + sin(angle) * inner, half_z + 0.07 + 0.006 * float(odd))
		_b(at, Vector3(0.225 * inner / 0.485, 0.23, 0.2 + 0.012 * float(odd)), "stone_warm" if odd == 0 else "stone_light", Vector3(0, 0, angle - PI / 2.0))


## A round window set in the gable: ring of limestone, dark panes and a wooden cross.
func _oculus(center: Vector3, scale: float, face: float) -> void:
	var ring: float = 0.27 * scale
	for index: int in range(12):
		var angle: float = float(index) * TAU / 12.0
		var depth: float = 0.1 + (0.012 if index % 2 == 1 else 0.0)
		_b(center + Vector3(cos(angle) * ring, sin(angle) * ring, face * 0.03), Vector3(0.115 * scale, 0.17 * scale, depth), "stone_warm" if index % 3 else "stone_light", Vector3(0, 0, angle))
	var pane: float = 0.4 * scale
	_b(center + Vector3(0, 0, face * -0.01), Vector3(pane, pane, 0.05), "window")
	_b(center + Vector3(0, 0, face * -0.008), Vector3(pane, pane, 0.05), "window", Vector3(0, 0, PI / 4.0))
	_b(center + Vector3(0, 0, face * 0.035), Vector3(0.04, 0.46 * scale, 0.03), "oak")
	_b(center + Vector3(0, 0, face * 0.036), Vector3(0.46 * scale, 0.04, 0.03), "oak")


## A warm-lit window: four heavy timber border bars round a recessed glowing pane, a wooden cross, a log lintel and
## a limestone sill. `face` is a quarter turns about the vertical axis: 0 front, 1 and -1 the long walls, 2 the back.
func _side_window(center: Vector3, face: float) -> void:
	var turn := Vector3(0, face * PI / 2.0, 0)
	var basis: Basis = Basis.from_euler(turn)
	_b(center + basis * Vector3(0, 0, 0.03), Vector3(0.46, 0.58, 0.05), "window_glow", turn)
	for x: float in [-0.275, 0.275]:
		_b(center + basis * Vector3(x, 0, 0.02), Vector3(0.09, 0.76, 0.12), "wood_dark", turn)
	for y: float in [-0.335, 0.335]:
		_b(center + basis * Vector3(0, y, 0.02), Vector3(0.46, 0.09, 0.12), "wood_dark", turn)
	_b(center + basis * Vector3(0, 0, 0.065), Vector3(0.04, 0.58, 0.04), "oak", turn)
	_b(center + basis * Vector3(0, 0.01, 0.066), Vector3(0.46, 0.04, 0.04), "oak", turn)
	_b(center + basis * Vector3(0, 0.47, 0.03), Vector3(0.84, 0.15, 0.17), "wood", turn)
	_b(center + basis * Vector3(0, -0.42, 0.07), Vector3(0.78, 0.09, 0.22), "stone_warm", turn)


## Steep two-slope roof of chunky tiles: a dark underlay, staggered rows with a lighter lip on every tile,
## dark fascia, a wooden ridge capped in tile and a limestone finial on the front peak.
func _roof() -> void:
	var slope: float = atan2(rise, half_x)
	var run: float = sqrt(half_x * half_x + rise * rise) + overhang
	var length: float = (half_z + verge) * 2.0
	var ridge := Vector3(0, eave + rise, 0)
	for side: float in [-1.0, 1.0]:
		var along := Vector3(side * cos(slope), -sin(slope), 0)
		var normal := Vector3(side * sin(slope), cos(slope), 0)
		var tilt := Vector3(0, 0, -side * slope)
		_b(ridge + along * (run * 0.5) + normal * 0.06, Vector3(run, 0.12, length), _tile("_dark"), tilt)
		var pitch: float = (run - 0.1) / float(tile_rows)
		for row: int in range(tile_rows):
			var d: float = 0.12 + pitch * (float(row) + 0.5)
			var lift: float = 0.12 + float(tile_rows - 1 - row) * 0.01
			var width: float = length / float(columns)
			var cuts: Array[float] = []
			if row % 2 == 0:
				for column: int in range(columns + 1):
					cuts.append(-length * 0.5 + float(column) * width)
			else:
				cuts.append(-length * 0.5)
				for column: int in range(columns):
					cuts.append(-length * 0.5 + (float(column) + 0.5) * width)
				cuts.append(length * 0.5)
			for column: int in range(cuts.size() - 1):
				var z: float = (cuts[column] + cuts[column + 1]) * 0.5
				var span: float = cuts[column + 1] - cuts[column] - 0.015
				var shade: int = (row * 17 + column * 13 + int(side) * 5) % 11
				var tile_id: String = _tile("_light") if shade < 2 else (_tile("_dark") if shade > 9 else _tile(""))
				_b(ridge + along * d + normal * (lift + 0.048) + Vector3(0, 0, z), Vector3(pitch + 0.05, 0.096, span), tile_id, tilt)
				var lip_id: String = _tile("") if shade == 5 else _tile("_light")
				_b(ridge + along * (d + pitch * 0.5 - 0.014) + normal * (lift + 0.07) + Vector3(0, 0, z), Vector3(0.085, 0.14, span - 0.012), lip_id, tilt)
		# Fascia along the eave and under each verge.
		_b(ridge + along * (run - 0.04) + normal * 0.02, Vector3(0.09, 0.2, length), "wood_dark", tilt)
		for end: float in [-1.0, 1.0]:
			_b(ridge + along * (run * 0.5) + normal * -0.03 + Vector3(0, 0, end * (half_z + verge - 0.05)), Vector3(run, 0.13, 0.1), "wood", tilt)
	_b(ridge + Vector3(0, 0.02, 0), Vector3(0.2, 0.18, length + 0.16), "wood_dark")
	for column: int in range(ridge_caps):
		var z: float = -length * 0.5 + (float(column) + 0.5) * length / float(ridge_caps)
		_b(ridge + Vector3(0, 0.12, z), Vector3(0.36, 0.1, length / float(ridge_caps) - 0.02), _tile("_dark") if column % 2 == 0 else _tile(""))
	_b(ridge + Vector3(0, -0.06, length * 0.5 - 0.02), Vector3(0.22, 0.34, 0.22), "stone_warm")
	_b(ridge + Vector3(0, 0.14, length * 0.5 - 0.02), Vector3(0.28, 0.07, 0.28), "stone_light")


## A square limestone stack on the ridge, laid in courses with a dark flue.
func _chimney() -> void:
	var z: float = chimney_z
	var cs: float = chimney_scale
	var floor_y: float = eave + rise - 0.4
	var courses: int = int(round(8.0 * cs))
	for course: int in range(courses):
		var y: float = floor_y + 0.08 + float(course) * 0.16
		var wide: bool = course % 2 == 0
		var size: float = (0.52 if wide else 0.5) * cs
		_b(Vector3(0, y, z), Vector3(size, 0.155, size), "stone_warm" if course % 3 != 1 else "stone_light")
		for face: float in [-1.0, 1.0]:
			_b(Vector3(face * (size * 0.5 + 0.001), y, z + (0.1 if wide else -0.12) * cs), Vector3(0.012, 0.155, 0.015), "stone_dark")
			_b(Vector3((0.12 if wide else -0.1) * cs, y, z + face * (size * 0.5 + 0.001)), Vector3(0.015, 0.155, 0.012), "stone_dark")
	var top: float = floor_y + 0.08 + float(courses) * 0.16
	_b(Vector3(0, top, z), Vector3(0.64 * cs, 0.1, 0.64 * cs), "stone_warm")
	_b(Vector3(0, top + 0.07, z), Vector3(0.62 * cs, 0.05, 0.62 * cs), "stone_light")
	_b(Vector3(0, top + 0.1, z), Vector3(0.3 * cs, 0.02, 0.3 * cs), "iron")


# ====================================================================================================
# Lamppost
# ====================================================================================================
const POST_X: float = -0.27
const PLINTH_X: float = 0.22
const LANTERN_Z: float = 0.62

## A timber post on an iron foot beside a limestone pedestal, with an arm that carries a hanging lantern whose glass
## is its own material so the game can light it. The concept's conifer is left out: no shrubs in this prototype.
func lamppost() -> void:
	_pedestal()
	_b(Vector3(POST_X, 0.2, 0), Vector3(0.38, 0.4, 0.38), "iron")
	_b(Vector3(POST_X, 0.465, 0), Vector3(0.27, 0.13, 0.27), "iron")
	_b(Vector3(POST_X, 0.43, 0), Vector3(0.3, 0.03, 0.3), "stone_dark")
	_b(Vector3(POST_X, 1.375, 0), Vector3(0.17, 1.74, 0.17), "wood")
	_b(Vector3(POST_X + 0.088, 1.375, 0.012), Vector3(0.02, 1.74, 0.08), "wood_dark")
	_b(Vector3(POST_X - 0.012, 1.375, 0.088), Vector3(0.08, 1.74, 0.02), "wood_light")
	_b(Vector3(POST_X, 2.3, 0), Vector3(0.24, 0.13, 0.24), "iron")
	_b(Vector3(POST_X, 2.39, 0), Vector3(0.15, 0.05, 0.15), "iron")
	# Arm, brace and the hook the lantern hangs from.
	_b(Vector3(POST_X, 2.12, 0.2875), Vector3(0.1, 0.1, 0.665), "wood_dark")
	_b(Vector3(POST_X, 1.9, 0.23), Vector3(0.08, 0.08, 0.523), "wood_dark", Vector3(-0.758, 0, 0))
	_b(Vector3(POST_X, 2.12, LANTERN_Z), Vector3(0.12, 0.12, 0.12), "iron")
	_b(Vector3(POST_X, 2.04, LANTERN_Z), Vector3(0.05, 0.1, 0.05), "iron")
	_lantern(Vector3(POST_X, 1.66, LANTERN_Z))


## `at` is the middle of the glass. Four corner posts and a pane between a pitched cap and a tapering base.
func _lantern(at: Vector3) -> void:
	_b(at + Vector3(0, 0.33, 0), Vector3(0.22, 0.05, 0.22), "wood_dark")
	_b(at + Vector3(0, 0.28, 0), Vector3(0.38, 0.05, 0.38), "wood")
	_b(at + Vector3(0, 0.225, 0), Vector3(0.52, 0.06, 0.52), "wood_dark")
	_b(at + Vector3(0, 0.165, 0), Vector3(0.45, 0.06, 0.45), "wood")
	_b(at, Vector3(0.35, 0.36, 0.35), "lamp_glass")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_b(at + Vector3(sx * 0.2, 0, sz * 0.2), Vector3(0.065, 0.4, 0.065), "wood_dark")
	_b(at + Vector3(0, -0.205, 0), Vector3(0.45, 0.05, 0.45), "wood_dark")
	_b(at + Vector3(0, -0.265, 0), Vector3(0.34, 0.06, 0.34), "wood")
	_b(at + Vector3(0, -0.32, 0), Vector3(0.2, 0.05, 0.2), "wood_dark")
	_b(at + Vector3(0, -0.36, 0), Vector3(0.09, 0.05, 0.09), "iron")


## Pinwheel masonry: four blocks round a square, turned a quarter each course so the joints break.
func _pedestal() -> void:
	_b(Vector3(PLINTH_X, 0.2, 0), Vector3(0.52, 0.4, 0.52), "stone_dark")
	for course: int in range(2):
		var y: float = 0.085 + float(course) * 0.165
		for index: int in range(4):
			var turn: int = (index + course) % 4
			var angle: float = float(turn) * PI / 2.0
			var offset := Vector2(-0.13, 0.17).rotated(angle)
			var long: Vector2 = Vector2(0.34, 0.26) if turn % 2 == 0 else Vector2(0.26, 0.34)
			_b(Vector3(PLINTH_X + offset.x, y, offset.y), Vector3(long.x - 0.03, 0.15, long.y - 0.03), "stone_warm" if (index + course) % 3 else "stone_light")
	_b(Vector3(PLINTH_X, 0.395, 0), Vector3(0.66, 0.1, 0.66), "stone_warm")
	_b(Vector3(PLINTH_X, 0.455, 0), Vector3(0.5, 0.02, 0.5), "stone_light")
