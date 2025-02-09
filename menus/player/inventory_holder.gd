extends Control

@onready var inventory_s = preload("res://Items/inventory.tscn")

@onready var h_box_container: HBoxContainer = $HBoxContainer


func _ready() -> void:
	Globals.add_subinventory.connect(add_subinventory)
	Globals.open_inventory.connect(open_inventory)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		
		for i in h_box_container.get_children():
			if "Owner" in i:
				if i.Owner != null:
					i.hide()
				
		if visible:
			Globals.paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_subinventory(Owner:Node):
	var inventory = inventory_s.instantiate()
	inventory.Owner = Owner
	h_box_container.add_child(inventory)
	inventory.visible = false

func open_inventory(Owner:Node):
	for i in h_box_container.get_children():
		if "Owner" in i:
			if i.Owner == Owner:
				i.show()
			
	visible = !visible
		
	if visible:
		Globals.paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Globals.paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
