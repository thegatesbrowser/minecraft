extends TextureButton
class_name CraftableButton

@export var blueprint: Blueprint
@onready var image: TextureRect = $CenterContainer/Image


func _ready() -> void:
	if blueprint != null:
		image.texture = blueprint.texture

func _on_pressed():
	var slot_manager = get_node("/root/Main").find_child("SlotManager")
	
	if !blueprint: return
	var slot = slot_manager.blueprint_holder_full()
	
	if slot != null:
		slot.item = blueprint
		slot.update_slot()
