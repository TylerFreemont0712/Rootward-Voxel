class_name ClearingView
extends Node3D
## Fixed-angle orthographic 3D presentation of one area document. Rules and collision live in LabWorld.
## Static cubes share one MultiMesh per material and map chunk; only interactive parts are nodes.
## `setup(area)` builds the world; the seed recipes further down are one-time bootstraps for Blender.

## FREE is build mode's camera: it stays where it is panned to.
enum CameraMode { FOLLOW, CINEMATIC, FIXED, FREE }

const WorldAssets := preload("res://art/world_assets.gd")
## The most models a program's preview draws for houses, trees and doodads.
const MAX_PREVIEW_MODELS: int = 48
const SurfaceMaterials := preload("res://art/surface_materials.gd")
const SpriteActor := preload("res://art/sprite_actor.gd")

const PALETTE: Dictionary = preload("res://art/world_palette.gd").COLORS
## Camera offset from its focus point: the diagonal heading and about 31 degrees of elevation.
const CAMERA_OFFSET: Vector3 = Vector3(21.0, 17.8, 21.0)
const CHUNK: int = 16
const LIGHT_POOL: int = 6
## Flat ground never needs to cast shadows, and skipping it keeps the shadow pass cheap.
const NO_SHADOW: Array[String] = ["grass", "grass_light", "grass_dark", "soil", "soil_dark", "dirt", "dirt_light", "dirt_dark", "water", "path_dark"]

var area: AreaDef
var ground_skin: GroundSkin
var villagers: VillagerView
var water_surface: WaterSurface
var camera: Camera3D
var camera_mode: CameraMode = CameraMode.FOLLOW
## Smoothing rate of the follow camera; larger is snappier.
var follow_rate: float = 5.5
var _materials: Dictionary = {}
## The same palette for parts that move or stand alone: pictures follow the mesh instead of the world.
var _part_materials: Dictionary = {}
var _batches: Dictionary = {}
## What is drawn of the player's edits, so a change adds and removes only what differs: buildings by id,
## trees by position key (to the chunk that draws them), and the nodes of each tree chunk.
var _drawn_buildings: Dictionary = {}
var _entrance_surfaces: Array[Dictionary] = []
var _prop_visuals: Dictionary = {}
var _drawn_trees: Dictionary = {}
var _tree_nodes: Dictionary = {}
var _asset_tree_nodes: Dictionary = {}
var _tree_styles: Dictionary = {}
var _tree_root: Node3D
## Generated land, drawn per chunk of cells so shaping the land redraws only what it touched: {chunk: [nodes]}.
var _terrain_root: Node3D
var _terrain_nodes: Dictionary = {}
var _chunk: int = 0
var _content: Node3D
var _area_presentation: Dictionary = {}
var _decks: Dictionary = {}
var _lamps: Dictionary = {}
var _gates: Dictionary = {}
var _wheels: Array[Node3D] = []
var _player: Node3D
var _player_cells: Dictionary = {}
var _body: Node3D
var hotaru: HotaruFairy
## A room's own story presentation (RoomStage.for_area); null in every room that has none.
var stage: RoomStage
var _selection: Node3D
var _route_visual: Node3D
var _ghost: Node3D
var _quest_marker: Node3D
var _committed: Dictionary = {}
var _art_transform: Transform3D = Transform3D.IDENTITY
var _elapsed: float = 0.0
var _ghost_material: ShaderMaterial
var _ghost_edge_material: ShaderMaterial
var _removed_material: ShaderMaterial
var _removed_edge_material: ShaderMaterial
var _sun: DirectionalLight3D
var _environment: Environment
var _lamp_lights: Array[OmniLight3D] = []
var _lit_positions: Array[Vector3] = []
var _focus: Vector3 = Vector3.ZERO
var _focus_target: Vector3 = Vector3.ZERO
var _zoom_target: float = 13.0
var _view_shift: float = 0.0
var _view_shift_target: float = 0.0
## An outdoor room's own sun, sky and painted distance (area interior.outdoor); empty everywhere else.
var _outdoor: Dictionary = {}
var _backdrop: OutdoorBackdrop
var _warmth: float = 0.3
var _warmth_target: float = 0.3
var _warmth_from_state: bool = true
var _light_focus: Vector3 = Vector3(1e6, 0, 0)
var _cinematic_time: float = 0.0
var _marker_cell: Variant = null
var _marker_hidden: bool = false
var terminal_display: ZoneTerminalDisplay
## "paper" gives the Sparks journey round, outlined route dots, a lit destination and a brass-dial job mark; "" keeps
## the original square gold route and tiled ring everywhere else.
var marker_style: String = ""
var _highlighted: Node3D
var _highlight_material: ShaderMaterial
var _motes: Array[Dictionary] = []


func _ready() -> void:
	_make_materials()
	_make_lighting()


func _make_materials() -> void:
	_materials = SurfaceMaterials.build(PALETTE)
	var water := ShaderMaterial.new()
	water.shader = preload("res://art/water.gdshader")
	water.set_shader_parameter("water_texture", WorldTextures.texture("water"))
	_materials["water"] = water
	var glow: StandardMaterial3D = SurfaceMaterials.painted("lit", Color("ffe6a5"))
	if glow.albedo_texture == null:
		glow.emission_enabled = true
		glow.emission = Color("ffcb7b")
		glow.emission_energy_multiplier = 1.3
	_materials["lit"] = glow
	_part_materials = _materials.duplicate()
	_part_materials.merge(SurfaceMaterials.build(PALETTE, false), true)
	# A proposal is a pulsing blue ghost; what a program would take away is the same ghost in coral.
	_ghost_material = _ghost_shader_material(PaperPal.GHOST, false)
	_ghost_edge_material = _ghost_shader_material(PaperPal.GHOST, true)
	_removed_material = _ghost_shader_material(Color(0.96, 0.56, 0.45), false)
	_removed_edge_material = _ghost_shader_material(Color(0.96, 0.56, 0.45), true)


func _ghost_shader_material(tint: Color, edges: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/ghost.gdshader")
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("edges", edges)
	return material


func _make_lighting() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)
	_sun = DirectionalLight3D.new()
	_sun.name = "LateAfternoonSun"
	_sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	_sun.shadow_enabled = true
	_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_sun.directional_shadow_max_distance = 60.0
	_sun.shadow_bias = 0.035
	add_child(_sun)
	camera = Camera3D.new()
	camera.name = "IsometricCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = _zoom_target
	camera.far = 140.0
	add_child(camera)
	camera.position = _focus + CAMERA_OFFSET
	camera.look_at(_focus)
	camera.current = true
	_apply_warmth(_warmth)


## 0 is a cool blue hour with the lamps out; 1 is warm late sun. Lamps lit by the player push it up.
func set_warmth(value: float, follow_state: bool = false) -> void:
	_warmth_target = clampf(value, 0.0, 1.0)
	_warmth_from_state = follow_state


func _apply_warmth(w: float) -> void:
	if _environment == null:
		return
	if not _outdoor.is_empty():
		# An outdoor room keeps its own daylight; warmth is a valley's evening and does not reach it.
		_environment.background_color = Color(str(_outdoor.haze))
		_environment.ambient_light_color = Color(str(_outdoor.ambient.color))
		_environment.ambient_light_energy = float(_outdoor.ambient.energy)
		_sun.light_color = Color(str(_outdoor.sun.color))
		_sun.light_energy = float(_outdoor.sun.energy)
		return
	# The void around the valley stays a deep teal night; warmth only lifts it a little.
	_environment.background_color = Color("0f161d").lerp(Color("2a3a40"), w)
	_environment.ambient_light_color = Color("98a6c2").lerp(Color("bbc9df"), w)
	_environment.ambient_light_energy = lerpf(0.5, 0.38, w)
	_sun.light_color = Color("c4d0f0").lerp(Color("fff0d8"), w)
	_sun.light_energy = lerpf(0.62, 0.85, w)


# ----------------------------------------------------------------- camera
func set_camera_mode(mode: CameraMode) -> void:
	camera_mode = mode


func set_zoom(size: float) -> void:
	_zoom_target = clampf(size, 7.0, 24.0)


func zoom() -> float:
	return _zoom_target


## Slides the focus sideways so the player stays centered in the part of the window no panel covers.
## 0.15 shifts the camera by 15% of the view width toward the panel.
func set_view_shift(fraction: float) -> void:
	_view_shift_target = fraction


## Moves the focus to a cell. `instant` also skips the glide, for a new game or a teleport.
func focus_on(cell: Vector2, instant: bool = false) -> void:
	_focus_target = _clamped_focus(Vector3(cell.x, ground_y(cell), -cell.y))
	if instant:
		_focus = _focus_target
		_place_camera()


## The focus keeps its height, so the camera rises with the player climbing a terrace.
func _clamped_focus(point: Vector3) -> Vector3:
	if area == null:
		return point
	if bool(area.interior.get("camera_floor_lock", false)): point.y = 0.0
	var margin: float = 5.0
	return Vector3(clampf(point.x, margin, float(area.width - 1) - margin), point.y, clampf(point.z, -(float(area.height - 1) - margin), -margin))


## How high the ground stands under a logical point, in world units: its land level, or partway up a flight of stairs.
func ground_y(point: Vector2) -> float:
	return area.ground_level(point) * TerrainBuilder.LEVEL_RISE if area != null else 0.0


func _place_camera() -> void:
	var aspect: float = 16.0 / 10.0
	if is_inside_tree() and get_viewport() != null:
		var rect: Vector2 = get_viewport().get_visible_rect().size
		aspect = rect.x / maxf(1.0, rect.y)
	camera.h_offset = _view_shift * camera.size * aspect
	camera.position = _focus + CAMERA_OFFSET


func _update_camera(delta: float) -> void:
	match camera_mode:
		CameraMode.FREE:
			_focus_target = _clamped_focus(_focus_target)
		CameraMode.FOLLOW:
			if _player != null:
				_focus_target = _clamped_focus(_player.position)
		CameraMode.CINEMATIC:
			_cinematic_time += delta
			var t: float = _cinematic_time
			# A slow loop from the green, over the mill race and back, so the title screen never sits still.
			var centre := Vector3(33.0, 0.0, -19.5) if area==null or area.id=="kindle-hollow" else Vector3(float(area.width)*.5,0,-float(area.height)*.5)
			_focus_target = _clamped_focus(centre + Vector3(sin(t * 0.045) * 11.0, 0.0, cos(t * 0.031) * 3.5 - sin(t * 0.045) * 1.5))
	var blend: float = 1.0 - exp(-delta * follow_rate)
	_focus = _focus.lerp(_focus_target, blend)
	camera.size = lerpf(camera.size, _zoom_target, 1.0 - exp(-delta * 6.0))
	_view_shift = lerpf(_view_shift, _view_shift_target, 1.0 - exp(-delta * 8.0))
	_place_camera()


# ------------------------------------------------------------------ build
## Builds the whole area from its document. Call once, after the view has entered the tree.
func setup(definition: AreaDef) -> void:
	if _content != null:
		remove_child(_content)
		_content.queue_free()
		_decks.clear()
		_lamps.clear()
		_gates.clear()
		_wheels.clear()
		_drawn_buildings.clear()
		_prop_visuals.clear()
		_drawn_trees.clear()
		_tree_nodes.clear()
		_asset_tree_nodes.clear()
		_tree_styles.clear()
		_lamp_lights.clear()
		_lit_positions.clear()
		_terrain_nodes.clear()
	area = definition
	_set_outdoor(area.interior.get("outdoor", {}) as Dictionary if area.interior.get("outdoor") is Dictionary else {})
	_area_presentation = WorldAssets.area_presentation(area.id)
	_refresh_entrance_surfaces()
	_chunk = CHUNK
	_content = Node3D.new()
	_content.name = "Area_" + area.id.replace("-", "_")
	add_child(_content)
	ground_skin = null
	water_surface = null
	villagers = null
	_terrain_root = null
	if not area.interior.is_empty():
		InteriorBuilder.build(area, _block, _try_world_asset)
	elif area.ground.is_empty():
		var skin := GroundSkin.new()
		if skin.build(area):
			ground_skin = skin
			_content.add_child(skin)
		else:
			skin.free()
		TerrainBuilder.foundation(area, _block)
		TerrainBuilder.segments(area, _block)
		VillageBoundary.build(_content, area, _materials["grass_dark"], _make_tree)
	else:
		_try_world_asset(String(area.ground.asset), Vector3.ZERO)
	if area.interior.is_empty():
		water_surface = WaterSurface.new()
		_content.add_child(water_surface)
		water_surface.build(area)
	for building: Dictionary in _built_things():
		_place_building(building)
	_flush_batches()
	if area.interior.is_empty() and area.ground.is_empty():
		# The cells are drawn chunk by chunk, so shaping the land redraws only the chunks it touched.
		_terrain_root = Node3D.new()
		_terrain_root.name = "Terrain"
		_content.add_child(_terrain_root)
		for cy: int in range(0, area.height, CHUNK):
			for cx: int in range(0, area.width, CHUNK):
				_rebuild_terrain_chunk(Vector2i(cx / CHUNK, cy / CHUNK))
				BuildPump.pump()
	_tree_root = Node3D.new()
	_tree_root.name = "Trees"
	_content.add_child(_tree_root)
	_sync_trees()
	_make_mechanisms()
	_make_player()
	terminal_display = null
	if not area.terminals.is_empty():
		terminal_display = ZoneTerminalDisplay.new()
		_content.add_child(terminal_display)
		terminal_display.setup(self)
	stage = RoomStage.for_area(area)
	if stage != null:
		_content.add_child(stage)
		stage.setup(self)
	hotaru = null
	if stage == null or not stage.replaces_companion():
		hotaru=HotaruFairy.new()
		hotaru.target=_player
		_content.add_child(hotaru)
	_selection = Node3D.new()
	_selection.name = "CellSelection"
	_content.add_child(_selection)
	_route_visual = Node3D.new()
	_route_visual.name = "RouteMarkers"
	_content.add_child(_route_visual)
	_ghost = Node3D.new()
	_ghost.name = "PreviewGhosts"
	_content.add_child(_ghost)
	_make_quest_marker()
	_make_light_pool()
	if not area.villagers.is_empty():
		villagers = VillagerView.new()
		_content.add_child(villagers)
		villagers.setup(self)
	focus_on(Vector2(area.spawn), true)
	apply_state({"player": [area.spawn.x, area.spawn.y, 0], "lamps": {}, "gates": {}, "bridges": {}})


## Daylight and the painted distance for an outdoor room, or the shared valley light everywhere else. The view
## outlives each area, so a room that has none puts the sun back where it was.
func _set_outdoor(outdoor: Dictionary) -> void:
	_outdoor = outdoor
	if is_instance_valid(_backdrop):
		# Out of the tree at once, so a room set up again this frame never finds its predecessor.
		_backdrop.get_parent().remove_child(_backdrop)
		_backdrop.queue_free()
	_backdrop = null
	if _outdoor.is_empty():
		_sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	else:
		var turn: Array = _outdoor.sun.rotation
		_sun.rotation_degrees = Vector3(float(turn[0]), float(turn[1]), float(turn[2]))
		if _outdoor.has("backdrop"):
			_backdrop = OutdoorBackdrop.new()
			_backdrop.name = "PaintedDistance"
			camera.add_child(_backdrop)
			if not _backdrop.setup(self, _outdoor):
				_backdrop.queue_free()
				_backdrop = null
	_apply_warmth(_warmth)


## Whether a companion is here to talk to: the fairy, or the room stage's own companion.
func companion_present() -> bool:
	return is_instance_valid(hotaru) or (stage != null and is_instance_valid(stage.companion_node()))


## Where a speech mark sits over the companion, in world space; null when there is none.
func companion_anchor() -> Variant:
	if is_instance_valid(hotaru):
		return hotaru.global_position + Vector3(0, .1, 0)
	if stage != null and is_instance_valid(stage.companion_node()):
		return stage.companion_anchor()
	return null


## The player's node, for presenters that follow or face the apprentice.
func player_node() -> Node3D:
	return _player


# --------------------------------------------------------------- the player's edits
## Brings what is drawn in line with a new area (after a placement, a move, an undo or a load), touching only
## what differs. A new or moved building pops into place and a removed one shrinks away when `animate` is set.
func sync_edits(definition: AreaDef, animate: bool = true) -> void:
	var appearance_only: bool = area.buildings == definition.buildings and area.trees == definition.trees and area.props == definition.props
	var reshaped: Dictionary = _reshaped_cells(area, definition)
	area = definition
	_refresh_entrance_surfaces()
	if not reshaped.is_empty():
		_reshape(reshaped)
	if ground_skin != null:
		ground_skin.update_area(area)
	if appearance_only and reshaped.is_empty():
		return
	if villagers != null:
		villagers.rules = LabWorld.new(area)
	var wanted: Dictionary = {}
	for building: Dictionary in _built_things():
		wanted[building.id] = _building_key(building)
	for id: String in _drawn_buildings.keys():
		if not wanted.has(id) or (_drawn_buildings[id] as Dictionary).key != wanted[id]:
			_remove_building(id, animate and not wanted.has(id))
	for building: Dictionary in _built_things():
		if not _drawn_buildings.has(building.id):
			var node: Node3D = _place_building(building)
			if animate and node != null:
				_pop(node)
	_sync_trees()
	_update_props(_committed)


## The cells whose land changed between two versions of the area (terrain, level or stairs), as a set.
static func _reshaped_cells(before: AreaDef, after: AreaDef) -> Dictionary:
	var cells: Dictionary = {}
	if before == null or before.width != after.width or before.height != after.height:
		return cells
	if before.terrain != after.terrain or before.levels != after.levels:
		for index: int in range(after.terrain.size()):
			if before.terrain[index] != after.terrain[index] or before.levels.is_empty() != after.levels.is_empty() or (not after.levels.is_empty() and before.levels[index] != after.levels[index]):
				cells[Vector2i(index % after.width, index / after.width)] = true
	var flights: Dictionary = {}
	for flight: Dictionary in before.stairs:
		flights["%s|%s" % [str(flight.at), flight.up]] = flight
	for flight: Dictionary in after.stairs:
		var key: String = "%s|%s" % [str(flight.at), flight.up]
		if flights.has(key):
			flights.erase(key)
		else:
			flights[key] = flight
	for flight: Dictionary in flights.values():
		for cell: Vector2i in [flight.at, (flight.at as Vector2i) + (flight.dir as Vector2i), (flight.at as Vector2i) - (flight.dir as Vector2i)]:
			cells[cell] = true
	return cells


## Redraws the land round changed cells: their terrain chunks (with a neighbour's, since cliffs and banks look at
## the cells beside them), the ground skin's heights and the water.
func _reshape(cells: Dictionary) -> void:
	if _terrain_root == null:
		return
	var chunks: Dictionary = {}
	for cell: Vector2i in cells:
		for dx: int in range(-1, 2):
			for dy: int in range(-1, 2):
				var near: Vector2i = cell + Vector2i(dx, dy)
				if area.in_bounds(near):
					chunks[Vector2i(near.x / CHUNK, near.y / CHUNK)] = true
	for chunk: Vector2i in chunks:
		_rebuild_terrain_chunk(chunk)
	if ground_skin != null:
		ground_skin.rebuild_mesh(area)
	if water_surface != null:
		water_surface.rebuild(area)


## Draws one chunk of cells afresh, leaving whatever else is queued alone.
func _rebuild_terrain_chunk(chunk: Vector2i) -> void:
	for node: Node in _terrain_nodes.get(chunk, []):
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	var queued: Dictionary = _batches
	_batches = {}
	for y: int in range(chunk.y * CHUNK, mini((chunk.y + 1) * CHUNK, area.height)):
		for x: int in range(chunk.x * CHUNK, mini((chunk.x + 1) * CHUNK, area.width)):
			TerrainBuilder.cell(area, Vector2i(x, y), _block, ground_skin != null, true)
	var nodes: Array = []
	_flush_batches(_terrain_root, chunk, "Terrain", nodes)
	_terrain_nodes[chunk] = nodes
	_batches = queued


## A small piece of land (an AreaDef of its own) as one model, for a card picture or the details panel: its blocks
## merged per material, with its water and any waterfalls.
func build_land_model(land: AreaDef) -> Node3D:
	var queued: Dictionary = _batches
	_batches = {}
	TerrainBuilder.build(land, _block, false, true)
	var blocks: Dictionary = _batches
	_batches = queued
	var holder := Node3D.new()
	holder.name = "Land"
	var mesh := ArrayMesh.new()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	for material_id: String in blocks:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for transform: Transform3D in blocks[material_id]:
			tool.append_from(cube, 0, transform)
		tool.set_material(_materials[material_id])
		tool.commit(mesh)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	holder.add_child(body)
	var water := WaterSurface.new()
	holder.add_child(water)
	water.build(land, false)
	return holder


## Everything drawn as a placed model: the buildings and the props. Both carry id, asset, at, facing and scale.
func _built_things() -> Array[Dictionary]:
	var things: Array[Dictionary] = []
	things.append_array(area.buildings)
	things.append_array(area.props)
	return things


## The model whose door leaves a room link swings: a placed room asset, or "shell" for the room's own set.
func link_doors(id: String) -> Node3D:
	if id == "":
		return null
	if id == "shell":
		for name: String in ["LaneSet", "SquareSet", "WorkshopShell", "LoftShell"]:
			var shell: Node3D = _content.find_child(name, false, false) as Node3D
			if shell != null: return shell
		return null
	return building_node(id)


## The node drawn for a building or a prop (their ids never collide: "build-N" and "prop-N").
func building_node(id: String) -> Node3D:
	for item: Dictionary in area.interior.get("assets", []):
		if str(item.id) == id: return _content.find_child(id, true, false) as Node3D
	return (_drawn_buildings.get(id, {}) as Dictionary).get("node") as Node3D


func _refresh_entrance_surfaces() -> void:
	_entrance_surfaces.clear()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WorldAssets.CATALOG)).assets
	for building: Dictionary in area.buildings:
		var entrance: Dictionary = (catalog.get(building.asset, {}) as Dictionary).get("entrance", {})
		if entrance.has("steps"):
			_entrance_surfaces.append({"at": building.at, "facing": building.facing, "scale": building.scale, "base": ground_y(building.at), "steps": entrance.steps})


func open_door(house: String) -> void:
	var building: Node3D = building_node(house)
	if building == null:
		return
	for hinge: Node in building.find_children("DoorHinge*", "Node3D", true, false):
		var angle: float = -1.3 if hinge.name.ends_with("_R") else 1.3
		create_tween().tween_property(hinge, "rotation:y", angle, 0.22)


## Pick the actual door face, rather than the ground several cells behind it.
func pick_door(point: Vector2) -> Dictionary:
	if not area.interior.is_empty():
		var exit: Array = area.interior.exit
		var at := Vector3(float(exit[0]), 0.08, -float(exit[1]))
		if _door_polygon(at, Vector3.RIGHT, 1.3, 2.0, point):
			return {"house": ""}
		return {}
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WorldAssets.CATALOG)).assets
	for house: Dictionary in area.buildings:
		var entry: Dictionary = (catalog.get(house.asset, {}) as Dictionary).get("entrance", {})
		if not entry.has("plane"):
			continue
		var yaw: float = deg_to_rad(float(AreaDef.FACINGS[house.facing]))
		var front: Vector3 = Vector3.BACK.rotated(Vector3.UP, yaw)
		if front.dot(camera.position - Vector3(house.at.x, 0, -house.at.y)) <= 0:
			continue
		var at := Vector3(house.at.x, ground_y(house.at) + float(entry.get("bottom", 0.15)) * float(house.scale), -house.at.y) + front * float(entry.plane) * float(house.scale)
		if _door_polygon(at, Vector3.RIGHT.rotated(Vector3.UP, yaw), float(entry.width) * float(house.scale), float(entry.height) * float(house.scale), point):
			return {"house": house.id}
	return {}


func _door_polygon(at: Vector3, right: Vector3, width: float, height: float, point: Vector2) -> bool:
	var polygon := PackedVector2Array()
	for offset: Vector2 in [Vector2(-0.5, 0), Vector2(0.5, 0), Vector2(0.5, 1), Vector2(-0.5, 1)]:
		polygon.append(camera.unproject_position(at + right * offset.x * width + Vector3.UP * offset.y * height))
	return Geometry2D.is_point_in_polygon(point, polygon)


func _remove_building(id: String, animate: bool) -> void:
	var node: Node3D = building_node(id)
	_drawn_buildings.erase(id)
	_prop_visuals.erase(id)
	if node == null:
		return
	# Free the name at once: a replacement of the same id arrives in this very call, and a node waiting to be
	# freed would otherwise keep the name and push the new one onto another.
	node.name = String(node.name) + "_leaving"
	if animate:
		var tween := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, "scale", node.scale * Vector3(1.0, 0.02, 1.0), 0.26)
		tween.tween_callback(node.queue_free)
	else:
		node.queue_free()


## A short settle: the building drops in a little squashed and springs to its height.
func _pop(node: Node3D) -> void:
	var rest: Vector3 = node.scale
	node.scale = Vector3(rest.x * 0.96, rest.y * 0.5, rest.z * 0.96)
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", rest, 0.4)


## Draws every tree the area lists, and afterwards only the chunks where one appeared or went. A crown's shape
## is fixed by where it stands, so the other trees never change when one is added or removed.
func _sync_trees() -> void:
	var wanted: Dictionary = {}
	for tree: Dictionary in area.trees:
		wanted[AreaBuild.tree_key(tree.at)] = tree
	var dirty: Dictionary = {}
	for key: String in _drawn_trees.keys():
		if not wanted.has(key):
			dirty[_drawn_trees[key]] = true
			_drawn_trees.erase(key)
			_asset_tree_nodes.erase(key)
			_tree_styles.erase(key)
	for key: String in wanted:
		var style: String = "%s|%s" % [str(wanted[key].get("asset", "")), str(wanted[key].size)]
		if not _drawn_trees.has(key):
			var chunk: Vector2i = _tree_chunk(wanted[key].at)
			_drawn_trees[key] = chunk
			dirty[chunk] = true
		elif _tree_styles.get(key, "") != style:
			dirty[_drawn_trees[key]] = true
		_tree_styles[key] = style
	for chunk: Vector2i in dirty:
		_rebuild_tree_chunk(chunk, wanted)


func _tree_chunk(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / float(CHUNK)), floori(-at.y / float(CHUNK)))


func _rebuild_tree_chunk(chunk: Vector2i, wanted: Dictionary) -> void:
	for node: Node in _tree_nodes.get(chunk, []):
		node.queue_free()
	var nodes: Array = []
	_tree_nodes[chunk] = nodes
	_batches.clear()
	for key: String in _drawn_trees:
		if _drawn_trees[key] == chunk:
			var tree: Dictionary = wanted[key]
			if tree.get("asset", "") != "":
				var model: Node3D = WorldAssets.instantiate(_presented_asset(str(tree.asset)))
				if model != null:
					_tree_root.add_child(model)
					model.position = Vector3(tree.at.x, ground_y(tree.at), -tree.at.y)
					model.scale = Vector3.ONE * float(tree.size)
					_asset_tree_nodes[key] = model
					nodes.append(model)
			else:
				_make_tree(Vector3(tree.at.x, ground_y(tree.at), -tree.at.y), float(tree.size), tree_seed(tree.at))
	_flush_batches(_tree_root, chunk, "Trees", nodes)


## A crown's variety comes from its place, not its position in a list.
static func tree_seed(at: Vector2) -> int:
	return absi(roundi(at.x * 10.0) * 7919 + roundi(at.y * 10.0) * 104729) % 100000


## One tree as a single merged mesh, for a placement ghost or a catalog thumbnail.
func build_tree_mesh(size: float, crown_seed: int = 0) -> ArrayMesh:
	var queued: Dictionary = _batches
	_batches = {}
	_make_tree(Vector3.ZERO, size, crown_seed)
	var blocks: Dictionary = _batches
	_batches = queued
	var mesh := ArrayMesh.new()
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	for material_id: String in blocks:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for transform: Transform3D in blocks[material_id]:
			tool.append_from(cube, 0, transform)
		tool.set_material(_materials[material_id])
		tool.commit(mesh)
	return mesh


## Nudges the free camera by a logical offset (x east, y north), in cells.
func pan_focus(offset: Vector2) -> void:
	_focus_target = _clamped_focus(_focus_target + Vector3(offset.x, 0.0, -offset.y))


## Pans by a screen distance, in the camera plane's units (what a mouse drag measures): `right` along the
## ground's right-hand diagonal, `up` along its far diagonal, stretched by the camera's elevation.
func pan_focus_screen(right: float, up: float) -> void:
	var elevation: float = atan2(CAMERA_OFFSET.y, Vector2(CAMERA_OFFSET.x, CAMERA_OFFSET.z).length())
	pan_focus(Vector2(1.0, 1.0) * (right / sqrt(2.0)) + Vector2(-1.0, 1.0) * (up / sin(elevation) / sqrt(2.0)))


## Where the camera is looking, as a logical point.
func focus_point() -> Vector2:
	return Vector2(_focus.x, -_focus.z)


## Where the camera is looking, in world space.
func focus_world() -> Vector3:
	return _focus


func _presented_asset(id: String) -> String:
	return (_area_presentation.get("assets", {}) as Dictionary).get(id, id)


func _try_world_asset(id: String, at: Vector3, size: float = 1.0, facing: float = 0.0, node_name: String = "", look: Variant = null) -> bool:
	if not WorldAssets.is_blender(id):
		push_error("World asset '%s' is not a Blender-selected model. Adopt it through the world catalog first." % id)
		return false
	var presented: String = _presented_asset(id)
	var variant: Dictionary = HouseVariants.look(WorldAssets.entry(presented), look) if look != null else {}
	var asset: Node3D = WorldAssets.instantiate(presented, ResourceLoader.CACHE_MODE_REUSE, variant)
	if asset != null:
		asset.name = node_name if node_name != "" else id.replace("-", "_")
		asset.position = at
		asset.rotation_degrees.y = facing
		asset.scale = Vector3.ONE * size
		_content.add_child(asset)
	BuildPump.pump()
	return true  # A missing selected asset is an error; do not silently replace artist work.


func _place_building(building: Dictionary) -> Node3D:
	var at: Vector2 = building.at
	var node_name: String = String(building.id).replace("-", "_")
	_try_world_asset(building.asset, Vector3(at.x, ground_y(at), -at.y), float(building.scale), float(AreaDef.FACINGS[building.facing]), node_name)
	var node: Node3D = _content.get_node_or_null(node_name) as Node3D
	_drawn_buildings[building.id] = {"node": node, "key": _building_key(building)}
	if node != null:
		FinishMaterials.apply(node, WorldAssets.entry(_presented_asset(str(building.asset))), building.get("finishes", {}))
		if _area_presentation.get("illustrated_edges", false):
			IllustratedEdges.apply(node)
	if node != null and not (building.get("interaction", {}) as Dictionary).is_empty():
		var visual := PropVisual.new()
		node.add_child(visual)
		visual.setup(node, building.interaction)
		_prop_visuals[building.id] = visual
	return node


static func _building_key(building: Dictionary) -> String:
	return "%s|%s|%s|%s|%s" % [building.asset, str(building.at), building.facing, str(building.scale), JSON.stringify(building.get("finishes", {}))]


func _make_mechanisms() -> void:
	var box := Callable(self, "_mesh_box")
	var post_asset: String = _area_presentation.get("post_lamp", "lamppost")
	for lamp: Dictionary in area.lamps:
		if lamp.style == "fixture":
			for spec: Dictionary in area.interior.get("lamp_fixtures", []):
				if spec.id != lamp.id: continue
				var fixture := _content.get_node_or_null(NodePath(str(spec.asset))) as Node3D
				if fixture != null and MechanismBuilder.bind_fixture(fixture, spec): _lamps[lamp.id] = fixture
			continue
		var root: Node3D = MechanismBuilder.lamp(_content, box, lamp.style, post_asset)
		root.name = String(lamp.id).replace("-", "_")
		root.position = Vector3(lamp.at.x, ground_y(lamp.at), -lamp.at.y)
		_lamps[lamp.id] = root
	for gate: Dictionary in area.gates:
		var parts: Dictionary = MechanismBuilder.gate(_content, box, gate.axis)
		(parts.root as Node3D).position = Vector3(gate.cell.x, ground_y(Vector2(gate.cell)), -gate.cell.y)
		(parts.root as Node3D).name = String(gate.id).replace("-", "_")
		_gates[gate.id] = parts.door
	for bridge: Dictionary in area.bridges:
		var sockets: Array[Vector2i] = bridge.sockets
		var axis: String = "y" if sockets.size() > 1 and sockets[1].y != sockets[0].y else "x"
		for index: int in range(sockets.size()):
			var section: Node3D = MechanismBuilder.deck(_content, box, axis, index == 0, index == sockets.size() - 1)
			section.name = "Deck_%s_%d" % [String(bridge.id).replace("-", "_"), index]
			section.position = Vector3(sockets[index].x, ground_y(Vector2(sockets[index])), -sockets[index].y)
			section.visible = false
			_decks[sockets[index]] = section
	for wheel: Dictionary in area.wheels:
		var radius: float = float(wheel.size.y)*.5
		var height: float = radius-.28 if wheel.axle_to != wheel.at else .73
		var turning: Node3D = MechanismBuilder.wheel(_content, box,radius,float(wheel.size.x)*.9)
		turning.name = String(wheel.id).replace("-", "_")
		turning.position = Vector3(wheel.at.x, height + ground_y(wheel.at), -wheel.at.y)
		if wheel.axle_to != wheel.at:
			var support: Node3D = MechanismBuilder.wheel_support(_content,box,float(wheel.axle_to.x-wheel.at.x),height)
			support.name = turning.name+"_support"
			support.position = turning.position
		_wheels.append(turning)


func _make_light_pool() -> void:
	for index: int in range(LIGHT_POOL):
		var light := OmniLight3D.new()
		light.name = "LampLight%d" % index
		light.light_color = Color("ffcf86")
		light.light_energy = 0.0
		light.omni_range = 3.4
		light.shadow_enabled = false
		light.visible = false
		_content.add_child(light)
		_lamp_lights.append(light)


func _make_quest_marker() -> void:
	_quest_marker = Node3D.new()
	_quest_marker.name = "QuestMarker"
	_quest_marker.visible = false
	_content.add_child(_quest_marker)
	_motes.clear()
	if marker_style == "paper":
		_make_spark_marker()
		return
	for index: int in range(8):
		var angle: float = float(index) * TAU / 8.0
		var tile := _mesh_box(_quest_marker, Vector3(cos(angle) * 0.62, 0.0, sin(angle) * 0.62), Vector3(0.22, 0.04, 0.12), "lit")
		tile.rotation.y = -angle
		tile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var beam := _mesh_box(_quest_marker, Vector3(0, 1.4, 0), Vector3(0.07, 2.8, 0.07), "lit")
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.name = "Beam"


## The paper journey's "look here": a brass dial on the floor with a ring of ticks and a warm glow, and a few sparks
## rising from it. Sparks are this world's one gentle magic, so the mark where work is done is made of them.
func _make_spark_marker() -> void:
	var dial := MeshInstance3D.new()
	dial.name = "Dial"
	var quad := QuadMesh.new()
	quad.size = Vector2(2.1, 2.1)
	dial.mesh = quad
	var dial_material := ShaderMaterial.new()
	dial_material.shader = preload("res://art/spark_dial.gdshader")
	dial_material.render_priority = 1
	dial.material_override = dial_material
	dial.rotation_degrees.x = -90.0
	dial.position.y = 0.02
	dial.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_quest_marker.add_child(dial)
	for index: int in range(6):
		var mote := MeshInstance3D.new()
		var point := QuadMesh.new()
		point.size = Vector2(0.32, 0.32)
		mote.mesh = point
		var material := ShaderMaterial.new()
		material.shader = preload("res://art/spark_mote.gdshader")
		material.render_priority = 3
		mote.material_override = material
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_quest_marker.add_child(mote)
		_motes.append({"node": mote, "material": material, "phase": float(index) / 6.0, "angle": float(index) * 2.4})


func _animate_spark_marker() -> void:
	for mote: Dictionary in _motes:
		var rise: float = fposmod(_elapsed * 0.32 + float(mote.phase), 1.0)
		var around: float = float(mote.angle) + _elapsed * 0.7
		var node := mote.node as MeshInstance3D
		node.position = Vector3(cos(around) * 0.3 * (1.0 - rise * 0.5), 0.1 + rise * 1.6, sin(around) * 0.3 * (1.0 - rise * 0.5))
		(mote.material as ShaderMaterial).set_shader_parameter("fade", sin(rise * PI))
		# Quads face the camera whichever way the camera looks.
		node.look_at(camera.global_position, Vector3.UP, true)


## A ring of light that sweeps outward across the ground, for the moment the hollow is fully lit.
func celebrate(cell: Vector2) -> void:
	if _content == null:
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 6
	ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.albedo_color = Color(1.0, 0.8, 0.4, 0.9)
	ring.material_override = material
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(cell.x, ground_y(cell) + 0.12, -cell.y)
	ring.scale = Vector3(0.4, 1.0, 0.4)
	_content.add_child(ring)
	var tween := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(ring, "scale", Vector3(22.0, 1.0, 22.0), 3.2)
	tween.tween_property(material, "albedo_color:a", 0.0, 3.2)
	tween.chain().tween_callback(ring.queue_free)


## Build mode hides the quest's beam, which would otherwise stand in the way of the grid and the ghost.
func set_marker_hidden(hidden: bool) -> void:
	_marker_hidden = hidden
	if _quest_marker != null:
		_quest_marker.visible = _marker_cell is Vector2 and not hidden


## A glowing ring on the ground where the current quest happens. null hides it.
func set_quest_marker(cell: Variant) -> void:
	_marker_cell = cell
	if _quest_marker == null:
		return
	_quest_marker.visible = cell is Vector2 and not _marker_hidden
	if cell is Vector2:
		_quest_marker.position = Vector3(cell.x, ground_y(cell) + 0.06, -cell.y)


# ------------------------------------------------------------------------------------
# One-time seed recipes. world_seed.gd bootstraps the Blender sources from these; the adopted
# .blend files are the masters now. Do not call them from the normal build path.
# ------------------------------------------------------------------------------------
func _make_island() -> void:
	# Broad grass banks remove the old checkerboard lawn, while the stream stays a real gap.
	_block(Vector3(7.5, -0.58, -5.5), Vector3(16.0, 0.5, 12.0), "soil_dark")
	_block(Vector3(3.0, -0.20, -5.5), Vector3(7.0, 0.4, 12.0), "soil")
	_block(Vector3(12.5, -0.20, -5.5), Vector3(6.0, 0.4, 12.0), "soil")
	_block(Vector3(3.0, -0.015, -5.5), Vector3(7.0, 0.06, 12.0), "grass")
	_block(Vector3(12.5, -0.015, -5.5), Vector3(6.0, 0.06, 12.0), "grass")
	_block(Vector3(8.0, -0.40, -5.5), Vector3(3.0, 0.12, 12.0), "stone_dark")
	_block(Vector3(8.0, -0.255, -5.5), Vector3(3.0, 0.08, 12.0), "water")
	for side: float in [6.51, 9.49]:
		_block(Vector3(side, -0.17, -5.5), Vector3(0.18, 0.35, 12.0), "stone_dark")
		for index: int in range(17):
			var z: float = 0.35 - float(index) * 0.72
			var material: String = "stone_light" if index % 3 else "stone"
			_block(Vector3(side, -0.17, z), Vector3(0.24, 0.18, 0.68), material)
			_block(Vector3(side + (-0.06 if side < 8.0 else 0.06), -0.025, z - 0.13), Vector3(0.30, 0.11, 0.68), "stone_light")
	# Simple timber boundary fences are large structural forms, with no scattered props.
	for limits: Vector2i in [Vector2i(0, 6), Vector2i(10, 15)]:
		for x: int in range(limits.x, limits.y + 1):
			_block(Vector3(x, 0.32, 0.46), Vector3(0.13, 0.64, 0.15), "oak")
			_block(Vector3(x, 0.66, 0.46), Vector3(0.18, 0.09, 0.19), "wood_dark")
		var midpoint: float = float(limits.x + limits.y) * 0.5
		for height: float in [0.22, 0.51]:
			_block(Vector3(midpoint, height, 0.46), Vector3(float(limits.y - limits.x), 0.075, 0.09), "oak")


func _make_paths() -> void:
	for x: int in range(1, 15):
		if x >= 7 and x <= 9:
			continue
		for y: int in range(4, 7):
			_paved_cell(x, y)
	for y: int in [7]:
		for x: int in [2, 12]:
			_paved_cell(x, y)
	for y: int in [7, 8, 9]:
		_paved_cell(5, y)
	for x: int in [6, 10]:
		_block(Vector3(x, 0.025, -5), Vector3(0.95, 0.08, 1.1), "stone_light")


func _paved_cell(x: int, y: int) -> void:
	_block(Vector3(x, 0.018, -y), Vector3(1.0, 0.035, 1.0), "path_dark")
	for row: int in range(3):
		for column: int in range(4):
			var hash: int = absi(x * 31 + y * 17 + column * 13 + row * 7)
			var material: String = ["path", "path", "path_light", "stone", "path"][hash % 5]
			var offset: float = 0.015 * float(hash % 3 - 1)
			_block(Vector3(float(x) - 0.37 + float(column) * 0.25 + offset, 0.041, -float(y) - 0.33 + float(row) * 0.33), Vector3(0.225, 0.035 + float(hash % 2) * 0.008, 0.302), material, Vector3(0, float(hash % 5 - 2) * 0.018, 0))


func _make_house(center: Vector3, mill: bool) -> void:
	var height: float = 2.0 if mill else 1.8
	var wall_top: float = height + 0.35
	var front: float = 1.25
	_block(center + Vector3(0, 0.16, 0), Vector3(2.82, 0.32, 2.72), "stone_dark")
	# Individual stone courses create mortar joints and a clear foundation.
	for row: int in range(2):
		for column: int in range(7):
			var x: float = -1.2 + float(column) * 0.4
			var stone: String = "stone_light" if (column + row) % 3 else "stone"
			_block(center + Vector3(x, 0.08 + float(row) * 0.16, 1.37), Vector3(0.38, 0.145, 0.14), stone)
			_block(center + Vector3(1.42, 0.08 + float(row) * 0.16, -1.17 + float(column) * 0.39), Vector3(0.14, 0.145, 0.37), stone)
	_block(center + Vector3(0, height / 2.0 + 0.35, 0), Vector3(2.55, height, 2.45), "plaster")
	for x: float in [-1.19, 1.19]:
		_block(center + Vector3(x, height / 2.0 + 0.35, front), Vector3(0.17, height + 0.12, 0.16), "wood")
		for y: float in [0.53, wall_top - 0.12]:
			_block(center + Vector3(x, y, front + 0.095), Vector3(0.065, 0.065, 0.025), "oak_light")
	for z: float in [-1.15, 0.0, 1.15]:
		_block(center + Vector3(1.3, height / 2.0 + 0.35, z), Vector3(0.16, height, 0.15), "wood")
	for y: float in [0.49, wall_top - 0.04]:
		_block(center + Vector3(0, y, front + 0.02), Vector3(2.68, 0.13, 0.17), "wood")
		_block(center + Vector3(1.31, y, 0), Vector3(0.15, 0.13, 2.55), "wood")
	# Side braces and pegs make the timberwork feel assembled.
	for z: float in [-0.57, 0.57]:
		_block(center + Vector3(1.32, wall_top - 0.4, z), Vector3(0.11, 0.8, 0.12), "oak", Vector3(0.7 if z > 0 else -0.7, 0, 0))
	for row: int in range(4):
		var y: float = 0.63 + float(row) * 0.36
		_block(center + Vector3(-1.23, y, front + 0.055), Vector3(0.26 if row % 2 == 0 else 0.19, 0.15, 0.13), "stone_light")
		_block(center + Vector3(1.32, y, -1.18), Vector3(0.15, 0.15, 0.25 if row % 2 == 0 else 0.19), "stone_light")
	# Planked door, iron straps, warm brass latch and a block-stone arch.
	_block(center + Vector3(0, 0.95, front + 0.055), Vector3(0.64, 1.3, 0.09), "wood_dark")
	for plank: int in range(5):
		_block(center + Vector3(-0.23 + float(plank) * 0.115, 0.95, front + 0.115), Vector3(0.105, 1.23, 0.07), "oak" if plank % 2 else "oak_light")
	for y: float in [0.6, 1.3]:
		_block(center + Vector3(0, y, front + 0.17), Vector3(0.54, 0.055, 0.025), "iron")
	_block(center + Vector3(0.17, 0.97, front + 0.195), Vector3(0.065, 0.09, 0.045), "gold")
	for x: float in [-0.38, 0.38]:
		for row: int in range(5):
			_block(center + Vector3(x, 0.47 + float(row) * 0.205, front + 0.12), Vector3(0.17, 0.19, 0.2), "stone_light" if row % 2 else "stone")
	for index: int in range(7):
		var angle: float = float(index) * PI / 6.0
		_block(center + Vector3(cos(angle) * 0.37, 1.4 + sin(angle) * 0.3, front + 0.12), Vector3(0.18, 0.18, 0.21), "stone_light", Vector3(0, 0, angle - PI / 2.0))
	for x: float in [-0.84, 0.84]:
		_window(center + Vector3(x, 1.33, front + 0.07), false)
	_window(center + Vector3(1.34, 1.42, 0.13), true)
	# A filled timber gable supports two tiled slopes; each shingle has its own shape.
	var rise: float = 1.05
	for row: int in range(12):
		var width: float = 2.58 * (1.0 - float(row) / 12.0)
		for z: float in [-1.22, 1.28]:
			_block(center + Vector3(0, wall_top + float(row) * rise / 12.0, z), Vector3(width, rise / 12.0 + 0.008, 0.11), "oak")
	var roof_color: String = "teal" if mill else "roof"
	var slope: float = atan2(rise, 1.6)
	for side: float in [-1.0, 1.0]:
		_block(center + Vector3(side * 0.8, wall_top + rise * 0.5, 0), Vector3(1.98, 0.12, 3.18), roof_color + "_dark", Vector3(0, 0, -side * slope))
		for row: int in range(7):
			var distance: float = 0.11 + float(row) * 0.24
			for column: int in range(8):
				var z: float = -1.36 + float(column) * 0.39 + (0.1 if row % 2 else 0.0)
				var shade: int = (row * 17 + column * 13) % 11
				var material: String = roof_color + ("_light" if shade < 2 else ("_dark" if shade == 9 else ""))
				_block(center + Vector3(side * distance, wall_top + rise - distance * tan(slope) + 0.09, z), Vector3(0.32, 0.095, 0.375), material, Vector3(0, 0, -side * slope))
		_block(center + Vector3(side * 1.63, wall_top - 0.015, 0), Vector3(0.13, 0.18, 3.28), "wood_dark")
		# Front bargeboards frame the gable in warm wood, rather than pale stripes.
		_block(center + Vector3(side * 0.77, wall_top + rise * 0.51, 1.64), Vector3(1.93, 0.13, 0.13), "wood", Vector3(0, 0, -side * slope))
	for column: int in range(9):
		_block(center + Vector3(0, wall_top + rise + 0.14, -1.48 + float(column) * 0.37), Vector3(0.27, 0.14, 0.35), roof_color + "_dark")
	_block(center + Vector3(0, wall_top + 0.34, 1.35), Vector3(0.45, 0.43, 0.10), "wood_dark")
	_block(center + Vector3(0, wall_top + 0.34, 1.415), Vector3(0.31, 0.3, 0.045), "window_warm")
	_block(center + Vector3(0, wall_top + 0.34, 1.445), Vector3(0.045, 0.33, 0.035), "oak_light")
	_block(center + Vector3(0, wall_top + 0.34, 1.445), Vector3(0.33, 0.045, 0.035), "oak_light")
	for row: int in range(7):
		var y: float = wall_top + 0.59 + float(row) * 0.16
		_block(center + Vector3(-0.75, y, -0.62), Vector3(0.45, 0.15, 0.46), "stone_light" if row % 2 else "stone")
		_block(center + Vector3(-0.74 + (0.07 if row % 2 else -0.06), y, -0.382), Vector3(0.015, 0.15, 0.008), "stone_dark")
	_block(center + Vector3(-0.75, wall_top + 1.73, -0.62), Vector3(0.55, 0.13, 0.56), "stone_light")
	_block(center + Vector3(-0.75, wall_top + 1.801, -0.62), Vector3(0.28, 0.014, 0.29), "wood_dark")
	for step: int in range(2):
		_block(center + Vector3(0, 0.07 + float(step) * 0.10, front + 0.63 - float(step) * 0.22), Vector3(1.02 - float(step) * 0.12, 0.14, 0.35), "stone_light")
	if mill:
		_block(center + Vector3(0, 1.99, front + 0.16), Vector3(0.72, 0.27, 0.09), "wood_dark")
		for index: int in range(3):
			_block(center + Vector3(-0.15 + float(index) * 0.15, 1.99, front + 0.22), Vector3(0.065, 0.13, 0.025), "gold", Vector3(0, 0, -0.35 + float(index) * 0.35))


func _window(center: Vector3, side: bool) -> void:
	var rotation: Vector3 = Vector3(0, PI / 2.0, 0) if side else Vector3.ZERO
	var basis: Basis = Basis.from_euler(rotation)
	_block(center, Vector3(0.52, 0.65, 0.10), "wood_dark", rotation)
	_block(center + basis * Vector3(0, 0, 0.06), Vector3(0.4, 0.52, 0.06), "window_warm", rotation)
	_block(center + basis * Vector3(0, 0, 0.11), Vector3(0.045, 0.55, 0.045), "oak_light", rotation)
	_block(center + basis * Vector3(0, 0, 0.11), Vector3(0.43, 0.045, 0.045), "oak_light", rotation)
	_block(center + basis * Vector3(0, -0.34, 0.06), Vector3(0.64, 0.09, 0.24), "stone_light", rotation)
	for x: float in [-0.33, 0.33]:
		_block(center + basis * Vector3(x, 0, 0.07), Vector3(0.13, 0.57, 0.075), "oak", rotation)
		for y: float in [-0.17, 0.17]:
			_block(center + basis * Vector3(x, y, 0.12), Vector3(0.15, 0.035, 0.03), "iron", rotation)


func _make_tree(center: Vector3, scale_factor: float, seed: int) -> void:
	_block(center + Vector3(0, 0.93, 0) * scale_factor, Vector3(0.35, 1.86, 0.35) * scale_factor, "wood")
	_block(center + Vector3(0.24, 1.52, 0) * scale_factor, Vector3(0.58, 0.18, 0.18) * scale_factor, "oak", Vector3(0, 0, 0.4))
	_block(center + Vector3(-0.19, 1.38, 0.14) * scale_factor, Vector3(0.44, 0.17, 0.17) * scale_factor, "wood", Vector3(0, 0.4, -0.4))
	_block(center + Vector3(0, 2.38, 0) * scale_factor, Vector3(1.6, 1.1, 1.6) * scale_factor, "leaf_dark")
	# An ellipsoid of overlapping leaf clusters replaces the three flat stacked slabs.
	for x: int in range(-3, 4):
		for y: int in range(-2, 3):
			for z: int in range(-3, 4):
				var distance: float = pow(float(x) / 3.2, 2.0) + pow(float(y) / 2.5, 2.0) + pow(float(z) / 3.0, 2.0)
				var hash: int = absi(x * 71 + y * 43 + z * 29 + seed * 113)
				if distance > 1.0 + float(hash % 4) * 0.035:
					continue
				var at := Vector3(float(x) * 0.38, 2.55 + float(y) * 0.39, float(z) * 0.38)
				at += Vector3(float(hash % 3 - 1) * 0.04, float(hash % 5 - 2) * 0.025, float(hash % 7 - 3) * 0.02)
				var material: String = "leaf_light" if y >= 1 and hash % 4 != 0 else ("leaf_dark" if y < 0 and hash % 3 == 0 else "leaf")
				var size: float = 0.42 + float(hash % 3) * 0.04
				_block(center + at * scale_factor, Vector3(size, size * 0.95, size) * scale_factor, material)


func _make_player() -> void:
	_player = Node3D.new()
	_player.name = "Programmer"
	_content.add_child(_player)
	_player.position = Vector3(area.spawn.x, ground_y(Vector2(area.spawn)) + 0.055, -area.spawn.y)
	if not ResourceLoader.exists("res://assets/characters/adventurer/frames.tres") or not FileAccess.file_exists("res://assets/characters/library.json"):
		push_error("Selected character output is missing. Run scripts/art.sh; the game never substitutes another character.")
		return
	_body = SpriteActor.new()
	(_body as SpriteAdventurer).occlusion_silhouette = true
	_player.add_child(_body)


func set_character_skin(id: String) -> bool:
	return _body is SpriteAdventurer and (_body as SpriteAdventurer).set_skin(id)


## Commits a world state to the picture, or shows it as a translucent proposal when `preview` is true.
func apply_state(state: Dictionary, preview: bool = false) -> void:
	if not is_node_ready() or area == null:
		return
	if preview:
		_show_preview(state)
		if terminal_display != null: terminal_display.sync(state, true)
		return
	clear_preview()
	_committed = state.duplicate(true)
	if terminal_display != null: terminal_display.sync(state)
	var bridges: Dictionary = state.get("bridges", {})
	for bridge: Dictionary in area.bridges:
		var built: int = int(bridges.get(bridge.id, 0))
		var sockets: Array[Vector2i] = bridge.sockets
		for index: int in range(sockets.size()):
			(_decks[sockets[index]] as Node3D).visible = index < built
	var lamps: Dictionary = state.get("lamps", {})
	_lit_positions.clear()
	for lamp_id: String in _lamps:
		var root: Node3D = _lamps[lamp_id]
		var lit: bool = bool(lamps.get(lamp_id, false))
		if not root.has_meta("glass"):
			continue  # The selected lamp model failed to load; MechanismBuilder already reported it.
		# The lantern glass is found through the lamp's own metadata, so a lamp may be drawn by a procedural recipe or an adopted model.
		(root.get_meta("glass") as MeshInstance3D).material_override = root.get_meta("lit", _materials["lit"]) as Material if lit else root.get_meta("unlit") as Material
		var halo := root.get_node("Halo") as MeshInstance3D
		halo.visible = lit
		var fixture_light := root.get_node_or_null("FixtureLight") as OmniLight3D
		if fixture_light != null: fixture_light.visible = lit
		var embers := root.get_node_or_null("Embers") as CPUParticles3D
		if embers != null:
			embers.emitting = lit
		if lit:
			_lit_positions.append(halo.global_position)
	var gates: Dictionary = state.get("gates", {})
	for gate_id: String in _gates:
		(_gates[gate_id] as Node3D).rotation.y = -PI / 2.0 if bool(gates.get(gate_id, false)) else 0.0
	if _warmth_from_state and not _lamps.is_empty():
		_warmth_target = 0.28 + 0.72 * float(_lit_positions.size()) / float(_lamps.size())
	_update_light_pool()
	_update_props(state)
	sync_player(state)
	set_player_motion(Vector2.ZERO)


func _update_props(state: Dictionary) -> void:
	var values: Dictionary = state.get("props", {})
	for id: String in _prop_visuals:
		(_prop_visuals[id] as PropVisual).set_active(bool(values.get(id, false)))


func _update_light_pool() -> void:
	_light_focus = _focus
	var ordered: Array[Vector3] = _lit_positions.duplicate()
	ordered.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_squared_to(_focus) < b.distance_squared_to(_focus))
	for index: int in range(_lamp_lights.size()):
		var light: OmniLight3D = _lamp_lights[index]
		light.visible = index < ordered.size()
		if light.visible:
			light.position = ordered[index]
			light.light_energy = 0.9


## Where the player's feet go: on the ground (or up the stairs), a little higher on a bridge deck.
func _deck_height(at: Vector2) -> float:
	return WalkingSurface.height(area, at, _entrance_surfaces)


func sync_player(state: Dictionary) -> void:
	if _player == null:
		return
	var cell: Array = state.get("player", [area.spawn.x, area.spawn.y, 0])
	_committed["player"] = cell.duplicate()
	var at := Vector2(float(cell[0]), float(cell[1]))
	_player.position = Vector3(at.x, _deck_height(at), -at.y)
	_player_cells = {Vector2i(at.round()): true}


## A walk drawn without a step in the rules (through a scene change): past the area's edge the feet keep the height
## of the nearest cell inside it.
func walk_player_visual(from: Vector2, to: Vector2, fraction: float) -> void:
	if _player == null:
		return
	var at: Vector2 = from.lerp(to, fraction)
	var inside: Vector2 = at.clamp(Vector2.ZERO, Vector2(area.width - 1, area.height - 1))
	_player.position = Vector3(at.x, _deck_height(inside), -at.y)


func interpolate_player(from: Vector2, to: Vector2, fraction: float) -> void:
	var at: Vector2 = from.lerp(to, fraction)
	_player.position = Vector3(at.x, _deck_height(at), -at.y)
	_player_cells = {Vector2i(from.round()): true, Vector2i(to.round()): true}


## The cells the player takes up: where they stand, or both cells of the step they are taking. Residents keep out.
func player_cells() -> Dictionary:
	return _player_cells


## The cells residents take up, where the player may not step (none where nobody lives).
func resident_cells() -> Dictionary:
	return VillageLife.occupied(villagers.life, true) if villagers != null else {}


## The player's current screen position in the viewport, for placing speech and markers.
func player_screen_position() -> Vector2:
	return camera.unproject_position(_player.position + Vector3(0, 0.8, 0)) if _player != null else Vector2.ZERO


## Where a cell's ground, a little above it, falls in the viewport; a cell just beyond the area's edge keeps the
## height of the nearest cell inside it.
func screen_position_of_cell(cell: Vector2) -> Vector2:
	var inside: Vector2 = cell.clamp(Vector2.ZERO, Vector2(area.width - 1, area.height - 1))
	return camera.unproject_position(Vector3(cell.x, _deck_height(inside) + 0.8, -cell.y))


func set_marker_style(style: String) -> void:
	marker_style = style


func show_route(route: Array[Vector2i]) -> void:
	if _route_visual == null:
		return
	for child: Node in _route_visual.get_children():
		_route_visual.remove_child(child)
		child.queue_free()
	if marker_style == "paper":
		_show_paper_route(route)
		return
	for cell: Vector2i in route:
		var height: float = ground_y(Vector2(cell)) + (0.14 if not area.socket(cell).is_empty() else 0.085)
		var marker := _mesh_box(_route_visual, Vector3(cell.x, height, -cell.y), Vector3(0.13, 0.018, 0.13), "gold")
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Round dots with a dark outline mark each step; the last cell gets a breathing ring so the end of the journey is
## the clearest thing on the floor.
func _show_paper_route(route: Array[Vector2i]) -> void:
	for index: int in range(route.size()):
		var cell: Vector2i = route[index]
		var last: bool = index == route.size() - 1
		var quad := QuadMesh.new()
		quad.size = Vector2(1.35, 1.35) if last else Vector2(0.66, 0.66)
		var marker := MeshInstance3D.new()
		marker.mesh = quad
		marker.material_override = _route_material(last)
		marker.rotation_degrees.x = -90.0
		marker.position = Vector3(cell.x, _deck_height(Vector2(cell)) - WalkingSurface.CLEARANCE + 0.02, -cell.y)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_route_visual.add_child(marker)


func _route_material(destination: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/route_marker.gdshader")
	material.render_priority = 2 if destination else 1
	if destination:
		material.set_shader_parameter("radius", 0.6)
		material.set_shader_parameter("ring_half", 0.1)
		material.set_shader_parameter("line", 0.055)
		material.set_shader_parameter("pulse", 0.06)
	else:
		material.set_shader_parameter("radius", 0.5)
		material.set_shader_parameter("line", 0.17)
	return material


## Lights up one placed object, or none, with a soft brass-and-teal pulse: where the traveller is headed, or what F
## would use. Only the paper style draws it.
func set_target_highlight(id: String) -> void:
	var target: Node3D = building_node(id) if id != "" and marker_style == "paper" else null
	if target == _highlighted:
		return
	if is_instance_valid(_highlighted):
		_set_overlay(_highlighted, null)
	_highlighted = target
	if target == null:
		return
	if _highlight_material == null:
		_highlight_material = ShaderMaterial.new()
		_highlight_material.shader = preload("res://art/target_glow.gdshader")
	_set_overlay(target, _highlight_material)


func _set_overlay(node: Node, material: Material) -> void:
	if node is MeshInstance3D and node.name != &"IllustratedOutline":
		(node as MeshInstance3D).material_overlay = material
	for child: Node in node.get_children():
		_set_overlay(child, material)


func set_player_motion(velocity: Vector2) -> void:
	if _body == null:
		return
	if _body is SpriteAdventurer:
		(_body as SpriteAdventurer).set_screen_motion(_screen_direction(velocity))


## The character turns to face a logical direction (x east, y north) without taking a step.
func face_player(direction: Vector2) -> void:
	if _body is SpriteAdventurer:
		(_body as SpriteAdventurer).face_screen_direction(_screen_direction(direction))


func _screen_direction(logical: Vector2) -> Vector2:
	var origin: Vector3 = _player.position
	return camera.unproject_position(origin + Vector3(logical.x, 0, -logical.y)) - camera.unproject_position(origin)


func clear_preview() -> void:
	if terminal_display != null:
		terminal_display.clear_test_output()
		terminal_display.sync(_committed)
	if area != null:
		for lamp: Dictionary in area.lamps:
			if lamp.style == "fixture" and _lamps.has(lamp.id): _set_fixture_preview(_lamps[lamp.id], bool((_committed.get("lamps", {}) as Dictionary).get(lamp.id, false)), false)
	if _ghost == null:
		return
	for child: Node in _ghost.get_children():
		_ghost.remove_child(child)
		child.queue_free()


func _set_fixture_preview(root: Node3D, lit: bool, provisional: bool) -> void:
	var material: Material = root.get_meta("lit" if lit else "unlit") as Material
	if provisional:
		var key: String = "preview_lit" if lit else "preview_dark"
		if not root.has_meta(key):
			# The glass turns into a blue ghost of itself: a proposal, not yet a lamp that is really on.
			var preview := material.duplicate() as StandardMaterial3D
			preview.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			preview.albedo_color = preview.albedo_color.lerp(PaperPal.GHOST, .55)
			preview.albedo_color.a = .7
			if preview.emission_enabled:
				preview.emission = PaperPal.GHOST
			root.set_meta(key, preview)
		material = root.get_meta(key) as Material
	(root.get_meta("glass") as MeshInstance3D).material_override = material
	(root.get_node("Halo") as Node3D).visible = lit
	var light := root.get_node("FixtureLight") as OmniLight3D
	light.visible = lit
	light.light_energy = float(light.get_meta("committed_energy")) * (.55 if provisional else 1.0)


func _show_preview(state: Dictionary) -> void:
	clear_preview()
	var bridges: Dictionary = state.get("bridges", {})
	var committed_bridges: Dictionary = _committed.get("bridges", {})
	for bridge: Dictionary in area.bridges:
		var next_built: int = int(bridges.get(bridge.id, 0))
		var was_built: int = int(committed_bridges.get(bridge.id, 0))
		var sockets: Array[Vector2i] = bridge.sockets
		for index: int in range(sockets.size()):
			if index < next_built and index >= was_built:
				_ghost_box(Vector3(sockets[index].x, ground_y(Vector2(sockets[index])) + 0.11, -sockets[index].y), Vector3(0.95, 0.12, 1.1))
			elif index >= next_built and index < was_built:
				_ghost_box(Vector3(sockets[index].x, ground_y(Vector2(sockets[index])) + 0.15, -sockets[index].y), Vector3(0.95, 0.12, 1.1), true)
	var lamps: Dictionary = state.get("lamps", {})
	var previous_lamps: Dictionary = _committed.get("lamps", {})
	for lamp: Dictionary in area.lamps:
		if bool(lamps.get(lamp.id, false)) != bool(previous_lamps.get(lamp.id, false)):
			if lamp.style == "fixture" and _lamps.has(lamp.id):
				var root: Node3D = _lamps[lamp.id]
				_set_fixture_preview(root, bool(lamps.get(lamp.id, false)), true)
				var halo := root.get_node("Halo") as Node3D
				_ghost_box(halo.global_position, Vector3(.36,.48,.36), not bool(lamps.get(lamp.id, false)))
				continue
			var tall: bool = lamp.style == "beacon"
			_ghost_box(Vector3(lamp.at.x, ground_y(lamp.at) + (2.5 if tall else 1.67), -lamp.at.y), Vector3(0.9, 1.1, 0.9) if tall else Vector3(0.43, 0.6, 0.43),
				not bool(lamps.get(lamp.id, false)))
	var gates: Dictionary = state.get("gates", {})
	var previous_gates: Dictionary = _committed.get("gates", {})
	for gate: Dictionary in area.gates:
		if bool(gates.get(gate.id, false)) != bool(previous_gates.get(gate.id, false)):
			var span := Vector3(1.2, 1.3, 0.17) if gate.axis == "x" else Vector3(0.17, 1.3, 1.2)
			_ghost_box(Vector3(gate.cell.x, ground_y(Vector2(gate.cell)) + 0.72, -gate.cell.y), span, bool(previous_gates.get(gate.id, false)))
	var player: Array = state.get("player", [area.spawn.x, area.spawn.y])
	var next_props: Dictionary = state.get("props", {})
	var previous_props: Dictionary = _committed.get("props", {})
	for prop: Dictionary in area.props:
		if bool(next_props.get(prop.id, false)) != bool(previous_props.get(prop.id, false)):
			_ghost_box(Vector3(prop.at.x, ground_y(prop.at) + 0.80, -prop.at.y), Vector3(prop.rect.size.x + 0.06, 1.45, prop.rect.size.y + 0.06), not bool(next_props.get(prop.id, false)))
	var previous_player: Array = _committed.get("player", [area.spawn.x, area.spawn.y])
	if player != previous_player:
		_ghost_box(Vector3(float(player[0]), ground_y(Vector2(float(player[0]), float(player[1]))) + 0.6, -float(player[1])), Vector3(0.43, 1.2, 0.4))


## Draws what a program would change among the houses, trees and doodads (see AreaBuild.diff): a translucent model
## where something would stand (new, or turned or moved to) and a red one where something would be taken away.
## Capped, so a program that changes hundreds of things still previews quickly.
func show_build_preview(diff: Dictionary) -> void:
	if _ghost == null:
		return
	var shown: int = 0
	for group: String in ["changed", "added", "removed"]:
		for entry: Dictionary in diff.get(group, []):
			if shown >= MAX_PREVIEW_MODELS:
				return
			var model: Node3D = _preview_model(entry)
			if model == null:
				continue
			shown += 1
			var at: Vector2 = entry.at
			model.position = Vector3(at.x, ground_y(at), -at.y)
			if entry.kind != "tree":
				model.rotation_degrees.y = float(AreaDef.FACINGS[str(entry.facing)])
			_tint_model(model, _removed_material if group == "removed" else _ghost_material)
			_ghost.add_child(model)


func _preview_model(entry: Dictionary) -> Node3D:
	var asset: String = str(entry.get("asset", ""))
	if asset != "":
		var model: Node3D = WorldAssets.instantiate(_presented_asset(asset))
		if model != null and entry.kind == "tree":
			model.scale = Vector3.ONE * float(entry.get("size", 1.0))
		return model
	if entry.kind != "tree":
		return null
	var holder := MeshInstance3D.new()
	holder.mesh = build_tree_mesh(float(entry.get("size", 1.0)), tree_seed(entry.at))
	return holder


func _tint_model(node: Node, tint: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = tint
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_tint_model(child, tint)


func _ghost_box(at: Vector3, size: Vector3, removing: bool = false) -> void:
	var mesh := _mesh_box(_ghost, at, size, "cream")
	mesh.material_override = _removed_material if removing else _ghost_material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var outline := MeshInstance3D.new()
	outline.mesh = _box_edges(size)
	outline.material_override = _removed_edge_material if removing else _ghost_edge_material
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.add_child(outline)


## The twelve edges of a box, as lines, so a proposed shape has an outline as well as a fill.
func _box_edges(size: Vector3) -> ArrayMesh:
	var h: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for z: float in [-h.z, h.z]:
		for y: float in [-h.y, h.y]:
			for x: float in [-h.x, h.x]:
				corners.append(Vector3(x, y, z))
	var pairs: Array[Vector2i] = [Vector2i(0, 1), Vector2i(2, 3), Vector2i(4, 5), Vector2i(6, 7), Vector2i(0, 2), Vector2i(1, 3), Vector2i(4, 6), Vector2i(5, 7), Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)]
	var points := PackedVector3Array()
	for pair: Vector2i in pairs:
		points.append(corners[pair.x])
		points.append(corners[pair.y])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


func set_selection(cell: Vector2i) -> void:
	if _selection == null:
		return
	for child: Node in _selection.get_children():
		_selection.remove_child(child)
		child.queue_free()
	if not area.in_bounds(cell):
		return
	_selection.position = Vector3(cell.x, ground_y(Vector2(cell)) + 0.07, -cell.y)
	for offset: float in [-0.46, 0.46]:
		var edge := _mesh_box(_selection, Vector3(offset, 0, 0), Vector3(0.035, 0.035, 0.96), "lit")
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		edge = _mesh_box(_selection, Vector3(0, 0, offset), Vector3(0.96, 0.035, 0.035), "lit")
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func pick_cell(viewport_position: Vector2) -> Vector2i:
	if camera == null or area == null:
		return Vector2i(-1, -1)
	var point: Variant = pick_point(viewport_position)
	if point == null:
		return Vector2i(-1, -1)
	var cell := Vector2i(floori((point as Vector2).x + 0.5), floori((point as Vector2).y + 0.5))
	return cell if area.in_bounds(cell) else Vector2i(-1, -1)


## The logical point of the land under a viewport position, or null if the ray misses. The ray tries each level's
## height from the top down and keeps the first cell standing at least that high, so a terrace's top or cliff face is
## found before the valley floor behind it.
func pick_point(viewport_position: Vector2) -> Variant:
	if camera == null or area == null:
		return null
	var origin := camera.project_ray_origin(viewport_position)
	var direction := camera.project_ray_normal(viewport_position)
	var stair_hit: Variant = _pick_room_stairs(origin, direction)
	if stair_hit != null: return stair_hit
	var flight_hit: Variant = _pick_rising_room_stairs(origin, direction)
	if flight_hit != null: return flight_hit
	for level: int in range(AreaDef.MAX_LEVEL, -1, -1):
		var hit: Variant = Plane(Vector3.UP, float(level) * TerrainBuilder.LEVEL_RISE).intersects_ray(origin, direction)
		if hit == null:
			continue
		var point := Vector2((hit as Vector3).x, -(hit as Vector3).z)
		if level == 0 or area.level_at(Vector2i(floori(point.x + 0.5), floori(point.y + 0.5))) >= level:
			return point
	return null


## Pick the actual negative-height treads through the room's cutaway. A ray
## whose floor intersection is outside the hatch (and north of the cut edge)
## hits solid floor first, so a hidden tread cannot steal that click.
func _pick_rising_room_stairs(origin: Vector3, direction: Vector3) -> Variant:
	for flight: Dictionary in area.interior.get("stair_flights", []):
		var r: Array = flight.rect
		var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		var forward := Vector2(AreaDef.STEPS[flight.up])
		var length: float = rect.size.y if forward.y != 0 else rect.size.x
		var depth: float = length / float(flight.treads.size())
		for index: int in range(flight.treads.size() - 1, -1, -1):
			var hit: Variant = Plane(Vector3.UP, float(flight.treads[index])).intersects_ray(origin, direction)
			if hit == null: continue
			var point := Vector2((hit as Vector3).x, -(hit as Vector3).z)
			if not rect.has_point(point): continue
			var along: float = (point - rect.get_center()).dot(forward) + length * .5
			if along >= index * depth and along < (index + 1) * depth: return point
	return null


func _pick_room_stairs(origin: Vector3, direction: Vector3) -> Variant:
	var well: Dictionary = area.interior.get("stairwell", {})
	if well.is_empty(): return null
	var raw: Array = well.rect
	var rect := Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))
	var floor_hit: Variant = Plane(Vector3.UP, float(well.floor)).intersects_ray(origin, direction)
	if floor_hit != null:
		var floor_point := Vector2((floor_hit as Vector3).x, -(floor_hit as Vector3).z)
		# Solid floor runs from the room's walking front; a hatch at the front edge has none before it.
		var front: float = float(area.interior.get("walk_front", rect.position.y + .5)) - .5
		if not rect.has_point(floor_point) and floor_point.y >= front: return null
	var forward := Vector2(AreaDef.STEPS[well.up])
	var length: float = rect.size.y if forward.y != 0 else rect.size.x
	var depth: float = length / float(well.treads.size())
	for index: int in range(well.treads.size() - 1, -1, -1):
		var hit: Variant = Plane(Vector3.UP, float(well.treads[index])).intersects_ray(origin, direction)
		if hit == null: continue
		var point := Vector2((hit as Vector3).x, -(hit as Vector3).z)
		if not rect.has_point(point): continue
		var along: float = (point - rect.get_center()).dot(forward) + length * .5
		if along >= index * depth and along < (index + 1) * depth: return point
	return null


func _process(delta: float) -> void:
	_elapsed += delta
	for wheel: Node3D in _wheels:
		wheel.rotation.x += delta * 0.22
	if absf(_warmth - _warmth_target) > 0.0005:
		_warmth = move_toward(_warmth, _warmth_target, delta * 0.35)
		_apply_warmth(_warmth)
	if camera != null:
		_update_camera(delta)
		if not _lit_positions.is_empty() and _focus.distance_to(_light_focus) > 1.5:
			_update_light_pool()
	if _quest_marker != null and _quest_marker.visible and not _motes.is_empty():
		_animate_spark_marker()
	elif _quest_marker != null and _quest_marker.visible:
		_quest_marker.rotation.y = _elapsed * 0.6
		var beam := _quest_marker.get_node("Beam") as Node3D
		beam.scale.y = 0.85 + 0.15 * sin(_elapsed * 2.4)
		_quest_marker.scale = Vector3.ONE * (1.0 + 0.06 * sin(_elapsed * 3.2))


func _block(at: Vector3, size: Vector3, material_id: String, rotation: Vector3 = Vector3.ZERO) -> void:
	if not _batches.has(material_id):
		_batches[material_id] = []
	(_batches[material_id] as Array).append(_art_transform * Transform3D(Basis.from_euler(rotation) * Basis.from_scale(size), at))


## One MultiMesh per material (and per map chunk once an area is loaded, so far chunks are culled).
## Turns the queued blocks into one MultiMesh per material (and per map chunk). `bucket`, if given, puts them all in
## one named chunk under `parent_node` instead, which is how a single chunk of trees is redrawn on its own.
func _flush_batches(parent_node: Node = null, bucket: Variant = null, prefix: String = "Blocks", collected: Array = []) -> void:
	var parent: Node = parent_node if parent_node != null else (_content if _content != null else self)
	for material_id: String in _batches:
		BuildPump.pump()
		var buckets: Dictionary = {}
		for transform: Transform3D in _batches[material_id]:
			var key := Vector2i.ZERO
			if bucket != null:
				key = bucket
			elif _chunk > 0:
				key = Vector2i(floori(transform.origin.x / float(_chunk)), floori(transform.origin.z / float(_chunk)))
			if not buckets.has(key):
				buckets[key] = []
			(buckets[key] as Array).append(transform)
		for key: Vector2i in buckets:
			var transforms: Array = buckets[key]
			var mesh := BoxMesh.new()
			mesh.size = Vector3.ONE
			mesh.material = _materials[material_id]
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			multimesh.instance_count = transforms.size()
			for index: int in range(transforms.size()):
				multimesh.set_instance_transform(index, transforms[index])
			var batch := MultiMeshInstance3D.new()
			batch.name = "%s_%s" % [prefix, material_id] if _chunk == 0 else "%s_%s_%d_%d" % [prefix, material_id, key.x, key.y]
			batch.multimesh = multimesh
			if _chunk > 0 and NO_SHADOW.has(material_id):
				batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(batch)
			collected.append(batch)
	_batches.clear()


func _mesh_box(parent: Node3D, at: Vector3, size: Vector3, material_id: String) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = box
	instance.material_override = _part_materials.get(material_id, _materials[material_id])
	instance.position = at
	parent.add_child(instance)
	return instance
