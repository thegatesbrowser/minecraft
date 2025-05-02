extends CanvasLayer

@export var enabled: bool :
	get:
		return visible
	set(value):
		visible = value
		counter.enabled = value
@onready var counter = $Counter


# Register the FPS counter with a console if the console exists.
func _ready():
	if $"/root".has_node("Console"):
		$"/root".get_node("Console").add_command("fps", self, 'toggle_enabled')\
				.set_description("Enables or disables the FPS counter.")\
				.register()
	
	enabled = false


func toggle_enabled():
	enabled = !enabled
