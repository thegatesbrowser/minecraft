extends Control

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_scene: PackedScene
@export var loading_bar: ProgressBar


func _ready() -> void:
	if Connection.is_server():
		start_scene()
		return

	Backend.playerdata_updated.connect(start_scene)

func _process(delta):
	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	
	

func start_scene() -> void:
	get_tree().call_deferred("change_scene_to_packed", multiplayer_scene)
