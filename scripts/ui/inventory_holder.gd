extends Control
class_name Inventory_Holder

@onready var container: HBoxContainer= $"Panel/MarginContainer/VBoxContainer/Inventory Holder"

var spawned:Array = []

func _ready() -> void:
	pass

	#Globals.sync_change_open.connect(ui_change)
	#Globals.open_inventory.connect(open_inventory)

func ui_change(pos,data,id):
	print("id ",id, "your ",multiplayer.get_unique_id())
	if multiplayer.get_unique_id() == id: return
	
	for child in container.get_children():
		if "id" in child:
			if child.id == pos:
				child.open_with_meta(JSON.parse_string(data))
	show()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		
			
		if visible:
			#Globals.save_player_ui.emit()
			GlobalAnimation._tween(self,"bounce_in",.2)
			Globals.paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			for i in spawned:
				var hold_i = i
				i.queue_free()
				spawned.erase(hold_i)
				
			Globals.closed_inventory.emit()
			GlobalAnimation._tween(self,"bounce_out",.4)
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func open_inventory(id:Vector3) -> void:
	#Globals.save_player_ui.emit()
	#for i in h_box_container.get_children():
		#if "id" in i:
			#if i.id == id:
				#i.open() ## opens the subinventory that has the same id
			#elif i.id != Vector3.ZERO:
				#i.hide() 
	show() ## opens the inventory holder
	
	if visible:
		GlobalAnimation._tween(self,"bounce_in",.2)
		Globals.paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Globals.closed_inventory.emit()
		Globals.paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
