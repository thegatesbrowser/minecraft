extends CharacterBody3D

@export var creature_resource:Creature

var health

func _ready() -> void:
	health = creature_resource.max_health
	
	
