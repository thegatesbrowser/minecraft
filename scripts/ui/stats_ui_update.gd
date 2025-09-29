extends Control

@onready var healthbar: TextureProgressBar = $HBoxContainer/healthbar
@onready var hungerbar: TextureProgressBar =$HBoxContainer/hungerbar
@onready var player_direct: Control = $player_direct


var your_player: Player


func _process(_delta: float) -> void:
	if your_player == null: return
	
	player_direct.your_player = your_player
	
	healthbar.max_value = your_player.max_health
	hungerbar.max_value = your_player.base_hunger
	
	healthbar.value = your_player.health
	hungerbar.value = your_player.hunger
