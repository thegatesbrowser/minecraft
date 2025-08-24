extends Node

var debug:bool = false

var astar := AStar3D.new()

var points := {}

var nav_viewers := []

var tick:float = 1.0

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
	Console.add_command("nav", self, 'toggle_nav_debug')\
		.set_description("test command to spawn a creature at player pos")\
		.register()

	var update_nav_timer := Timer.new()
	update_nav_timer.wait_time = tick
	update_nav_timer.autostart = true
	add_child(update_nav_timer)
	update_nav_timer.timeout.connect(update_navs)



func create_point(pos):
	#print("multiplayer id ",multiplayer.get_unique_id())
	
	if points.has(pos): return

	var point_id = astar.get_available_point_id()

	if multiplayer.is_server():
		astar.add_point(point_id, pos)

	points[pos] = {
		"point_id":point_id,
		"mesh":null
	}

	if debug:
		create_visual_debug(pos + Vector3(0.5,0,0.5))  # Create a visual debug sphere at the point position's center
   
	#print("Point created at: ", Vector3(x, y, z))
	#print("Total points: ", astar.get_point_count())

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
		if multiplayer.is_server():
			var point_id = points[i].point_id
			astar.remove_point(point_id)

		var mesh = points[i].mesh
		if mesh:
			points[i].mesh = null
			mesh.queue_free()

	points.clear()

func connect_points():
	if not multiplayer.is_server(): return

	for pos in points:
		for dir in _moore_dirs:
			var search_area = pos + dir
			if points.has(search_area):
				var current_id = points[pos].point_id
				var neighbor_id = points[search_area].point_id

				if not astar.are_points_connected(current_id,neighbor_id):
					astar.connect_points(current_id,neighbor_id)
					#print("astar connected point ", current_id, " to ", neighbor_id )

func find_path(from:Vector3,to:Vector3):
	# from and to are already been rounded
	var start_id = astar.get_closest_point(from)
	var end_id = astar.get_closest_point(to)

	if start_id == -1 or end_id == -1: return

	var path = astar.get_point_path(start_id,end_id,true)

	if debug:
		debug_path.rpc(path)
	
	return path

@rpc("any_peer")
func debug_path(path:PackedVector3Array):
	if multiplayer.is_server(): return # client debug

	for point in points:
		if path.has(point):
			if points[point].mesh:
				points[point].mesh.material_override = load("res://assets/materials/debug.tres")
		else:
			if points[point].mesh:
				points[point].mesh.material_override = null


func update_nav_pool():
	nav_viewers = get_tree().get_nodes_in_group("NavViewer")

func update_navs():
	clear_points()

	for nav_viewer in nav_viewers:
		var surroundings = nav_viewer.grab_surrounds()
		for pos in surroundings:
			create_point(pos)

	connect_points()

func allowed_path(path:PackedVector3Array) -> bool:
	var _path = path.duplicate()
	for point in _path:
		var curr_point = point
		_path.remove_at(_path.find(point))
		for next_point in _path:
			#print("current ",curr_point, " next point ",next_point)

			var height_range = curr_point.y - next_point.y 

			if height_range > 1:
				return false
			else:
				return true
	
	return false ## doesn't have a path

func toggle_nav_debug():
	debug = !debug

	if debug == false:
		clear_points()
