extends TextureButton
class_name CraftableButton

@export var inventory:Inventory

@export var blueprint: Blueprint
@onready var image: TextureRect = $CenterContainer/Image


func _ready() -> void:
	inventory = get_tree().get_first_node_in_group("Main Inventory")

	if blueprint != null:
		image.texture = blueprint.texture

func _on_pressed():
	if !inventory or !blueprint: return

	inventory.spawn_item(blueprint)
