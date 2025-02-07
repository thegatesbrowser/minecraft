extends ScrollContainer

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		visible = !visible
		if visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
