extends Node
class_name TerrainInteraction

signal block_broken(type: StringName)

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
	if is_multiplayer_authority() or Connection.is_server():
		terrain = get_tree().get_first_node_in_group(VOXEL_TERRAIN_GROUP)
		voxel_tool = terrain.get_voxel_tool()
	else:
		block.visible = false


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
	return last_hit != null and !block_is_inside_character and Globals.can_build


func can_break() -> bool:
	return last_hit != null


func get_type() -> StringName:
	var voxel: int = voxel_tool.get_voxel(last_hit.position)
	var array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
	return array[0]


## Places a block with the given type
func place_block(type: StringName) -> void:
	_place_block_server.rpc_id(1, type, last_hit.previous_position)


## Breaks the block and returns the type name
func break_block() -> void:
	_break_block_server.rpc_id(1, last_hit.position)


@rpc("reliable", "authority")
func _place_block_server(type: StringName, position: Vector3) -> void:
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = voxel_blocky_type_library.get_model_index_default(type)
	voxel_tool.do_point(position)


@rpc("reliable", "authority")
func _break_block_server(position: Vector3) -> void:
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = AIR_TYPE

	var voxel: int = voxel_tool.get_voxel(position)
	voxel_tool.do_point(position)

	var array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
	_block_broken_local.rpc_id(get_multiplayer_authority(), array[0])


@rpc("reliable", "any_peer")
func _block_broken_local(type: StringName) -> void:
	block_broken.emit(type)


func _on_Area_body_entered(_body):
	block_is_inside_character = true


func _on_Area_body_exited(_body):
	block_is_inside_character = false
