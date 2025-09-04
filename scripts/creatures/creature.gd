extends Resource
class_name Creature

@export var body_scene: PackedScene

@export_group("Stats")
@export var damage: int
@export var speed: float = 5.0
@export var max_health: int
@export var mesh_name:String
@export var drop_items: Array[ItemBase] = []
@export var utility:Utilities

@export_group("Sounds")
@export var hurt_sound:AudioStream
@export var death_sound:AudioStream
@export var idle_sound:AudioStream

@export_group("Type")
@export var flyies:bool = false
@export var flying_height:float = 10.0
@export var attacks: bool

@export_group("Animation")
@export var walk_ani_name:String
@export var idle_ani_name:String

@export_group("Collision")
@export var collision_shape: Shape3D
@export var collision_offset:Vector3
