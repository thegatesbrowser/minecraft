extends ScrollContainer
class_name HotBar

@onready var slots: HBoxContainer = $MarginContainer/VBoxContainer/Slots

#
#@onready var grass = $HBoxContainer/Grass
#@onready var dirt = $HBoxContainer/Dirt
#@onready var stone = $HBoxContainer/Stone
#@onready var glass = $HBoxContainer/Glass
#@onready var log1 = $HBoxContainer/Log1
#@onready var log2 = $HBoxContainer/Log2
#@onready var wood1 = $HBoxContainer/Wood
#@onready var wood2 = $HBoxContainer/Wood2
#@onready var leaf1 = $HBoxContainer/Leaf1
#@onready var leaf2 = $HBoxContainer/Leaf2

enum {GRASS, DIRT, STONE, GLASS, LOG1, WOOD1, LOG2, WOOD2, LEAF1, LEAF2}

var current_key = WOOD1
var buttons
var keys


func _ready():
	Globals.remove_item_from_hotbar.connect(remove)
	Globals.hotbar_slot_clicked.connect(hotbar_slot_clicked)
	buttons = slots.get_children()
	#keys = [WorldGen.GRASS, WorldGen.DIRT, WorldGen.STONE, WorldGen.GLASS, WorldGen.LOG1, \
		#WorldGen.WOOD1, WorldGen.LOG2, WorldGen.WOOD2, WorldGen.LEAVES1, WorldGen.LEAVES2]


func _input(_event):
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
	
	
	
	current_key %= 10
	_unpress_all()
	#print(buttons[current_key])
	buttons[current_key].focused = true
	#if buttons[current_key].Item_resource != null:
	_press_key(current_key)
	#_press_key(current_key)


func _unpress_all():
	for i in slots.get_children():
		i.button_pressed = false
		i.focused = false

func get_current():
	return buttons[current_key]

func _press_key(i):
	buttons[i].button_pressed = true
	Globals.remove_item_in_hand.emit()
	if buttons[current_key].Item_resource != null:
		
		## add holdable if has one
		
		if buttons[current_key].Item_resource.holdable_mesh != null:
			Globals.add_item_to_hand.emit(buttons[current_key].Item_resource)
		
		if buttons[current_key].Item_resource is ItemBlock:
			Globals.current_block = buttons[current_key].Item_resource.unique_name
			Globals.can_build = true 
		elif buttons[current_key].Item_resource is ItemTool:
			Globals.can_build = false
		else:
			Globals.custom_block = buttons[current_key].Item_resource.unique_name
			Globals.can_build = true 
	else:
		#Globals.custom_block = ""
		#Globals.current_block = ""
		Globals.can_build = false
		
	current_key = i


func _on_Grass_pressed():
	_unpress_all()
	_press_key(GRASS)


func _on_Dirt_pressed():
	_unpress_all()
	_press_key(DIRT)


func _on_Stone_pressed():
	_unpress_all()
	_press_key(STONE)


func _on_Glass_pressed():
	_unpress_all()
	_press_key(GLASS)


func _on_Log1_pressed():
	_unpress_all()
	_press_key(LOG1)


func _on_Log2_pressed():
	_unpress_all()
	_press_key(LOG2)


func _on_Wood_pressed():
	_unpress_all()
	_press_key(WOOD1)


func _on_Wood2_pressed():
	_unpress_all()
	_press_key(WOOD2)


func _on_Leaf1_pressed():
	_unpress_all()
	_press_key(LEAF1)


func _on_Leaf2_pressed():
	pass


func hotbar_slot_clicked(_slot):
	pass
	#_unpress_all()
	#_press_key(slot.Item_resource.type)


func remove(unique_name:String = "", amount:int = 1):
	if unique_name == "":
		var slot = get_current()
		slot.amount -= 1
		if slot.amount <= 0:
			slot.Item_resource = null
		slot.update_slot()
