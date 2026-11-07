class_name EveningQuest
extends RefCounted
## Nell walks home on the existing lane. The map owns all staging cells.
var game: Game
var _content: Node3D
var _holder: Node3D
var _actor: SpriteActor
var _path: Array[Vector2i] = []

func _init(owner_game: Game) -> void:game=owner_game

func tick(delta: float) -> void:
	if game.area.id!="haverlund-lane" or not game.session.cycle.evening_started:
		_content=null
		return
	var config: Dictionary = game.area.interior.evening
	if _content!=game.view._content:
		_content=game.view._content
		_holder=Node3D.new()
		_holder.name="NellReturned"
		_content.add_child(_holder)
		_actor=SpriteActor.new()
		_actor.skin_id="sparks_nell"
		_holder.add_child(_actor)
		var at: Array = config.arrival if not game.session.state.inspections_read.has("nell-evening") else config.stand
		_holder.position=Vector3(at[0],game.view._deck_height(Vector2(at[0],at[1])),-at[1])
		_path.clear()
		game.view.story_actors["nell"]=_actor
	var at:=Vector2(_holder.position.x,-_holder.position.z)
	var goal:=Vector2i(config.stand[0],config.stand[1])
	game.view.story_cells[Vector2i(roundi(at.x),roundi(at.y))]=true
	if game.notebook_open or not game._modals.is_empty() or game._flow_busy:
		_actor.set_screen_motion(Vector2.ZERO)
		return
	if _path.is_empty() and at.distance_to(Vector2(goal))>.01:
		_path=game.session.rules.find_path(game.session.state,goal,Vector2i(roundi(at.x),roundi(at.y)))
	if not _path.is_empty():
		var next: Vector2i=_path[0]
		if game.view.player_cells().has(next):
			_actor.set_screen_motion(Vector2.ZERO)
			return
		var now: Vector2=at.move_toward(Vector2(next),delta*2.5)
		_actor.set_screen_motion(game.view._screen_direction(Vector2(next)-at))
		_holder.position=Vector3(now.x,game.view._deck_height(now),-now.y)
		if now.distance_to(Vector2(next))<.001:_path.pop_front()
	else:
		_actor.set_screen_motion(Vector2.ZERO)
		_actor.face_screen_direction(game.view._screen_direction(Vector2(game.session.player_cell())-at))

func interaction() -> Dictionary:
	if _content!=game.view._content or not is_instance_valid(_holder):return {}
	if Vector2(game.session.player_cell()).distance_to(Vector2(_holder.position.x,-_holder.position.z))<2.0:
		return {"kind":"nell-evening","id":"nell","label":"Talk to Nell"}
	return {}

func face_player() -> void:
	if not is_instance_valid(_holder):return
	_actor.set_screen_motion(Vector2.ZERO)
	var direction: Vector2=Vector2(game.session.player_cell())-Vector2(_holder.position.x,-_holder.position.z)
	_actor.face_screen_direction(game.view._screen_direction(direction))
	game.session.turn_toward(game.session._direction_toward(game.session.player_cell(),Vector2i(roundi(_holder.position.x),roundi(-_holder.position.z))))
