extends Control

@onready var healthbar: TextureProgressBar = $healthbar
@onready var hungerbar: TextureProgressBar = $hungerbar


@export var player_spawner:PlayerSpawner
var your_player:Player

func find_player():
	for id in player_spawner.players:
		if id == multiplayer.get_unique_id():
			your_player = player_spawner.players[id].player

func _process(delta: float) -> void:
	if your_player == null: return
	
	healthbar.max_value = your_player.max_health
	hungerbar.max_value = your_player.base_hunger
	
	healthbar.value = your_player.health
	hungerbar.value = your_player.hunger
