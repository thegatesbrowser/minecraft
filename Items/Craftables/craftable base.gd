extends TextureButton

var inventory:Node = null

@export var craftable: Craftable


func _ready() -> void:
	inventory = get_tree().get_root().find_child("Inventory", true, false)
	if craftable != null:
		texture_normal = craftable.texture


func craft() -> void:
	if inventory != null:
		var steps = craftable.items_needed.duplicate().size()
		for i in craftable.items_needed:
			#print(craftable.items_needed[i].name)
			if inventory.check_amount_of_item(craftable.items_needed[i].name) >= craftable.items_needed[i].amount:
				steps -= 1
				#print("is the same")
				
		print(steps)
		
		if steps == 0:
			if inventory.full == false:
				print("crafted")
				inventory.spawn_item(craftable.output_item)
				for i in craftable.items_needed:
					Globals.remove_item.emit(craftable.items_needed[i].name, craftable.items_needed[i].amount)
				


func _on_mouse_entered() -> void:
	Globals.craftable_hovered.emit(craftable,self)


func _on_mouse_exited() -> void:
	Globals.craftable_unhovered.emit()

func can_craft():
	if inventory != null:
		var steps = craftable.items_needed.duplicate().size()
		for i in craftable.items_needed:
			#print(craftable.items_needed[i].name)
			if inventory.check_amount_of_item(craftable.items_needed[i].name) >= craftable.items_needed[i].amount:
				steps -= 1
				#print("is the same")
				
		print(steps)
		
		if steps == 0:
			return true
		else:
			return false
