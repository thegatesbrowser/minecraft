extends Control

@export var single_player_btn: Button
@export var multiplayer_btn: Button
@export var game_scene: PackedScene

@export_category("Splash Screen")
@export var splash_sayings: PackedStringArray = [""]
@export var splash: Label
@export var animation_player: AnimationPlayer


func _ready():
	if Connection.is_server():
		start_multiplayer()
		return

	multiplayer_btn.pressed.connect(start_multiplayer)
	single_player_btn.pressed.connect(start_singleplayer)
	
	setup_splash_screen()


func start_multiplayer():
	get_tree().change_scene_to_packed(game_scene)


func start_singleplayer():
	# TODO: Support singleplayer
	assert(false, "Singleplayer not supported yet")


func setup_splash_screen():
	var saying = splash_sayings[randi() % splash_sayings.size()]
	splash.text = saying

	animation_player.play("Splash")
