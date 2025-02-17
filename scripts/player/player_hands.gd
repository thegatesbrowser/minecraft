extends Node


signal place_block(block_name)

var timer = Timer.new()

@export var utilies_base_s = preload("res://scenes/other/utilities_base.tscn")
@export var terrain_interaction: TerrainInteraction
@export var item_library:ItemsLibrary

func _ready():
	item_library.init_items()
	terrain_interaction.enable()


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
			
			
			var timer = Timer.new()
			
			if Globals.custom_block.is_empty():
				timer.wait_time = item_library.get_item(type).break_time
			else:
				if item_library.get_item(Globals.custom_block) is ItemTool:
					if item_library.get_item(Globals.custom_block).suitable_objects.has(item_library.get_item(type)):
						timer.wait_time = item_library.get_item(type).break_time - item_library.get_item(Globals.custom_block).breaking_efficiency
					else:
						timer.wait_time = item_library.get_item(type).break_time
						
			add_child(timer)
			timer.start()
			
			await timer.timeout
			
			if Input.is_action_pressed("Mine"):
				var soundmanager = get_node("/root/Main").find_child("SoundManager")
				soundmanager.play_sound(type,terrain_interaction.last_hit.position)
				
				timer.queue_free()
				terrain_interaction.break_block()
				Globals.spawn_item_inventory.emit(item_library.get_item(type))
