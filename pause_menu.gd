extends Control

var played_ani: bool


func _process(_delta: float) -> void:
	
	if Input.is_action_just_pressed("Start"):
		visible = !visible
		
		if visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if !played_ani:
				GlobalAnimation._tween(self,"bounce_in",.2)
				played_ani = true
			show()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			$Settings.hide()
			played_ani = false
			hide()


func _on_main_menu_pressed() -> void:
	await get_tree().process_frame
	Globals.paused = false
	get_tree().change_scene_to_file("res://menus/Menu.tscn")


func _on_settings_pressed() -> void:
	$Settings.visible = !$Settings.visible
