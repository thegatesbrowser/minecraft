extends Resource
class_name ItemBase

@export var unique_name: StringName
@export var texture: Texture
@export_range(1, 65535) var max_stack: int = 64

@export var holdable_mesh: Mesh

@export var utility: Utilities

@export_category("Tools")
@export var breaking_efficiency: float = 0.0
