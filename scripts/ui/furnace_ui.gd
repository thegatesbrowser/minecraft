extends PanelContainer

@export var fuel_types = ["wood_oak","wood_birch","log_oak","log_birch"]

@export var cooking_slot:Slot
@export var fuel_slot:Slot

var server_info: Dictionary

var server_info_output: Dictionary
@export var sync:bool = true

@export var output_container: GridContainer 
@export var input_container:VBoxContainer

@export var fueled:bool = false

@onready var time_bar: ProgressBar = $PanelContainer/MarginContainer/HBoxContainer/Inputs/VBoxContainer2/VBoxContainer/Slot/time

var Owner:Vector3
var last_cooking_amount:int

func _ready() -> void:
	for output in output_container.get_children():
		output.item_changed.connect(change_output)

func _process(delta: float) -> void:
	var forge_item = cooking_slot.Item_resource
	if forge_item != null:
		if forge_item.forgable:
			if last_cooking_amount != cooking_slot.amount:
				_fuel()
				if fueled:
					var cook_time = forge_item.forge_time
					
					var timer = Timer.new()
					timer.wait_time = cook_time
					add_child(timer)
					timer.start()
					
					await timer.timeout
					
					cook(forge_item)
					timer.queue_free()
			

func fuel(index: int, item_path: String, amount: int) -> void:
	pass

func cook(Item:ItemBase):
	cooking_slot.amount -= 1
	cooking_slot.update_slot()
	for i in output_container.get_children():
		if i.Item_resource == null:
			i.Item_resource = Item.output_item
			i.update_slot()
			break
		elif i.Item_resource == Item.output_item:
			i.amount += 1
			i.update_slot()
			break

func _fuel():
		
	if fuel_slot.Item_resource != null:
		if fuel_types.has(fuel_slot.Item_resource.unique_name):
			fueled = true
			fuel_slot.amount -= 1
			last_cooking_amount = cooking_slot.amount
			fuel_slot.update_slot()
		else:
			fueled = false
	else:
		fueled = false


func open():
	show()
	if sync:
		server_check_output.rpc_id(1)
		server_check.rpc_id(1)

#region syncing the input slots
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
	#print("check ",server_info)
	
@rpc("any_peer","call_local")
func update_client(info):
	for i in info:
		var slot = input_container.get_child(i)
		if slot != null:
			slot.Item_resource = load(info[i].item_path)
			slot.amount = info[i].amount
			slot.update_slot()
#endregion


#region syncing the output slots

func change_output(index: int, item_path: String, amount: int):
	if sync:
		send_to_server_output.rpc_id(1,index,item_path,amount)
	
@rpc("any_peer","call_local")
func send_to_server_output(slot_index: int, item_path: String, amount: int):
	if multiplayer.is_server():
		server_info_output[slot_index] = {
			"item_path":item_path,
			"amount":amount,
		}
		#print(server_info_output)
		#print(server_info)
		
@rpc("any_peer","call_local")
func server_check_output():
	if not multiplayer.is_server(): return
	update_client_output.rpc(server_info_output)
	#print("check ",server_info_output)
	
@rpc("any_peer","call_local")
func update_client_output(info):
	for i in info:
		var slot = output_container.get_child(i)
		slot.Item_resource = load(info[i].item_path)
		slot.amount = info[i].amount
		slot.update_slot()
#endregion
