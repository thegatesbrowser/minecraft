extends ScrollContainer
class_name Inventory

var server_info: Dictionary

@export var sync:bool = true ## FALSE for the player main inventory

@export var slot_s: PackedScene
@export var test_2: PackedScene
@export var items_collection: GridContainer
@export var amount_of_slots:int = 10
@export var inventroy_name: Label

@export var Owner: Vector3

var times:int = 0
var items = []
var slots = []
var full:bool = false
var inventory = []

@export var items_library: ItemsLibrary

func _ready() -> void:
	for i in items_collection.get_children():
		i.item_changed.connect(change)
		
	Globals.spawn_item_inventory.connect(spawn_item)
	Globals.remove_item.connect(remove_item)
	Globals.check_amount_of_item.connect(check_amount_of_item)



func _process(_delta: float) -> void:
	
	check_slots()
	check_if_full()
					
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
				#print(item_resource)
				i.update_slot()
				for num in amount:
					inventory.append(item_resource.unique_name)
				check_if_full()
				sort()
				break


func make_slots():
	for i in amount_of_slots:
		var slot = slot_s.instantiate()
		slot.set_multiplayer_authority(1,true)
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
	if Owner != Vector3.ZERO: return ## Owner mean its not the players inventory
	
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
	pass

func open():
	show()
	if sync:
		server_check.rpc_id(1)

func change(index: int, item_path: String, amount: int):
	if sync:
		send_to_server.rpc_id(1,index,item_path,amount)
	
@rpc("any_peer","call_local")
func send_to_server(slot_index: int, item_path: String, amount: int):
	if multiplayer.is_server():
		server_info[slot_index] = {
			"item_path":item_path,
			"amount":amount,
		}
		#print(server_info)
		
@rpc("any_peer","call_local")
func server_check():
	if not multiplayer.is_server(): return
	update_client.rpc(server_info)
	
@rpc("any_peer","call_local")
func update_client(info):
	for i in info:
		var slot = items_collection.get_child(i)
		slot.Item_resource = load(info[i].item_path)
		slot.amount = info[i].amount
		slot.update_slot()

func _on_update_tick_timeout() -> void:
	## updates the inventory to the server version
	if visible:
		if sync:
			server_check.rpc()
