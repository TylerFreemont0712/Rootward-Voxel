class_name VoxelAdventurer
extends Node3D
## A small textured, articulated 3D character. It has no authority over movement or world state.

var materials: Dictionary = {}
var walking: bool = false
var _phase: float = 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []


func _ready() -> void:
	name = "Adventurer"
	# Chunky boots and trouser legs retain a readable gap between the feet.
	for side: float in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13, 0.47, 0.0)
		add_child(leg)
		_legs.append(leg)
		_box(leg, Vector3(0, -0.13, 0), Vector3(0.19, 0.3, 0.23), "cloth_dark")
		_box(leg, Vector3(0, -0.32, 0.045), Vector3(0.23, 0.25, 0.34), "leather")
		_box(leg, Vector3(0, -0.43, 0.05), Vector3(0.24, 0.055, 0.36), "wood_dark")
		_box(leg, Vector3(0, -0.22, 0), Vector3(0.24, 0.065, 0.28), "leather_light")
		_box(leg, Vector3(0, -0.31, 0.218), Vector3(0.08, 0.055, 0.025), "gold")
	_box(self, Vector3(0, 0.665, 0), Vector3(0.46, 0.49, 0.32), "cloth")
	_box(self, Vector3(0, 0.6, -0.19), Vector3(0.49, 0.46, 0.09), "cloth_dark")
	_box(self, Vector3(0, 0.47, 0), Vector3(0.49, 0.075, 0.35), "leather")
	_box(self, Vector3(-0.04, 0.47, 0.19), Vector3(0.105, 0.09, 0.045), "gold")
	_box(self, Vector3(-0.04, 0.47, 0.219), Vector3(0.055, 0.045, 0.018), "leather")
	for side: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.29, 0.83, 0)
		add_child(arm)
		_arms.append(arm)
		_box(arm, Vector3(0, -0.10, 0), Vector3(0.17, 0.28, 0.25), "cloth")
		_box(arm, Vector3(0, -0.24, 0), Vector3(0.19, 0.08, 0.26), "cloth_light")
		_box(arm, Vector3(0, -0.32, 0.02), Vector3(0.15, 0.13, 0.18), "skin")
	# Diagonal leather strap, folded satchel flap, stitching and a brass clasp.
	var strap := _box(self, Vector3(0.04, 0.69, 0.182), Vector3(0.065, 0.49, 0.035), "leather_light")
	strap.rotation.z = -0.67
	_box(self, Vector3(0.32, 0.49, -0.035), Vector3(0.21, 0.28, 0.3), "leather")
	_box(self, Vector3(0.32, 0.585, 0.02), Vector3(0.225, 0.11, 0.3), "leather_light")
	_box(self, Vector3(0.32, 0.52, 0.177), Vector3(0.065, 0.07, 0.025), "gold")
	# A warm ochre scarf keeps the original fantasy-adventurer palette.
	_box(self, Vector3(0, 0.89, 0.025), Vector3(0.49, 0.115, 0.37), "scarf")
	var scarf_tail := _box(self, Vector3(-0.14, 0.73, 0.21), Vector3(0.13, 0.26, 0.055), "scarf")
	scarf_tail.rotation.z = -0.12
	_box(self, Vector3(-0.125, 0.61, 0.245), Vector3(0.13, 0.035, 0.025), "cream")
	# Large head and a painted face stay readable at the game's orthographic scale.
	_box(self, Vector3(0, 1.105, 0), Vector3(0.49, 0.43, 0.43), "skin")
	for side: float in [-1.0, 1.0]:
		_box(self, Vector3(side * 0.255, 1.075, 0.02), Vector3(0.065, 0.115, 0.1), "skin")
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.49, 0.43)
	face.mesh = quad
	face.material_override = materials["face"]
	face.position = Vector3(0, 1.105, 0.216)
	add_child(face)
	# An asymmetric fringe and lifted locks break up the old flat cuboid cap.
	_box(self, Vector3(0, 1.32, -0.015), Vector3(0.54, 0.16, 0.48), "hair")
	_box(self, Vector3(0, 1.16, -0.205), Vector3(0.52, 0.3, 0.11), "hair")
	for index: int in range(5):
		var at := Vector3(-0.22 + float(index) * 0.105, 1.29 + float(index % 2) * 0.025, 0.204)
		var lock := _box(self, at, Vector3(0.13, 0.17 + float(index % 3) * 0.025, 0.10), "hair_light" if index == 1 else "hair")
		lock.rotation.z = -0.15 + float(index) * 0.06
	for index: int in range(4):
		var lock := _box(self, Vector3(-0.17 + float(index) * 0.12, 1.405, -0.025), Vector3(0.15, 0.11, 0.25), "hair_light" if index % 3 == 0 else "hair")
		lock.rotation.z = -0.16 + float(index) * 0.10


func _process(delta: float) -> void:
	_phase += delta * (12.0 if walking else 3.0)
	for index: int in range(_legs.size()):
		var side: float = -1.0 if index == 0 else 1.0
		_legs[index].rotation.x = sin(_phase) * 0.4 * side if walking else 0.0
		_arms[index].rotation.x = -sin(_phase) * 0.3 * side if walking else sin(_phase) * 0.025 * side


func _box(parent: Node3D, at: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = materials[material]
	instance.position = at
	parent.add_child(instance)
	return instance
