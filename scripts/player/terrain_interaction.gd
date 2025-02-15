extends Node
class_name TerrainInteraction

@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D

const VOXEL_TERRAIN_GROUP = "VoxelTerrain"

var terrain: VoxelTerrain
var voxel_tool: VoxelTool

var block_is_inside_character: bool
var last_hit: VoxelRaycastResult


func _ready():
	if Connection.is_server() or not is_multiplayer_authority():
		block.visible = false
		return

	terrain = get_tree().get_first_node_in_group(VOXEL_TERRAIN_GROUP)
	voxel_tool = terrain.get_voxel_tool()


func _physics_process(_delta):
	if not is_multiplayer_authority():
		return

	var origin = camera.get_global_transform().origin
	var forward = -camera.get_global_transform().basis.z.normalized()
	last_hit = voxel_tool.raycast(origin, forward, distance)

	if last_hit != null:
		block.show()
		block.global_position = Vector3(last_hit.position) + (Vector3.ONE / 2)
		block.global_rotation = Vector3.ZERO
	else:
		block.hide()


func can_place() -> bool:
	return last_hit != null and !block_is_inside_character


func can_break() -> bool:
	return last_hit != null


func place_block(type: int):
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = type
	voxel_tool.do_point(last_hit.previous_position)


func break_block() -> int:
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = 0

	var voxel = voxel_tool.get_voxel(last_hit.position)
	voxel_tool.do_point(last_hit.position)
	return voxel


func _on_Area_body_entered(_body):
	block_is_inside_character = true


func _on_Area_body_exited(_body):
	block_is_inside_character = false
