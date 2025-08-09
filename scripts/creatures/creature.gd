extends Resource
class_name Creature

@export var body_scene: PackedScene
@export var max_health: int
@export var attacks: bool
@export var run_away_after_attack: bool

@export var damage: int
@export var speed: float = 5.0
@export var coll_shape: Shape3D
@export var mesh_name:String
@export var hurt_sound:AudioStream
@export var death_sound:AudioStream
@export var idle_sound:AudioStream

@export var flyies:bool = false
@export var flying_height:float = 10.0

@export var creature_name: String
@export var texture: Texture
@export var drop_items: Array[ItemBase] = []

@export var utility:Utilities
