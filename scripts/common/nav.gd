extends Node

var pathfinding :=AStar3D.new()

const _moore_dirs = [
	Vector3(-1, 0, -1),
	Vector3(0, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1),
	
	Vector3(-1, 1, -1),
	Vector3(0, 1, -1),
	Vector3(1, 1, -1),
	Vector3(-1, 1, 0),
	Vector3(1, 1, 0),
	Vector3(-1, 1, 1),
	Vector3(0, 1, 1),
	Vector3(1, 1, 1),
	
	Vector3(-1, -1, -1),
	Vector3(0, -1, -1),
	Vector3(1, -1, -1),
	Vector3(-1, -1, 0),
	Vector3(1, -1, 0),
	Vector3(-1, -1, 1),
	Vector3(0, -1, 1),
	Vector3(1, -1, 1),
]

func _ready() -> void:
	if multiplayer.get_unique_id() == 1:
		#get_tree().create_timer(10.0).timeout.connect(test_path)
		pass

func create_point(x: int, y: int, z: int):
	var point_id = pathfinding.get_available_point_id()

	pathfinding.add_point(point_id, Vector3(x, y, z))
	create_visual_debug(Vector3(x, y, z))  # Create a visual debug sphere at the point position
	#connect_points(point_id - 1,point_id)  # Connect to the previous point for a simple path
   


	print("Point created at: ", Vector3(x, y, z))
	print("Total points: ", pathfinding.get_point_count())


func has_point(position:Vector3) -> bool:
	for point in pathfinding.get_point_ids():
		var point_pos = pathfinding.get_point_position(point)
		if point_pos == position: 
			return true
			
	return false
	
func connect_points(point_id: int, neighbor_id: int):
	if pathfinding.has_point(point_id) and pathfinding.has_point(neighbor_id):

		if not pathfinding.are_points_connected(point_id, neighbor_id):
			pathfinding.connect_points(point_id, neighbor_id)
			print("Connected points: ", point_id, " and ", neighbor_id)
			#print("nav_path ",get_nav_path(pathfinding.get_point_position(point_id), pathfinding.get_point_position(neighbor_id)))

func connect_all_points():
	for point in pathfinding.get_point_ids():
		var point_pos = pathfinding.get_point_position(point)
		for dir in _moore_dirs:
			var possible_point_pos = point_pos + dir
			var possible_point = pathfinding.get_closest_point(possible_point_pos)
			if possible_point != point:
				if pathfinding.has_point(possible_point):
					pathfinding.connect_points(point,possible_point,true)
					print(":connected ",point,possible_point)
	
	
	#print("All points added to pathfinding.",pathfinding.get_point_ids())
	#print("Total points: ", pathfinding.get_point_count())

func test_path():
	print("Testing pathfinding...",multiplayer.get_unique_id())
	if pathfinding.get_point_count() >= 4:
		var start = pathfinding.get_point_ids()[0]
		var end = pathfinding.get_point_ids()[4]

		#print("path  ",get_nav_path(pathfinding.get_point_position(start), pathfinding.get_point_position(end)))

func get_nav_path(start: Vector3, end: Vector3) -> PackedVector3Array:
	var start_id = pathfinding.get_closest_point(start)
	var end_id = pathfinding.get_closest_point(end)
	if pathfinding.has_point(start_id) and pathfinding.has_point(end_id):
		pathfinding.connect_points(start_id,end_id)
	
	
		if pathfinding.are_points_connected(start_id, end_id):
			print("Path exists between points: ", start_id, " and ", end_id)
			return pathfinding.get_point_path(start_id,end_id, true)
		else:
			print("No direct path between points: ", start_id, " and ", end_id)
	return PackedVector3Array()


func create_visual_debug(pos:Vector3):
	var sphere := SphereMesh.new()
	sphere.radius = 0.1
	
	var instance := MeshInstance3D.new()
	instance.mesh = sphere
	instance.transform.origin = pos
	
	get_tree().root.add_child(instance)
