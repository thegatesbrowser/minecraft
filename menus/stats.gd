extends HBoxContainer

func _process(delta: float) -> void:
	$VBoxContainer2/Health.value = Globals.player_health
	$VBoxContainer2/Health.max_value = Globals.max_health
