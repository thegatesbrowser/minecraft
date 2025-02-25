extends HBoxContainer

@onready var health_bar: ProgressBar = $VBoxContainer2/Health


func _ready() -> void:
	health_bar.max_value = Globals.max_health
	health_bar.value = Globals.player_health

func _process(delta: float) -> void:
	health_bar.value = Globals.player_health
