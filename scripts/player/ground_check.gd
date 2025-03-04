extends Node3D

@export var exclude:Node
@onready var ground: RayCast3D = $ground
@onready var loading: Control = $loading


func _ready() -> void:
	if is_multiplayer_authority():
		loading.show()
		ground.add_exception(exclude)
		Globals.paused = true
	else:
		loading.hide()
	
func _process(delta: float) -> void:
	if is_multiplayer_authority():
		if ground.is_colliding():
			Globals.paused = false
			queue_free()
