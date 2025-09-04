extends OmniLight3D

@export var color:Color
@export var energy:=0.1
@export var size:float = 5.0
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	light_color = color
	light_energy = energy
	light_size = size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
