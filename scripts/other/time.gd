extends Node

var time:int

@onready var night: DirectionalLight3D = $"../rotation/night"
@onready var day: DirectionalLight3D = $"../rotation/day"
@onready var rotation: Node3D = $"../rotation"
@onready var world_environment: WorldEnvironment = $".."


func _process(delta: float) -> void:
	
	rotation.rotation_degrees.x += .01

	if rotation.rotation_degrees.x >= 360 or rotation.rotation_degrees.x <= -360:
		rotation.rotation_degrees.x = 0

	if rotation.rotation_degrees.x <= 120:
		night.show()
		day.hide()
		world_environment.environment.ambient_light_energy = 1
		#world_environment.environment.amb = Color.BLACK
	elif rotation.rotation_degrees.x >= 200:
		#world_environment.environment.ambient_light_color = Color(0.14, 0.14, 0.14)
		day.show()
		night.hide()
		world_environment.environment.ambient_light_energy = 2.85
	
	
