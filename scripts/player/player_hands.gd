extends Node

@export var break_part:GPUParticles3D
@export var terrain_interaction:Node
@export var items_library: ItemsLibrary
@export var voxel_library = preload("res://resources/voxel_block_library.tres")
@export var floor_ray:RayCast3D
@export var drop_item_scene:PackedScene
@export var hand_ani:AnimationPlayer

var terrian:VoxelTerrain
var voxel_tool:VoxelTool
var eat_timer: Timer
var timer: Timer
@export var camera: Camera3D

func _ready():
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
				if Globals.selected_slot != null:
					var item =  Globals.selected_slot.Item_resource
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

	
	if Input.is_action_pressed("Mine"):
		
		if !get_parent().crouching:
			interaction() ## checks for interactions
			if is_interactable(): return
		
		if timer.is_stopped():
			if terrain_interaction.can_break():
				var type = terrain_interaction.get_type()
				if type == "air": return
				
				var item = items_library.get_item(type) as ItemBlock
				
				if Globals.selected_slot != null:
					if Globals.selected_slot.Item_resource is ItemTool:
						var holding_item = Globals.selected_slot.Item_resource as ItemTool
						if holding_item.suitable_objects.has(item):
							timer.wait_time = item.break_time - holding_item.breaking_efficiency
						else:
							timer.wait_time = item.break_time
					else:
							timer.wait_time = item.break_time
				else:
					timer.wait_time = item.break_time
					
				#print(timer.wait_time )
							
				break_part.global_position = terrain_interaction.last_hit.position
				break_part.emitting = true
				break_part.show()
				timer.start()
				await timer.timeout

				if Input.is_action_pressed("Mine"):
					if terrain_interaction.last_hit != null:
						break_part.emitting = false
						terrain_interaction.break_block()
	else:
		break_part.emitting = false
		timer.stop()


func is_interactable() -> bool:
	if terrain_interaction.last_hit == null: return false
	
	var type = terrain_interaction.get_type()
	
	if type == "air": return false
	
	var item = items_library.get_item(type)
	
	if item.utility != null:
		return true
	else:
		return false


func interaction() -> void:
	if terrain_interaction.last_hit == null: return
	
	var type = terrain_interaction.get_type()
	
	if type == "air": return
	
	var item = items_library.get_item(type)
	
	if item.utility != null:
		if item.utility.has_ui:
			Globals.open_inventory.emit(terrain_interaction.last_hit.position)
			
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
func receive_meta(meta_data, type:int):
	print(meta_data)
	if type == voxel_library.get_model_index_default("portal"):
		Globals.enter_portal.emit(meta_data)
