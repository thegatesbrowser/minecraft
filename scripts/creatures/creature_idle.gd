extends State
class_name CreatureIdle

var move_distance:float = 10.0
var target : Vector3
var wander_time : float

var nav_path:PackedVector3Array

@export var creature: CreatureBase

func randomize_wander():
	target = get_random_pos_in_sphere(move_distance) + creature.global_position
	update_nav_path()
	wander_time = randf_range(1,4)

func Enter(data:Dictionary):
	randomize_wander()
	
func Exit():
	pass
	
func Update(delta:float):
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func Physics_Update(delta:float):
	if creature:
		var new_velocity: Vector3
		var current_pos = creature.global_position
		
		var player = get_closest_player()
		
		if creature.creature_resource.attacks:
			
			if nav_path:
				if nav_path.size() >= 2:
					creature.stopped = false
					
					
					var point:Vector3 = nav_path[1] + Vector3(0.5,0,0.5)
					var point_id = nav_path.find(point - Vector3(0.5,0,0.5))
					
					var distance_to_point = current_pos.distance_to(point)
					
					if distance_to_point <= 1:
						#print("on top of point")
						nav_path.remove_at(point_id)
						

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
			
			if player:
				#print("distance ",current_pos.distance_to(player.global_position))
				if current_pos.distance_to(player.global_position) <= 10:
					Transitioned.emit(self,"Chase",{})
		else:
			if player:
				#print("distance ",current_pos.distance_to(player.global_position))
				if current_pos.distance_to(player.global_position) <= 10:
					Transitioned.emit(self,"runaway",{})

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
	
	
func update_nav_path():
	var current_pos = creature.global_position
	
	var OK = Nav.find_path(current_pos,target)

	if OK:
		nav_path = OK
		
		for i in nav_path:
			Nav.create_visual_debug(i,true)
