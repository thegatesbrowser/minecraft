extends Resource
class_name Craftable

@export var Name:String
@export var texture:Texture
@export var output_item:ItemBase
@export var output_amount:int = 1

@export var items_needed := {
	1: {"name": "wood",
	"amount": 1,}
}
