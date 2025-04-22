extends Control

const SPLASH_ANIMATION_NAME = "Splash"

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_btn: Button
@export var multiplayer_scene: PackedScene

@export_category("Splash Screen")
@export var splash_sayings: PackedStringArray
@export var splash: Label
@export var animation_player: AnimationPlayer

func _enter_tree() -> void:
	var backend = backend_scene.instantiate()
	get_tree().root.call_deferred("add_child",backend)
	pass
	
func _ready() -> void:
	
	if Connection.is_server():
		start_scene(multiplayer_scene)
		return
	
	#single_player_btn.pressed.connect(func(): start_scene(singleplayer_scene))
	multiplayer_btn.pressed.connect(func(): start_scene(multiplayer_scene))
	
	setup_splash_screen()


func setup_splash_screen() -> void:
	var saying = splash_sayings[randi() % splash_sayings.size()]
	splash.text = saying
	
	animation_player.play(SPLASH_ANIMATION_NAME)


func start_scene(scene: PackedScene) -> void:
	get_tree().call_deferred("change_scene_to_packed", scene)
