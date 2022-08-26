extends Spatial

onready var chunk_scene_0 := preload("res://Chunking/Chunk_Static.tscn")
onready var chunk_scene_1 := preload("res://Chunking/Chunk_Static.tscn")
onready var chunk_scene_2 := preload("res://Chunking/Chunk_Static.tscn")
onready var chunk_scene_3 := preload("res://Chunking/Chunk_Static.tscn")

onready var player := $Player
onready var chunks := $Chunks

var player_chunk_pos := Vector2.ZERO
var chunk_scene


func _ready():
	chunk_scene = chunk_scene_0
	player_chunk_pos = _player_pos_to_chunk_pos(player.translation)
	
	# Load only the chunks immediately surrounding the player, then add more while the player is in the game.
	var load_radius = Globals.load_radius
	Globals.load_radius = 1
	chunks.load_chunks(player_chunk_pos, chunk_scene, false)
	
	# Load the rest of the chunks all at once.
	if Globals.single_threaded_mode:
		Globals.load_radius = load_radius
		chunks.load_chunks(player_chunk_pos, chunk_scene)
	else:
		# Load the rest of the chunks asynchronously in a ring from the player outwards.
		while (Globals.load_radius < load_radius):
			Globals.load_radius += 1
			chunks.load_chunks(player_chunk_pos, chunk_scene)

	# Change the mouse mode only when we're done loading.
	if Globals.capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta):
	if Input.is_action_just_pressed("Start"):
		Globals.paused = !Globals.paused
		if Globals.paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
	
	var player_pos = _player_pos_to_chunk_pos(player.translation)
	if player_pos != player_chunk_pos:
		player_chunk_pos = player_pos
		chunks.update_chunks(player_chunk_pos, chunk_scene)
	
	# Only works in debug mode :-( I guess I'll have to actually optimize this thing...
	if OS.get_static_memory_usage() > 1073741824 * Globals.max_game_memory_gb:
		chunks.free_stale_chunk()


func _player_pos_to_chunk_pos(position: Vector3) -> Vector2:
	var pos_round = (position / Globals.chunk_size).floor()
	return Vector2(pos_round.x, pos_round.z)


func _on_Player_break_block(position: Vector3):
	chunks.break_block(position, _player_pos_to_chunk_pos(position))


func _on_Player_place_block(position: Vector3):
	chunks.place_block(position, _player_pos_to_chunk_pos(position), WorldGen.STONE)
