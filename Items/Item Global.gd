extends Resource
class_name Item_Global

enum {GRASS, DIRT, STONE, GLASS, LOG1, WOOD1, LOG2, WOOD2, LEAF1, LEAF2}
## Type is the locaction of the type in this enum starting at 0 as grass


@export var item_name:String
@export var item_texture:Texture
@export var type:int
