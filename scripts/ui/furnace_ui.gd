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


#@onready var time_bar: ProgressBar = $PanelContainer/MarginContainer/HBoxContainer/Inputs/VBoxContainer2/VBoxContainer/Slot/time

var slots:Array
var Owner:Vector3
var last_cooking_amount:int

func _ready() -> void:
	
	for output in output_container.get_children():
		if output is Slot:
			output.item_changed.connect(change)

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
					
					cooking_slot.amount -= 1
					cooking_slot.update_slot()
					
					cook(forge_item)
					timer.queue_free()
					
					
			

func fuel(index: int, item_path: String, amount: int, parent:String) -> void:
	#cooking_slot.update_slot()
	pass

func cook(Item:ItemBase):
	for i in output_container.get_children():
		if i is Slot:
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


func open(server_details:= {}):
	show()
	if sync:
		if !server_details.is_empty():
			#print(server_details)
			update_client.rpc(server_details)

func change(index: int, item_path: String, amount: int, parent:String):
	if sync:
		#print(index,"item ", item_path, parent)
		Globals.sync_ui_change.emit(index,item_path,amount,parent)
	

@rpc("any_peer","call_local")
func update_client(info):
	for i in info:
		var parent = find_child(info[i].parent)
		if parent != null:
			var slot = parent.get_child(i)
			if slot != null:
				slot.Item_resource = load(info[i].item_path)
				slot.amount = info[i].amount
				slot.update_slot()
