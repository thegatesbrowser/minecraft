extends NavigationRegion3D


func _on_voxel_terrain_block_loaded(position: Vector3i) -> void:
	bake_navigation_mesh(false)
	VoxelAStarGrid3D

func _on_voxel_terrain_block_unloaded(position: Vector3i) -> void:
	bake_navigation_mesh(false)
