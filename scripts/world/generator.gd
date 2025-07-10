#tool
extends VoxelGeneratorScript

const Structure = preload("res://scripts/world/structure.gd")
const TreeGenerator = preload("res://scripts/world/tree_generator.gd")
const StructureGen = preload("res://scripts/world/structure_gen.gd")
const HeightmapCurve = preload("res://resources/heightmap_curve.tres")
const HeatCurve = preload("res://resources/HeatCurve.tres")
const CaveHeightmapCurve = preload("res://resources/cave_heightmap_curve.tres")
const VoxelLibrary = preload("res://resources/voxel_block_library.tres")
const ItemLibrary  = preload("res://resources/items_library.tres")

var _array_mutex := Mutex.new()

# TODO Don't hardcode, get by name from library somehow
var AIR := VoxelLibrary.get_model_index_default("air")
var DIRT := VoxelLibrary.get_model_index_default("dirt")
var GRASS := VoxelLibrary.get_model_index_default("grass")
var WATER_FULL := VoxelLibrary.get_model_index_default("water_full")
var WATER_TOP := VoxelLibrary.get_model_index_default("water_top")
var LOG := VoxelLibrary.get_model_index_default("log_oak")
var OAK_LEAVES := VoxelLibrary.get_model_index_default("leaf_oak")
var BIRCH_LEAVES := VoxelLibrary.get_model_index_default("leaf_birch")
var TALL_GRASS := VoxelLibrary.get_model_index_default("tall_grass")
var DEAD_SHRUB := VoxelLibrary.get_model_index_default("air")
var STONE := VoxelLibrary.get_model_index_default("stone")
var SAND := VoxelLibrary.get_model_index_default("sand")
var CREATURE_SPAWNER = VoxelLibrary.get_model_index_default("creature_spawner")
var PORTAl = VoxelLibrary.get_model_index_default("portal")
var REEDS = VoxelLibrary.get_model_index_default("reeds")
var CACTUS = VoxelLibrary.get_model_index_default("cactus")

var iron := preload("res://resources/items/iron_block.tres")
var diamond := preload("res://resources/items/diamond_block.tres")

@export var possible_worlds:Array[String] = ["https://thegates.io/worlds/devs/snap_games_studio/minecraft_world2.gate"]

@export var biomes : Array[Biome]


var possible_ore = [iron,diamond]

var HeatNoise = FastNoiseLite.new()
var caves := []
var creatures_spawners: Array[Vector3] = []

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE


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


var _tree_structures := []
var _custom_structures := []

var _heightmap_min_y := int(HeightmapCurve.min_value)
var _heightmap_max_y := int(HeightmapCurve.max_value)
var _heightmap_range := 0
var _heightmap_noise := FastNoiseLite.new()

var _trees_min_y := 0
var _trees_max_y := 0

var rng = RandomNumberGenerator.new()
#var _trees_min_y := 0
#var _trees_max_y := 0


func _init():
	#call_deferred("ready")
	# TODO Even this must be based on a seed, but I'm lazy
	
	
	if is_server():
		var tree_generator = TreeGenerator.new()
	
	
		tree_generator.log_type = LOG
		tree_generator.leaves_type = OAK_LEAVES
		
		for i in 16:
			var s = tree_generator.generate()
			_tree_structures.append(s)
			
		var customGen = StructureGen.new()
		
		customGen.possible_worlds = possible_worlds
		
		for i in 3:
			var s = customGen.generate()
			_custom_structures.append(s)
	
	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
			
	_trees_min_y = _heightmap_min_y
	_trees_max_y = _heightmap_max_y + tallest_tree_height

	#_heightmap_noise.seed = 131183
	_heightmap_noise.frequency = 1.0 / 128.0
	_heightmap_noise.fractal_octaves = 4
	
	HeatNoise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	HeatNoise.frequency = 0.001
	HeatNoise.fractal_octaves = 5
	HeatNoise.fractal_weighted_strength = 1
	HeatNoise.fractal_gain = 0
	
	rng.seed = _get_chunk_seed_2d(Vector3(1,1,1))
	# IMPORTANT
	# If we don't do this `Curve` could bake itself when interpolated,
	# and this causes crashes when used in multiple threads
	HeatCurve.bake()
	CaveHeightmapCurve.bake()
	HeightmapCurve.bake()

func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL

var biome:Biome

func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
			
	
	var temp:float
	
	# TODO There is an issue doing this, need to investigate why because it should be supported
	# Saves from this demo used 8-bit, which is no longer the default
	# buffer.set_channel_depth(_CHANNEL, VoxelBuffer.DEPTH_8_BIT)

	# Assuming input is cubic in our use case (it doesn't have to be!)
	var block_size := int(buffer.get_size().x)
	var oy := origin_in_voxels.y
	# TODO This hardcodes a cubic block size of 16, find a non-ugly way...
	# Dividing is a false friend because of negative values
	var chunk_pos := Vector3(
		origin_in_voxels.x >> 4,
		origin_in_voxels.y >> 4,
		origin_in_voxels.z >> 4)

	_heightmap_range = _heightmap_max_y - _heightmap_min_y

	# Ground
	
	
	
	
				
	temp = temp_data(origin_in_voxels.x,origin_in_voxels.z)
	temp = round(temp)
	await select_biome(temp)
	#print(biome.biome_name)
	
	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(AIR, _CHANNEL)
		


	
	## BedRock
	#elif origin_in_voxels.y + block_size < _heightmap_min_y:
		#buffer.fill(STONE, _CHANNEL)
		
	
	
	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _get_chunk_seed_2d(chunk_pos)
		
		var gx : int
		var gz := origin_in_voxels.z

		for z in block_size:
			gx = origin_in_voxels.x

			for x in block_size:
				var height := _get_height_at(gx, gz)
				
				
				
				
				if biome == null:
					return
					
				var relative_height := height - oy
				
				# Dirt and grass
				if relative_height > block_size:
					buffer.fill_area(biome.blocks.stone_layer_block,
						Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
					
							
					var ore_size = possible_ore.size() - 1
					var ore = possible_ore[rng.randi_range(0,ore_size)]
					if rng.randf() < ore.spawn_chance:
						var pos = Vector3(rng.randi_range(x,x+ore.spawn_size),rng.randi_range(0,block_size),rng.randi_range(z,z+ore.spawn_size))
						if pos.y >= 0:
							if pos.x >= 0:
								if pos.z >= 0:
									buffer.fill_area(VoxelLibrary.get_model_index_default(ore.unique_name),Vector3(pos.x,pos.y,pos.z),Vector3(pos.x +1,pos.y + 1,pos.z+ 1),_CHANNEL)
									#
					buffer.fill_area(biome.blocks.stone_layer_block,
						Vector3(x, 0, z), Vector3(x + 1, block_size, z +1), _CHANNEL)
						
				elif relative_height > 0:
					buffer.fill_area(biome.blocks.stone_layer_block,
						Vector3(x, 0, z), Vector3(x + 1, relative_height, z + 1), _CHANNEL)
						
					if height >= 0:
						buffer.set_voxel(biome.blocks.surface_block, x, relative_height - 1, z, _CHANNEL)
						
						if relative_height - 2 >= 0:
							buffer.set_voxel(biome.blocks.dirt_layer_block,x, relative_height - 2, z, _CHANNEL)
						
						if relative_height < block_size:
							
							if rng.randf() <= biome.plant_chance:
								var plant_size = biome.plants.size() - 1
								var plant = biome.plants[rng.randi_range(0,plant_size)]
								
								var foliage
							
								foliage = plant
								
								buffer.set_voxel(foliage, x, relative_height, z, _CHANNEL)
							
							#
							if rng.randf() < 0.001:
								buffer.set_voxel(CREATURE_SPAWNER,x,relative_height,z,_CHANNEL)
								buffer.set_voxel_metadata(Vector3i(x,relative_height,z),biome.possible_creatures.pick_random())
								creatures_spawners.append(Vector3(x,relative_height,z))
							#elif rng.randf() < 0.00001:
		#
								#buffer.set_voxel(PORTAl,x,relative_height,z,_CHANNEL)
								#var worlds = possible_worlds.size() - 1
								#var world = possible_worlds[rng.randi_range(0,worlds)]
								#buffer.set_voxel_metadata(Vector3i(x,relative_height,z),world)
								
								#
					##
				
				if height < 0 and oy < 0:
					var start_relative_height := 0
					if relative_height > 0:
						start_relative_height = relative_height
					buffer.fill_area(WATER_FULL,
						Vector3(x, start_relative_height, z), 
						Vector3(x + 1, block_size -1, z + 1), _CHANNEL)
					if oy + block_size == 0:
						buffer.set_voxel(WATER_TOP,x,block_size - 1,z)
					#if oy + block_size == 0:
						# Surface block
						#buffer.fill_area(WATER_TOP,Vector3(x + 1,block_size, z + 1),Vector3(x + 2,block_size -1, z + 2),_CHANNEL)
						#buffer.fill_area(WATER_TOP,
						#Vector3(x,  block_size, z), 
						#Vector3(x + 1, block_size + 1, z + 1), _CHANNEL)
						#
				gx += 1

			gz += 1
			
	# Custom Structures
	
	if origin_in_voxels.y <= _heightmap_max_y and origin_in_voxels.y + block_size >= _heightmap_min_y:
		var voxel_tool := buffer.get_voxel_tool()
		var structure_instances := []
			
		_get_structure_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)
	
		# Relative to current block
		var block_aabb := AABB(Vector3(), buffer.get_size() + Vector3i(1, 1, 1))

		for dir in _moore_dirs:
			var ncpos : Vector3 = (chunk_pos + dir).round()
			_get_structure_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)

		for structure_instance in structure_instances:
			var pos : Vector3 = structure_instance[0]
			var structure : Structure = structure_instance[1]
			var lower_corner_pos := pos - structure.offset
			var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3i(1, 1, 1))
			
			if aabb.intersects(block_aabb):
					
				voxel_tool.paste_masked(lower_corner_pos, 
					structure.voxels,VoxelBuffer.CHANNEL_TYPE,
					# Masking
					VoxelBuffer.CHANNEL_TYPE, AIR)
						
				
	# Trees

	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		#if rng.randf() < biome.tree_chance:
		var voxel_tool := buffer.get_voxel_tool()
		var structure_instances := []
			
		_get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)
	
		# Relative to current block
		var block_aabb := AABB(Vector3(), buffer.get_size() + Vector3i(1, 1, 1))

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
				voxel_tool.paste_masked(lower_corner_pos, 
					structure.voxels,VoxelBuffer.CHANNEL_TYPE,
					# Masking
					VoxelBuffer.CHANNEL_TYPE, AIR)
						

			
	buffer.compress_uniform_channels()
	

	

func _get_tree_instances_in_chunk(
	cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
		
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(cpos)
	
	for i in 4:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)
		
		
		if pos.y > 0:
			if allows_trees(pos):
				pos -= offset
				
				var si := rng.randi() % len(_tree_structures)
				var structure : Structure = _tree_structures[si]
				tree_instances.append([pos.round(), structure])

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
			
#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))

func temp_data(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * HeatNoise.get_noise_2d(x, z)
	#return int(HeightmapCurve.sample_baked(t)) 
	return int(HeatCurve.sample_baked(t))

func _get_height_at(x: int, z: int) -> int:
	var noise = biome.noise
	var t = 0.5 + 0.5 * noise.get_noise_2d(x, z)
	var curve = biome.heightmap
	return int(curve.sample_baked(t))
	
	
func select_biome(temp):
	
	if !biome:
		_array_mutex.lock()
		var test_biome =  get_biome(temp)
		if test_biome != null:
				biome = test_biome
		_array_mutex.unlock()
	else:
		if biome:
			if temp <= biome.min_temp:
				_array_mutex.lock()
				var test_biome =  get_biome(temp)
				if test_biome != null:
					biome =test_biome
				_array_mutex.unlock()
			elif temp >= biome.max_temp:
				_array_mutex.lock()
				var test_biome =  get_biome(temp)
				if test_biome != null:
					biome =test_biome
				_array_mutex.unlock()
				
	
func get_biome(temp:float) -> Biome:
	var return_biome:Biome
	for _biome in biomes:
		if temp >= _biome.min_temp and temp <= _biome.max_temp:
			return_biome = _biome
			return_biome.create_voxels_ids()
	
	return return_biome
	
	
func allows_trees(chunk_pos) -> bool:
	var temp = temp_data(chunk_pos.x,chunk_pos.z)
	var b = get_biome(temp)
	if b:
		if b.trees:
			return true
		else:
			return false
	else:
		print("error no biome")
	return false

static func is_server() -> bool:
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return "--server" in args
