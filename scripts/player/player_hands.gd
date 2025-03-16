extends Node

@export var terrain_interaction:Node
@export var items_library: ItemsLibrary

var timer: Timer


func _ready():
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
				
				terrain_interaction.place_block(Globals.current_block)
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
