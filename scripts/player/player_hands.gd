extends Node

@export var terrain_interaction: TerrainInteraction


func _ready():
	terrain_interaction.enable()


func _process(_delta: float) -> void:
	if not is_multiplayer_authority() and Connection.is_peer_connected: return
	
	if Input.is_action_just_pressed("Build"):
		if terrain_interaction.can_place():
			terrain_interaction.place_block(&"stone")
	
	if Input.is_action_just_pressed("Mine"):
		if terrain_interaction.can_break():
			var type = terrain_interaction.break_block()
	
	# BUILDING / BREAKING
	# if ray.is_colliding():
	# 	var coll = ray.get_collider()
	# 	if Input.is_action_pressed("Mine"):
	# 		if coll != null:
	# 			if coll.has_method("interact"):
	# 				coll.interact()
	# 			elif coll.has_method("hit"):
	# 				coll.hit()
