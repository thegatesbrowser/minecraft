extends Node
class_name SlotManager

var hotbar_full:bool = false
var last_clicked_slot:Slot
var selected_slot:Slot ## the slot that is selected in the hotbar

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Drop"):
		if last_clicked_slot != null:
			var item = last_clicked_slot.item as ItemBase
			if item != null:
				Globals.drop_item.emit(multiplayer.get_unique_id(),item)
				if last_clicked_slot.type == "inventory":
					Globals.remove_item.emit(item.unique_name,1)
				else:
					Globals.remove_item_from_hotbar.emit(item.unique_name,1)
				last_clicked_slot = null

func slot_clicked(slot:Slot):
	var soundmanager = get_node("/root/Main").find_child("SoundManager")
	soundmanager.play_UI_sound()
			
	if last_clicked_slot == null:
		last_clicked_slot = slot
		last_clicked_slot.focused = true

	if slot == last_clicked_slot: return
	else:
		## move to blank
		if slot.item == null:
			#print("move ")
			
			if slot.type == "chest_plate":
				if last_clicked_slot.item is ItemArmour:
					if last_clicked_slot.item.chest == false:
						return
				else:
					return
					
			if slot.type == "pants":
				if last_clicked_slot.item is ItemArmour:
					if last_clicked_slot.item.pants == false:
						return
				else:
					return
					
			if slot.type == "helment":
				if last_clicked_slot.item is ItemArmour:
					if last_clicked_slot.item.helment == false:
						return
				else:
					return
					
			slot.item = last_clicked_slot.item
			#slot.add_item.rpc(last_clicked_slot.item)
			slot.health = last_clicked_slot.health
			slot.amount = last_clicked_slot.amount
			slot.rot = last_clicked_slot.rot
			last_clicked_slot.item = null
			slot.update_slot()
			last_clicked_slot.update_slot()
			last_clicked_slot.focused = false
			last_clicked_slot = null
		else:
			## stack
			if slot.item == last_clicked_slot.item:
				if slot.amount + last_clicked_slot.amount  < slot.item.max_stack:
					#print("stack ")
					if slot.item is ItemFood:
						if last_clicked_slot.item is ItemFood:
							if last_clicked_slot.rot != slot.rot:
								return
								
					slot.amount += last_clicked_slot.amount
					last_clicked_slot.item = null
					last_clicked_slot.update_slot()
					last_clicked_slot.focused = false
					last_clicked_slot = null
					slot.update_slot()
				
			## swap
			else:
				if slot.item != null:
					if slot.item != last_clicked_slot.item:
						#print("swap " )
						
						if slot.type == "chest_plate":
							if last_clicked_slot.item is ItemArmour:
								if last_clicked_slot.item.chest == false:
									return
							else:
								return
							
						if slot.type == "pants":
							if last_clicked_slot.item is ItemArmour:
								if last_clicked_slot.item.pants == false:
									return
							else:
								return
							
						if slot.type == "helment":
							if last_clicked_slot.item is ItemArmour:
								if last_clicked_slot.item.helment == false:
									return
							else:
								return
							
						var hold_slot_health = slot.health
						var hold_slot_amount = slot.amount
						var hold_slot_rot = slot.rot
						var hold_slot_resource = slot.item
						
						slot.item = last_clicked_slot.item
						
						#slot.item =  last_clicked_slot.item
						slot.rot = last_clicked_slot.rot
						slot.amount = last_clicked_slot.amount
						slot.health = last_clicked_slot.health
						#last_clicked_slot.item = hold_slot_resource
						last_clicked_slot.item = hold_slot_resource
						
						last_clicked_slot.amount = hold_slot_amount
						last_clicked_slot.health = hold_slot_health
						last_clicked_slot.rot = hold_slot_rot
						last_clicked_slot.update_slot()
						last_clicked_slot.focused = false
						last_clicked_slot = null
						
						slot.update_slot()

func add_item_to_hotbar_or_inventory(item:ItemBase):
	if hotbar_full: Globals.spawn_item_inventory.emit(item)
	else:
		Globals.spawn_item_hotbar.emit(item)
