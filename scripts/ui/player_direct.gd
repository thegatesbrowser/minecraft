extends Control

var your_player:Player

const player_marker = preload("res://scenes/ui/player_marker.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_markers():
	if your_player == null: return
	
	
	
	for player in get_tree().get_nodes_in_group("Player"):
		print(your_player.global_position.direction_to(player.global_position))
		var marker = player_marker.instantiate()
		marker.position = Vector2(847,893)
		add_child(marker)
