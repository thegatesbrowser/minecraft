extends ItemBase
class_name ItemTool

@export var use_animation: Animation
@export var suitable_objects: Array[ItemBlock]
@export var breaking_efficiency: float
@export var damage: int = 2

@export var max_health : float = 5
@export var degrade_rate: float = .1
var health:float

func _init() -> void:
	call_deferred('ready')

func ready():
	health = max_health
	
func used():
	health -= degrade_rate
