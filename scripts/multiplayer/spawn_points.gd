extends Node3D
class_name SpawnPoints

var used_ids: Array[int]

func get_spawn_position() -> Vector3:
	var spawn_points = get_children() as Array[Node]
	var size = spawn_points.size()
	
	var id = 0
	for x in range(1000):
		id = randi() % size
		if not id in used_ids:
			used_ids.push_back(id)
			break
		elif used_ids.size() == size:
			used_ids.pop_front()
	
	return spawn_points[id].global_position
