extends Node3D


func _process(delta: float) -> void:
	var player = get_node("/root/Main").find_child(str(multiplayer.get_unique_id()))
	if player != null:
		global_position = player.global_position
