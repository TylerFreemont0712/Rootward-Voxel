class_name RobotBlink
extends Node
## Small cosmetic eye squash. Never changes face glass, lamp light, movement or gameplay state.

const DURATION: float=.16
var _eyes: Array[Node3D]=[]
var _scales: Array[Vector3]=[]
var _until: float=5.0
var _elapsed: float=-1.0
var _rng:=RandomNumberGenerator.new()

func setup(model: Node3D)->void:
	_rng.randomize()
	_until=_rng.randf_range(3.5,7.0)
	for node: Node in model.find_children("*","MeshInstance3D",true,false):
		if WorldAssetMeta.value(node,"blink_eyes",false):
			_eyes.append(node as Node3D)
			_scales.append((node as Node3D).scale)

func blink()->void:
	_elapsed=0.0
	_until=_rng.randf_range(4.8,7.2)

func _process(delta: float)->void:
	if _eyes.is_empty():return
	if _elapsed<0:
		_until-=delta
		if _until<=0:blink()
		return
	_elapsed+=delta
	var openness: float
	if _elapsed<.05:openness=lerpf(1.0,.08,smoothstep(0,.05,_elapsed))
	elif _elapsed<.085:openness=.08
	else:openness=lerpf(.08,1.0,smoothstep(.085,DURATION,_elapsed))
	for index: int in range(_eyes.size()):
		_eyes[index].scale=_scales[index]*Vector3(1,openness,1)
	if _elapsed>=DURATION:_elapsed=-1.0
