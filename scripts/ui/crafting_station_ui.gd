extends ScrollContainer

@export var send_to_inventory:Inventory
@export var craftable_button_scene:PackedScene
@export var crafting_library:CraftableLibrary

@onready var list: GridContainer = $MarginContainer/VBoxContainer/List


func _ready() -> void:
	crafting_library.init_craftable()
	for craftable in crafting_library.craftable_array:
		var button = craftable_button_scene.instantiate()
		button.craftable = craftable
		button.inventory = send_to_inventory
		list.add_child(button)
	pass
