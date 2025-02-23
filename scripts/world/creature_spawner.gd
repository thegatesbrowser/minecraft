extends MultiplayerSpawner

signal player_spawned(id: int, creature)

var creature_base = preload("res://scenes/creatures/creature_base.tscn")

func _ready() -> void:
	spawn_function = custom_spawn
	Console.add_command("AI_debug",self,'toggle_AI_debug')\
		.set_description("toggles the npc debug).")\
		.register()
		
	Globals.spawn_creature.connect(spawn_creature)
	
func spawn_creature(id: int = 1) -> void:
	if not multiplayer.is_server(): return
	
	#for i in $"../Players".get_children():
		#id = i.name.to_int()
		
	var spawn_position = Vector3(9,128,8)
	spawn([id, spawn_position])
	print("spawn")

func get_cloest_player(pos):
	var last_distance
	var closest_player:Node
	for i in get_tree().get_nodes_in_group("Player"):
		if last_distance == null:
			last_distance = pos.distance_to(i.global_position)
			closest_player = i
		else:
			if last_distance > pos.distance_to(i.global_position):
				last_distance = pos.distance_to(i.global_position)
				closest_player = i
		return closest_player

func toggle_AI_debug():
	for i in get_tree().get_nodes_in_group("NPCS"):
		i.toggle_debug()
		

func custom_spawn(data: Array) -> Node:
	var id: int = data[0]
	var spawn_position: Vector3 = data[1]
	
	var creature = creature_base.instantiate()
	creature.set_multiplayer_authority(id)
	creature.name = str(id)
	creature.position = spawn_position
	
	player_spawned.emit(id, creature)
	return creature
