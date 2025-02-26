extends MultiplayerSpawner

signal player_spawned(id: int, creature)
signal creature_despawned(id: int)

var creature_base = preload("res://scenes/creatures/creature_base.tscn")
@export var view_distance: int = 128


func _ready() -> void:
	spawn_function = custom_spawn
	Console.add_command("AI_debug",self,'toggle_AI_debug')\
		.set_description("toggles the npc debug).")\
		.register()
		
	Globals.spawn_creature.connect(spawn_creature)
	
func spawn_creature(pos: Vector3, id: int = 1) -> void:
	if not multiplayer.is_server(): return
		
	var spawn_position = pos
	spawn([id, spawn_position])
	print("creature spawn")

func destroy_creature(Name: String) -> void:
	if not multiplayer.is_server(): return
	get_node(spawn_path).get_node(Name).queue_free()

	


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
	
	create_viewer(id, creature)
	
	player_spawned.emit(id, creature)
	return creature


func create_viewer(id: int, creature: CreatureBase) -> void:
	if Connection.is_server():
		var viewer := VoxelViewer.new()

		viewer.view_distance = view_distance
		viewer.requires_visuals = false
		viewer.requires_collisions = true
		
		viewer.set_network_peer_id(id)
		viewer.set_requires_data_block_notifications(true)
		creature.add_child(viewer)
	
	elif id == multiplayer.get_unique_id():
		var viewer := VoxelViewer.new()
		
		# larger so blocks don't get unloaded too soon
		viewer.view_distance = view_distance + 16
		
		creature.add_child(viewer)
