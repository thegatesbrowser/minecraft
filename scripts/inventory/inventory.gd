extends ScrollContainer
class_name Inventory

@export var drop_item_scene:PackedScene
@export var slot_s: PackedScene
@export var test_2: PackedScene
@export var items_collection: GridContainer
@export var amount_of_slots:int = 10
@export var inventroy_name: Label

@export var Owner: Node

var owner_id:int
var times:int = 0
var items = []
var slots = []
var full:bool = false
var inventory = []

@export var items_library: ItemsLibrary


func _ready() -> void:
	if Owner != null:
		inventroy_name.text = str(Owner.resource.Name, " Inventory")
		
	Globals.spawn_item_inventory.connect(spawn_item)
	Globals.remove_item.connect(remove_item)
	Globals.check_amount_of_item.connect(check_amount_of_item)
	#Globals.slot_clicked.connect(slot_clicked)
	make_slots()


func _process(_delta: float) -> void:
	check_slots()
	check_if_full()
	
	if Input.is_action_just_pressed("Drop"):
		if Globals.last_clicked_slot != null:
			if Globals.last_clicked_slot.Item_resource != null:
				var drop_item = drop_item_scene.instantiate()
				drop_item.Item = Globals.last_clicked_slot.Item_resource
				for i in get_tree().get_nodes_in_group("Player"):
					if i.your_id == owner_id:
						drop_item.global_position = get_node(i.get_drop_node()).global_position
						get_parent().add_child(drop_item)
						remove_item(Globals.last_clicked_slot.Item_resource.unique_name,1)
					
	if Input.is_action_just_pressed("Build"):
		## split
		if Globals.last_clicked_slot != null:
			if is_even(Globals.last_clicked_slot.amount):
				if Globals.last_clicked_slot.amount >= 2:
					var amount = Globals.last_clicked_slot.amount / 2
					Globals.last_clicked_slot.amount = Globals.last_clicked_slot.amount / 2
					spawn_item(Globals.last_clicked_slot.Item_resource,amount)
					Globals.last_clicked_slot.update_slot()
					Globals.last_clicked_slot = null


func is_even(x: int):
	return x % 2 == 0


func spawn_item(item_resource, amount:int = 1):
	if !visible: return
	if !full:
		for i in items_collection.get_children():
			if i.Item_resource == null:
				i.Item_resource = item_resource
				i.amount = amount
				i.update_slot()
				for num in amount:
					inventory.append(item_resource.unique_name)
				check_if_full()
				sort()
				break


func make_slots():
	for i in amount_of_slots:
		var slot = slot_s.instantiate()
		items_collection.add_child(slot)


func sort():
	items.clear()
	slots.clear()
	for i in items_collection.get_children():
		if i.Item_resource != null:
			if items.has(i.Item_resource.unique_name) == false:
				items.append(i.Item_resource.unique_name)
				slots.append(i)
				
	for slot in items_collection.get_children():
		var find_item
		if slot.Item_resource != null:
			if slot.amount < slot.Item_resource.max_stack:
				find_item = slot
				
				for i in slots:
					if i.Item_resource == find_item.Item_resource:
						if i != find_item:
							if find_item != null:
								if find_item.Item_resource != null:
									if find_item.amount + i.amount  <= find_item.Item_resource.max_stack:
										find_item.amount += i.amount
										i.Item_resource = null
										i.update_slot()
										find_item.update_slot()
										return


func _on_sort_pressed() -> void:
	sort()


func _on_add_random_item_pressed() -> void:
	var item = items_library.items_array.pick_random()
	spawn_item(item)


func check_amount_of_item(item:StringName):
	var amount = 0
	for i in inventory:
		#print(i)
		if i == item:
			amount += 1
		elif item in i:
			#print("yes ",item, " in ", i)
			amount += 1
	return amount


func remove_item(unique_name:StringName,amount:int):
	if Owner != null: return ## Owner mean its not the players inventory
	
	for i in amount:
		for slot in items_collection.get_children():
			if slot.Item_resource != null:
				if slot.Item_resource.unique_name == unique_name:
					if slot.amount == 1:
						slot.Item_resource = null
					else:
						slot.amount -= 1
					slot.update_slot()
					var index = inventory.find(unique_name)
					inventory.remove_at(index)
					check_if_full()
					break
				elif unique_name in slot.Item_resource.unique_name:
					if slot.amount == 1:
						slot.Item_resource = null
					else:
						slot.amount -= 1
					slot.update_slot()
					var index = inventory.find(unique_name)
					inventory.remove_at(index)
					check_if_full()
					break


func check_if_full():
	var free_space:int = 0
	for i in items_collection.get_children():
		if i.Item_resource == null:
			free_space += 1
	if free_space == 0:
		full = true
	else:
		full = false


func check_slots():
	inventory.clear()
	
	for i in items_collection.get_children():
		if i.Item_resource != null:
			for amount in i.amount:
				inventory.append(i.Item_resource.unique_name)


func _on_close_pressed() -> void:
	#Globals.paused = false
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass
