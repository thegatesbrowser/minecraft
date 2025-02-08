extends Resource
class_name Creature


@export var creature_name:String
@export var texture:Texture
@export var body_scene:PackedScene
@export var max_health:int
@export var attacks:bool
@export var damage:int
@export var speed:float = 5.0
@export var creature_coll_baseshape:Shape3D
@export var coll_size:Vector3
