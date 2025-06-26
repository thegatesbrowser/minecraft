extends Control
class_name Inventory_Holder

@export var h_box_container: HBoxContainer


func _ready() -> void:
	Globals.sync_change_open.connect(ui_change)
	#Globals.open_inventory.connect(open_inventory)
	pass
	pass

func ui_change(pos,data,id):
	print("id ",id, "your ",multiplayer.get_unique_id())
	if multiplayer.get_unique_id() == id: return
	
	for i in h_box_container.get_children():
		if "id" in i:
			if i.id == pos:
				i.open_with_meta(JSON.parse_string(data))
				

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		
		for i in h_box_container.get_children():
			if "sync" in i:
				if i.sync:
					if !visible:
						i.queue_free()
		
		if visible:
			#Globals.save_player_ui.emit()
			GlobalAnimation._tween(self,"bounce_in",.2)
			Globals.paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			GlobalAnimation._tween(self,"bounce_out",.4)
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#
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
		Globals.paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
