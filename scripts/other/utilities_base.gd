extends StaticBody3D

@export var resource: Utilities

@onready var body: MeshInstance3D = $body
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ui: Control = $UI

var mesh: MeshInstance3D
var inventory


func _ready() -> void:
	if resource:
		body.mesh = resource.mesh
		collision_shape_3d.shape = body.mesh.create_trimesh_shape()
		if resource.has_inventory:
			Globals.add_subinventory.emit(self)


func interact():
	if resource.has_inventory:
		Globals.open_inventory.emit(self)
