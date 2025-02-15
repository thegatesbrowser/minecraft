extends PanelContainer

@export var step_text_s: PackedScene
@export var name_label: Label


func _ready() -> void:
	hide()
	Globals.craftable_hovered.connect(craftable_hovered)
	Globals.craftable_unhovered.connect(craftable_unhovered)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


func craftable_hovered(craftable:Craftable,node):
	if node.can_craft() == true:
		modulate = Color.GREEN
	else:
		modulate = Color.RED
	name_label.text = craftable.Name
	for i in craftable.items_needed:
		var step = step_text_s.instantiate()
		step.text = str(craftable.items_needed[i].name," X ",craftable.items_needed[i].amount)
		$MarginContainer/VBoxContainer/VBoxContainer.add_child(step)
	show()


func craftable_unhovered():
	for i in $MarginContainer/VBoxContainer/VBoxContainer.get_children():
		i.queue_free()
	hide()
