extends VoxelGeneratorMultipassCB

const Structure = preload("res://scripts/world/structure.gd")
const CustomStructureGen = preload("res://scripts/world/structure_gen.gd")
const TreeGenerator = preload("res://scripts/world/tree_generator.gd")
const voxels:VoxelBlockyTypeLibrary = preload("res://resources/voxel_block_library.tres")
const curve:Curve = preload("res://resources/heightmap_curve.tres")
const cavenoise:FastNoiseLite = preload("res://resources/cave_noise.tres")

const CHANNEL = VoxelBuffer.CHANNEL_TYPE

var trunk_len_min := 6
var trunk_len_max := 15

var heightmap_noise: FastNoiseLite = FastNoiseLite.new()

var max_heightmap:int = (curve.max_value)
var min_heightmap:int = (curve.min_value)

var _tree_structures := []
var _custom_structures := []
var _trees_min_y := 0
var _trees_max_y := 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

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

	_custom_structures = cus_gen.generate()

	tree_generator.log_type = voxels.get_model_index_default("log_oak")
	tree_generator.leaves_type = voxels.get_model_index_default("leaf_oak")

	for i in 16:
		var s = tree_generator.generate()
		_tree_structures.append(s)
		
	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
			
	#test_structure = _tree_structures.pick_random()
			
	_trees_min_y = min_heightmap
	_trees_max_y = max_heightmap + tallest_tree_height


	heightmap_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	heightmap_noise.frequency = 0.01

	curve.bake()

func _generate_pass(voxel_tool: VoxelToolMultipassGenerator, pass_index: int):
	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()


	var _cpos := Vector3(
		min_pos.x >> 4,
		min_pos.y >> 4,
		min_pos.z >> 4)

	

	rng.seed = _get_chunk_seed_2d(_cpos)

	if pass_index == 0:
		# Base terrain
		for z in range(min_pos.z, max_pos.z):
			for x in range(min_pos.x, max_pos.x):
				for y in range(min_pos.y, max_pos.y):
					
					var real_height = _get_height_at(x,z)

					if y <= real_height:
						if y == real_height:
							
							voxel_tool.set_voxel_metadata(Vector3i(x, y, z),"walkable")
							if rng.randf() <= 0.8:
								#voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("spawner"))
								#voxel_tool.set_voxel_metadata(Vector3i(x, y, z), load("res://resources/creatures/fox.tres"))
								pass
							if rng.randf() <= 0.8:
								voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("tall_grass"))

						if y == real_height - 1:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("grass"))
							
							
						if y == real_height - 2:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("dirt"))
						if y < real_height - 2:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("stone"))

						var cave = cave(x,y,z)
						
						if cave:
							voxel_tool.set_voxel(Vector3i(x, y, z),voxels.get_model_index_default("air"))# x, y, and z are all between 0-15
					else:
						voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("air"))
	

	elif pass_index == 1:
		var tree_count := 3
		
		for tree_index in tree_count:
			try_plant_tree(voxel_tool, rng)
			

	elif pass_index == 2:
		try_place_structure(voxel_tool, rng)
					
								 
func _get_height_at(x: int, z: int) -> int:
	var t = 0.5 + 0.5 * heightmap_noise.get_noise_2d(x, z)
	return int(curve.sample_baked(t))

func cave(x:int,y:int,z:int) -> bool:
	var t = cavenoise.get_noise_3d(x, y, z)
	if t > 0:
		return true
	else:
		return false

static func _get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))


func try_plant_tree(voxel_tool: VoxelToolMultipassGenerator, rng: RandomNumberGenerator):
	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()
	var chunk_size = max_pos - min_pos
	
	var tree_rpos := Vector3i(
		rng.randi_range(0, chunk_size.x), 0,
		rng.randi_range(0, chunk_size.z)
	)
#	print("Trying to plant a tree at ", tree_rpos)
	
	var tree_pos := min_pos + tree_rpos
	tree_pos.y = max_pos.y - 1
	
	var found_ground := false
	while tree_pos.y >= min_pos.y:
		var v := voxel_tool.get_voxel(tree_pos)
		# Note, we could also find tree blocks that were placed earlier!
		if v == voxels.get_model_index_default("grass") or v == voxels.get_model_index_default("tall_grass"):
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
		#print("Ground not found")
		return
	
	voxel_tool.paste_masked(tree_pos, _tree_structures.pick_random().voxels, 1 << VoxelBuffer.CHANNEL_TYPE,VoxelBuffer.CHANNEL_TYPE,voxels.get_model_index_default("air"))


func try_place_structure(voxel_tool: VoxelToolMultipassGenerator, rng: RandomNumberGenerator):
	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()
	var chunk_size = max_pos - min_pos
	
	var tree_rpos := Vector3i(
		rng.randi_range(0, chunk_size.x), 0,
		rng.randi_range(0, chunk_size.z)
	)
#	print("Trying to plant a tree at ", tree_rpos)
	
	var tree_pos := min_pos + tree_rpos
	tree_pos.y = max_pos.y - 1
	
	var found_ground := false
	while tree_pos.y >= min_pos.y:
		var v := voxel_tool.get_voxel(tree_pos)
		# Note, we could also find tree blocks that were placed earlier!
		if v == voxels.get_model_index_default("grass"):
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
		#print("Ground not found")
		return
	var structure:Structure = _custom_structures.pick_random()


	if rng.randf() > structure.spawn_chance: return

	voxel_tool.paste_masked(tree_pos - type_convert(structure.offset,10), structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE,VoxelBuffer.CHANNEL_TYPE,voxels.get_model_index_default("air"))
