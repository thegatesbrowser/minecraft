extends AudioStreamPlayer

@export var chance: float = 0.4

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _on_timer_timeout() -> void:
	if rng.randf() < chance:
		if playing == false:
			play()
