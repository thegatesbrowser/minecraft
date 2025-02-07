extends ScrollContainer

var times:int = 0
@onready var slot_s = preload("res://Items/Slot.tscn")
@onready var items_collection: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/Items
@export var amount_of_slots:int = 10

var possible_items = ["res://Items/Dirt.tres","res://Items/Glass.tres","res://Items/Grass.tres","res://Items/Leaf1.tres","res://Items/Leaf2.tres","res://Items/Log1.tres","res://Items/Log2.tres","res://Items/Stone.tres","res://Items/Wood1.tres","res://Items/Wood2.tres"]

func _ready() -> void:
	Globals.slot_clicked.connect(slot_clicked)
	make_slots()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		if visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("5"):
		spawn_item(load("res://Items/Test2.tres"))
		
	if Input.is_action_just_pressed("Build"):
		## split
		if Globals.last_clicked_slot != null:
			print(is_even(Globals.last_clicked_slot.amount))
			if is_even(Globals.last_clicked_slot.amount):
				if Globals.last_clicked_slot.amount >= 2:
					var amount = Globals.last_clicked_slot.amount / 2
					Globals.last_clicked_slot.amount = Globals.last_clicked_slot.amount / 2
					spawn_item(Globals.last_clicked_slot.Item_resource,amount)
					Globals.last_clicked_slot.update_slot()
					Globals.last_clicked_slot = null
		
func is_even(x: int):
	return x % 2 == 0
			
func slot_clicked(slot):
	times += 1
	if slot == Globals.last_clicked_slot: return
	if Globals.last_clicked_slot == null:
		Globals.last_clicked_slot = slot
	else:
		## move to blank
		if slot.Item_resource == null:
			print("move ", times)
			slot.Item_resource = Globals.last_clicked_slot.Item_resource
			slot.amount = Globals.last_clicked_slot.amount
			Globals.last_clicked_slot.Item_resource = null
			slot.update_slot()
			Globals.last_clicked_slot.update_slot()
			Globals.last_clicked_slot = null
		else:
			## stack
			if slot.Item_resource == Globals.last_clicked_slot.Item_resource:
				print("stack ", times)
				slot.amount += Globals.last_clicked_slot.amount
				Globals.last_clicked_slot.Item_resource = null
				Globals.last_clicked_slot.update_slot()
				Globals.last_clicked_slot = null
				slot.update_slot()
			
			## swap
			else:
				if slot.Item_resource != null:
					if slot.Item_resource != Globals.last_clicked_slot.Item_resource:
						print("swap ",times )
						var hold_slot_amount = slot.amount
						var hold_slot_resource = slot.Item_resource
						
						slot.Item_resource =  Globals.last_clicked_slot.Item_resource
						slot.amount = Globals.last_clicked_slot.amount
						
						Globals.last_clicked_slot.Item_resource = hold_slot_resource
						Globals.last_clicked_slot.amount = hold_slot_amount
						
						slot.update_slot()
						Globals.last_clicked_slot.update_slot()
						Globals.last_clicked_slot = null

func spawn_item(item_resource, amount:int = 1):
	for i in items_collection.get_children():
		if i.Item_resource == null:
			i.Item_resource = item_resource
			i.amount = amount
			i.update_slot()
			break
	#items_collection.aa
	
func make_slots():
	for i in amount_of_slots:
		var slot = slot_s.instantiate()
		items_collection.add_child(slot)

func sort():
	var last
	for i in items_collection.get_children():
		if last == null:
			if i.Item_resource != null:
				last = i
		else:
			if i.Item_resource == last.Item_resource:
				last.amount += 1
				i.Item_resource = null
				i.update_slot()
				last.update_slot()
			else:
				if i.Item_resource != null:
					last = i


func _on_sort_pressed() -> void:
	sort()


func _on_add_random_item_pressed() -> void:
	var item = possible_items.pick_random()
	spawn_item(load(item))
