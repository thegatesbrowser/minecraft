extends Control

var inventory
var pause_menu
var text_chat 

func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)
	on_visibility_changed()

func _input(_event: InputEvent) -> void:
	# if Input.is_action_just_pressed("show_mouse"): set_captured(false)
	#if Input.is_action_just_released("show_mouse"): set_captured(true)
	pass


func on_visibility_changed() -> void:
	if is_visible_in_tree():
		set_captured(true)
	else:
		set_captured(false)


func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_visible_in_tree():
				set_captured(true)
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			pass


func set_captured(captured: bool) -> void:
	
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func ui_captured(captured: bool, caller = null) -> void:
	if !inventory and !pause_menu and !text_chat:
		inventory = get_node("/root/Main").find_child("Inventory")
		pause_menu = get_node("/root/Main").find_child("Pause_Menu")
		text_chat = get_node("/root/Main").find_child("Text_Chat")
		
	if captured:
		if inventory.visible or text_chat.visible or pause_menu.visible:
			#print(inventory.visible,text_chat.visible,pause_menu.visible)
			return
			
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
