extends Resource
class_name Creature

@export_category("Must Be Filled Out")
@export var body_scene: PackedScene
@export var max_health: int
@export var attacks: bool
@export var run_away_after_attack: bool
@export var damage: int
@export var speed: float = 5.0
@export var coll_shape: Shape3D
@export var coll_height: float
@export var coll_radius: float
@export var walk_ani_name: String

@export_category("Optional")
@export var creature_name: String
@export var texture: Texture
@export var drop_items: Array[ItemBase] = []
