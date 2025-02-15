extends Node

@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D

const VOXEL_TERRAIN_GROUP = "VoxelTerrain"

var terrain: VoxelTerrain
var voxel_tool: VoxelTool
var block_is_inside_character: bool

var _action_place := false
var _action_remove := false


func _ready():
	if Connection.is_server() or not is_multiplayer_authority():
		block.visible = false
		return

	terrain = get_tree().get_first_node_in_group(VOXEL_TERRAIN_GROUP)
	voxel_tool = terrain.get_voxel_tool()


func get_pointed_voxel() -> VoxelRaycastResult:
	var origin = camera.get_global_transform().origin
	var forward = -camera.get_global_transform().basis.z.normalized()
	var hit = voxel_tool.raycast(origin, forward, distance)
	return hit


func _physics_process(_delta):
	if terrain == null:
		return
	
	var hit := get_pointed_voxel()
	if hit != null:
		block.show()
		block.global_position = Vector3(hit.position) + (Vector3.ONE / 2)
		block.global_rotation = Vector3.ZERO
	else:
		block.hide()
	
	if hit != null:
		if _action_place:
			var pos = hit.previous_position
			if !block_is_inside_character:
				place_block(pos)
		
		elif _action_remove:
			break_block(hit.position)

	_action_place = false
	_action_remove = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Mine"):
		_action_remove = true
	
	if event.is_action_pressed("Build"):
		_action_place = true


func place_block(pos: Vector3):
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = 1
	voxel_tool.do_point(pos)


func break_block(pos: Vector3):
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = 0
	voxel_tool.do_point(pos)


func _on_Area_body_entered(_body):
	block_is_inside_character = true


func _on_Area_body_exited(_body):
	block_is_inside_character = false
