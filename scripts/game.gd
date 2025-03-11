extends Node3D
class_name Game

signal change_block(global_pos: Vector3, chunk_id: Vector2, type: int)

@export var creature_s: PackedScene

var player: Player
var is_fullscreen = false

func _process(_delta):
	if Connection.is_server() or player == null: return
	
	multiplayer.get_unique_id()
	
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

func spawn_creature(pos:Vector3):
	var creature = creature_s.instantiate()
	creature.position = pos + Vector3(0,1,0)
	add_child(creature)
