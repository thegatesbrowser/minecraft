extends Node3D
class_name Game

signal change_block(global_pos: Vector3, chunk_id: Vector2, type: int)

@export var creature_s: PackedScene
@export var breaktime: Timer

var player: Player
var player_pos := Vector2.ZERO
var is_fullscreen = false


func _process(_delta):
	if Connection.is_server() or player == null: return
	
	if Input.is_action_just_pressed("Start"):
		Globals.paused = !Globals.paused
		if Globals.paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
	
	# Maybe should be in a different script, only available in the actual simulation
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		is_fullscreen = !is_fullscreen
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
	
	player_pos = _player_pos_to_chunk_pos(player.position)


func _player_pos_to_chunk_pos(pos: Vector3) -> Vector2:
	var pos_round = (pos / Globals.chunk_size).floor()
	return Vector2(pos_round.x, pos_round.z)


func _on_Player_break_block(_pos: Vector3):
	# var chunk_id = _player_pos_to_chunk_pos(pos)
	
	# if chunk_resource != null:
	# 	if breaktime.is_stopped():
	# 		if chunk_resource.break_time - Globals.breaking_efficiency == 0:
	# 			breaktime.wait_time = 0
	# 		else:
	# 			breaktime.wait_time = chunk_resource.break_time - Globals.breaking_efficiency
	# 		breaktime.start()
			
	# 		await breaktime.timeout
			
	# 		if Input.is_action_pressed("Mine"):
	# 			change_block.emit(pos, chunk_id, 0)
	# 		else:
	# 			breaktime.stop()
	pass


func _on_Player_place_block(_pos: Vector3):
	# Globals.remove_item_from_hotbar.emit()
	# if Globals.custom_block != null:
	# 	var object = Globals.custom_block.place_object.instantiate()
	# 	object.resource = Globals.custom_block.utility
		
	# 	var X = snappedf(pos.x,0.5)
	# 	var Z = snappedf(pos.z,0.5)
		
	# 	if step_decimals(X) == 0:
	# 		X += 0.5
	# 	if step_decimals(Z) == 0:
	# 		Z += 0.5
			
	# 	var new_pos = Vector3(X,pos.y,Z)
	# 	print("new_pos ", new_pos)
	# 	object.position = new_pos
	# 	add_child(object)
		
	# else:
	# 	var chunk_id = _player_pos_to_chunk_pos(pos)
	# 	change_block.emit(pos, chunk_id, Globals.current_block)
	pass


func spawn_creature(pos:Vector3):
	var creature = creature_s.instantiate()
	creature.position = pos + Vector3(0,1,0)
	add_child(creature)
