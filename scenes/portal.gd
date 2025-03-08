extends Control

@export var portal_url_ui:PackedScene

func _ready() -> void:
	Globals.create_portal.connect(create_portal)
	
	
func create_portal(id:Vector3):
	var portal = portal_url_ui.instantiate()
	portal.id = id
	add_child(portal)
