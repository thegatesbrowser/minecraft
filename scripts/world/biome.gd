extends Resource
class_name Biome

var compiled:bool = false

const voxel_library = preload("res://resources/voxel_block_library.tres")

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
	"stone_layer_block":  "stone",
	"dirt_layer_block": "dirt",
}

#func create_voxels_ids():
	#if compiled: return
	#
	#for plant in plants:
		#plants.erase(plant)
		#plants.append(voxel_library.get_model_index_default(plant))
		#print(plants)
		#
	#for block in blocks:
		#blocks[block] = voxel_library.get_model_index_default(blocks[block])
		#
	#compiled = true
	
func _init() -> void:
	call_deferred("create_voxels")
	
func create_voxels():
	for plant in plants:
		plants.erase(plant)
		plants.append(voxel_library.get_model_index_default(plant))
		print(plants)
		
	for block in blocks:
		blocks[block] = voxel_library.get_model_index_default(blocks[block])
