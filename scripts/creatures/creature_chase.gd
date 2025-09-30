extends State
class_name CreatureChase

const ITEM_BLOCK_LIBRARY = preload("res://resources/items_library.tres")
const VOXEL_BLOCK_LIBRARY = preload("res://resources/voxel_block_library.tres")

var last_pos_check:Vector3

var nav_path:PackedVector3Array

@export var update_time:float

@export var creature : CharacterBody3D
var player: Player

func Enter(data:Dictionary):
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
	
	var player = get_closest_player()
	
	if !player: return
	
	var distance = creature.global_position.distance_to(player.global_position)
	##
	var current_pos = creature.global_position
	
			
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
#
	if distance < 1:
		return
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

func update_nav_path():
	var player = get_closest_player()
	var current_pos = creature.global_position
	
	var OK = Nav.find_path(current_pos,player.global_position)

	
	if OK:
		nav_path = OK
		
		#for i in nav_path:
			#Nav.create_visual_debug(i)
	
