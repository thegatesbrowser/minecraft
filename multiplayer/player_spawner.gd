extends MultiplayerSpawner
class_name PlayerSpawner

signal local_player_spawned(player: Player)
signal player_spawned(id: int, player: Player)
signal player_despawned(id: int)

@export var player_scene: PackedScene
@export var spawn_points: SpawnPoints

const HIDDEN_POSITION = Vector3.UP * 1000
var local_player: Player


func _ready() -> void:
	spawn_function = custom_spawn
	multiplayer.peer_connected.connect(create_player)
	multiplayer.peer_disconnected.connect(destroy_player)
	spawned.connect(on_spawned)
	despawned.connect(on_despawned)
	create_local_player()


func create_local_player() -> void:
	if Connection.is_server(): return
	var spawn_position = spawn_points.get_spawn_position()
	var player: Player = player_scene.instantiate()
	
	player.name = "LocalPlayer"
	player.call_deferred("set_position", spawn_position)
	local_player = player
	
	get_node(spawn_path).add_child(player)
	local_player_spawned.emit(local_player)


func respawn_local_player() -> void:
	var spawn_position = spawn_points.get_spawn_position()
	local_player.respawn(spawn_position)
	Debug.log_msg("Respawn player at " + str(spawn_position))


func create_player(id: int) -> void:
	if not multiplayer.is_server(): return
	spawn(id)
	Debug.log_msg("Player %d spawned" % [id])


func destroy_player(id: int) -> void:
	if not multiplayer.is_server(): return
	get_node(spawn_path).get_node(str(id)).queue_free()
	
	player_despawned.emit(id)


func custom_spawn(id: int) -> Node:
	var player: Player
	if id == multiplayer.get_unique_id():
		local_player.set_multiplayer_authority(id)
		local_player.name = str(id)
		
		var fake = player_scene.instantiate() as Player
		fake.set_multiplayer_authority(0)
		fake.name = "FakeLocalPlayer"
		fake.position = HIDDEN_POSITION
		call_deferred("remove_fake", fake)
		
		player = fake
	else:
		player = player_scene.instantiate() as Player
		player.set_multiplayer_authority(id)
		player.name = str(id)
		player.position = HIDDEN_POSITION
	
	player_spawned.emit(id, player)
	return player


func remove_fake(fake: Player) -> void:
	fake.queue_free()


func on_spawned(node: Node) -> void:
	player_spawned.emit(node.get_multiplayer_authority(), node)


func on_despawned(node: Node) -> void:
	player_despawned.emit(node.get_multiplayer_authority())
