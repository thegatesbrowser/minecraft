extends Node

@export var player: Player
@export var camera: Camera3D
@export var camera_height: float
@export var creature_point: MeshInstance3D

var creature_points: Dictionary = {}


func _ready() -> void:
	if not is_multiplayer_authority() and not Connection.is_server():
		queue_free()


func _process(_delta: float) -> void:
	camera.global_position = player.global_position
	camera.global_position.y = camera_height
	
