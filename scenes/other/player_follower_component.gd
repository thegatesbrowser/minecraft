extends Node

@export var follow_x:bool
@export var follow_y:bool
@export var follow_z:bool

var player:Player
var players:Array

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = .5 
	add_child(timer)
	timer.start()
	timer.timeout.connect(update_pos)
	try_get_player()
			
			
func update_pos():
	if player == null: 
		try_get_player() 
		return
	
	if follow_x:
		get_parent().global_position.x = lerp(get_parent().global_position.x,player.global_position.x,1.0)
	if follow_y:
		get_parent().global_position.y = lerp(get_parent().global_position.y,player.global_position.y,1.0)
	if follow_z:
		get_parent().global_position.z = lerp(get_parent().global_position.z,player.global_position.z,1.0)

func try_get_player():
	players = get_tree().get_nodes_in_group("Player")
	
	for i in players:
		if i.is_multiplayer_authority():
			player = i
