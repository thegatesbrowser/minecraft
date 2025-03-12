extends PanelContainer

@export var step_text_s: PackedScene
@export var name_label: Label
@export var item_library:ItemsLibrary


func _ready() -> void:
	item_library.init_items()
	hide()
	Globals.craftable_hovered.connect(craftable_hovered)
	Globals.craftable_unhovered.connect(craftable_unhovered)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func craftable_hovered(craftable: Craftable, node: Node) -> void:
	if node.can_craft() == true:
		self_modulate = Color.GREEN
	else:
		self_modulate = Color.RED
	name_label.text = craftable.Name
	for i in craftable.items_needed:
		var step = step_text_s.instantiate()
		step.get_child(0).text = str(craftable.items_needed[i].name," X ",craftable.items_needed[i].amount)
		step.get_child(1).texture = craftable.items_needed[i].texture
		$MarginContainer/VBoxContainer/VBoxContainer.add_child(step)
	show()


func craftable_unhovered() -> void:
	for i in $MarginContainer/VBoxContainer/VBoxContainer.get_children():
		i.queue_free()
	hide()
