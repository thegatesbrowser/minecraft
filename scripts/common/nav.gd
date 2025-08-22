extends Node

var astar := AStar3D.new()

var debug_meshes = []

var points := {}

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


func create_point(x: int, y: int, z: int):
	var point_id = astar.get_available_point_id()

	astar.add_point(point_id, Vector3(x, y, z))

	points[Vector3(x, y, z)] = {
		"point_id":point_id,
		"mesh":null
	}

	create_visual_debug(Vector3(x, y, z) + Vector3(0.5,0,0.5))  # Create a visual debug sphere at the point position's center
   
	print("Point created at: ", Vector3(x, y, z))
	print("Total points: ", astar.get_point_count())

func create_visual_debug(pos:Vector3):
	var sphere := BoxMesh.new()
	
	var instance := MeshInstance3D.new()
	instance.mesh = sphere
	instance.position = pos
	
	get_tree().root.add_child(instance)
	#instance.material_override = load("res://assets/materials/debug.tres")
	instance.scale = Vector3(0.4,.4,.4)

	points[pos - Vector3(0.5,0,0.5)].mesh = instance

func clear_points():

	## Debug Clear

	## Point Clear
	
	for i in points:
		var point_id = points[i].point_id
		astar.remove_point(point_id)
		var mesh = points[i].mesh
		points[i].mesh = null
		mesh.queue_free()

	points.clear()

func connect_points():
	for pos in points:
		for dir in _moore_dirs:
			var search_area = pos + dir
			if points.has(search_area):
				var current_id = points[pos].point_id
				var neighbor_id = points[search_area].point_id

				if not astar.are_points_connected(current_id,neighbor_id):
					astar.connect_points(current_id,neighbor_id)
					print("astar connected point ", current_id, " to ", neighbor_id )

func find_path(from:Vector3,to:Vector3):
	# from and to are already been rounded
	var start_id = astar.get_closest_point(from)
	var end_id = astar.get_closest_point(to)

	var path = astar.get_point_path(start_id,end_id)

	for point in points:
		if path.has(point):
			points[point].mesh.material_override = load("res://assets/materials/debug.tres")
		else:
			points[point].mesh.material_override = null


	return path
