extends VoxelGeneratorMultipassCB

const Structure = preload("res://scripts/world/structure.gd")
const voxels:VoxelBlockyTypeLibrary = preload("res://resources/voxel_block_library.tres")
const curve:Curve = preload("res://resources/heightmap_curve.tres")
const temp_curve:Curve = preload("res://resources/HeatCurve.tres")

const cavenoise:FastNoiseLite = preload("res://resources/noises/cave_noise.tres")
const river_noise:FastNoiseLite = preload("res://resources/noises/river noise.tres")
const hill_noise:FastNoiseLite = preload("res://resources/noises/hills noise.tres")

var last_biome:String = ""

var _tested:bool = false
var Bedrock:int = voxels.get_model_index_default("bedrock")
const AIR: int = 0

var biomes : Dictionary = {
	"forest": {
		"heat_range": [0,1,2,3,4,5,6,7,8,9,10],
		"first_layer": voxels.get_model_index_default("grass"),
		"second_layer": voxels.get_model_index_default("dirt"),
		"third_layer": voxels.get_model_index_default("stone"),
		"ore": {
			voxels.get_model_index_default("iron"): {"spawn_chance":0.001},
			voxels.get_model_index_default("diamond"): {"spawn_chance":0.0001},
			},
		"plants": [voxels.get_model_index_default("tall_grass"),voxels.get_model_index_default("tall_flower")],
		"noise": preload("res://resources/forest.tres"),
		"biome_curve": preload("res://resources/heightmap_curve forest.tres"),
		"trees": ["res://pine_tree 1.txt","res://pine_tree 2.txt","res://pine_tree 3.txt"],
		"_custom_structures": {"res://chest_island.txt": {"spawn_chance":0.1,}},
		"creatures": ["res://resources/creatures/fox.tres"],
		"creature_spawn_chance": 0.006
	},
	"desert": {
		"heat_range": [11,12,13,14,15,16,17,18,19,20],
		"first_layer": voxels.get_model_index_default("sand"),
		"second_layer": voxels.get_model_index_default("sand"),
		"third_layer": voxels.get_model_index_default("stone"),
		"ore": {
			voxels.get_model_index_default("iron"): {"spawn_chance":0.001},
			voxels.get_model_index_default("diamond"): {"spawn_chance":0.0001},
			},
		"plants": [voxels.get_model_index_default("reeds")],
		"noise": preload("res://resources/desert.tres"),
		"biome_curve": preload("res://resources/heightmap_curve desert.tres"),
		"trees": [],
		"_custom_structures": {"res://chest_island.txt": {"spawn_chance":0.1,}},
		"creatures": [],
		"creature_spawn_chance": 0.006
	},
}

const CHANNEL = VoxelBuffer.CHANNEL_TYPE


var heightmap_noise: FastNoiseLite = FastNoiseLite.new()
var temperature_noise: FastNoiseLite = FastNoiseLite.new()
var moisture_noise: FastNoiseLite = FastNoiseLite.new()

var max_heightmap:int = (curve.max_value)
var min_heightmap:int = (curve.min_value)

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

	heightmap_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	heightmap_noise.frequency = 0.01

	temperature_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	temperature_noise.frequency = 0.01
	temperature_noise.seed = 123453

	temp_curve.bake()
	curve.bake()

func _generate_pass(voxel_tool: VoxelToolMultipassGenerator, pass_index: int):
	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()
	
	var block_size := int(32)

	var _cpos := Vector3(
		min_pos.x >> 4,
		min_pos.y >> 4,
		min_pos.z >> 4)

	rng.seed = hash("Godot")


	if pass_index == 0:
		# Base terrain
		for z in range(min_pos.z, max_pos.z):
			for x in range(min_pos.x, max_pos.x):
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

				for y in range(min_pos.y, max_pos.y):

					if y <= real_height:

						if y == real_height:
							if rng.randf() <= 0.2:
								#voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("portal"))
								pass
								
							elif rng.randf() <= biomes[biome_name].creature_spawn_chance:
								if biomes[biome_name].creatures.is_empty() == false:
									Globals.call_deferred("_create_spawner",Vector3i(x, y, z) + Vector3i(0,1,0),biomes[biome_name].creatures.pick_random())
									
								#	Globals.spawn_creature.emit(Vector3i(x, y, z) + Vector3i(0,1,0),load(biomes[biome_name].creatures.pick_random()))
									#voxel_tool.set_voxel(Vector3i(x, y, z), voxels.get_model_index_default("spawner"))
									#voxel_tool.set_voxel_metadata(Vector3i(x, y, z), biomes[biome_name].creatures.pick_random())
								pass
							elif rng.randf() <= 0.5:
								
								if !cave(x,y+1,z):
									var i = rng.randi() % len(biomes[biome_name].plants)
									var plant = biomes[biome_name].plants[i]
									voxel_tool.set_voxel(Vector3i(x, y, z), plant)

					
						if y == real_height - 1:
							voxel_tool.set_voxel(Vector3i(x, y, z), biomes[biome_name].first_layer)
							
							
						if y == real_height - 2:
							voxel_tool.set_voxel(Vector3i(x, y, z), biomes[biome_name].second_layer)
						if y < real_height - 2:
							## Stone
							voxel_tool.set_voxel(Vector3i(x, y, z), biomes[biome_name].third_layer)
							var ores:Dictionary = biomes[biome_name].ore
							var ore_size =  ores.keys().size() - 1
							var key = (ores.keys()[rng.randi_range(0,ore_size)]) ## key is voxel id
							var ore = ores[key]
							
							if rng.randf() < ore.spawn_chance:
								
								voxel_tool.set_voxel(Vector3i(x, y, z),key)
								
							
							

						var _cave = cave(x,y,z)
						
						if _cave:
							voxel_tool.set_voxel(Vector3i(x, y, z),AIR)# x, y, and z are all between 0-15
							
						if y <= -63:
							voxel_tool.set_voxel(Vector3i(x,y,z),voxels.get_model_index_default("bedrock"))
								
					else:
						voxel_tool.set_voxel(Vector3i(x, y, z), AIR)
	

	elif pass_index == 1:
		#try_place_structure(voxel_tool, rng)
		var tree_count := 7
		var _rng := RandomNumberGenerator.new()
		for tree_index in tree_count:
			rng.seed = tree_index + _get_chunk_seed_2d(voxel_tool.get_main_area_min())
			try_plant_tree(voxel_tool,_rng)
			

	elif pass_index == 2:
		for i in 3:
			try_place_structure(voxel_tool, rng)
					
								 
func _get_height_at(x: int, z: int) -> int:
	var river_noise_value:float =  0.5 + 0.5 * river_noise.get_noise_2d(x, z)
	var hill_noise_value:float =  0.5 + 0.5 * hill_noise.get_noise_2d(x, z)
	var base_noise_value:float =  0.5 + 0.5 * heightmap_noise.get_noise_2d(x, z) * 100

	if hill_noise_value > 0.5:
		hill_noise_value = hill_noise_value * 50
	else:
		hill_noise_value = 0.0

	if river_noise_value > 0.9:
		river_noise_value = river_noise_value * -50
	else:
		river_noise_value = 0.0

	
	


	var height:float = base_noise_value + (river_noise_value + hill_noise_value)

	if last_biome == "desert":
			return int(lerpf(height,0,.2))
	else:
		return int(lerpf(base_noise_value,height,.7))

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
		if v == voxels.get_model_index_default("grass"):
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
#		print("Ground not found")
		return
	
	if voxel_tool.get_voxel(tree_pos - Vector3i(0,1,0)) == AIR: return
	
	var paste_buffer := VoxelBuffer.new()
	
	var biome_name = get_biome(get_temp(tree_pos.x,tree_pos.z))
	#print("biome ", biomes[biome_name])
	if biomes[biome_name].trees.is_empty(): return # returns if no trees in that biome

	var tree = biomes[biome_name].trees.pick_random()

	var file = FileAccess.open(tree,FileAccess.READ)
	#print("file ",file)
	var size := file.get_32()
	var data := file.get_buffer(size)
	VoxelBlockSerializer.deserialize_from_byte_array(data, paste_buffer, true)

	voxel_tool.paste_masked(tree_pos, paste_buffer, 1 << VoxelBuffer.CHANNEL_TYPE,VoxelBuffer.CHANNEL_TYPE,voxels.get_model_index_default("air"))


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
		if v == voxels.get_model_index_default("grass") or v == voxels.get_model_index_default("sand"):
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
		#print("Ground not found")
		return
		
	var biome_name = get_biome(get_temp(tree_pos.x,tree_pos.z))
	
	var structures:Dictionary = biomes[biome_name]._custom_structures
	
	var structure_paths:Array = structures.keys()
	structure_paths.shuffle()
	
	var chance = rng.randf()
	
	var structure:String = ""
	
	for i in structure_paths:
		if structures[i].spawn_chance > chance:
			#print( "S chance ",structures[i].spawn_chance, " chance ",chance)
			structure = i
			break
	
	if structure == "": return ## did not find a structure
	
	var paste_buffer := VoxelBuffer.new()
	var file = FileAccess.open(structure,FileAccess.READ)
	#print("file ",file)
	var size := file.get_32()
	var data := file.get_buffer(size)
	VoxelBlockSerializer.deserialize_from_byte_array(data, paste_buffer, true)
	voxel_tool.paste_masked(tree_pos, paste_buffer, 1 << VoxelBuffer.CHANNEL_TYPE,VoxelBuffer.CHANNEL_TYPE,voxels.get_model_index_default("air"))
	#voxel_tool.set_voxel(tree_pos,voxels.get_model_index_default("stone"))
	
func get_biome(temp: int) -> String:
	for biome_name in biomes:
		var biome = biomes[biome_name]
		if temp in biome.heat_range:
			return biome_name

	return "forest"  # Default biome if none match

func get_temp(x: int, z: int) -> int:
	var temperature =  0.5 + 0.5 * temperature_noise.get_noise_2d(x, z)
	return int(temp_curve.sample_baked(temperature))


func plant(voxel:int) -> bool:
	for biome in biomes:
		if biomes[biome].plants.has(voxel):
			return true

	return false
