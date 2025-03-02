extends Resource
class_name Craftable
# RESOURCES GRASS, DIRT, STONE, GLASS, LOG1, WOOD1, LOG2, WOOD2, LEAF1, LEAF2

@export var Name:String
@export var texture:Texture
@export var output_item:ItemBase
@export var output_amount:int = 1

@export var items_needed := {
	1: {"name": "wood",
	"amount": 1,}
}
