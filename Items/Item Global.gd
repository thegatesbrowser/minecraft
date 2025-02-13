extends Resource
class_name Item_Global

enum {GRASS, DIRT, STONE, GLASS, LOG1, WOOD1, LOG2, WOOD2, LEAF1, LEAF2}
## Type is the locaction of the type in this enum starting at 0 as grass

@export var item_name:String
@export var item_texture:Texture
@export var type:int
@export var max_stack:int = 64
@export var placeable:bool = true
@export var holdable:bool = false
@export var holdable_mesh:Mesh
@export var break_time:float = .4

#only for stuff like chests and crafting tables not normal blocks like grass
@export var place_object:PackedScene
@export var utility:Utilities

@export_category("Tools")
@export var breaking_efficiency:float = 0.0

@export_category("Weapons")
@export var weapon:bool = false
@export var damage:int
@export var weapon_model:Mesh
@export var needs_ammo:bool

@export var ammo_name:String = "Ammo"
@export var shoots:bool
@export var fire_rate:float
