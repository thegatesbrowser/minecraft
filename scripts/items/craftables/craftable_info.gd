extends PanelContainer
class_name blueprint_ui

@export var step_text_s: PackedScene
@export var name_label: Label
@export var item_library:ItemsLibrary
@export var inventory:Inventory
@export var craft_button:Button

var blueprint:Blueprint

func _ready() -> void:
	item_library.init_items()
	hide()
	Globals.closed_inventory.connect(unhovered)
	Globals.blueprint_hovered.connect(hovered)
	Globals.blueprint_unhovered.connect(unhovered)

func _process(delta):
	if	can_craft() == true:
		craft_button.disabled = false
		self_modulate = Color.GREEN
	else:
		craft_button.disabled = true
		self_modulate = Color.RED

func hovered(_blueprint: Blueprint, slot:Slot) -> void:
	#print("show")
	for i in $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
		
	#global_position = slot.global_position - slot.size / 2 
	blueprint = _blueprint
	

	name_label.text = _blueprint.Name
	for i in _blueprint.items_needed:
		var step = step_text_s.instantiate()
		step.get_child(0).text = str(_blueprint.items_needed[i].name," X ",_blueprint.items_needed[i].amount)
		step.get_child(1).texture = _blueprint.items_needed[i].texture
		$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(step)
	show()


func unhovered() -> void:
	for i in $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
	blueprint = null
	hide()


func can_craft() -> bool:
	if not blueprint: return false

	if Globals.find_item(blueprint,true,false,true) == null:
		unhovered()
		return false

	if inventory != null:
		var steps = blueprint.items_needed.duplicate().size()
		for step in blueprint.items_needed:
			#print(craftable.items_needed[i].name)
			#print(inventory.check_amount_of_item(craftable.items_needed[i].name))
			if inventory.check_amount_of_item(blueprint.items_needed[step].name) >= blueprint.items_needed[step].amount:
				steps -= 1
				#print("is the same")
				
		#print(steps)
		
		if steps == 0:
			return true
		else:
			return false
	
	return false


func _on_craft_pressed() -> void:
	if not blueprint: return

	if can_craft():
		if inventory.full == false:
			var soundmanager = get_node("/root/Main").find_child("SoundManager")
			soundmanager.play_UI_sound()
			if "health" in blueprint.output_item:
				inventory.spawn_item(blueprint.output_item,blueprint.output_amount, blueprint.output_item.health)
			else:
				inventory.spawn_item(blueprint.output_item,blueprint.output_amount)
			for i in blueprint.items_needed:
				inventory.remove_item(blueprint.items_needed[i].name, blueprint.items_needed[i].amount)
		

func _on_close_pressed() -> void:
	blueprint = null
	hide()
