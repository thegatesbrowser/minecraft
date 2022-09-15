extends Spatial

onready var chunk_scene_0 := preload("res://Chunking/Chunk_Simple.tscn")
onready var chunk_scene_1 := preload("res://Chunking/Chunk_Mesh.tscn")
onready var chunk_scene_2 := preload("res://Chunking/Chunk_Tileset.tscn")
onready var chunk_scene_3 := preload("res://Chunking/Chunk_Ultimate.tscn")

onready var player := $Player
onready var chunks := $Chunks
onready var env: Environment = $WorldEnvironment.get_environment()
onready var debug := $Overlay/DebugOverlay

var player_pos := Vector2.ZERO


func _ready():
	if Globals.test_mode == Globals.TestMode.STATIC_LOAD or Globals.test_mode == Globals.TestMode.RUN_LOAD:
		Globals.capture_mouse_on_start = false
		Globals.paused = false
	
	var chunk_types = [chunk_scene_0, chunk_scene_1, chunk_scene_2, chunk_scene_3]
	chunks.chunk_scene = chunk_types[Globals.chunk_type]
	
	# Generate chunk 0 so we don't fall through the world.
	chunks.load_chunk(_player_pos_to_chunk_pos(player.translation), 0, 0, false)
	
	# Change the mouse mode only when we're done loading.
	if Globals.capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set the draw distance to match our settings.
	_set_draw_distance(Globals.load_radius)


func _process(_delta):
	if Input.is_action_just_pressed("Start"):
		Globals.paused = !Globals.paused
		if Globals.paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
	
	player_pos = _player_pos_to_chunk_pos(player.translation)
	chunks.update_chunks(player_pos)
	debug.update_chunks(player_pos)
	debug.update_player_pos(player.translation)


func _set_draw_distance(radius: int):
	var distance = (radius) * Globals.chunk_size.x
	if Globals.no_fog:
		$Player/Head/Camera.far = distance * 10
		env.fog_enabled = false
		env.dof_blur_far_enabled = false
	else:
		$Player/Head/Camera.far = distance * 1.25
		env.fog_enabled = true
		env.fog_depth_begin = distance - min(50, distance * 0.1)
		env.fog_depth_end = distance


func _player_pos_to_chunk_pos(position: Vector3) -> Vector2:
	var pos_round = (position / Globals.chunk_size).floor()
	return Vector2(pos_round.x, pos_round.z)


func _on_Player_break_block(position: Vector3):
	chunks.break_block(position, _player_pos_to_chunk_pos(position))


func _on_Player_place_block(position: Vector3):
	chunks.place_block(position, _player_pos_to_chunk_pos(position), Globals.current_block)
