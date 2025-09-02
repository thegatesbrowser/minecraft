extends Node
class_name TerrainInteraction

signal block_broken(type: StringName)

@export var distance: float = 10
@export var camera: Camera3D
@export var block: Node3D
@export var voxel_blocky_type_library: VoxelBlockyTypeLibrary
@export var item_library:ItemsLibrary
@export var ping_label:Label

const AIR_TYPE = 0

var plants: Array[int]
var terrain: VoxelTerrain
var voxel_tool: VoxelTool

var is_enabled: bool
var block_is_inside_character: bool
var last_hit: VoxelRaycastResult

var last_ping_time: float

var _dirs: Array[Vector3] = [
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1),
	Vector3(-1, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 1),
	Vector3(1, 0, 1),
	
	Vector3(-1, 1, 0),
	Vector3(1, 1, 0),
	Vector3(0, 1, -1),
	Vector3(0, 1, 1),
	Vector3(-1, 1, -1),
	Vector3(1, 1, -1),
	Vector3(-1, 1, 1),
	Vector3(1, 1, 1),

	Vector3(-1, -1, 0),
	Vector3(1, -1, 0),
	Vector3(0, -1, -1),
	Vector3(0, -1, 1),
	Vector3(-1, -1, -1),
	Vector3(1, -1, -1),
	Vector3(-1, -1, 1),
	Vector3(1, -1, 1)
]

var slot_manager:SlotManager

func _ready() -> void:
	slot_manager = get_node("/root/Main").find_child("SlotManager")
	
	plants = [voxel_blocky_type_library.get_model_index_default("tall_grass"),voxel_blocky_type_library.get_model_index_default("fern"),voxel_blocky_type_library.get_model_index_default("flower"),voxel_blocky_type_library.get_model_index_default("reeds")]

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
	last_hit = voxel_tool.raycast(origin, forward, distance, 1)
	#$"../../RotationRoot/Head/Camera3D/RayCast3D".global_position = origin
	#$"../../RotationRoot/Head/Camera3D/RayCast3D".basis.z = forward

	if last_hit != null:
		
		var target_ = get_type()
		var target_block = voxel_blocky_type_library.get_type_from_name(target_).base_model
		#var aabbs = target_block.base_model.collision_aabbs
		block.scale = target_block.collision_aabbs.front().size
		block.global_position = Vector3(last_hit.position) + target_block.collision_aabbs.front().position + (Vector3.ONE / 2)
		block.global_rotation = Vector3.ZERO
		block.show()
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
func place_block(type: StringName, player_pos: Vector3 = Vector3.ZERO) -> void:
	_place_block_server.rpc_id(1, type, last_hit.previous_position, player_pos)
	
	var item = item_library.get_item(type)
	
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	
	#if item is ItemPlant:
		#plant_start_growth(item,last_hit.previous_position)
	
	if item.rotatable:
		## make the block rotation towards the player when placed
		voxel_tool.value = voxel_blocky_type_library.get_model_index_single_attribute(type,get_direction(player_pos,last_hit.previous_position))
	else:
		voxel_tool.value = voxel_blocky_type_library.get_model_index_default(type)
	
	voxel_tool.do_point(last_hit.previous_position)

#func place_block_

## Breaks the block and returns the type name
func break_block() -> void:
	
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = AIR_TYPE
	
	var above_voxel:int = voxel_tool.get_voxel(last_hit.position + Vector3i(0,1,0))
	
	var voxel: int = voxel_tool.get_voxel(last_hit.position)
	
	if plants.has(above_voxel):
		voxel_tool.do_point(last_hit.position + Vector3i(0,1,0))
		
	voxel_tool.do_point(last_hit.position)
	
	_break_block_server.rpc_id(1, last_hit.position)


@rpc("reliable", "authority")
func _place_block_server(type: StringName, position: Vector3, player_pos: Vector3 = Vector3.ZERO) -> void:
	var item = item_library.get_item(type)
	if item:
		if item.utility:
			if item.utility.portal:
				Globals.create_portal.emit(position)
				open_portal_ui.rpc_id(multiplayer.get_remote_sender_id(),position)
				
	
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	
		
	if item.rotatable:
		## make the block rotation towards the player when placed
		voxel_tool.value = voxel_blocky_type_library.get_model_index_single_attribute(type,get_direction(player_pos,position))
	else:
		voxel_tool.value = voxel_blocky_type_library.get_model_index_default(type)
	
	voxel_tool.do_point(position)

@rpc("any_peer","call_local")
func get_voxel_meta(position:Vector3):
	var meta = voxel_tool.get_voxel_metadata(position)
	print("meta ", meta)
	get_parent().rpc_id(multiplayer.get_remote_sender_id(),"receive_meta",meta,voxel_tool.get_voxel(position),position)
	

@rpc("reliable", "authority")
func _break_block_server(position: Vector3) -> void:
	voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	voxel_tool.value = AIR_TYPE
	
	var above_voxel:int = voxel_tool.get_voxel(position + Vector3(0,1,0))
	
	var voxel: int = voxel_tool.get_voxel(position)
	
	if plants.has(above_voxel):
		voxel_tool.do_point(position + Vector3(0,1,0))
		
	voxel_tool.do_point(position)
	
	var array = voxel_blocky_type_library.get_type_name_and_attributes_from_model_index(voxel)
	
	if array[0] != "air":
		var item = item_library.get_item(array[0])
		
		for drop_item in item.drop_items:
			send_item.rpc_id(multiplayer.get_remote_sender_id(),drop_item)
		
		if item.utility != null:
			if item.utility.has_ui:
				voxel_tool.set_voxel_metadata(position,null)
				
			elif item.utility.portal:
				Globals.remove_portal_data.emit(position)
				
			elif item.utility.spawn_point:
				remove_spawn_point.rpc(position)
				
	for di in len(_dirs):
		var npos := position + _dirs[di]
		var nv := voxel_tool.get_voxel(npos)
		if water(nv):
			var water_m = get_tree().get_first_node_in_group("Water Updater")
			water_m.schedule(npos)
		
	_block_broken_local.rpc_id(get_multiplayer_authority(), array[0])


@rpc("reliable", "any_peer")
func _block_broken_local(type: StringName) -> void:
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	
	if last_hit != null:
		soundmanager.play_sound(type,last_hit.previous_position)
		
	block_broken.emit(type)


func _on_Area_body_entered(_body: Node3D) -> void:
	block_is_inside_character = true


func _on_Area_body_exited(_body: Node3D) -> void:
	block_is_inside_character = false


@rpc("any_peer","call_remote")
func send_item(type: StringName) -> void:
	var slot_manager = get_node("/root/Main").find_child("SlotManager")
	## if the player is holding a tool it will be damaged
	if slot_manager.selected_slot != null:
		if slot_manager.selected_slot.item != null:
			if slot_manager.selected_slot.item is ItemTool:
				slot_manager.selected_slot.used()
						
	## gives the broken item to the player
	var item = item_library.get_item(type)
	#Globals.spawn_item_inventory.emit(item)
	slot_manager.add_item_to_hotbar_or_inventory(item)


@rpc("any_peer","call_local")
func open_portal_ui(id: Vector3) -> void:
	Globals.open_portal_url.emit(id)
	pass

@rpc("any_peer","call_local")
func remove_spawn_point(pos: Vector3) -> void:
	var player = get_parent().get_parent() as Player
	if player.spawn_position == pos + Vector3(0,1,0):
		player.spawn_position = player.start_position

func water(v:int):
	var _is_water:bool = false
	if v == voxel_blocky_type_library.get_model_index_default("water_full"):
		_is_water = true
	if v ==  voxel_blocky_type_library.get_model_index_default("water_top"):
		_is_water = true
	return _is_water

func get_direction(player_pos:Vector3, place_pos:Vector3):
	var dir = place_pos.direction_to(player_pos)
	print(dir)
	
	if round(dir).x != 0:
		if round(dir).x == 1:
			return VoxelBlockyAttributeDirection.DIR_NEGATIVE_X
		else:
			return VoxelBlockyAttributeDirection.DIR_POSITIVE_X
			
	elif round(dir).z != 0:
		if round(dir).z == 1:
			return VoxelBlockyAttributeDirection.DIR_NEGATIVE_Z
		else:
			return VoxelBlockyAttributeDirection.DIR_POSITIVE_Z

#func plant_start_growth(plant:ItemPlant,position:Vector3):
	#var growth_timer = get_tree().create_timer(plant.time_to_grow)
	#await growth_timer.timeout
	#_place_block_server.rpc_id(1,plant.next_plant_stage.unique_name,position)
	#place_block(plant.next_plant_stage.unique_name)
