extends Node

@export var player: Player
@export var camera: Camera3D
@export var camera_height: float
@export var creature_point: MeshInstance3D

var creature_points: Dictionary = {}


func _ready() -> void:
	if not is_multiplayer_authority() and not Connection.is_server():
		queue_free()


func _process(_delta: float) -> void:
	camera.global_position = player.global_position
	camera.global_position.y = camera_height
	
	var new_creatures = get_tree().get_nodes_in_group("NPCS")
	for creature in new_creatures:
		if not creature_points.has(creature):
			var point = creature_point.duplicate()
			point.visible = true
			creature_points[creature] = point
			camera.add_child(point)
	
	for creature in creature_points.keys():
		if not is_instance_valid(creature):
			var point = creature_points[creature]
			creature_points.erase(creature)
			point.queue_free()
	
	for creature in creature_points.keys():
		if not creature.is_inside_tree(): continue
		var point = creature_points[creature]
		point.global_position = creature.global_position
		point.global_position.y += camera_height - 100
