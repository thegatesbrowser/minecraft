
const VoxelLibrary = preload("res://resources/voxel_block_library.tres")
const Structure = preload("./structure.gd")
var possible_structures:Array[JSON] = []

var channel := VoxelBuffer.CHANNEL_TYPE

func generate() -> Structure:
	var voxels: Dictionary = {}
	
	var node_data = {"0":{"block_name":"log_birch","x":0,"y":0,"z":0},"1":{"block_name":"log_birch","x":0,"y":1,"z":0},"2":{"block_name":"log_birch","x":0,"y":2,"z":0},"3":{"block_name":"log_birch","x":-1,"y":3,"z":0},"4":{"block_name":"log_birch","x":-2,"y":4,"z":0},"5":{"block_name":"log_birch","x":-2,"y":5,"z":0},"6":{"block_name":"log_birch","x":1,"y":3,"z":0},"7":{"block_name":"log_birch","x":0,"y":4,"z":0},"8":{"block_name":"log_birch","x":0,"y":5,"z":0},"9":{"block_name":"log_birch","x":1,"y":6,"z":0},"10":{"block_name":"log_birch","x":0,"y":3,"z":-1},"11":{"block_name":"log_birch","x":0,"y":4,"z":-2},"12":{"block_name":"log_birch","x":0,"y":5,"z":-2},"13":{"block_name":"log_birch","x":0,"y":6,"z":-3},"14":{"block_name":"log_birch","x":0,"y":3,"z":1},"15":{"block_name":"log_birch","x":0,"y":4,"z":2},"16":{"block_name":"log_birch","x":0,"y":5,"z":2}}
	for index in node_data:
		
		var type = VoxelLibrary.get_model_index_default(node_data[index].block_name)
		var x = node_data[index].x
		var y = node_data[index].y
		var z = node_data[index].z
		
		voxels[Vector3(x,y,z)] = type

	# Let's make crappy trees

	# Make structure
	var aabb: AABB = AABB()
	
	for pos in voxels:
		aabb = aabb.expand(pos)
	
	var structure: Structure = Structure.new()
	structure.offset = -aabb.position

	var buffer: VoxelBuffer = structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos: Vector3 = pos + structure.offset
		var v: int = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)
	
	return structure


# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game(file_path:String):
	if not FileAccess.file_exists(file_path):
		return # Error! We don't have a save to load.
	var save_file = FileAccess.open(file_path, FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data
		
		return node_data
