@tool
extends WorldEnvironment

@export var ramp: GradientTexture1D
@onready var sun_moon: Node3D = $SunMoon

@onready var sun: MeshInstance3D = $SunMoon/sun
@export var sun_pos: float = 0
@export_range(0, 2400, 0.01) var TimeOfDay: float = 1200.0
@export var sky_rotation: float = 116.4
@export var color: Color = Color.WHEAT


func _process(_delta: float) -> void:
	update_rotation()
	update_sky()


func update_rotation() -> void:
	var hourmapped: float = remap(TimeOfDay, 0.0, 2400.0, 0.0, 1.0)
	sun_moon.rotation_degrees.y = sky_rotation
	sun_moon.rotation_degrees.x = hourmapped * 360.0


func update_sky() -> void:
	sun_pos = sun.global_position.y / 2.0 + 0.5
	var sky_mat: ShaderMaterial = environment.sky.get_material()
	color = ramp.gradient.sample(sun_pos)
	sky_mat.set_shader_parameter("skyColor", color)

	
