@tool
extends Node3D

@onready var arrow_scene = preload("res://scenes/other/playerArrow.tscn")

@onready var player: Node3D = $Player

@onready var target: Node3D = $MeshInstance3D

var shown_players = []

func update():
	var player_spawner = get_node("/root/Main").find_child("PlayerSpawner")
	for id in player_spawner.players:
		
		if shown_players.has(id) == false:
			if multiplayer.get_unique_id() != id:
				var arrow = arrow_scene.instantiate()
				arrow.name = str(id)
				add_child(arrow,true)
				shown_players.append(id)
			
		var node = player_spawner.players[id].node as Player
		
		var your_player = player_spawner.players[multiplayer.get_unique_id()].node as Player
		
		if multiplayer.get_unique_id() != node.name.to_int():
			var arrow = get_node(str(id))
			if arrow == null: return
			
			var direction_to_target = (node.global_transform.origin - arrow.global_transform.origin).normalized()
			
			var angle_y = atan2(direction_to_target.x,direction_to_target.z)
			
			arrow.rotation_degrees.y = rad_to_deg(angle_y) + 90
			#arrow.get_child(0).rotation_degrees.y = rad_to_deg(-your_player._rotation.y)
		
func _process(delta: float) -> void:
	rotation = get_parent().global_rotation
	update()
	#var direction_to_target = (target.global_transform.origin - player.global_transform.origin).normalized()
		#
	#var angle_y = atan2(direction_to_target.x,direction_to_target.z)
	#
	#player.rotation_degrees.y = rad_to_deg(angle_y) + 90
