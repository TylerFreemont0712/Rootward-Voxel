extends SceneTree
## Authoring repair: choose nearby reachable service cells for newly connected street fittings.
func _initialize() -> void:
	for id: String in ["haverlund-square","haverlund-lane","city-hall","workshop-loft"]:
		var area: AreaDef=AreaStore.load_area(id)
		if area==null:quit(1);return
		var rules:=LabWorld.new(area)
		var state: Dictionary=rules.initial_state()
		var path: String="res://content/areas/"+id+".json"
		var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		var changed: bool=false
		for lamp: Dictionary in doc.lamps:
			if not lamp.has("stand"):continue
			var at:=Vector2i(lamp.stand[0],lamp.stand[1])
			if rules.is_walkable(state,at) and (at==area.spawn or not rules.find_path(state,at).is_empty()):continue
			var candidates: Array[Vector2i]=[]
			for x: int in range(maxi(0,at.x-3),mini(area.width,at.x+4)):
				for y: int in range(maxi(0,at.y-3),mini(area.height,at.y+4)):
					var cell:=Vector2i(x,y)
					if rules.is_walkable(state,cell):candidates.append(cell)
			candidates.sort_custom(func(a: Vector2i,b: Vector2i)->bool:return Vector2(a).distance_squared_to(Vector2(lamp.at[0],lamp.at[1]))<Vector2(b).distance_squared_to(Vector2(lamp.at[0],lamp.at[1])))
			for cell: Vector2i in candidates:
				if cell==area.spawn or not rules.find_path(state,cell).is_empty():
					lamp.stand=[cell.x,cell.y]
					changed=true
					print(id," ",lamp.id," service point ",at," -> ",cell)
					break
		if changed:
			var out:=FileAccess.open(path,FileAccess.WRITE)
			out.store_string(JSON.stringify(doc,"  ",false)+"\n")
	quit()
