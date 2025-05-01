extends State
class_name CreatureFollow

@export var creature : CharacterBody3D
var player: Player

func Enter():
	#player = creature.animal_owner
	print("follow")
	player = get_tree().get_first_node_in_group("Player")
	
func Physics_Update(delta:float):
	if !player:
		return
		
	var distance = creature.global_position.distance_to(player.global_position)
	
	var current_pos = creature.global_position
	
	if distance > 0:
		var new_velocity: Vector3
		var new_velocity_x = (player.global_position.x - current_pos.x)
		var new_velocity_z = (player.global_position.z - current_pos.z)
		new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * creature.creature_resource.speed

		creature.velocity = creature.velocity.move_toward(new_velocity, .25)
		creature.look_at_target = Vector3(player.global_position.x,current_pos.y + 0.01,player.global_position.z)
	else:
		creature.velocity = Vector3(0,0,0)
		creature.look_at_target = Vector3(player.global_position.x,current_pos.y + 0.01,player.global_position.z)
	
	if distance > 50:
		Transitioned.emit(self,"Idle")
