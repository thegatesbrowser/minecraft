extends Node3D

const Voxels = preload("res://resources/voxel_block_library.tres")
@export var player:Player

@export var update_time:float = 1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var update_timer = Timer.new()
	update_timer.wait_time = update_time
	update_timer.autostart = true
	add_child(update_timer)
	update_timer.timeout.connect(grab_surrounds)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		grab_surrounds()



func grab_surrounds():
	Nav.clear_points()

	for x in range(-12,12):
		for y in range(-2,2):
			for z in range(-12,12):
				var block_pos = floor(player.position) + Vector3(x,y,z)
				var voxel_tool = TerrainHelper.get_terrain_tool().get_voxel_tool()
				var voxel_id:int = voxel_tool.get_voxel(block_pos)
				print("voxel",voxel_id)
				if voxel_id == 0 or voxel_id == Voxels.get_model_index_default("reeds"):
					var below_voxel_id:int = voxel_tool.get_voxel(block_pos - Vector3(0,1,0))
					if ground(below_voxel_id):
						Nav.create_point(block_pos.x,block_pos.y,block_pos.z)
						#Nav.create_visual_debug(block_pos + Vector3(0.5,0,0.5))
						
	Nav.connect_points()

func ground(voxel_id:int) -> bool:
	if voxel_id == Voxels.get_model_index_default("grass"):
		return true
	if voxel_id == Voxels.get_model_index_default("sand"):
		return true
	elif voxel_id == Voxels.get_model_index_default("stone"):
		return true
	elif voxel_id == Voxels.get_model_index_default("dirt"):
		return true
	else:
		return false

	