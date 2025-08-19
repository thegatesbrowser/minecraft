extends Node3D

@export var day:DirectionalLight3D 
@export var night:DirectionalLight3D 
@export var world_environment:WorldEnvironment
@export var speed:float = .0001

func _process(delta: float) -> void:
	pass
	rotation.x += speed
	

	if rotation_degrees.x >= 360 or rotation_degrees.x <= -360:
		rotation_degrees.x = 0
	
	if rotation_degrees.x <= 120:
		night.show()
		day.hide()
		world_environment.environment.volumetric_fog_albedo = Color.DARK_SLATE_BLUE
	elif rotation_degrees.x >= 200:
		day.show()
		night.hide()
		world_environment.environment.volumetric_fog_albedo = Color.LIGHT_BLUE
	else:
		night.show()
		day.hide()
		world_environment.environment.volumetric_fog_albedo = Color.DARK_SLATE_BLUE
