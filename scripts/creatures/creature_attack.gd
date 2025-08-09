extends State
class_name CreatureAttack

const ITEM_BLOCK_LIBRARY = preload("res://resources/items_library.tres")
const VOXEL_BLOCK_LIBRARY = preload("res://resources/voxel_block_library.tres")

@export var creature : CharacterBody3D
var player: Player

func Enter():
	player = get_tree().get_first_node_in_group("Player")
	
func Physics_Update(delta:float):
	var distance = creature.global_position.distance_to(player.global_position)
	##
	var current_pos = creature.global_position
	var new_velocity: Vector3
	
	var new_velocity_x = (player.global_position.x - current_pos.x)
	var new_velocity_z = (player.global_position.z - current_pos.z)
	
	new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * creature.creature_resource.speed
#
	print(new_velocity)
	#creature.global_position.move_toward(player.global_position,.25)
	creature.velocity = creature.velocity.move_toward(new_velocity, .25)
	creature.look_at_target = Vector3(player.global_position.x,current_pos.y + 0.01,player.global_position.z)
	#
	#if distance <= 0.2:
		#Transitioned.emit(self,"RunAway")
	#
	if distance > 20:
		Transitioned.emit(self,"Idle")
