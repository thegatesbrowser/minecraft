extends Resource
class_name ItemBase

@export var unique_name: StringName
@export var texture: Texture2D
@export var background_texture: Texture2D
@export_range(1, 65535) var max_stack: int = 64

@export var holdable_mesh:PackedScene

@export var utility: Utilities
@export var rotatable:bool = false
@export var drop_items:Array[StringName]

@export_category('forging')
@export var forgable:bool = false
@export var forge_time:float = 2.0
@export var output_item:ItemBase

@export var value:int = 10
