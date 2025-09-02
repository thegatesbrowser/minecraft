extends PanelContainer

@export var craftable_button_scene:PackedScene
@export var crafting_library:CraftableLibrary


func _ready() -> void:
	crafting_library.init_craftable()
	for craftable in crafting_library.craftable_array:
		var button = craftable_button_scene.instantiate()
		button.blueprint = craftable
		$MarginContainer/VBoxContainer/ScrollContainer/GridContainer.add_child(button)
	pass
