class_name MorningRoom
extends RefCounted
## The first home's authored cutaway shell. Furniture instances/collision are
## still in morning-bedroom.json; this draws its windows, joinery and small details.


static func build(area: AreaDef, block: Callable) -> void:
	var p: Dictionary = area.interior.materials.duplicate(true)
	p.merge(area.interior.get("finishes", {}), true)
	var floor: String = str(p.get("floor", "herringbone_oak"))
	var walls: String = str(p.get("walls", "limewash"))
	var timber: String = str(p.get("timber", "timber_panels"))
	var front: float=float(area.interior.exit[1])-.12
	var rear: float=area.height-.5
	var depth: float=rear-front
	var middle: float=(front+rear)*.5
	block.call(Vector3(5.5,-.16,-middle),Vector3(12,.35,depth),"wood_dark")
	block.call(Vector3(5.5,.018,-middle),Vector3(11.7,.05,depth-.02),floor)
	# A darker oak border and a pale stone entrance distinguish the room's floor.
	for x: float in [-.30,11.30]:block.call(Vector3(x,.055,-middle),Vector3(.20,.04,depth-.02),timber)
	for y: float in [front+.10,10.30]:block.call(Vector3(5.5,.055,-y),Vector3(11.8,.04,.20),timber)
	block.call(Vector3(6,.061,-(front+1.8)*.5),Vector3(1.4,.06,1.8-front),"limestone_flags")
	# Far wall and west wall, with a lower panelled skirt. Near sides stay cut away.
	block.call(Vector3(-.40,1.65,-middle),Vector3(.24,3.3,depth),walls)
	block.call(Vector3(5.5,1.65,-10.40),Vector3(12,3.3,.24),walls)
	for y: float in [front+.1,2.5,5,7.5,10]:block.call(Vector3(-.24,1.7,-y),Vector3(.15,3.4,.15),timber)
	for x: float in [0,3.7,7.1,11]:block.call(Vector3(x,1.7,-10.22),Vector3(.15,3.4,.15),timber)
	block.call(Vector3(-.22,.48,-middle),Vector3(.12,.82,depth-.1),timber)
	block.call(Vector3(5.5,.48,-10.21),Vector3(11.3,.82,.12),timber)
	block.call(Vector3(5.5,3.20,-10.19),Vector3(11.5,.18,.22),"wood_dark")
	# One broad, deeply framed morning window over the desk; a smaller bedside one.
	for x: float in [2.0,8.3]:
		var width: float = 2.0 if x<3 else 2.7
		block.call(Vector3(x,2.05,-10.19),Vector3(width+.25,1.63,.14),"wood_dark")
		block.call(Vector3(x,2.05,-10.08),Vector3(width,1.40,.10),"window_warm")
		for side: float in [-1,1]:
			block.call(Vector3(x+side*width*.5,2.05,-9.97),Vector3(.12,1.57,.20),"oak_light")
		block.call(Vector3(x,2.05,-9.96),Vector3(.075,1.42,.18),"wood_dark")
		block.call(Vector3(x,2.05,-9.96),Vector3(width,.075,.18),"wood_dark")
		block.call(Vector3(x,1.28,-9.94),Vector3(width+.38,.14,.50),"oak_light")
		# Soft linen curtains drawn back from the light, with a wooden rail.
		block.call(Vector3(x,2.96,-9.90),Vector3(width+.58,.065,.065),"wood_dark")
		for side: float in [-1,1]:
			block.call(Vector3(x+side*(width*.5+.10),2.10,-9.85),Vector3(.23,1.58,.12),str(p.get("cloth","woven_linen")))
	# A framed botanical print on the solid wall between the windows, above
	# the central bed. Both layers sit against the plaster rather than floating.
	block.call(Vector3(5.5,2.3,-10.22),Vector3(1.35,1.02,.07),"wood_dark")
	block.call(Vector3(5.5,2.3,-10.175),Vector3(1.13,.80,.018),"sage_wallpaper")
	var exit: Array=area.interior.exit
	for post: Rect2 in HouseInstances.frame_posts(area):block.call(Vector3(post.get_center().x,1.25,-post.get_center().y),Vector3(post.size.x,2.45,post.size.y),"wood_dark")
	block.call(Vector3(exit[0],2.48,-float(exit[1])),Vector3(1.72,.18,.24),"oak_light")
	block.call(Vector3(exit[0],.10,-float(exit[1])),Vector3(1.42,.08,.24),"stone_light")
	# The rug comes from the area document; small details follow their furniture.
	for item: Dictionary in area.interior.furniture:
		if item.kind!="rug":continue
		block.call(Vector3(item.at.x,.073,-item.at.y),Vector3(item.size.x,.04,item.size.y),"cloth_dark")
		block.call(Vector3(item.at.x,.096,-item.at.y),Vector3(item.size.x-.25,.025,item.size.y-.25),str(p.get("rug","violet_quilt")))
	var desk: Dictionary=area.prop("desk")
	var yaw: float=deg_to_rad(float(AreaDef.FACINGS[desk.facing]))
	block.call(_on_prop(area,"desk",Vector3(-.15,.974,.04)),Vector3(.49,.035,.38),"cream",Vector3(0,yaw,0))
	block.call(_on_prop(area,"desk",Vector3(-.15,.996,.04)),Vector3(.018,.01,.38),"wood_dark",Vector3(0,yaw,0))
	block.call(_on_prop(area,"desk",Vector3(.45,1.0,.05)),Vector3(.12,.17,.12),"teal")
	block.call(_on_prop(area,"desk",Vector3(.45,1.08,.05)),Vector3(.08,.025,.08),"gold")
	block.call(_on_prop(area,"washstand",Vector3(0,.895,.08)),Vector3(.45,.04,.34),str(p.get("cloth","woven_linen")),Vector3(0,deg_to_rad(float(AreaDef.FACINGS[area.prop("washstand").facing])),0))


static func _on_prop(area: AreaDef,id: String,offset: Vector3) -> Vector3:
	var prop: Dictionary=area.prop(id)
	var origin:=Vector3(prop.at.x,0,-prop.at.y)
	return origin+offset.rotated(Vector3.UP,deg_to_rad(float(AreaDef.FACINGS[prop.facing])))*float(prop.scale)
