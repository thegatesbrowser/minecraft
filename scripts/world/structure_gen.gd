
const Item_LIB = preload("res://resources/items_library.tres")
const VoxelLibrary = preload("res://resources/voxel_block_library.tres")
const Structure = preload("./structure.gd")

var files:Array[String] = ["res://assets/custom structures/1.save","res://assets/custom structures/2.save","res://assets/custom structures/3.save"]
var possible_worlds:Array[String]

var channel := VoxelBuffer.CHANNEL_TYPE

func _init() -> void:
	Item_LIB.init_items()
	
func generate() -> Structure:
	var voxels: Dictionary = {}
	var spawn_chance:float
	var possible_items:Array = []
	
	#var dir_path = get_folder_path()
	#var dir = DirAccess.open(dir_path)
#
	#var file_name:String
	#var files:PackedStringArray = []
	#
	#if dir:
		#files = dir.get_files()
		#print("files ",files)
		
	var select = randi_range(0, files.size() -1)
	var file_name = files[select]
			
			#while file_name != "":
				#if not dir.current_is_dir():
					#print("Found file: " + file_name)
					#break
				##file_name = dir.get_next()
		#else:
			#print("Could not open directory: " + dir_path)
	#
	#var file_path = str("res://assets/custom structures","/",file_name)
	#var file = load(file_name)
	#ResourceLoader.load()
	var file = FileAccess.open(file_name,FileAccess.READ)
	
	while file.get_position() < file.get_length():
		#file.fil
		#var node_data = {"0":{"block_name":"portal","x":0,"y":42,"z":0},"1":{"block_name":"stone","x":0,"y":43,"z":0},"2":{"block_name":"stone","x":1,"y":43,"z":0},"3":{"block_name":"stone","x":0,"y":44,"z":0},"4":{"block_name":"stone","x":-1,"y":43,"z":0},"5":{"block_name":"stone","x":1,"y":44,"z":0},"6":{"block_name":"stone","x":0,"y":43,"z":-1},"7":{"block_name":"stone","x":0,"y":43,"z":1},"8":{"block_name":"stone","x":0,"y":44,"z":1},"9":{"block_name":"stone","x":-1,"y":43,"z":1},"10":{"block_name":"stone","x":1,"y":44,"z":1},"11":{"block_name":"stone","x":1,"y":43,"z":1},"12":{"block_name":"stone","x":1,"y":43,"z":2},"13":{"block_name":"stone","x":0,"y":43,"z":2},"14":{"block_name":"stone","x":2,"y":43,"z":1},"15":{"block_name":"stone","x":2,"y":43,"z":0},"16":{"block_name":"stone","x":1,"y":43,"z":-1},"17":{"block_name":"stone","x":1,"y":42,"z":1},"18":{"block_name":"stone","x":0,"y":42,"z":1},"19":{"block_name":"stone","x":1,"y":42,"z":0},"20":{"block_name":"stone","x":1,"y":41,"z":0},"21":{"block_name":"stone","x":0,"y":41,"z":1},"22":{"block_name":"stone","x":1,"y":41,"z":1},"23":{"block_name":"stone","x":1,"y":42,"z":-1},"24":{"block_name":"stone","x":2,"y":42,"z":0},"25":{"block_name":"stone","x":2,"y":42,"z":1},"26":{"block_name":"stone","x":0,"y":42,"z":2},"27":{"block_name":"stone","x":1,"y":42,"z":2},"28":{"block_name":"stone","x":-1,"y":42,"z":1},"29":{"block_name":"stone","x":0,"y":42,"z":-1},"30":{"block_name":"stone","x":-1,"y":42,"z":0},"31":{"block_name":"stone","x":0,"y":41,"z":0},"32":{"block_name":"stone","x":0,"y":40,"z":0},"33":{"block_name":"stone","x":-1,"y":41,"z":0},"34":{"block_name":"stone","x":0,"y":41,"z":-1},"35":{"block_name":"stone","x":-1,"y":41,"z":1},"36":{"block_name":"stone","x":0,"y":41,"z":2},"37":{"block_name":"stone","x":2,"y":41,"z":1},"38":{"block_name":"stone","x":2,"y":41,"z":0},"39":{"block_name":"stone","x":1,"y":41,"z":-1},"40":{"block_name":"stone","x":1,"y":40,"z":1},"41":{"block_name":"stone","x":0,"y":40,"z":1},"42":{"block_name":"stone","x":1,"y":40,"z":0},"43":{"block_name":"stone","x":1,"y":39,"z":0},"44":{"block_name":"stone","x":0,"y":39,"z":1},"45":{"block_name":"stone","x":1,"y":39,"z":1},"46":{"block_name":"stone","x":1,"y":40,"z":-1},"47":{"block_name":"stone","x":2,"y":40,"z":0},"48":{"block_name":"stone","x":2,"y":40,"z":1},"49":{"block_name":"stone","x":0,"y":40,"z":2},"50":{"block_name":"stone","x":-1,"y":40,"z":1},"51":{"block_name":"stone","x":0,"y":40,"z":-1},"52":{"block_name":"stone","x":-1,"y":40,"z":0},"53":{"block_name":"stone","x":0,"y":39,"z":0},"54":{"block_name":"stone","x":-1,"y":41,"z":2},"55":{"block_name":"stone","x":-2,"y":41,"z":1},"56":{"block_name":"stone","x":-1,"y":41,"z":-1},"57":{"block_name":"stone","x":-2,"y":41,"z":0},"58":{"block_name":"stone","x":-2,"y":42,"z":0},"59":{"block_name":"stone","x":-1,"y":42,"z":-1},"60":{"block_name":"stone","x":-2,"y":42,"z":1},"61":{"block_name":"stone","x":-1,"y":42,"z":2},"62":{"block_name":"stone","x":1,"y":41,"z":2},"63":{"block_name":"stone","x":2,"y":41,"z":2},"64":{"block_name":"stone","x":2,"y":41,"z":-1},"65":{"block_name":"stone","x":3,"y":41,"z":0},"66":{"block_name":"stone","x":3,"y":41,"z":1},"67":{"block_name":"stone","x":2,"y":42,"z":2},"68":{"block_name":"stone","x":3,"y":42,"z":1},"69":{"block_name":"stone","x":3,"y":42,"z":0},"70":{"block_name":"stone","x":2,"y":42,"z":-1},"71":{"block_name":"stone","x":1,"y":41,"z":3},"72":{"block_name":"stone","x":0,"y":41,"z":3},"73":{"block_name":"stone","x":1,"y":42,"z":3},"74":{"block_name":"stone","x":0,"y":42,"z":3},"75":{"block_name":"stone","x":1,"y":41,"z":-2},"76":{"block_name":"stone","x":0,"y":41,"z":-2},"77":{"block_name":"stone","x":0,"y":42,"z":-2},"78":{"block_name":"stone","x":1,"y":42,"z":-2}}
		
		var json_string = file.get_line()
		
		var json = JSON.new()

			# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
			
		var node_data = json.data

		#var node_data = json.parse(data)
		if node_data != null:
			if typeof(node_data) == TYPE_DICTIONARY:
				for index in node_data:
					
					var type = VoxelLibrary.get_model_index_default(node_data[index].block_name)
					var x = node_data[index].x
					var y = node_data[index].y
					var z = node_data[index].z
					
					voxels[Vector3(x,y,z)] = type
			elif typeof(node_data) == TYPE_ARRAY:
				possible_items = node_data
			else:
				spawn_chance = json_string.to_float()
				print(spawn_chance)
				
		else:
			spawn_chance = json_string.to_float()
			print(spawn_chance)
		# Let's make crappy trees	

	# Make structure
	var aabb: AABB = AABB()
	
	for pos in voxels:
		aabb = aabb.expand(pos)
		
	var structure: Structure = Structure.new()
	structure.offset = -aabb.position
	structure.name = file_name
	structure.spawn_chance = spawn_chance
	var buffer: VoxelBuffer = structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos: Vector3 = pos + structure.offset
		var v: int = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)
		var name = VoxelLibrary.get_type_name_and_attributes_from_model_index(v)[0]
		if name == "portal":
			buffer.set_voxel_metadata(Vector3(rpos.x, rpos.y, rpos.z), possible_worlds.pick_random())
		if name == "chest":
			var inventory:Dictionary = create_inventory()
			print("created",inventory)
			
			for i in randi_range(1,5):
				var item_name = possible_items.pick_random()
				var item = Item_LIB.get_item(item_name)
				inventory[str(i)] = {
					"item_path":item.get_path(),
					"amount":randi_range(0,item.max_stack),
					"parent":"Items",
					"health":1.0,
					"rot":0.0,
				}
				
			var save = JSON.stringify(inventory)
			
			buffer.set_voxel_metadata(Vector3(rpos.x, rpos.y, rpos.z), save)
	
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

func create_inventory() -> Dictionary:
	var save_data:Dictionary = {}
	var index = 0
	for i in 18:
		save_data[str(index)] = {
			"item_path":"",
			"amount":1,
			"parent":"Items",
			"health":0.0,
			"rot":0.0,
			}
		index += 1
	return save_data

#func get_folder_path() -> String:
	#var args := OS.get_cmdline_args()
	#var index = args.has("structure")
#
	#if index == -1 or args.size() <= index + 1: return ""
	#return args[index + 1]
