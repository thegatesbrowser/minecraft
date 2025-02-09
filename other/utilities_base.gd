extends StaticBody3D

@export var resource:Utilities
var mesh:MeshInstance3D

@onready var body: MeshInstance3D = $body
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ui: Control = $UI


var inventory

func _ready() -> void:
	print("ut")
	if resource:
		body.mesh = resource.mesh
		collision_shape_3d.shape = body.mesh.create_trimesh_shape()
		if resource.has_inventory:
			Globals.add_subinventory.emit(self)
func interact():
	if resource.has_inventory:
		print("open inventory")
		Globals.open_inventory.emit(self)
		
