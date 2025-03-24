extends Node

@export var terrain_interaction:Node
@export var items_library: ItemsLibrary
@export var floor_ray:RayCast3D
@export var drop_item_scene:PackedScene

var timer: Timer
@export var camera: Camera3D

func _ready():
	Globals.drop_item.connect(drop)
	items_library.init_items()
	terrain_interaction.enable()
	timer = Timer.new()
	timer.one_shot = true
	add_child(timer)


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
	
	if Input.is_action_pressed("Mine"):
		
		if !get_parent().crouching:
			interaction() ## checks for interactions
			if is_interactable(): return
		
		if timer.is_stopped():
			if terrain_interaction.can_break():
				var type = terrain_interaction.get_type()
				if type == "air": return
				
				var item = items_library.get_item(type)
				
				if Globals.custom_block.is_empty():
					timer.wait_time = item.break_time
				else:
					if items_library.get_item(Globals.custom_block) is ItemTool:
						if items_library.get_item(Globals.custom_block).suitable_objects.has(items_library.get_item(type)):
							timer.wait_time = item.break_time - items_library.get_item(Globals.custom_block).breaking_efficiency
						else:
							timer.wait_time = item.break_time
							
				timer.start()
				await timer.timeout
				
				if Input.is_action_pressed("Mine"):
					
				
						
					if terrain_interaction.last_hit != null:
						terrain_interaction.break_block()


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
			Globals.enter_portal.emit(terrain_interaction.last_hit.position)

func drop(owner_id:int ,item:ItemBase ,amount := 1):
	print("drop")
	if get_multiplayer_authority() != owner_id: return
	print(get_multiplayer_authority(), " is ", owner_id)
	if floor_ray.is_colliding():
		var pos = floor_ray.get_collision_point()
		var spawn_node = get_node("/root/Main").find_child("Objects")
		
		sync_drop.rpc_id(1,item.resource_path,pos,amount)
		#drop_item.Item = item
		#drop_item.amount = amount
		#drop_item.position = pos
		#spawn_node.add_child(drop_item)

@rpc("any_peer","call_local")
func sync_drop(item_path,pos,amount := 1):
	#var drop_item = drop_item_scene.instantiate()
		
	Globals.add_object.emit([1,pos,"res://scenes/items/dropped_item.tscn",item_path,amount])
