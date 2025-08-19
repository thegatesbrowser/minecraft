extends VoxelGeneratorMultipassCB

const Structure = preload("res://scripts/world/structure.gd")
const CustomStructureGen = preload("res://scripts/world/structure_gen.gd")
const TreeGenerator = preload("res://scripts/world/tree_generator.gd")
const voxels:VoxelBlockyTypeLibrary = preload("res://resources/voxel_block_library.tres")
const curve:Curve = preload("res://resources/heightmap_curve.tres")
const temp_curve:Curve = preload("res://resources/HeatCurve.tres")


var iron := preload("res://resources/items/iron_block.tres")
var diamond := preload("res://resources/items/diamond_block.tres")
var possible_ore = [iron,diamond]

const cavenoise:FastNoiseLite = preload("res://resources/noises/cave_noise.tres")
const river_noise:FastNoiseLite = preload("res://resources/noises/river noise.tres")
const hill_noise:FastNoiseLite = preload("res://resources/noises/hills noise.tres")


var last_biome:String = ""

const biomes : Dictionary = {
	"forest": {
		"heat_range": [0,1,2,3,4,5,6,7,8,9,10],
		"trees": ["oak", "birch"],
		"first_layer": "grass",
		"second_layer": "dirt",
		"third_layer": "stone",
		"plants": ["tall_grass","tall_flower"],
		"noise": preload("res://resources/forest.tres"),
		"biome_curve": preload("res://resources/heightmap_curve forest.tres")
	},
	"desert": {
		"heat_range": [11,12,13,14,15,16,17,18,19,20],
		"trees": ["cactus"],
		"first_layer": "sand",
		"second_layer": "sand",
		"third_layer": "stone",
		"plants": ["reeds"],
		"noise": preload("res://resources/desert.tres"),
		"biome_curve": preload("res://resources/heightmap_curve desert.tres")
	},
	"snowy": {
		"heat_range":[-1,-2],
		"trees": ["pine"],
		"first_layer": "grass",
		"second_layer": "dirt",
		"third_layer": "stone",
	}
}


const CHANNEL = VoxelBuffer.CHANNEL_TYPE

var trunk_len_min := 6
var trunk_len_max := 15

var heightmap_noise: FastNoiseLite = FastNoiseLite.new()
var temperature_noise: FastNoiseLite = FastNoiseLite.new()
var moisture_noise: FastNoiseLite = FastNoiseLite.new()

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

	temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temperature_noise.frequency = 0.01
	temperature_noise.seed = 123453

	moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	moisture_noise.frequency = 0.01
	moisture_noise.seed = 12345

	

	temp_curve.bake()
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
					
					
					var temp:int = get_temp(x, z)
					var biome_name 

					if last_biome == "":
						biome_name = get_biome(temp)
					else:
						if temp in biomes[last_biome].heat_range:
							biome_name = last_biome
						else:
							biome_name = get_biome(temp)
							last_biome = biome_name

					var real_height = _get_height_at(x,z)
					

					if y <= real_height:

						if y == real_height:
							
							voxel_tool.set_voxel_metadata(Vector3i(x, y, z),"walkable")
							
							if rng.randf() <= 0.8:
								#voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("spawner"))
								#voxel_tool.set_voxel_metadata(Vector3i(x, y, z), load("res://resources/creatures/fox.tres"))
								pass
							if rng.randf() <= 0.5:
								if voxel_tool.get_voxel(Vector3i(x, y - 1, z)) != voxels.get_model_index_default("air"):
									#voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default(plant))
								
									var plant = biomes[biome_name].plants.pick_random()
									voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default(plant))

					
						if y == real_height - 1:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default(biomes[biome_name].first_layer))
							
							
						if y == real_height - 2:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default(biomes[biome_name].second_layer))
						if y < real_height - 2:
							voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default(biomes[biome_name].third_layer))
							var ore_size = possible_ore.size() - 1
				
							var ore = possible_ore[rng.randi_range(0,ore_size)]
							if rng.randf() < ore.spawn_chance:
								voxel_tool.set_voxel(Vector3i(x, y, z),voxels.get_model_index_default(ore.unique_name))

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
	var river_noise_value =  0.5 + 0.5 * river_noise.get_noise_2d(x, z)
	var hill_noise_value =  0.5 + 0.5 * hill_noise.get_noise_2d(x, z)
	var base_noise_value =  0.5 + 0.5 * heightmap_noise.get_noise_2d(x, z) * 100

	if hill_noise_value > 0.5:
		hill_noise_value = hill_noise_value * 100
	else:
		hill_noise_value = 0.0

	if river_noise_value > 0.9:
		river_noise_value = river_noise_value * -50
	else:
		river_noise_value = 0.0

	
	


	var height = (river_noise_value + hill_noise_value + base_noise_value) / 3.0

	return int(height)

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
		if v == voxels.get_model_index_default("grass") or v == voxels.get_model_index_default("tall_grass") or v == voxels.get_model_index_default("sand"):
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
		#print("Ground not found")
		return
	var structure:Structure = _custom_structures.pick_random()

	
	if rng.randf() > structure.spawn_chance: return

	voxel_tool.paste_masked(tree_pos - type_convert(structure.offset,10), structure.voxels, 1 << VoxelBuffer.CHANNEL_TYPE,VoxelBuffer.CHANNEL_TYPE,voxels.get_model_index_default("air"))

	
	

func get_biome(temp: int) -> String:
	for biome_name in biomes:
		var biome = biomes[biome_name]
		if temp in biome.heat_range:
			return biome_name

	return "forest"  # Default biome if none match

func get_temp(x: int, z: int) -> int:
	var temperature =  0.5 + 0.5 * temperature_noise.get_noise_2d(x, z)
	return int(temp_curve.sample_baked(temperature))
