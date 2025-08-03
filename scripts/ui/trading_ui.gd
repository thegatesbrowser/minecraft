extends PanelContainer

@export var items_lib:ItemsLibrary

@export var sell_slot:Slot
@export var buy_slot:Slot

@onready var offer_cost: Label = $"MarginContainer/VBoxContainer/offer/Sell/offer cost"
@onready var buy_cost: Label = $"MarginContainer/VBoxContainer/offer/Buy/buy cost"

var sync = true

var bought:bool = false
var can_buy:bool = false

func _ready() -> void:
	items_lib.init_items()

	sell_slot.item_changed.connect(new_offer)
	buy_slot.item_changed.connect(Buy)
	
	#select_item.rpc(1)
	
func new_offer(index:int,item_path:String,amount:int,parent:String,health:float,rot:int):
	if sell_slot.item == null: return
	if buy_slot.item == null: return
	
	var offer = sell_slot.item.value * sell_slot.amount
	offer_cost.text = str("$",offer)
	var buy = buy_slot.item.value * buy_slot.amount
	
	if offer >= buy:
		can_buy = true
		buy_slot.locked = false
		
	Globals.sync_ui_change.emit(index,item_path,amount,parent,health,rot)
		
func Buy(index:int,item_path:String,amount:int,parent:String,health:float,rot:int):
	if bought == true: return
	
	if can_buy:
		
		offer_cost.text = str("$",0)
		buy_cost.text = str("$",0)
		
		sell_slot.item = null
		sell_slot.amount = 1
		sell_slot.update_slot()
		bought = true
		
		Globals.sync_ui_change.emit(index,item_path,amount,parent,health,rot)
		
func open(server_details:= {}):
	if !server_details.is_empty():
		update_client.rpc(server_details)
	else:
		var buy_item = items_lib.items_array.pick_random()
		buy_slot.item = buy_item
		buy_slot.amount = randi_range(1,buy_item.max_stack)
		buy_slot.update_slot()
		var value = buy_slot.item.value * buy_slot.amount
		buy_cost.text = str("$",value)
		Globals.sync_ui_change.emit(buy_slot.get_index(),buy_item.get_path(),buy_slot.amount,buy_slot.get_parent().name,buy_slot.health,buy_slot.rot)
	
@rpc("any_peer","call_local")
func update_client(info):
	print(info)
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
		
		if info[i].parent == "Buy":
			if buy_slot.item != null:
				var value = buy_slot.item.value * buy_slot.amount
				buy_cost.text = str("$",value)
				
		elif info[i].parent == "Sell":
			if sell_slot.item != null:
				var value = sell_slot.item.value * sell_slot.amount
				offer_cost.text = str("$",value)
