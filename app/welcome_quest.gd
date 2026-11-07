class_name WelcomeQuest
extends RefCounted
## App staging over area-owned cells; all routes use the same pure world passages.
var game: Game
var _content: Node3D
var actors: Dictionary = {}
var _braum_path: Array[Vector2i] = []
var _called: bool = false
var _gate_open: bool = false

func _init(owner_game: Game) -> void: game=owner_game

func available() -> bool:
	return game.area.id=="haverlund-lane" and game._journey_completed().has("morning-round") and PlayerItems.has(game.session.state,"field-tablet")

func seen(id: String) -> bool:
	return (game._dialogue_read.get("workshop-scenes",[]) as Array).has(id)

func tick(delta: float) -> void:
	if game.area.id!="haverlund-lane":
		_content=null
		actors.clear()
		return
	if _content!=game.view._content:
		_content=game.view._content
		actors.clear()
		_braum_path.clear()
		_called=false
		_gate_open=false
		var config: Dictionary=game.area.interior.welcome
		for id: String in ["braum","iona"]:
			var spec: Dictionary=config[id]
			var at: Array=spec.get("at",spec.get("spawn"))
			if id=="braum" and seen("braum-welcome"): at=spec.landing
			var holder:=Node3D.new()
			_content.add_child(holder)
			holder.name=id
			var actor:=SpriteAdventurer.new()
			actor.skin_id=str(spec.skin)
			holder.add_child(actor)
			holder.position=Vector3(at[0],game.view._deck_height(Vector2(at[0],at[1])),-at[1])
			actors[id]={"node":holder,"actor":actor}
			game.view.story_actors[id]=actor
	game.view.story_cells.clear()
	for id: String in actors:
		var node: Node3D=actors[id].node
		game.view.story_cells[Vector2i(roundi(node.position.x),roundi(-node.position.z))]=true
	if not available(): return
	var braum: Node3D=actors.braum.node
	var at:=Vector2(braum.position.x,-braum.position.z)
	var config: Dictionary=game.area.interior.welcome
	var destination: Array=config.braum.landing if seen("braum-welcome") else config.braum.call
	var target:=Vector2i(destination[0],destination[1])
	var player: Vector2=Vector2(game.session.player_cell())
	var gate: Node3D=_content.find_child(str(config.gate),true,false) as Node3D
	var gate_at:=Vector2(config.gate_at[0],config.gate_at[1])
	var open: bool=player.distance_to(gate_at)<2.2 or at.distance_to(gate_at)<2.2
	if open!=_gate_open:
		_gate_open=open
		DoorSwing.set_open(gate,open)
	if not game._modals.is_empty() or game.notebook_open:
		(actors.braum.actor as SpriteAdventurer).set_screen_motion(Vector2.ZERO)
		return
	if _braum_path.is_empty() and at.distance_to(Vector2(target))>.05:
		_braum_path=game.session.rules.find_path(game.session.state,target,Vector2i(roundi(at.x),roundi(at.y)))
		if not _braum_path.is_empty() and _braum_path[0]==Vector2i(roundi(at.x),roundi(at.y)): _braum_path.pop_front()
	if not _braum_path.is_empty():
		var next: Vector2i=_braum_path[0]
		if game.view.player_cells().has(next) or (game.view.villagers!=null and VillageLife.occupied(game.view.villagers.life,true).has(next)):
			(actors.braum.actor as SpriteAdventurer).set_screen_motion(Vector2.ZERO)
			return
		game.view.story_cells[next]=true
		var direction: Vector2=Vector2(next)-at
		var now: Vector2=at.move_toward(Vector2(next),delta*2.0)
		braum.position=Vector3(now.x,game.view._deck_height(now),-now.y)
		(actors.braum.actor as SpriteAdventurer).set_screen_motion(game.view._screen_direction(direction))
		if now.distance_to(Vector2(next))<.001: _braum_path.pop_front()
	else:
		(actors.braum.actor as SpriteAdventurer).set_screen_motion(Vector2.ZERO)
		if not _called and not seen("braum-welcome") and player.distance_to(at)<5:
			_called=true
			game.hud.show_toast('Braum: “You there. From Nell’s, are you?” · F to talk')
	# First reaction requires the committed sign; interrupted scenes stay available.
	if game.session.completed.has("proper-welcome") and not seen("welcome-finished") and not game._workshop_dismissed.has("welcome-finished") and at.distance_to(Vector2(config.braum.landing[0],config.braum.landing[1]))<.1 and player.distance_to(Vector2(config.iona.at[0],config.iona.at[1]))<3:
		_face_player("braum")
		_face_player("iona",true)
		game._show_workshop_scene("welcome-finished")

func markers() -> Dictionary:
	if not available():return {}
	var result: Dictionary={}
	if not seen("braum-welcome"):result.braum="!"
	if seen("braum-welcome"):
		if not seen("iona-commission"):result.iona="!"
		elif not game.session.completed.has("proper-welcome"):result.iona="?"
		elif not seen("welcome-finished"):result.iona="!"
	return result

func interaction() -> Dictionary:
	if not available() or actors.is_empty(): return {}
	var point:=Vector2(game.session.player_cell())
	var sign: Dictionary=DisplayCards.find(game.area,"tram-welcome")
	if DisplayCards.in_reach(game.area,game.session.state,sign):return {"kind":"display","id":str(sign.id),"label":"Write the welcome sign's card"}
	for id: String in ["iona","braum"]:
		var node: Node3D=actors[id].node
		if point.distance_to(Vector2(node.position.x,-node.position.z))<1.6:
			return {"kind":"welcome-person","id":id,"label":"Talk to "+("Iona" if id=="iona" else "Braum")}
	return {}

func talk(id: String) -> void:
	_face_player(id,true)
	if id=="braum" and not seen("braum-welcome"):
		game._show_workshop_scene("braum-welcome")
	elif id=="iona" and not seen("braum-welcome"):
		game.hud.show_toast('Iona: “Braum was looking for Nell. He is by his garden gate.”')
	elif id=="iona" and not seen("iona-commission"):
		game._show_workshop_scene("iona-commission","sign-commission")
	elif id=="iona" and game.session.completed.has("proper-welcome") and not seen("welcome-finished"):
		game._show_workshop_scene("welcome-finished")
	else:
		game.hud.show_toast('Iona: “The socket is below the glass. Bring the slate round.”' if id=="iona" else 'Braum: “Iona’s by the tram sign. She’ll tell you what it needs.”')

func _face_player(id: String, turn_player: bool=false) -> void:
	var actor: SpriteAdventurer=actors[id].actor
	var node: Node3D=actors[id].node
	actor.face_screen_direction(game.view._screen_direction(Vector2(game.session.player_cell())-Vector2(node.position.x,-node.position.z)))
	if turn_player:game.session.turn_toward(Vector2i(roundi(node.position.x),roundi(-node.position.z))-game.session.player_cell())
