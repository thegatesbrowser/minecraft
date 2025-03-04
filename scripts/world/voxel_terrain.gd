extends VoxelTerrain


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_disconnected(_peer_id: int) -> void:
	if multiplayer.get_peers().size() == 0:
		save_modified_blocks()
		print("All peers disconnected, saving modified blocks")


func exit_tree() -> void:
	save_modified_blocks()
	print("Closing game, saving modified blocks")
