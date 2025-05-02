extends Node3D

@export var camera:Camera3D
@export var height:float = 30

func _process(delta: float) -> void:
	camera.global_position = Vector3(global_position.x,height,global_position.z)
