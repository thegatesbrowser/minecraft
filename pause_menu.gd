extends PanelContainer

var played_ani:bool = false

func _process(delta: float) -> void:
	
	if Input.is_action_just_pressed("Start"):
		visible = !visible
		
		if visible:
			if !played_ani:
				GlobalAnimation._tween(self,"bounce_in",.2)
				played_ani = true
			show()
		else:
			played_ani = false
			hide()
		
func _on_main_menu_pressed() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://menus/Menu.tscn")
