extends Node
class_name TerrainInteraction

@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D
@export var voxel_blocky_type_library: VoxelBlockyTypeLibrary

const VOXEL_TERRAIN_GROUP = "VoxelTerrain"
const AIR_TYPE = 0

var terrain: VoxelTerrain
var voxel_tool: VoxelTool

var is_enabled: bool
var block_is_inside_character: bool
var last_hit: VoxelRaycastResult


func _ready():
	if Connection.is_server() or not is_multiplayer_authority():
		block.visible = false
		return

	terrain = get_tree().get_first_node_in_group(VOXEL_TERRAIN_GROUP)
	voxel_tool = terrain.get_voxel_tool()


func _physics_process(_delta):
	if not is_multiplayer_authority() or not is_enabled:
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


func enable():
	is_enabled = true


func disable():
	is_enabled = false


func can_place() -> bool:
	return last_hit != null and !block_is_inside_character


func can_break() -> bool:
	return last_hit != null


## Places a block with the given type
func place_block(type: StringName):
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = voxel_blocky_type_library.get_model_index_default(type)
	voxel_tool.do_point(last_hit.previous_position)


## Breaks the block and returns the type name
func break_block() -> StringName:
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = AIR_TYPE

	var voxel: int = voxel_tool.get_voxel(last_hit.position)
	voxel_tool.do_point(last_hit.position)

	var array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
	return array[0]


func _on_Area_body_entered(_body):
	block_is_inside_character = true


func _on_Area_body_exited(_body):
	block_is_inside_character = false
