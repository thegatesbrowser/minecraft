extends Node

@export var terrain_interaction:Node
@export var items_library: ItemsLibrary
@export var voxel_library = preload("res://resources/voxel_block_library.tres")
@export var floor_ray:RayCast3D
@export var drop_item_scene:PackedScene
@export var hand_ani:AnimationPlayer
@export var interactable_icon:TextureRect
@export var break_block:Node3D

var terrian:VoxelTerrain
var voxel_tool:VoxelTool
var eat_timer: Timer
var timer: Timer
var slot_manager:SlotManager
@export var camera: Camera3D

func _ready():
	slot_manager = get_node("/root/Main").find_child("SlotManager")
	Globals.drop_item.connect(drop)
	items_library.init_items()
	terrain_interaction.enable()
	voxel_tool = TerrainHelper.get_terrain_tool().get_voxel_tool()
	
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)
	
	eat_timer = Timer.new()
	eat_timer.one_shot = true
	add_child(eat_timer)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority() and Connection.is_peer_connected: return
	if Globals.paused: return
	
	if is_interactable():
		interactable_icon.show()
	else:
		interactable_icon.hide()
	
	if Input.is_action_just_pressed("Build"):
		if terrain_interaction.can_place():
			if Globals.can_build:
				
				var soundmanager = get_node("/root/Main").find_child("SoundManager")
				soundmanager.play_sound(Globals.current_block,terrain_interaction.last_hit.position)
				var player_pos = get_parent().global_position
				terrain_interaction.place_block(Globals.current_block,player_pos)
				Globals.remove_item_from_hotbar.emit()
				
		if Input.is_action_pressed("Build"):
			if eat_timer.is_stopped():
				if slot_manager.selected_slot != null:
					var item =  slot_manager.selected_slot.item
					if item is ItemFood:
						
						eat_timer.wait_time = item.eat_time
						eat_timer.name = "food eat timer"
						eat_timer.start()
						
						if hand_ani.current_animation != "eat":
								hand_ani.play("eat")
								
						await eat_timer.timeout
						
						if Input.is_action_pressed("Build"):
							#eat_sfx.play()
							
								
							if item != null:
								Globals.hunger_points_gained.emit(item.food_points)
								print("ate ", item.unique_name, " gained ", item.food_points," food points")
								Globals.remove_item_from_hotbar.emit()
								Globals.remove_item_in_hand.emit()
								hand_ani.stop()

	if Input.is_action_just_pressed("Mine"):
		if !get_parent().crouching:
			interaction() ## checks for interactions
			if is_interactable(): return
				
	if Input.is_action_pressed("Mine"):
		
		var last_mine_pos:Vector3i
		if timer.is_stopped():
			if terrain_interaction.can_break():
				var type = terrain_interaction.get_type()
				if type == "air": return
				
				var item = items_library.get_item(type) as ItemBlock
				
				if slot_manager.selected_slot != null:
					if slot_manager.selected_slot.item is ItemTool:
						var holding_item = slot_manager.selected_slot.item as ItemTool
						if holding_item.suitable_objects.has(item):
							timer.wait_time = item.break_time - holding_item.breaking_efficiency
						else:
							timer.wait_time = item.break_time
					else:
							timer.wait_time = item.break_time
				else:
					timer.wait_time = item.break_time
					
				#print(timer.wait_time )

				timer.start()
				if last_mine_pos == Vector3i.ZERO:
					last_mine_pos = terrain_interaction.last_hit.position
				elif last_mine_pos != terrain_interaction.last_hit.position:
					timer.start()
					
				break_block.start_break(item.break_time)
					
				await timer.timeout
				
				if Input.is_action_pressed("Mine"):
					if terrain_interaction.last_hit != null:
						terrain_interaction.break_block()
						break_block.stop()
						last_mine_pos = Vector3i.ZERO
						
						
	else:
		break_block.stop()
		timer.stop()


func is_interactable() -> bool:
	if terrain_interaction.last_hit == null: return false
	
	var type = terrain_interaction.get_type()
	
	if type == "air": return false
	
	var item = items_library.get_item(type)
	
	if item == null:
		return false
		
	if item.utility != null:
		return true
	else:
		return false


func interaction() -> void:
	if terrain_interaction.last_hit == null: return
	
	var type = terrain_interaction.get_type()
	
	if type == "air": return
	
	var item = items_library.get_item(type)

	if item != null:
		if item.utility != null:
			if item.utility.has_ui:
				terrain_interaction.rpc_id(1,"get_voxel_meta",terrain_interaction.last_hit.position)
				
			if item.utility.spawn_point:
				get_parent().spawn_position = terrain_interaction.last_hit.position + Vector3i(0,1,0)
				print_debug("spawn point set ",get_parent().spawn_position)
			
			if item.utility.portal:
				terrain_interaction.rpc_id(1,"get_voxel_meta",terrain_interaction.last_hit.position)
				#

func drop(owner_id: int ,item: ItemBase ,amount := 1) -> void:
	print("drop")
	if get_multiplayer_authority() != owner_id: return
	print(get_multiplayer_authority(), " is ", owner_id)
	if floor_ray.is_colliding():
		var pos = floor_ray.get_collision_point()
		var spawn_node = get_node("/root/Main").find_child("Objects")
		
		sync_drop.rpc_id(1,item.resource_path,pos,amount)


@rpc("any_peer","call_local")
func sync_drop(item_path: String, pos: Vector3 ,amount := 1) -> void:
	Globals.add_object.emit([1,pos,"res://scenes/items/dropped_item.tscn",item_path,amount])

@rpc("any_peer","call_local")
func receive_meta(meta_data, type:int, position:Vector3):
	var item_name = voxel_library.get_type_name_and_attributes_from_model_index(type)[0]
	var item = items_library.get_item(item_name)
		
	print("receive ",meta_data, "type ",type)
	if type == voxel_library.get_model_index_default("portal"):
		Globals.enter_portal.emit(meta_data)
		
	if item_name == "chest":
		print("chest")

		print("open ",position)
		Globals.open_ui.emit(item.utility.ui_scene_path,position, meta_data)
	
	if item_name == "cooker":
		print("cooker")

		print("open ",position)
		Globals.open_ui.emit(item.utility.ui_scene_path,position,meta_data)
		
	if item_name == "blueprint_station":
		Globals.open_ui.emit(item.utility.ui_scene_path,position,null)
