extends PanelContainer

@export var fuel_types = ["wood_oak","wood_birch","log_oak","log_birch"]

@export var cooking_slot:Slot
@export var fuel_slot:Slot

var server_info: Dictionary
var server_info_output: Dictionary

@export var metadata:bool = true
@export var sync:bool = true

@export var output_container: GridContainer 
@export var input_container:GridContainer

@export var fueled:bool = false

var slots: Array[Slot]
var id: Vector3
var last_cooking_amount: int


func _ready() -> void:
	for output in output_container.get_children():
		if output is Slot:
			slots.append(output)	
			output.item_changed.connect(change)
			
	for input in input_container.get_children():
		if input is Slot:
			slots.append(input)
			input.item_changed.connect(change)

	
func _process(_delta: float) -> void:
	var forge_item: ItemBase = cooking_slot.item
	if forge_item != null:
		if forge_item.forgable:
			#print(forge_item.unique_name)
			if last_cooking_amount != cooking_slot.amount:
				_fuel()
				if fueled:
					#print(cook_time)
					var cook_time = forge_item.forge_time
					
					var timer = Timer.new()
					timer.wait_time = cook_time
					add_child(timer)
					timer.start()
					
					await timer.timeout # wait untill the cook time has fnished
					
					cooking_slot.amount -= 1
					cooking_slot.update_slot()
					
					cook(forge_item)
					timer.queue_free()


func cook(Item: ItemBase) -> void:
	for i in output_container.get_children():
		if i is Slot:
			if i.item == null:
				i.item = Item.output_item
				i.update_slot()
				break
			elif i.item == Item.output_item:
				i.amount += 1
				i.update_slot()
				break


func _fuel() -> void:
	if fuel_slot.item != null:
		if fuel_types.has(fuel_slot.item.unique_name):
			fueled = true
			fuel_slot.amount -= 1
			last_cooking_amount = cooking_slot.amount
			fuel_slot.update_slot()
			return
		else:
			fueled = false
	else:
		fueled = false


func open(server_details: Dictionary = {}) -> void:
	show()
	if sync:
		if !server_details.is_empty():
			#print(server_details)
			update_client.rpc(server_details)

func open_with_meta(data):
	show()
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


func change(index: int, item_path: String, amount: int, parent:String,health:float,rot:int) -> void:
	if sync:
		var _save = save()
		if metadata:
			var data = JSON.stringify(_save)
			Globals.sync_add_metadata.emit(id,data)
		else:
			Globals.update_registered_ui.emit(id,_save)

@rpc("any_peer","call_local")
func update_client(info) -> void:
	for i in info:
		
		var parent = find_child(info[i].parent)
			
		if parent != null:
			var slot = parent.get_child(i.to_int())
			
			if slot != null:
				slot.item = load(info[i].item_path)
				slot.health = info[i].health
				slot.amount = info[i].amount
				slot.rot =  info[i].rot
				slot.update_slot()



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
