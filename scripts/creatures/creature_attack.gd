extends State
class_name CreatureAttack

const ITEM_BLOCK_LIBRARY = preload("res://resources/items_library.tres")
const VOXEL_BLOCK_LIBRARY = preload("res://resources/voxel_block_library.tres")

@export var creature : CharacterBody3D
var player: Player

var path := []

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = .4
	add_child(timer)
	timer.start()
	timer.timeout.connect(timeout)

func Enter():
	#player = creature.animal_owner
	print("follow")
	player = get_tree().get_first_node_in_group("Player")
	
func Physics_Update(delta:float):
	#if !player:
		#return
		#
		##
	var distance = creature.global_position.distance_to(player.global_position)
	##
	var current_pos = creature.global_position
	var new_velocity: Vector3
	#
	#var point = path.pop_front()
	##
	#if path.is_empty():
		#creature.velocity = creature.velocity.move_toward(Vector3(0,0,0),.21)
		#
	#else:
		##if point.x != current_pos.x or point.z != current_pos.z:
		#print(point)
		#creature.target_reached = true
		#creature.velocity = current_pos.direction_to(point) * creature.creature_resource.speed
	#new_velocity = Vector3(point.x-current_pos.x,point.y-current_pos.y,point.z-current_pos.z)
		#print(new_velocity)
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

#
func timeout():
	pass
	##print("timeout")
	##if !player: returnwa
	#
	#var current_pos = floor(creature.global_position + Vector3(0,1,0))
	#var target:Vector3
	#
	#var pathfinding = VoxelAStarGrid3D.new()
	#var voxel_tool = TerrainHelper.get_terrain_tool().get_voxel_tool()
	#pathfinding.set_terrain(TerrainHelper.get_terrain_tool())
	#var aabb := AABB(floor(current_pos), Vector3()).grow(50)
	#pathfinding.set_region(aabb)
	#
	#if player:
		#
		#target = player.global_position
		#
		#var creature_voxel = VOXEL_BLOCK_LIBRARY.get_type_name_and_attributes_from_model_index(voxel_tool.get_voxel(current_pos))
		#var player_voxel = VOXEL_BLOCK_LIBRARY.get_type_name_and_attributes_from_model_index(voxel_tool.get_voxel(floor(target)))
		#
		#
		#
		#if creature_voxel[0] != "air":
			#current_pos = current_pos + Vector3(0,1,0)
			#path = pathfinding.find_path(current_pos,floor(target))
		#if player_voxel[0] != "air":
			#target = target + Vector3(0,1,0)
			#path = pathfinding.find_path(current_pos,floor(target))
		#
		#creature_voxel = VOXEL_BLOCK_LIBRARY.get_type_name_and_attributes_from_model_index(voxel_tool.get_voxel(current_pos))
		#player_voxel = VOXEL_BLOCK_LIBRARY.get_type_name_and_attributes_from_model_index(voxel_tool.get_voxel(floor(target)))
		#
		#print("path", path, "pos ",creature_voxel[0],player_voxel[0])
	##
	##if path.is_empty(): return
	#
	#
