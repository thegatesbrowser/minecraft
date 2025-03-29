extends ItemBase
class_name ItemArmour

@export_category("type (only one)")
@export var chest:bool
@export var pants:bool
@export var helment:bool

@export_category("stats")
@export var protect_amount:int = 1
@export var max_health : float = 5
@export var degrade_rate: float = .1

var health:float

func _init() -> void:
	call_deferred('ready')

func ready():
	health = max_health
	
func used():
	health -= degrade_rate
