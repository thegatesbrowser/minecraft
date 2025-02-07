extends TextureButton

var Inventroy:Node = null

@export var craftable: Craftable


func _ready() -> void:
	Inventroy = get_node("/root/Game/Overlay/Inventory")
	if craftable != null:
		texture_normal = craftable.texture


func craft() -> void:
	if Inventroy != null:
		var steps = craftable.items_needed.duplicate().size()
		for i in craftable.items_needed:
			#print(craftable.items_needed[i].name)
			if Inventroy.check_amount_of_item(craftable.items_needed[i].name) >= craftable.items_needed[i].amount:
				steps -= 1
				#print("is the same")
				
		print(steps)
		
		if steps == 0:
			if Inventroy.full == false:
				print("crafted")
				Inventroy.spawn_item(craftable.output_item)
				for i in craftable.items_needed:
					Globals.remove_item.emit(craftable.items_needed[i].name, craftable.items_needed[i].amount)
				


func _on_mouse_entered() -> void:
	Globals.craftable_hovered.emit(craftable,self)


func _on_mouse_exited() -> void:
	Globals.craftable_unhovered.emit()

func can_craft():
	if Inventroy != null:
		var steps = craftable.items_needed.duplicate().size()
		for i in craftable.items_needed:
			#print(craftable.items_needed[i].name)
			if Inventroy.check_amount_of_item(craftable.items_needed[i].name) >= craftable.items_needed[i].amount:
				steps -= 1
				#print("is the same")
				
		print(steps)
		
		if steps == 0:
			return true
		else:
			return false
