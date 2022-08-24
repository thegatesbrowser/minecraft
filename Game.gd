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
	chunks.load_chunks(_player_pos_to_chunk_pos(player.translation), chunk_scene, false)
	Globals.load_radius = load_radius
	chunks.load_chunks(player_chunk_pos, chunk_scene)


func _process(_delta):
	var player_pos = _player_pos_to_chunk_pos(player.translation)
	if player_pos != player_chunk_pos:
		player_chunk_pos = player_pos
		chunks.update_chunks(player_chunk_pos, chunk_scene)
	
	# Only works in debug mode :-( I guess I'll have to actually optimize this thing...
	if OS.get_static_memory_usage() > 1073741824 * Globals.max_game_memory_gb:
		chunks.free_stale_chunk()


func _player_pos_to_chunk_pos(position: Vector3) -> Vector2:
	var pos_round = (position / Globals.chunk_size).round()
	return Vector2(pos_round.x, pos_round.z)


func _on_Player_break_block(position: Vector3):
	chunks.break_block(position, _player_pos_to_chunk_pos(position))


func _on_Player_place_block(position: Vector3):
	chunks.place_block(position, _player_pos_to_chunk_pos(position), WorldGen.STONE)
