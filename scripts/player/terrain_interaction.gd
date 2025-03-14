extends Node
class_name TerrainInteraction

signal block_broken(type: StringName)

@export var broken_part:PackedScene
@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D
@export var voxel_blocky_type_library: VoxelBlockyTypeLibrary
@export var item_library:ItemsLibrary
@export var break_particle_scene:PackedScene
@export var ping_label:Label

const AIR_TYPE = 0

var terrain: VoxelTerrain
var voxel_tool: VoxelTool

var is_enabled: bool
var block_is_inside_character: bool
var last_hit: VoxelRaycastResult

var last_ping_time: float


func _ready() -> void:
	if is_multiplayer_authority() or Connection.is_server():
		terrain = TerrainHelper.get_terrain_tool()
		voxel_tool = terrain.get_voxel_tool()
	else:
		block.visible = false


func _physics_process(_delta: float) -> void:
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


func enable() -> void:
	is_enabled = true


func disable() -> void:
	is_enabled = false


func can_place() -> bool:
	return last_hit != null and !block_is_inside_character and Globals.can_build


func can_break() -> bool:
	return last_hit != null


func get_type() -> StringName:
	var voxel: int = voxel_tool.get_voxel(last_hit.position)
	var array: Array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
	return array[0]


## Places a block with the given type
func place_block(type: StringName) -> void:
	_place_block_server.rpc_id(1, type, last_hit.previous_position)


## Breaks the block and returns the type name
func break_block() -> void:
	_break_block_server.rpc_id(1, last_hit.position)


@rpc("reliable", "authority")
func _place_block_server(type: StringName, position: Vector3) -> void:
	var item = item_library.get_item(type)
	
	if item.utility != null:
		if item.utility.has_ui:
			Globals.new_ui.emit(position,item.utility.ui_scene_path)
			
		elif item.utility.portal:
			Globals.create_portal.emit(position)
			open_portal_ui.rpc_id(multiplayer.get_remote_sender_id(),position)
	
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
	
	if array[0] != "air":
		var item = item_library.get_item(array[0])
	
		send_item.rpc_id(multiplayer.get_remote_sender_id(),array[0])
		
		if item.utility != null:
			if item.utility.has_ui:
				Globals.remove_ui.emit(position)
				
			elif item.utility.portal:
				Globals.remove_portal_data.emit(position)
				
			elif item.utility.spawn_point:
				Globals.removed_spawnpoint.emit(position)
	
	_block_broken_local.rpc_id(get_multiplayer_authority(), array[0])


@rpc("reliable", "any_peer")
func _block_broken_local(type: StringName) -> void:
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	
	if last_hit != null:
		soundmanager.play_sound(type,last_hit.previous_position)
		#var part = broken_part.instantiate()
		#part.position = last_hit.previous_position
		#get_node("/root/Main").add_child(part)
		
	block_broken.emit(type)


func _on_Area_body_entered(_body: Node3D) -> void:
	block_is_inside_character = true


func _on_Area_body_exited(_body: Node3D) -> void:
	block_is_inside_character = false


@rpc("any_peer","call_remote")
func send_item(type: StringName) -> void:
	var item = item_library.get_item(type)
	Globals.spawn_item_inventory.emit(item)


@rpc("any_peer","call_local")
func open_portal_ui(id: Vector3) -> void:
	Globals.open_portal_url.emit(id)
	pass


@rpc("any_peer","reliable")
func ping_server() -> void:
	ping_client.rpc_id(multiplayer.get_remote_sender_id(),true)


@rpc("any_peer","reliable")
func ping_client(getting: bool = false) -> void:
	if multiplayer.is_server(): return
	if getting:
		var time: float = Time.get_unix_time_from_system() - last_ping_time
		ping_label.text = str("Ping ", roundf(time))
		print(multiplayer.get_unique_id(), " time ", roundf(time))

	else:
		ping_server.rpc_id(1)
		
	last_ping_time = Time.get_unix_time_from_system()


func tick() -> void:
	if ping_label.visible:
		ping_client()


func _on_block_broken(type: StringName) -> void:
	pass # Replace with function body.
