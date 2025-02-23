extends Node3D

var creature_base = preload("res://scenes/creatures/creature_base.tscn")

func _ready() -> void:
	Console.add_command("AI_debug",self,'toggle_AI_debug')\
		.set_description("toggles the npc debug).")\
		.register()
		
	Globals.spawn_creature.connect(spawn)
	
func spawn(pos: Vector3):
	var creature = creature_base.instantiate()
	creature.position = pos
	add_child(creature)
	print("spawn")

func get_cloest_player(pos):
	var last_distance
	var closest_player:Node
	for i in get_tree().get_nodes_in_group("Player"):
		if last_distance == null:
			last_distance = pos.distance_to(i .global_position)
			closest_player = i
		else:
			if last_distance > pos.distance_to(i .global_position):
				last_distance = pos.distance_to(i .global_position)
				closest_player = i
		return closest_player

func toggle_AI_debug():
	for i in get_tree().get_nodes_in_group("NPCS"):
		i.toggle_debug()
