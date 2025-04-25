extends Node

@export var update_time:float = 10.0
var update_timer:Timer = Timer.new()

var enabled:bool = false

func  _ready() -> void:
	update_timer.wait_time = update_time
	update_timer.start()
	update_timer.timeout.connect()
	


func update():
	#get_parent().
	pass
