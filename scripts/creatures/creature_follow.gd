extends State
class_name CreatureFollow

@export var creature : CreatureBase
var players: Array

func Enter(data:Dictionary):
	players = get_tree().get_nodes_in_group("Player")
	
func Physics_Update(delta:float):
	for player in players:
		
		var distance = creature.global_position.distance_to(player.global_position)
		
		var current_pos = creature.global_position
		
		if distance > 0:
			
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
		
		if distance > 50:
			#Transitioned.emit(self,"Idle")
			pass
