extends Node

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Drop"):
		if Globals.last_clicked_slot != null:
			var item = Globals.last_clicked_slot.Item_resource as ItemBase
			if item != null:
				Globals.drop_item.emit(multiplayer.get_unique_id(),item)
				if Globals.last_clicked_slot.type == "inventory":
					Globals.remove_item.emit(item.unique_name,1)
				else:
					Globals.remove_item_from_hotbar.emit(item.unique_name,1)
				Globals.last_clicked_slot = null
