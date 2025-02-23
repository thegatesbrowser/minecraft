extends Node

@export var terrain_interaction: TerrainInteraction
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
	
	if Input.is_action_just_pressed("Build"):
		if terrain_interaction.can_place():
			if Globals.can_build:
				
				var soundmanager = get_node("/root/Main").find_child("SoundManager")
				soundmanager.play_sound(Globals.current_block,terrain_interaction.last_hit.position)
				
				terrain_interaction.place_block(Globals.current_block)
				Globals.remove_item_from_hotbar.emit()
	
	if Input.is_action_just_pressed("Mine"):
		if terrain_interaction.can_break():
			var type = terrain_interaction.get_type()
			
			if Globals.custom_block.is_empty():
				timer.wait_time = items_library.get_item(type).break_time
			else:
				if items_library.get_item(Globals.custom_block) is ItemTool:
					if items_library.get_item(Globals.custom_block).suitable_objects.has(items_library.get_item(type)):
						timer.wait_time = items_library.get_item(type).break_time - items_library.get_item(Globals.custom_block).breaking_efficiency
					else:
						timer.wait_time = items_library.get_item(type).break_time
			
			#print(timer.wait_time)
			timer.start()
			await timer.timeout
			
			if Input.is_action_pressed("Mine"):
				var soundmanager = get_node("/root/Main").find_child("SoundManager")
				soundmanager.play_sound(type,terrain_interaction.last_hit.position)
				
				terrain_interaction.break_block()
				Globals.spawn_item_inventory.emit(items_library.get_item(type))
