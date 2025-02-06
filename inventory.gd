extends ScrollContainer

@onready var slot_s = preload("res://Items/Slot.tscn")
@onready var items_collection: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/Items
@export var amount_of_slots:int = 10


func _ready() -> void:
	Globals.slot_clicked.connect(slot_clicked)
	make_slots()
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("5"):
		spawn_item(load("res://Items/Test2.tres"))
		
		
func slot_clicked(slot):
	if slot == Globals.last_clicked_slot: return
	if Globals.last_clicked_slot == null:
		Globals.last_clicked_slot = slot
	else:
		if slot.Item_resource == null:
			slot.Item_resource = Globals.last_clicked_slot.Item_resource
			slot.amount = Globals.last_clicked_slot.amount
			Globals.last_clicked_slot.Item_resource = null
			slot.update_slot()
			Globals.last_clicked_slot.update_slot()
			Globals.last_clicked_slot = null
		else:
			if slot.Item_resource == Globals.last_clicked_slot.Item_resource:
				slot.amount += Globals.last_clicked_slot.amount
				Globals.last_clicked_slot.amount = 1
				Globals.last_clicked_slot.Item_resource = null
				Globals.last_clicked_slot.update_slot()
				Globals.last_clicked_slot = null
				slot.update_slot()
			
			## swap
			else:
				var hold_slot_resource = slot.Item_resource
				slot.Item_resource =  Globals.last_clicked_slot.Item_resource
				Globals.last_clicked_slot.Item_resource = hold_slot_resource
				slot.update_slot()
				Globals.last_clicked_slot.update_slot()
				Globals.last_clicked_slot = null

func spawn_item(item_resource):
	for i in items_collection.get_children():
		if i.Item_resource == null:
			i.Item_resource = item_resource
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
