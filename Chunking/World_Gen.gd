extends Node
tool

enum {
	AIR,
	DIRT,
	GRASS,
	STONE,
	LOG1,
	LEAVES1,
	WOOD1,
	LOG2,
	LEAVES2,
	WOOD2,
	GLASS,
	STUMP # Not real block type, signals that we need a tree here.
}

const is_transparent = {
	AIR:false,
	DIRT:true,
	GRASS:true,
	STONE:true,
	LOG1:true,
	LEAVES1:false,
	WOOD1:true,
	LOG2:true,
	LEAVES2:false,
	WOOD2:true,
	GLASS:false,
	STUMP:false,
}

class Tree_Object:
	var trunk_height := 6
	var brim_width := 2
	var brim_height := 2
	var top_width := 1
	var top_height := 2
	var trunk_type := LOG1
	var leaf_type := LEAVES1


export var biome_noise: OpenSimplexNoise
export(Curve) var biome_transition: Curve
export var min_height_percent := 0.25
export var plains_noise: OpenSimplexNoise
export var max_plans_height_percent := 0.5
export var hills_noise: OpenSimplexNoise
export var max_hills_height_percent := 0.5
export var tree_noise: OpenSimplexNoise
export(float, 0.01, 1) var base_tree_rate_hills := 0.5
export(float, 0.01, 1) var base_tree_rate_plains := 0.2
export var cave_noise_hills: OpenSimplexNoise
export(Curve) var cave_chance_hills: Curve
export var cave_noise_plains: OpenSimplexNoise
export(Curve) var cave_chance_plains: Curve
export var tree_heights := Vector2(2, 6)

var min_height
var max_plains_height
var max_hills_height


func _ready():
	min_height = Globals.chunk_size.y * min_height_percent
	max_plains_height = (Globals.chunk_size.y * max_plans_height_percent) - min_height
	max_hills_height = (Globals.chunk_size.y * max_hills_height_percent) - min_height


func set_seed(world_seed: int):
	var rand = RandomNumberGenerator.new()
	Globals.world_seed = world_seed
	rand.seed = world_seed
	hills_noise.seed = world_seed + rand.randi()
	tree_noise.seed = world_seed + rand.randi()
	plains_noise.seed = world_seed + rand.randi()
	biome_noise.seed = world_seed + rand.randi()
	cave_noise_hills.seed = world_seed + rand.randi()
	cave_noise_plains.seed = cave_noise_hills.seed


# Return a random number generator to use for details in this specific chunk.
func start_new_chunk(pos: Vector2):
	var random = RandomNumberGenerator.new()
	random.seed = Globals.world_seed + hash(pos)
	return random


func get_biome_percent(x, z):
	return biome_transition.interpolate_baked((biome_noise.get_noise_2d(x, z) + 1) * 0.5)


func get_height(x, z):
	return _get_height(x, z, get_biome_percent(x, z))


func get_block_type(x, y, z, rand: RandomNumberGenerator):
	var biome_percent = get_biome_percent(x, z)
	return _get_block_type(x, y, z, rand, biome_percent, _get_height(x, z, biome_percent))



func _get_block_type(x, y, z, rand: RandomNumberGenerator, biome_percent: float, height: int):
	var block := 0
	
	if y == 0:
		block = STONE
	elif y > height + 1 or _is_cave(x, y, z, height, biome_percent):
		block = AIR
	elif y < height - 4:
		block = STONE
	elif y < height:
		block = DIRT
	elif y == height:
		block = GRASS
	elif y == height + 1:
		if _is_tree(x, z, biome_percent, rand) and !_is_cave(x, y - 1, z, height, biome_percent):
			block = STUMP
	else:
		pass
	return block


func get_tree_dimensions(x, z, rand: RandomNumberGenerator) -> Tree_Object:
	var biome_percent = biome_transition.interpolate_baked((biome_noise.get_noise_2d(x, z) + 1) * 0.5)
	var tree := Tree_Object.new()
	tree.trunk_height = rand.randi_range(int(tree_heights.x), int(tree_heights.y))
	tree.brim_height = rand.randi_range(1, 3)
	tree.top_height = rand.randi_range(1, 2)
	if biome_percent > 0.7 and rand.randf() < 0.5:
		tree.leaf_type = LEAVES2
		tree.trunk_type = LOG2
	return tree


func _get_height(x: int, z: int, biome_percent: float) -> int:
	var height_hills = lerp(hills_noise.get_noise_2d(x, z) + 1, 0, biome_percent) * max_hills_height
	var height_plains = lerp(0, plains_noise.get_noise_2d(x, z) + 1 ,biome_percent) * max_plains_height
	return int(height_hills + height_plains + min_height)


func _is_cave(x: int, y: int, z: int, ground: int, biome_percent: float):
	if y > ground:
		return
	var depth: float = ground - y
	var percent_of_depth = depth / ground
	var plains_chance = cave_chance_plains.interpolate_baked(percent_of_depth)
	var hills_chance = cave_chance_hills.interpolate_baked(percent_of_depth)
	var total_chance = lerp(hills_chance, plains_chance, biome_percent)
	var noise_val = (lerp(cave_noise_hills.get_noise_3d(x, y, z), cave_noise_plains.get_noise_3d(x, y, z), biome_percent) + 1) * 0.5
	return noise_val < total_chance


func _is_tree(x: int, z: int, biome_percent: float, rand: RandomNumberGenerator) -> bool:
	var base_rate = lerp(base_tree_rate_hills, base_tree_rate_plains, biome_percent)
	var is_tree = (rand.randf() < (tree_noise.get_noise_2d(x, z) * base_rate))
	return is_tree
