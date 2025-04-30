extends State
class_name CreatureIdle

var move_distance:float = 10.0
var target : Vector3
var wander_time : float

@export var creature: CreatureBase

func randomize_wander():
	target = get_random_pos_in_sphere(move_distance) + creature.global_position
	wander_time = randf_range(1,4)

func Enter():
	randomize_wander()
	
func Update(delta:float):
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func Physics_Update(delta:float):
	if creature:
		var new_velocity: Vector3
		var current_pos = creature.global_position
		var new_velocity_x = (target.x - current_pos.x)
		var new_velocity_z = (target.z - current_pos.z)
		new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * creature.creature_resource.speed
		
		creature.look_at_target = Vector3(target.x,current_pos.y + 0.01,target.z)
		creature.velocity = creature.velocity.move_toward(new_velocity, .25)
		
		var player = get_closest_player()
		
		if creature.creature_resource.attacks:
			
			if player:
				#print("distance ",current_pos.distance_to(player.global_position))
				if current_pos.distance_to(player.global_position) <= 10:
					Transitioned.emit(self,"Attack")
		else:
			if player:
				#print("distance ",current_pos.distance_to(player.global_position))
				if current_pos.distance_to(player.global_position) <= 10:
					Transitioned.emit(self,"runaway")

func get_random_pos_in_sphere(radius : float) -> Vector3:
	var x1= randi_range(-1,1)
	var x2= randi_range(-1,1)
	
	while x1*x1 + x2*x2 >=1:
		x1= randi_range(-1,1)
		x2= randi_range(-1,1)
		
	var random_pos_on_unit_sphere = Vector3 (
		1 -2 * (x1*x1 + x2*x2),
		0,
		1 -2 * (x1*x1 + x2*x2))
		
	random_pos_on_unit_sphere.x *= randi_range(-radius, radius)
	random_pos_on_unit_sphere.z *= randi_range(-radius, radius)
	
	return random_pos_on_unit_sphere


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
