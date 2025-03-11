extends Control
class_name Inventory_Holder

@export var inventory_s: PackedScene
@export var h_box_container: HBoxContainer

func _ready() -> void:
	Globals.open_inventory.connect(open_inventory)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		
		for i in h_box_container.get_children():
			if "sync" in i:
				if i.sync:
					i.queue_free()
		
		if visible:
			GlobalAnimation._tween(self,"bounce_in",.2)
			Globals.paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			GlobalAnimation._tween(self,"bounce_out",.4)
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_inventory(id:Vector3) -> void:
	for i in h_box_container.get_children():
		if "id" in i:
			if i.id == id:
				i.open() ## opens the subinventory that has the same id
			elif i.id != Vector3.ZERO:
				i.hide() 
	show() ## opens the inventory holder
	
	if visible:
		GlobalAnimation._tween(self,"bounce_in",.2)
		Globals.paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Globals.paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
