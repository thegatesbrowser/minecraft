extends ScrollContainer
class_name HotBar

@export var eat_sfx: AudioStreamPlayer
@export var slots: HBoxContainer

var selected_item: ItemBase 

var current_key = 1
var buttons
var keys
var slot_manager:SlotManager

func _ready() -> void:
	slot_manager = get_node("/root/Main").find_child("SlotManager")
	Globals.spawn_item_hotbar.connect(spawn_item_hotbar)
	Globals.remove_item_from_hotbar.connect(remove)
	
	buttons = slots.get_children()
	
	var BackendClient = get_tree().get_first_node_in_group("BackendClient")
	if !BackendClient.playerdata.is_empty():
		if BackendClient.playerdata.Hotbar != null:
			update(JSON.parse_string(BackendClient.playerdata.Hotbar))
			pass
			
	for slot in buttons:
		slot.item_changed.connect(slot_updated)
			

func _input(_event: InputEvent) -> void:
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
	buttons[current_key].focused = true
	_press_key(current_key)


func _unpress_all() -> void:
	for i in slots.get_children():
		i.button_pressed = false
		i.focused = false


func get_current() -> Slot:
	return buttons[current_key]


func _press_key(i: int) -> void:
	selected_item = null
	buttons[i].button_pressed = true
	Globals.remove_item_in_hand.emit()
	slot_manager.selected_slot = buttons[current_key]
	
	if buttons[current_key].item != null:
		selected_item = buttons[current_key].item
	
		## add holdable if has one
		
		## general holdables
		if buttons[current_key].item.holdable_mesh != null:
				Globals.add_item_to_hand.emit(buttons[current_key].item,null)
				
		if buttons[current_key].item is ItemBlock:
			Globals.current_block = buttons[current_key].item.unique_name
			Globals.can_build = true 
			Globals.custom_block = &""
		#elif buttons[current_key].item is ItemPlant:
			#Globals.current_block = buttons[current_key].item.unique_name
			#Globals.can_build = true 
			#Globals.custom_block = &""
		elif buttons[current_key].item is ItemTool:
			Globals.can_build = false
			Globals.custom_block = buttons[current_key].item.unique_name
			#Globals.add_item_to_hand.emit(buttons[current_key].item)
		#elif buttons[current_key].item is ItemWeapon:
			#Globals.can_build = false
			#Globals.add_item_to_hand.emit(buttons[current_key].item,buttons[current_key].item.weapon_model)
			#Globals.custom_block = buttons[current_key].item.unique_name
		elif buttons[current_key].item is ItemFood: 
			Globals.can_build = false
			selected_item = buttons[current_key].item
			var holdable_array = selected_item.rot_step_holdable_models as Array
			if not holdable_array.is_empty():
				var holdable = holdable_array[buttons[current_key].rot]
				Globals.add_item_to_hand.emit(null,holdable)
		else:
			Globals.custom_block = buttons[current_key].item.unique_name
			Globals.can_build = true 
			
	else:
		Globals.can_build = false
		
	current_key = i


func remove(unique_name: String = "", amount: int = 1) -> void:
	if unique_name == "":
		var slot: Slot = get_current()
		slot.amount -= amount
		if slot.amount <= 0:
			slot.item = null
		slot.update_slot()
	else:
		for slot in buttons:
			if slot.item != null:
				if slot.item.unique_name == unique_name:
					slot.amount -= amount
					if slot.amount <= 0:
						slot.item = null
					slot.update_slot()


func drop_all() -> void:
	for slot in slots.get_children():
		var item = slot.item as ItemBase
		if item != null:
			Globals.drop_item.emit(item,slot.amount)
					
			remove(item.unique_name,slot.amount)

func _on_dropall_pressed() -> void:
	drop_all()


func save() -> Dictionary:
	var save_data:Dictionary = {}
	for i in slots.get_children():
		if i.item != null:
			save_data[str(i.get_index())] = {
				"item_path":i.item.get_path(),
				"amount":i.amount,
				"parent":i.get_parent().name,
				"health":i.health,
				"rot":i.rot,
				}
		else:
			save_data[str(i.get_index())] = {
				"item_path":"",
				"amount":i.amount,
				"parent":i.get_parent().name,
				"health":i.health,
				"rot":i.rot,
				}
	return save_data

func update(info) -> void:
	print("update hotbar ",info)
	for i in info:
		
		var slot = find_child(info[i].parent).get_child(i.to_int())
		
		if info[i].item_path != "":
			slot.item = load(info[i].item_path)
		else:
			slot.item = null
			
		slot.health = info[i].health
		slot.amount = info[i].amount
		slot.rot = info[i].rot
		slot.update_slot()
		
	Globals.hotbar_full = hotbar_full()
		
		

func slot_updated(index: int, item_path: String, amount: int,parent:String,health:float,rot:int):
	var BackendClient = get_tree().get_first_node_in_group("BackendClient")
	if !BackendClient.playerdata.is_empty():
		if BackendClient.playerdata.Inventory == null:
			Globals.save.emit()
		else:
			Globals.save_slot.emit(index,item_path,amount,parent,health,rot)
	

func spawn_item_hotbar(item:ItemBase) -> void:
	for slot in slots.get_children():
		if slot.item == null:
			slot.item = item
			slot.update_slot()
			break
		elif slot.item == item:
			if slot.item.max_stack >= slot.amount:
				#return
				slot.amount += 1
				slot.update_slot()
				break
				
func hotbar_full() -> bool:
	var full:bool = true
	for slot in slots.get_children():
		if slot.item == null:
			full = false
			#return true
	return full
