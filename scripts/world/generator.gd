#tool
extends VoxelGeneratorScript

const VoxelLibrary = preload("res://resources/voxel_block_library.tres")
const Structure = preload("./structure.gd")
const TreeGenerator = preload("./tree_generator.gd")

@export var generate_trees:bool = true
@export var HeightmapCurve = preload("res://resources/heightmap_curve.tres")
@export var _heightmap_noise:FastNoiseLite
@export var plant_odds:float = 0.1
@export var creature_odds:float =  0.0001
@export var possible_creatures: Array[Creature]

var stone_block := []

@export var possible_tree_types:Dictionary = {
	"oak": ["log_oak","leaf_oak"],
	"birch": ["log_birch","leaf_oak"]
}
@export var possible_plants: Array[StringName]

@export var possible_ore: Array[ItemBlock]

# TODO Don't hardcode, get by name from library somehow
var AIR := VoxelLibrary.get_model_index_default("air")
var DIRT := VoxelLibrary.get_model_index_default("dirt")
var GRASS := VoxelLibrary.get_model_index_default("grass")
var WATER_FULL := VoxelLibrary.get_model_index_default("air")
var WATER_TOP := VoxelLibrary.get_model_index_default("air")
var LOG := VoxelLibrary.get_model_index_default("log_oak")
var OAK_LEAVES := VoxelLibrary.get_model_index_default("leaf_oak")
var BIRCH_LEAVES := VoxelLibrary.get_model_index_default("leaf_birch")
var TALL_GRASS := VoxelLibrary.get_model_index_default("tall_grass")
var DEAD_SHRUB := VoxelLibrary.get_model_index_default("air")
var STONE := VoxelLibrary.get_model_index_default("stone")
var SAND := VoxelLibrary.get_model_index_default("sand")

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

var _heightmap_min_y := int(HeightmapCurve.min_value)
var _heightmap_max_y := int(HeightmapCurve.max_value)
var _heightmap_range := 0
var _trees_min_y := 0
var _trees_max_y := 0


func _init():
	
	# TODO Even this must be based on a seed, but I'm lazy
	var tree_generator = TreeGenerator.new()
	
	tree_generator.possible_types = possible_tree_types
	
	for i in 16:
		var s = tree_generator.generate()
		_tree_structures.append(s)

	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
	_trees_min_y = _heightmap_min_y
	_trees_max_y = _heightmap_max_y + tallest_tree_height
	#_heightmap_noise.fractal_octaves = 4

	# IMPORTANT
	# If we don't do this `Curve` could bake itself when interpolated,
	# and this causes crashes when used in multiple threads
	HeightmapCurve.bake()


func _get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func _generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3i, lod: int):
	
	#print(buffer.get_size())
	var voxel_tool := buffer.get_voxel_tool()
	#print(voxel_tool.do_box(origin_in_voxels, origin_in_voxels+Vector3i(100,100,100)))
	#buffer.fill_area()
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

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(AIR, _CHANNEL)

	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(STONE, _CHANNEL)

	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = _get_chunk_seed_2d(chunk_pos)
		
		var gx : int
		var gz := origin_in_voxels.z

		for z in block_size:
			gx = origin_in_voxels.x

			for x in block_size:
				var height := _get_height_at(gx, gz)
				var relative_height := height - oy
				# Dirt and grass
				if relative_height > block_size:
					
					buffer.fill_area(STONE,
						Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
					
					var ore = possible_ore.pick_random()
					if rng.randf() < ore.spawn_chance:
						var pos = Vector3(randi_range(x,x+ore.spawn_size),randi_range(0,block_size),randi_range(z,z+ore.spawn_size))
						if pos.y >= 0:
							if pos.x >= 0:
								if pos.z >= 0:
									buffer.fill_area(VoxelLibrary.get_model_index_default(ore.unique_name),Vector3(pos.x,pos.y,pos.z),Vector3(pos.x +1,pos.y + 1,pos.z+ 1),_CHANNEL)
					
					buffer.fill_area(DIRT,
						Vector3(x, 0, z), Vector3(x , block_size, z ), _CHANNEL)
				
				elif relative_height > 0:
					
					buffer.fill_area(STONE,
						Vector3(x, 0, z), Vector3(x + 1, relative_height, z + 1), _CHANNEL)
							
					#print(height, " ", relative_height)
					if height >= 0:
						
						
							
						buffer.set_voxel(GRASS, x, relative_height - 1, z, _CHANNEL)
						if relative_height - 2 >= 0:
							buffer.set_voxel(DIRT,x, relative_height - 2, z, _CHANNEL)
					#
						if relative_height < block_size and rng.randf() < 0.2:
							if rng.randf() < creature_odds:
								var pos := Vector3(rng.randi() % block_size, 0, rng.randi() % block_size)
								var ncpos : Vector3 = (chunk_pos).round()
								pos += ncpos * block_size
								Globals.call_deferred("Spawn_creature",Vector3(pos.x,_get_height_at(x,z) + 10,pos.z),possible_creatures.pick_random())
								#buffer.set_voxel(DIRT, x, relative_height + 2 , z, _CHANNEL)
							if rng.randf() < plant_odds:
								var plant = possible_plants.pick_random()
								var foliage = VoxelLibrary.get_model_index_default(plant)
								buffer.set_voxel(foliage, x, relative_height, z, _CHANNEL)
					
					
				#if height < 0 and oy < 0:
					#buffer.set_voxel(OAK_LEAVES, x, block_size - 1, z, _CHANNEL)
					#print("ore")
				# Water
				#if height < 0 and oy < 0:
					#var start_relative_height := 0
					#if relative_height > 0:
						#start_relative_height = relative_height
					#buffer.fill_area(WATER_FULL,
						#Vector3(x, start_relative_height, z), 
						#Vector3(x + 1, block_size, z + 1), _CHANNEL)
					#if oy + block_size == 0:
						## Surface block
						#buffer.set_voxel(WATER_TOP, x, block_size - 1, z, _CHANNEL)
				gx += 1

			gz += 1

	# Trees
	if generate_trees:
		if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:

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
					voxel_tool.paste_masked(lower_corner_pos, 
						structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE,
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
			pos -= offset
			var si := rng.randi() % len(_tree_structures)
			var structure : Structure = _tree_structures[si]
			tree_instances.append([pos.round(), structure])
			
	


#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))


func _get_height_at(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * _heightmap_noise.get_noise_2d(x, z)
	return int(HeightmapCurve.sample_baked(t))

func ore(start:Vector3,end:Vector3,channel,chunk_pos,buffer:VoxelBuffer):
	var rng := RandomNumberGenerator.new()
	rng.seed = _get_chunk_seed_2d(chunk_pos)
	
	if rng.randf() <= 1:
		var random_pos = Vector3(randi_range(start.x,end.x),randi_range(start.y,end.y),randi_range(start.z,end.z))
		buffer.set_voxel(random_pos.x,random_pos.y,random_pos.z, _CHANNEL)
