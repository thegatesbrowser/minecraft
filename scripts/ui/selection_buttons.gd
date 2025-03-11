extends ScrollContainer
class_name HotBar

var selected_item: ItemBase 

@onready var eat_sfx: AudioStreamPlayer = $eat

@onready var slots: HBoxContainer = $MarginContainer/VBoxContainer/Slots


var current_key = 1
var buttons
var keys

func _ready() -> void:
	Globals.remove_item_from_hotbar.connect(remove)
	buttons = slots.get_children()

func _input(_event) -> void:
	if Input.is_action_just_released("Scroll_Up"):
		current_key -= 1
	
	elif Input.is_action_just_released("Scroll_Down"):
		current_key += 1
		
	else:
		for i in range(9):
			if Input.is_action_just_pressed(str(i + 1)):
				current_key = i
		if Input.is_action_just_pressed("0"):
			current_key = 9
	
	if Input.is_action_just_pressed("Mine"):
		if selected_item != null:
			if selected_item is ItemFood:
				var timer = Timer.new()
				timer.wait_time = selected_item.eat_time
				timer.name = "food eat timer"
				add_child(timer,true)
				timer.start()
				
				await timer.timeout
				
				if Input.is_action_pressed("Mine"):
					remove()
					eat_sfx.play()
					Globals.hunger_points_gained.emit(selected_item.food_points)
					print("ate ", selected_item.unique_name, " gained ", selected_item.food_points," food points")
					
	
	current_key %= 10
	_unpress_all()
	buttons[current_key].focused = true
	_press_key(current_key)


func _unpress_all() -> void:
	for i in slots.get_children():
		i.button_pressed = false
		i.focused = false

func get_current() -> Slot:
	return buttons[current_key]

func _press_key(i) -> void:
	selected_item = null
	buttons[i].button_pressed = true
	Globals.remove_item_in_hand.emit()
	
	if buttons[current_key].Item_resource != null:
		selected_item = buttons[current_key].Item_resource
		## add holdable if has one
		
		## general holdables
		if buttons[current_key].Item_resource.holdable_mesh != null:
				Globals.add_item_to_hand.emit(buttons[current_key].Item_resource)
				
		if buttons[current_key].Item_resource is ItemBlock:
			Globals.current_block = buttons[current_key].Item_resource.unique_name
			Globals.can_build = true 
			Globals.custom_block = &""
		elif buttons[current_key].Item_resource is ItemTool:
			Globals.can_build = false
			Globals.custom_block = buttons[current_key].Item_resource.unique_name
			#Globals.add_item_to_hand.emit(buttons[current_key].Item_resource)
		elif buttons[current_key].Item_resource is ItemWeapon:
			Globals.can_build = false
			Globals.add_item_to_hand.emit(buttons[current_key].Item_resource)
			Globals.custom_block = buttons[current_key].Item_resource.unique_name
		elif buttons[current_key].Item_resource is ItemFood: 
			Globals.can_build = false
			selected_item = buttons[current_key].Item_resource
		else:
			Globals.custom_block = buttons[current_key].Item_resource.unique_name
			Globals.can_build = true 
			
	else:
		Globals.can_build = false
		
	current_key = i

func remove(unique_name:String = "", amount:int = 1) -> void:
	if unique_name == "":
		var slot = get_current()
		slot.amount -= 1
		if slot.amount <= 0:
			slot.Item_resource = null
		slot.update_slot()
