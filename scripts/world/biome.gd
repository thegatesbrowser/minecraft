extends Resource
class_name Biome

const voxel_library = preload("res://resources/voxel_block_library.tres")

## Biome properties
@export var min_temp:float
@export var max_temp:float

@export var biome_name:String
@export var possible_creatures: Array[Creature]

@export var plants : Array = ["tall_grass"]
@export var trees:bool = true
@export var tree_chance:float = 1.0
@export var plant_chance:float = 1.0

@export var heightmap:Curve
@export var noise:FastNoiseLite


@export var blocks: Dictionary = {
	"surface_block": "grass",
	"rock_block":  "stone",
	"dirt_block": "dirt",
}

func _init() -> void:
	call_deferred("compile")
	
## Compiles the biome, converting all strings to voxel indices
func compile():
	for plant in plants:
		plants.erase(plant)
		plants.append(voxel_library.get_model_index_default(plant))
		print(plants)
		
	for block in blocks:
		blocks[block] = voxel_library.get_model_index_default(blocks[block])
