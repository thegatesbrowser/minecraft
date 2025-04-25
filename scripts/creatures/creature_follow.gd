extends State
class_name CreatureFollow

@export var creature : CharacterBody3D
@export var move_speed := 10.0
var player: Player

func Enter():
	#player = creature.animal_owner
	player = get_tree().get_first_node_in_group("Player")
	
func Physics_Update(delta:float):
	if !player:
		return
		
	var distance = creature.global_position.distance_to(player.global_position)
	
	if distance > 5:
		var new_velocity: Vector3
		var current_pos = creature.global_position
		var new_velocity_x = (player.global_position.x - current_pos.x)
		var new_velocity_z = (player.global_position.z - current_pos.z)
		new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * move_speed

		creature.velocity = creature.velocity.move_toward(new_velocity, .25)
	else:
		creature.velocity = Vector3(0,0,0)
