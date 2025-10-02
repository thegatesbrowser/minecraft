extends Node

@onready var world_enviroment:WorldEnvironment = $".."
@onready var sun_rot_node:Node3D = $"../sun_rotation"


@export var night_time_start:int ## rad
@export var night_time_end:int ## rad
@export var mourning_time_start:float ## rad
@export var mourning_time_end:float ## rad

@export var update_time:float

@export var night_:bool = false
@export var day_:bool = false
	
var elapsed = 0.0

func _ready() -> void:
	$"../sun_rotation/MultiplayerSynchronizer".set_multiplayer_authority(1)

func _process(delta):
	var check =  round(sun_rot_node.rotation_degrees.x)
	
	if multiplayer.is_server(): 
		sun_rot_node.rotation.x += 0.0001
		if check > 360:
			sun_rot_node.rotation_degrees.x = 0
		return
	
	
	#print(check)
	
	if check >= 0:
		if check <= 179:
			#print("night")
			
			change_world_settings("night")
	if check >= 180:
		if check <= 360:
			#print("mourning")
			change_world_settings("day")
	
	
func save() -> Dictionary:
	var save = {
		"sun_rotation_rad":sun_rot_node.rotation_degrees.x
	}
	return save
	
	
func set_sun(deg:int):
	sun_rot_node.rotation_degrees.x = deg
	
	
func change_world_settings(type:String):
	if type == "night":
		$"../sun_rotation/night".show()
		
		world_enviroment.environment.volumetric_fog_albedo = Color.DARK_SLATE_BLUE
		if $"../sun_rotation/day".visible:
			var create_tween = get_tree().create_tween()
			create_tween.tween_property(world_enviroment.environment,"ambient_light_color",Color(0.223,0.223,0.223),.6)
		$"../sun_rotation/day".hide()
	elif type == "day":
		$"../sun_rotation/day".show()
		world_enviroment.environment.volumetric_fog_albedo = Color(0.601,0.921,0.97)
		if $"../sun_rotation/night".visible:
			var create_tween = get_tree().create_tween()
			create_tween.tween_property(world_enviroment.environment,"ambient_light_color",Color(0.34,0.34,0.34),.6)
		$"../sun_rotation/night".hide()
