extends ScrollContainer
class_name Inventory

@export var sync:bool = true ## FALSE for the player main inventory

@export var slot_s: PackedScene
@export var test_2: PackedScene
@export var items_collection: GridContainer
@export var amount_of_slots:int = 10
@export var inventroy_name: Label

@export var id: Vector3
@export var items_library: ItemsLibrary

var server_info: Dictionary

var times:int = 0
var items = []
var slots = []
var full:bool = false
var inventory = []


func _ready() -> void:
	if is_in_group("Main Inventory"):
		Console.add_command("item", self, '_on_add_random_item_pressed')\
		.set_description("spawns random item).")\
		.register()
		
		var BackendClient = get_tree().get_first_node_in_group("BackendClient")
		if !BackendClient.playerdata.is_empty():
			if BackendClient.playerdata.Inventory != null:
				update_client(JSON.parse_string(BackendClient.playerdata.Inventory))
				
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
					
	
			
func is_even(x: int) -> bool:
	return x % 2 == 0


func spawn_item(item_resource:ItemBase, amount:int = 1,health:int = 0) -> void:
	if !visible: return
	if !full:
		for i in items_collection.get_children():
			if i.Item_resource == null:
				i.Item_resource = item_resource
				i.amount = amount
				
				if item_resource is ItemFood:
					i.start_rot(item_resource.time_rot_step)
				
				if health != 0:
					i.health = health
				#print(item_resource)
				i.update_slot()
				for num in amount:
					inventory.append(item_resource.unique_name)
				check_if_full()
				sort()
				break

func sort() -> void:
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


func check_amount_of_item(item:StringName) -> int:
	var amount = 0
	for i in inventory:
		#print(i)
		if i == item:
			amount += 1
		elif item in i:
			#print("yes ",item, " in ", i)
			amount += 1
	return amount


func remove_item(unique_name:StringName,amount:int) -> void:
	if id != Vector3.ZERO: return ## id mean its not the players inventory
	
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


func check_if_full() -> void:
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


func open(server_details:= {}):
	show()
	if sync:
		for i in items_collection.get_children():
			i.Item_resource = null
			i.update_slot()
		if !server_details.is_empty():
			update_client.rpc(server_details)


func change(index: int, item_path: String, amount: int,parent:String,health:float,rot:int):
	if sync:
		Globals.sync_ui_change.emit(index,item_path,amount,parent,health,rot)

@rpc("any_peer","call_local")
func update_client(info):
	for i in info:
		
		var slot = find_child(info[i].parent).get_child(i.to_int())
		
		if info[i].item_path != "":
			slot.Item_resource = load(info[i].item_path)
		else:
			slot.Item_resource = null
			
		slot.health = info[i].health
		slot.amount = info[i].amount
		slot.rot = info[i].rot
		slot.update_slot()

func pack_items(items:Array[String]):
	for item in items:
		var Inventory_ = owner as Inventory
		Inventory_.spawn_item(load(item))

func drop_all():
	for slot in items_collection.get_children():
		var item = slot.Item_resource as ItemBase
		if item != null:
			Globals.drop_item.emit(multiplayer.get_unique_id(),item,slot.amount)
					
			remove_item(item.unique_name,slot.amount)

func _on_drop_all_pressed() -> void:
	drop_all()

func save() -> Dictionary:
	var save_data:Dictionary = {}
	for i in items_collection.get_children():
		if i.Item_resource != null:
			save_data[str(i.get_index())] = {
				"item_path":i.Item_resource.get_path(),
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
