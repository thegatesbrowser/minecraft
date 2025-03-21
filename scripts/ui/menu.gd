extends Control

const SPLASH_ANIMATION_NAME = "Splash"

@export var single_player_btn: Button
@export var multiplayer_btn: Button
@export var singleplayer_scene: PackedScene
@export var multiplayer_scene: PackedScene

@export_category("Splash Screen")
@export var splash_sayings: PackedStringArray
@export var splash: Label
@export var animation_player: AnimationPlayer

@export var loading_scene_packedscene: PackedScene = preload("res://scenes/ui/loading_scene.tscn")


func _ready() -> void:
	if Connection.is_server():
		start_scene(multiplayer_scene)
		return
	
	single_player_btn.pressed.connect(func(): start_scene(singleplayer_scene))
	multiplayer_btn.pressed.connect(func(): start_scene(multiplayer_scene))
	
	setup_splash_screen()


func setup_splash_screen() -> void:
	var saying = splash_sayings[randi() % splash_sayings.size()]
	splash.text = saying
	
	animation_player.play(SPLASH_ANIMATION_NAME)


func start_scene(scene: PackedScene) -> void:
	get_tree().call_deferred("change_scene_to_packed", scene)


func loaded(_scene: PackedScene) -> void:
	print("loaded")
