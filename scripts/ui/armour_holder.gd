extends PanelContainer

var equiped:Array[ItemArmour]

@export var slot_holder: VBoxContainer

func _on_pants_item_changed(index: int, item_path: String, amount: int, parent: String, health: float, rot: int) -> void:
	check_all()

func _on_chest_item_changed(index: int, item_path: String, amount: int, parent: String, health: float, rot: int) -> void:
	check_all()

func _on_helment_item_changed(index: int, item_path: String, amount: int, parent: String, health: float, rot: int) -> void:
	check_all()

func check_all():
	equiped.clear()
	for i in slot_holder.get_children():
		if i.item != null:
			equiped.append(i.item)
	caculate_protection()
		
func caculate_protection():
	var protect:int = 0
	for i in equiped:
		protect += i.protect_amount
		
	var players = get_tree().get_first_node_in_group("PlayerContainer")
	for player in players.get_children(): 
		if player.get_multiplayer_authority() == multiplayer.get_unique_id():
			player.protection = protect
