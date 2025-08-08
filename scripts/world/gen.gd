extends VoxelGeneratorScript


var _channel = VoxelBuffer.CHANNEL_TYPE
var voxels:VoxelBlockyTypeLibrary = preload("res://resources/voxel_block_library.tres")
var iron := preload("res://resources/items/iron_block.tres")
var diamond := preload("res://resources/items/diamond_block.tres")
var possible_ore = [iron,diamond]

const Structure = preload("res://scripts/world/structure.gd")
const CustomStructureGen = preload("res://scripts/world/structure_gen.gd")
const TreeGenerator = preload("res://scripts/world/tree_generator.gd")
const temp_curve = preload("res://resources/HeatCurve.tres") as Curve
const curve = preload("res://resources/heightmap_curve.tres") as Curve
const cavenoise:FastNoiseLite = preload("res://resources/cave_noise.tres")
#const Heat
#const cavenoise:NoiseTexture3D = preload("res://new_noise_texture_3d.tres")

@export var biomes:Array[Biome]

var test_structure:Structure
var lock:=Mutex.new()
var current_biome:Biome

var temp_noise:FastNoiseLite = FastNoiseLite.new()

var max_heightmap:int = (curve.max_value)
var min_heightmap:int = (curve.min_value)

var _tree_structures := []
var _custom_structures := []
var _trees_min_y := 0
var _trees_max_y := 0
	
var caves := []
const _moore_dirs = [
	Vector3(-1, 0, -1),
	Vector3(0, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1)
]

func _init() -> void:
	var tree_generator = TreeGenerator.new()
	var cus_gen = CustomStructureGen.new()
	
	tree_generator.log_type = voxels.get_model_index_default("log_oak")
	tree_generator.leaves_type = voxels.get_model_index_default("leaf_oak")
	_custom_structures = cus_gen.generate()
	for i in 16:
		var s = tree_generator.generate()
		_tree_structures.append(s)
		
	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
			
	test_structure = _tree_structures.pick_random()
			
	_trees_min_y = min_heightmap
	_trees_max_y = max_heightmap + tallest_tree_height
	
	
	temp_noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	temp_noise.frequency = 0.0037
	temp_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	temp_curve.bake()
	curve.bake()
	
var _cave:float
	
func _generate_block(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int) -> void:
	var temp:float
	var block_size := int(out_buffer.get_size().x)
	#var chunk_pos = Vector3(origin_in_voxels.x,origin_in_voxels.y,origin_in_voxels.z)
	var chunk_pos := Vector3(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)
		
	var rng = RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(chunk_pos)
	
	for x in range(16):
		for y in range(16):
			for z in range(16):
						  # current issue is that x, y, and z is between 0-15 as seen above in the for loop, when we obviously
				  # have a lot more coordinates in the world

				  # what we do have is the starting point of the currently generating chunk, origin_in_voxels, which we can use to figure out the real coordinate of the voxel we are about to place in this chunk

				  # we will get these "real" coordinates (ugly way)
				
				var real_coordinate_x := origin_in_voxels.x + x
				var real_coordinate_y := origin_in_voxels.y + y
				var real_coordinate_z := origin_in_voxels.z + z
				
				temp = temp(real_coordinate_x,real_coordinate_z)
				#print (temp)
				await select_biome(temp)
				#print(real_coordinate_y)
				 # these coordinates are now unique, e.g. Minecraft coordinates.
				  # if we check this coordinate for height, we will get the expected behaviour
				  # since it accounts for the position of the chunk we are generating, not just y == 4 in all chunks 
				var real_height = _get_height_at(real_coordinate_x,real_coordinate_z)
				var voxel_tool := out_buffer.get_voxel_tool()
				#print(real_height)
				
				if real_coordinate_y <= real_height:
				# important thing is that we do not set voxels using the real coordinate; the chunk we are generating ONLY cares about coordinates relative to itself, e.g. 0-16, so we use the normal y here
					
					if real_coordinate_y == real_height:
						if rng.randf() < 0.001:
							var creature = current_biome.possible_creatures.pick_random().get_path()
							out_buffer.set_voxel(voxels.get_model_index_default("creature_spawner"),x,y,z,_channel)
							out_buffer.set_voxel_metadata(Vector3i(x,y,z),creature)
					
						if rng.randf() <= current_biome.plant_chance:
							var plant_size = current_biome.plants.size() - 1
							var plant = current_biome.plants[rng.randi_range(0,plant_size)]
							
							var foliage
						
							foliage = plant
							
							out_buffer.set_voxel(foliage, x, y, z, _channel)
							
					#voxel_tool.paste(Vector3(x,y,z),test_structure.voxels,_channel)
					#voxel_tool.paste_masked(Vector3(x,y,z),test_structure.voxels,_channel,_channel,voxels.get_model_index_default("cave_air"))
						
						
					if real_coordinate_y == real_height - 1:
						out_buffer.set_voxel(current_biome.blocks.surface_block, x, y, z,_channel )# x, y, and z are all between 0-15
					if real_coordinate_y < real_height - 1:
						out_buffer.set_voxel(current_biome.blocks.dirt_block, x, y, z,_channel )# x, y, and z are all between 0-15
					if real_coordinate_y < real_height - 2:
							out_buffer.set_voxel(current_biome.blocks.rock_block, x, y, z,_channel )# x, y, and z are all between 0-15

							var ore_size = possible_ore.size() - 1
				
							var ore = possible_ore[rng.randi_range(0,ore_size)]
							if rng.randf() < ore.spawn_chance:
								out_buffer.set_voxel(voxels.get_model_index_default(ore.unique_name),x,y,z,_channel)
					var cave = cave(real_coordinate_x,real_coordinate_z,real_coordinate_y)
					if cave > 0:
						#caves.append(Vector3(real_coordinate_x,real_coordinate_y,real_coordinate_z))
						out_buffer.set_voxel(voxels.get_model_index_default("air"), x, y, z,_channel )# x, y, and z are all between 0-15
				#			
				else:
					out_buffer.set_voxel(voxels.get_model_index_default("air"),x,y,z,_channel)
			
					
					## Water
					#if real_height < 0 and origin_in_voxels.y < 0:
						#var start_relative_height := 0
						#if real_height - origin_in_voxels.y > 0:
							#start_relative_height = real_height - origin_in_voxels.y 
						#out_buffer.fill_area(voxels.get_model_index_default("water_full"),
							#Vector3(x, start_relative_height, z), 
							#Vector3(x + 1, block_size -1, z + 1), _channel)
						#if origin_in_voxels.y + block_size == 0:
							#out_buffer.set_voxel(voxels.get_model_index_default("water_top"),x,block_size - 1,z)
				
	
	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		#if rng.randf() < biome.tree_chance:
		var voxel_tool := out_buffer.get_voxel_tool()
		var structure_instances := []
		_get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)

		# Relative to current block
		var block_aabb := AABB(Vector3(), out_buffer.get_size() + Vector3i(1, 1, 1))

		for dir in _moore_dirs:
			var ncpos : Vector3 = (chunk_pos + dir).round()
			_get_tree_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)
		
		
		for structure_instance in structure_instances:
			var pos : Vector3 = structure_instance[0]
			var structure : Structure = structure_instance[1]
			var lower_corner_pos := pos - structure.offset
			var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))

			
			if aabb.intersects(block_aabb):
				#print(structure.voxels)
				#print("tree")
				
				voxel_tool.paste_masked(lower_corner_pos, 
					structure.voxels,VoxelBuffer.CHANNEL_TYPE,
					# Masking
					VoxelBuffer.CHANNEL_TYPE, voxels.get_model_index_default("air"))
						##print("tree ",lower_corner_pos)
		#
	#if origin_in_voxels.y <= max_heightmap and origin_in_voxels.y + block_size >= min_heightmap:
		#var voxel_tool := out_buffer.get_voxel_tool()
		#var structure_instances := []
			#
		#_get_structure_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)
	#
		## Relative to current block
		#var block_aabb := AABB(Vector3(), out_buffer.get_size() + Vector3i(1, 1, 1))
#
		#for dir in _moore_dirs:
			#var ncpos : Vector3 = (chunk_pos + dir).round()
			#_get_structure_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)
#
		#for structure_instance in structure_instances:
			#var pos : Vector3 = structure_instance[0]
			#var structure : Structure = structure_instance[1]
			#var lower_corner_pos := pos - structure.offset
			#var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))
			#
			#if aabb.intersects(block_aabb):
					#
				#voxel_tool.paste_masked(lower_corner_pos, 
					#structure.voxels,VoxelBuffer.CHANNEL_TYPE,
					## Masking
					#VoxelBuffer.CHANNEL_TYPE, voxels.get_model_index_default("air"))
						
			
					
func _get_height_at(x: int, z: int) -> int:
	var noise = FastNoiseLite.new()
	var t = 0.5 + 0.5 * noise.get_noise_2d(x, z)
	return int(curve.sample_baked(t))

func cave(x:int,z:int,y:int) -> float:
	var t = cavenoise.get_noise_3d(x, y, z)
	return t

func temp(x:int,z:int) -> int:
	var t = 0.5 + 0.5 * temp_noise.get_noise_2d(x, z)
	return int(temp_curve.sample_baked(t))
	
func select_biome(temp:int):
	lock.lock()
	if current_biome == null:
		for biome in biomes:
			if temp in range(biome.min_temp,biome.max_temp):
				current_biome = biome
	else:
		if temp not in range(current_biome.min_temp,current_biome.max_temp):
			for biome in biomes:
				if temp in range(biome.min_temp,biome.max_temp):
					current_biome = biome
	lock.unlock()
	
func _get_tree_instances_in_chunk(
	cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
		
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)
	
	for i in 4:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)
		
		
		if pos.y > 0:
			#if allows_trees(pos):
			pos -= offset
			
			var cave_ = cave(pos.x,pos.z,pos.y - 1)
			print("cave ",cave_)
			if cave_ <= 0:
				
				
				var si := rng.randi() % len(_tree_structures)
				var structure : Structure = _tree_structures[si]
				tree_instances.append([pos.round(), structure])
					
static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))

func _get_structure_instances_in_chunk(
	cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
		
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)

	for i in 4:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)
		
		if pos.y > 0:
			pos -= offset
			var si := rng.randi() % len(_custom_structures)
			var structure : Structure = _custom_structures[si]
			#print(structure.spawn_chance)
			if rng.randf() < structure.spawn_chance:
				tree_instances.append([pos.round(), structure])

func allows_trees(chunk_pos:Vector3) -> bool:
	var tree_temp = temp(chunk_pos.x,chunk_pos.z)
	var tree_biome = get_biome(tree_temp)
	if tree_biome != null:
		return tree_biome.trees
	else:
		print("error no biome")
		return false

	
func get_biome(temp:float) -> Biome:
	var return_b:Biome
	for biome in biomes:
		if temp in range(biome.min_temp,biome.max_temp):
			return_b = biome
			
	return return_b
