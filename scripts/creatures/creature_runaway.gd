extends State
class_name CreatureRunaway

@export var creature : CharacterBody3D
var player: Player

func Enter():
	player = get_closest_player()
	
func Physics_Update(delta:float):
	if !player:
		return
		
	var distance = creature.global_position.distance_to(player.global_position)
	
	var current_pos = creature.global_position
	
	if distance < 40:
		var new_velocity: Vector3
		var new_velocity_x = (player.global_position.x - current_pos.x)
		var new_velocity_z = (player.global_position.z - current_pos.z)
		new_velocity = Vector3(-new_velocity_x,0,-new_velocity_z).normalized() * creature.creature_resource.speed

		creature.velocity = creature.velocity.move_toward(new_velocity, .25)
		creature.look_at_target = Vector3(player.global_position.x,current_pos.y + 0.01,player.global_position.z)
	else:
		Transitioned.emit(self,"Idle")
		


func get_closest_player():
	var last_distance: float = 0.0
	var closest_player: CharacterBody3D
	
	for i in get_tree().get_nodes_in_group("Player"):
		if last_distance == 0.0:
			last_distance = creature.global_position.distance_to(i .global_position)
			closest_player = i
		else:
			if last_distance > creature.global_position.distance_to(i .global_position):
				last_distance = creature.global_position.distance_to(i .global_position)
				closest_player = i

	return closest_player
