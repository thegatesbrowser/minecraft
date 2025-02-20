extends RigidBody3D

var Item:ItemBase

func _ready() -> void:
	pass


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Globals.spawn_item_inventory.emit(Item)
		queue_free()
