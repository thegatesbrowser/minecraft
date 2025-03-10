extends Node
class_name TerrainInteraction

signal block_broken(type: StringName)

@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D
@export var voxel_blocky_type_library: VoxelBlockyTypeLibrary
@export var item_library:ItemsLibrary
@export var break_particle_scene:PackedScene

const AIR_TYPE = 0

var terrain: VoxelTerrain
var voxel_tool: VoxelTool

var is_enabled: bool
var block_is_inside_character: bool
var last_hit: VoxelRaycastResult


func _ready():
	
	if is_multiplayer_authority() or Connection.is_server():
		terrain = TerrainHelper.get_terrain_tool()
		voxel_tool = terrain.get_voxel_tool()
	else:
		#ping.rpc_id(1,multiplayer.get_unique_id(),true)
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
	call_server.rpc_id(1)
	_place_block_server.rpc_id(1, type, last_hit.previous_position)


## Breaks the block and returns the type name
func break_block() -> void:
	call_server.rpc_id(1)
	#var break_particle = break_particle_scene.instantiate()
	#break_particle.global_position = last_hit.position
	#get_tree().root.add_child(break_particle)
	_break_block_server.rpc_id(1, last_hit.position)


@rpc("reliable", "authority")
func _place_block_server(type: StringName, position: Vector3) -> void:
	var item = item_library.get_item(type)
	
	if item.utility != null:
		if item.utility.has_ui:
			Globals.new_ui.emit(position,item.utility.ui_scene_path)
		elif item.utility.portal:
			Globals.create_portal.emit(position)
	
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
	
	send_item.rpc_id(multiplayer.get_remote_sender_id(),array[0])

	_block_broken_local.rpc_id(get_multiplayer_authority(), array[0])


@rpc("reliable", "any_peer")
func _block_broken_local(type: StringName) -> void:
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	if last_hit != null:
		soundmanager.play_sound(type,last_hit.position)
				
	block_broken.emit(type)

func _on_Area_body_entered(_body):
	block_is_inside_character = true

func _on_Area_body_exited(_body):
	block_is_inside_character = false

@rpc("any_peer","call_remote")
func send_item(type:String):
	var item = item_library.get_item(type)
	Globals.spawn_item_inventory.emit(item)

var last_time:float 

@rpc("any_peer","reliable")
func call_server():
	send_client.rpc_id(multiplayer.get_remote_sender_id(),true)
	
	
@rpc("any_peer","reliable")
func send_client(getting:bool = false):
	if multiplayer.is_server(): return
	if getting:
		var time = Time.get_unix_time_from_system() - last_time 
		$"../../Ping".text = str("Ping ",roundf(time))
		print(multiplayer.get_unique_id(), " time ", roundf(time))
		
	else:
		call_server.rpc_id(1)
		
	last_time = Time.get_unix_time_from_system()


func tick() -> void:
	if $"../../Ping".visible:
		send_client()
