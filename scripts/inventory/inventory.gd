extends ScrollContainer
class_name Inventory

# External references
@export var sync:bool = true ## FALSE for the player main inventory
@export var slot_container: GridContainer
@export var id: Vector3
@export var items_library: ItemsLibrary



#var times:int = 0
var items = []
var slots = [] ## List of slots in the inventory
var full:bool = false
var inventory = [] ## List of ItemBase unique names in the inventory

# Server/client info
var server_info: Dictionary

func _ready() -> void:
	slots = slot_container.get_children()

	for slot in slots:
		slot.item_changed.connect(change)

	if is_in_group("Main Inventory"):
		Console.add_command("item", self, '_on_add_random_item_pressed')\
		.set_description("spawns random item).")\
		.register()
		
		var backend_client = get_tree().get_first_node_in_group("BackendClient")
		if backend_client and backend_client.playerdata:
			if backend_client.playerdata.Inventory:
				# If the player has an inventory, load it
				var data = JSON.parse_string(backend_client.playerdata.Inventory)
				if data:
					update_client(data)
		
	Globals.spawn_item_inventory.connect(spawn_item)
	Globals.remove_item.connect(remove_item)
	Globals.check_amount_of_item.connect(check_amount_of_item)
	
	
func _process(_delta: float) -> void:
	
	check_slots()
	check_if_full()
								
func is_even(x: int) -> bool:
	return x % 2 == 0

func spawn_item(item:ItemBase, amount:int = 1,health:int = 0) -> void:
	if full:
		return
	for slot in slots:
		if slot.item == null:
			slot.item = item
			slot.amount = amount
			
			if item is ItemFood:
				slot.start_rot(item.time_rot_step)
			
			if health != 0:
				slot.health = health

			
			for num in amount:
				inventory.append(item.unique_name)

			slot.update_slot()
			check_if_full()
			sort()
			break


func sort() -> void:
	#print("sorting inventory")
	items.clear()
	for i in slots:
		if i.item != null:
			if items.has(i.item.unique_name) == false:
				items.append(i.item.unique_name)
				#slots.append(i)
				
	for slot in slot_container.get_children():
		var find_item
		if slot.item != null:
			if slot.amount < slot.item.max_stack:
				find_item = slot
				
				for i in slots:
					if i.item == find_item.item:
						if i != find_item:
							if find_item != null:
								if find_item.item != null:
									if find_item.amount + i.amount  <= find_item.item.max_stack:
										find_item.amount += i.amount
										i.item = null
										i.update_slot()
										find_item.update_slot()
										return


func _on_sort_pressed() -> void:
	sort()

func check_amount_of_item(unique_name:StringName) -> int:
	var amount = 0
	for name in inventory:
		if name == unique_name:
			amount += 1
		elif unique_name in name: ## if asking for a part of the name like "wood" and the item is "oak_wood"
			amount += 1
	return amount


func remove_item(unique_name:StringName,amount:int) -> void:
	if id != Vector3.ZERO: return ## id mean its not the players inventory
	#print("remove from inventory ",unique_name,amount)
	for i in amount:
		for slot in slots:
			if slot.item != null:
				if slot.item.unique_name == unique_name:
					if slot.amount == 1:
						slot.item = null
					else:
						slot.amount -= 1
					slot.update_slot()
					var index = inventory.find(unique_name)
					inventory.remove_at(index)
					check_if_full()
					break
				elif unique_name in slot.item.unique_name:
					if slot.amount == 1:
						slot.item = null
					else:
						slot.amount -= 1
					slot.update_slot()
					var index = inventory.find(unique_name)
					inventory.remove_at(index)
					check_if_full()
					break


func check_if_full() -> void:
	var full:bool = false

	for slot in slots:
		if slot.item == null:
			full = false
			break
			
	full = full

func check_slots():
	inventory.clear()
	
	for slot in slots:
		if slot.item != null:
			for amount in slot.amount:
				inventory.append(slot.item.unique_name)
			

func change(index: int, item_path: String, amount: int,parent:String,health:float,rot:int):
	if sync:
		var _save = save()
		var data = JSON.stringify(_save)
		Globals.sync_add_metadata.emit(id,data)
	else:
		var BackendClient = get_tree().get_first_node_in_group("BackendClient")
		if BackendClient.playerdata.Inventory == null:
			Globals.save.emit()
		else:
			Globals.save_slot.emit(index,item_path,amount,parent,health,rot)
			
func open_with_meta(data):
	show()
	#print("new details ",data)
	if not data:
		return

	for i in data:
		
		var slot = find_child(data[i].parent).get_child(i.to_int())
		
		if data[i].item_path != "":
			slot.item = load(data[i].item_path)
		else:
			slot.item = null
			
		slot.health = data[i].health
		slot.amount = data[i].amount
		slot.rot = data[i].rot
		slot.update_slot()
			
			
@rpc("any_peer")
func update(pos,data):
	Globals.sync_change_open.emit(pos,data)
	
@rpc("any_peer","call_local")
func add_meta_data(data):
	
	#print("data",data)
	TerrainHelper.get_terrain_tool().get_voxel_tool().set_voxel_metadata(id,data)
	#print(" change",TerrainHelper.get_terrain_tool().get_voxel_tool().get_voxel_metadata(id))

func update_client(info):
	#("update inventory ",info)
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
	pass

#func pack_items(items:Array[String]):
	#for item in items:
		#var Inventory_ = owner as Inventory
		#Inventory_.spawn_item(load(item))

func drop_all():
	for slot in slot_container.get_children():
		var item = slot.item as ItemBase
		if item != null:
			Globals.drop_item.emit(multiplayer.get_unique_id(),item,slot.amount)
					
			remove_item(item.unique_name,slot.amount)

func _on_drop_all_pressed() -> void:
	drop_all()

func save() -> Dictionary:
	var save_data:Dictionary = {}
	for slot in slots:
		if slot.item != null:
			save_data[str(slot.get_index())] = {
				"item_path" : slot.item.get_path(),
				"amount" : slot.amount,
				"parent" : slot.get_parent().name,
				"health" : slot.health,
				"rot" : slot.rot,
				}
		else:
			save_data[str(slot.get_index())] = {
				"item_path" : "",
				"amount" : slot.amount,
				"parent" : slot.get_parent().name,
				"health" : slot.health,
				"rot" : slot.rot,
				}
	return save_data
