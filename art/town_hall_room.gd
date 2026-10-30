class_name TownHallRoom
extends RefCounted
## Civic cutaway shell; all furnishing positions and collision live in its area document.


static func build(area: AreaDef, block: Callable) -> void:
	var p: Dictionary=area.interior.materials.duplicate(true)
	p.merge(area.interior.get("finishes",{}),true)
	var front: float=float(area.interior.exit[1])-.12
	var rear: float=area.height-.5
	var depth: float=rear-front
	var mid: float=(rear+front)*.5
	var cx: float=(area.width-1)*.5
	var timber: String=str(p.timber)
	block.call(Vector3(cx,-.15,-mid),Vector3(area.width,.34,depth),"stone_dark")
	block.call(Vector3(cx,.03,-mid),Vector3(area.width-.12,.06,depth),str(p.floor))
	# A tall panelled council wall distinguishes the civic room from a cottage.
	block.call(Vector3(cx,2.15,-rear+.08),Vector3(area.width,4.3,.22),str(p.walls))
	block.call(Vector3(-.40,2.15,-mid),Vector3(.22,4.3,depth),str(p.walls))
	block.call(Vector3(cx,.60,-rear+.23),Vector3(area.width-.2,1.15,.10),timber)
	block.call(Vector3(-.24,.6,-mid),Vector3(.12,1.15,depth),timber)
	for x: float in [0,4.7,10.5,15]:
		block.call(Vector3(x,2.15,-rear+.22),Vector3(.19,4.3,.22),"wood_dark")
	for y: float in [3,6,9,12]:
		block.call(Vector3(-.23,2.15,-y),Vector3(.19,4.3,.22),"wood_dark")
	block.call(Vector3(cx,4.12,-rear+.22),Vector3(area.width,.22,.28),"wood_dark")
	for x: float in [2.5,12.5]:
		block.call(Vector3(x,3.25,-rear+.24),Vector3(2.2,1.5,.14),"wood_dark")
		block.call(Vector3(x,3.25,-rear+.34),Vector3(1.96,1.25,.10),"window_warm")
		for dx: float in [-.95,0,.95]:
			block.call(Vector3(x+dx,3.25,-rear+.44),Vector3(.065,1.38,.14),"oak_light")
		block.call(Vector3(x,3.25,-rear+.44),Vector3(2.05,.07,.14),"oak_light")
		block.call(Vector3(x,2.50,-rear+.45),Vector3(2.38,.14,.40),"stone_light")
	# Framed tree seal above the council seats, with visible branches and leaf pads.
	block.call(Vector3(cx,2.98,-rear+.26),Vector3(2.4,2.0,.12),"wood_dark")
	block.call(Vector3(cx,2.98,-rear+.34),Vector3(2.15,1.75,.06),"teal")
	block.call(Vector3(cx,2.75,-rear+.39),Vector3(.12,.98,.035),"gold")
	for side: float in [-1,1]:
		block.call(Vector3(cx+side*.25,3.0,-rear+.40),Vector3(.08,.65,.035),"gold",Vector3(0,0,-side*.75))
	for offset: Vector2 in [Vector2(-.48,.25),Vector2(.48,.25),Vector2(-.25,.6),Vector2(.25,.6),Vector2(0,.82)]:
		block.call(Vector3(cx+offset.x,2.75+offset.y,-rear+.42),Vector3(.42,.24,.04),"gold")
	for item: Dictionary in area.interior.furniture:
		if item.kind=="rug":
			block.call(Vector3(item.at.x,.075,-item.at.y),Vector3(item.size.x,.035,item.size.y),"teal")
			block.call(Vector3(item.at.x,.096,-item.at.y),Vector3(item.size.x-.18,.018,item.size.y-.18),str(p.rug))
	for post: Rect2 in HouseInstances.frame_posts(area):
		block.call(Vector3(post.get_center().x,1.3,-post.get_center().y),Vector3(post.size.x,2.6,post.size.y),"wood_dark")
	var exit: Array=area.interior.exit
	block.call(Vector3(exit[0],2.64,-float(exit[1])),Vector3(1.72,.18,.24),"oak_light")
	block.call(Vector3(exit[0],.08,-float(exit[1])),Vector3(1.4,.08,.24),"stone_light")
