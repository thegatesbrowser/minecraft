extends Node
# class_name TerrainHelper

const VOXEL_TERRAIN_GROUP = "VoxelTerrain"


func get_terrain_tool() -> VoxelTerrain:
	return get_tree().get_first_node_in_group(VOXEL_TERRAIN_GROUP)

