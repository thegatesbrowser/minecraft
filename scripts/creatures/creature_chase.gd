extends State
class_name CreatureChase

const ITEM_BLOCK_LIBRARY = preload("res://resources/items_library.tres")
const VOXEL_BLOCK_LIBRARY = preload("res://resources/voxel_block_library.tres")

@export var creature : CharacterBody3D
var player: Player

func Enter(data:Dictionary):
	pass
	
func Physics_Update(delta:float):
	
	var player = get_closest_player()
	
	if !player: return
	
	var distance = creature.global_position.distance_to(player.global_position)
	##
	var current_pos = creature.global_position
	var path = Nav.find_path(current_pos,player.global_position)
			
	if path:
		for i in path:
			if path.size() >= 2:
				creature.stopped = false

				var point = path[1] + Vector3(0.5,0,0.5)

				var direction = creature.global_position.direction_to(point)

				creature.velocity.x = direction.x * creature.creature_resource.speed
				creature.velocity.z = direction.z * creature.creature_resource.speed

				creature.guide.global_position = point

				#print("move to",point, "from ", pos)
			else:
				#print("cant move too close")
				creature.stopped = true
				creature.velocity.x = 0
				creature.velocity.z = 0 
	else:
		creature.velocity.x = 0
		creature.velocity.z = 0 
#
	if distance < 1:
		await get_tree().create_timer(2.0).timeout
		Transitioned.emit(self,"Attack",{"player":player})
	#
	if distance > 20:
		Transitioned.emit(self,"Idle",{})
		
		

func get_closest_player():
	var last_distance: float = 0.0
	var closest_player: CharacterBody3D
	
	for i in get_tree().get_nodes_in_group("Player"):
		if last_distance == 0.0:
			last_distance = creature.global_position.distance_to(i.global_position)
			closest_player = i
		else:
			if last_distance > creature.global_position.distance_to(i .global_position):
				last_distance = creature.global_position.distance_to(i .global_position)
				closest_player = i

	return closest_player
