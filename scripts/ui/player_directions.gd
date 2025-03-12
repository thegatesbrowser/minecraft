extends Control

var player_marker_scene = preload("res://scenes/ui/player_icon.tscn")


func update() -> void:
	var playerspawner: PlayerSpawner = get_node("/root/Main").find_child("PlayerSpawner")
	for i in playerspawner.players:
		
		var node = playerspawner.players[i].node as Player
		#print(node)
		
		var your_player = playerspawner.players[multiplayer.get_unique_id()].node as Player
		
		if node != your_player:
			var dir = your_player._camera_transform.direction_to(node.global_position)


func _on_update_timeout() -> void:
	update()
