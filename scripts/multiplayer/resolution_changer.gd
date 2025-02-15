extends Node


func _ready() -> void:
	if DisplayServer.screen_get_scale() == 2.0:
		get_viewport().scaling_3d_scale = 0.75
		get_window().content_scale_factor = 1.33333
		Debug.log_msg("Retina display. Change scaling")
