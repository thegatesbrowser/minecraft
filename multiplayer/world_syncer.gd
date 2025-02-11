extends Node

@export var game: Game
@export var connection: Connection
@export var chunks_data: Dictionary = {}


func _ready():
	if Connection.is_server(): return
	
	game.change_block.connect(on_change_block)
	connection.connected.connect(func(): get_chunks.rpc_id(1))


func on_change_block(global_pos: Vector3, chunk_id: Vector2, type: int):
	global_pos = global_pos.floor()

	sync_chunk.rpc(chunk_id, global_pos, type)


@rpc("any_peer", "reliable")
func sync_chunk(chunk_id: Vector2, global_pos: Vector3, type: int):
	if Connection.is_server():
		save_chunk(chunk_id, global_pos, type)
		return

	game.chunks.place_block(global_pos, chunk_id, type)


func save_chunk(chunk_id: Vector2, global_pos: Vector3, type: int):
	if not chunks_data.has(chunk_id):
		chunks_data[chunk_id] = {}
	
	chunks_data[chunk_id][global_pos] = type


@rpc("any_peer", "reliable")
func get_chunks():
	rpc_id(multiplayer.get_remote_sender_id(), "receive_chunks", chunks_data)


@rpc("authority", "reliable")
func receive_chunks(_chunks_data: Dictionary):
	for chunk_id in _chunks_data:
		for global_pos in _chunks_data[chunk_id]:
			game.chunks.place_block(global_pos, chunk_id, _chunks_data[chunk_id][global_pos], false)
	
	for chunk_id in _chunks_data:
		game.chunks._regen_block(chunk_id)
