extends State
class_name CreatureFollow

@export var update_time:float
@export var creature : CreatureBase

var player:Player
var nav_path:PackedVector3Array

func Enter(data:Dictionary):
	player = data.player
	
	var update_timer := Timer.new()
	update_timer.wait_time = update_time
	update_timer.autostart = true
	add_child(update_timer)
	update_timer.timeout.connect(update_nav_path)
	
func Exit():
	var timer = get_child(0)
	if timer is Timer:
		timer.queue_free()
		
func Physics_Update(delta:float):
	if player:
		
		var distance = creature.global_position.distance_to(player.global_position)
		
		var current_pos = creature.global_position
		
		if distance > 0:
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
		
		if distance > 50:
			#Transitioned.emit(self,"Idle")
			pass

func update_nav_path():
	if player:
		var current_pos = creature.global_position
		
		var OK = Nav.find_path(current_pos,player.global_position)

		if OK:
			nav_path = OK
			
			for i in nav_path:
				Nav.create_visual_debug(i,true)
