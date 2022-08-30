extends Node
tool

const TEXTURE_ATLAS_SIZE := Vector2(8,2)

enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

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
	STUMP # Not real block type, signals that we need a tree here.
}

const types = {
	AIR:{
		SOLID:false
	},
	DIRT:{
		TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(2, 0),
		RIGHT:Vector2(2,0), FRONT:Vector2(2, 0), BACK:Vector2(2, 0),
		SOLID:true
	},
	GRASS:{
		TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT:Vector2(1, 0),
		RIGHT:Vector2(1, 0), FRONT:Vector2(1, 0), BACK:Vector2(1, 0),
		SOLID:true
	},
	STONE:{
		TOP:Vector2(3, 0), BOTTOM:Vector2(3, 0), LEFT:Vector2(3, 0),
		RIGHT:Vector2(3, 0), FRONT:Vector2(3, 0), BACK:Vector2(3, 0),
		SOLID:true
	},
	LOG1:{
		TOP:Vector2(5, 0), BOTTOM:Vector2(5, 0), LEFT:Vector2(4, 0),
		RIGHT:Vector2(4, 0), FRONT:Vector2(4, 0), BACK:Vector2(4, 0),
		SOLID:true
	},
	LEAVES1:{
		TOP:Vector2(6, 0), BOTTOM:Vector2(6, 0), LEFT:Vector2(6, 0),
		RIGHT:Vector2(6, 0), FRONT:Vector2(6, 0), BACK:Vector2(6, 0),
		SOLID:true
	},
	WOOD1:{
		TOP:Vector2(7, 0), BOTTOM:Vector2(7, 0), LEFT:Vector2(7, 0),
		RIGHT:Vector2(7,0), FRONT:Vector2(7, 0), BACK:Vector2(7, 0),
		SOLID:true
	},
	LOG2:{
		TOP:Vector2(5, 1), BOTTOM:Vector2(5, 1), LEFT:Vector2(4, 1),
		RIGHT:Vector2(4, 1), FRONT:Vector2(4, 1), BACK:Vector2(4, 1),
		SOLID:true
	},
	LEAVES2:{
		TOP:Vector2(6, 1), BOTTOM:Vector2(6, 1), LEFT:Vector2(6, 1),
		RIGHT:Vector2(6, 1), FRONT:Vector2(6, 1), BACK:Vector2(6, 1),
		SOLID:true
	},
	WOOD2:{
		TOP:Vector2(7, 1), BOTTOM:Vector2(7, 1), LEFT:Vector2(7, 1),
		RIGHT:Vector2(7,1), FRONT:Vector2(7, 1), BACK:Vector2(7, 1),
		SOLID:true
	}
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


func get_block_type(x: int, y: int, z: int, rand: RandomNumberGenerator):
	if y == 0:
		return STONE
	var biome_percent = biome_transition.interpolate_baked((biome_noise.get_noise_2d(x, z) + 1) * 0.5)
	var height = _get_height(x, z, biome_percent)
	
	var block = AIR
	if _is_cave(x, y, z, height, biome_percent):
		return block
	
	if y < height - 4:
		block = STONE
	elif y < height:
		block = DIRT
	elif y == height:
		block = GRASS
	elif y == height + 1:
		if !_is_cave(x, y - 1, z, height, biome_percent) and _is_tree(x, z, biome_percent, rand):
			block = STUMP
	return block


func get_tree_dimensions(x: int, z:int, rand: RandomNumberGenerator) -> Tree_Object:
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
