extends AudioStreamPlayer3D

var rng = RandomNumberGenerator.new()
@export var chance:float = .4


func _on_timer_timeout() -> void:
	if rng.randf() < chance:
		play()
