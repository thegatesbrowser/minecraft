extends Node3D

@onready var block: MeshInstance3D = $Block
@onready var _half_time: Timer = $"Half Time"
@onready var _end_time: Timer = $"End Time"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_break(break_time:float):
	show()
	var block_mat:StandardMaterial3D = block.material_override
	var half_time = break_time/2
	
	block_mat.albedo_texture = load("res://assets/textures/blocks/break step 1.png")
	
	_half_time.wait_time = half_time
	_half_time.start()
	
	_end_time.wait_time = break_time - 0.1
	_end_time.start()

	
	
func stop():
	hide()
	_half_time.stop()
	_end_time.stop()


func _on_half_time_timeout() -> void:
	if visible:
		var block_mat:StandardMaterial3D = block.material_override
		block_mat.albedo_texture = load("res://assets/textures/blocks/break step 2.png")


func _on_end_time_timeout() -> void:
	if visible:
		var block_mat:StandardMaterial3D = block.material_override
		block_mat.albedo_texture = load("res://assets/textures/blocks/break step 3.png")
