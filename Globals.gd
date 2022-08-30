extends Node

# Debugging.
enum Level { DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3, CRITICAL = 4 }
export(Print.Level) var print_level := Print.Level.WARNING
export var single_threaded_mode := false
export var capture_mouse_on_start := true
export var no_fog := false

# Chunk Generation Settings.
export var world_seed := 0
export var chunk_size := Vector3(16, 256, 16)
export(int, 1, 50) var load_radius := 5 setget set_load_radius
export(int, 2, 100) var unload_radius := 6 setget set_unload_radius

# Configurable setting based on user's hardware.
export var max_game_memory_gb := 1
export var chunk_loading_threads := 7
export var reduce_radius_on_thread_count_exceeded := true

# Physics settings.
export var gravity := 20

# Player Settings.
export var paused := false
export var speed := 10
export var jump_speed := 10
export var mouse_sensitivity := Vector2(0.3, 0.3)
export var controller_sensitivity := Vector2(5, 2)
export var max_look_vertical := 75
export var controller_invert_look := false
export var mouse_invert_look := false
export var test_mode := true


func _ready():
	Print.level = print_level
	randomize()
	if world_seed == 0:
		world_seed = randi()
	WorldGen.set_seed(world_seed)


func set_load_radius(value):
	load_radius = value
	if unload_radius <= load_radius:
		unload_radius = load_radius + 1

func set_unload_radius(value):
	unload_radius = value
	if load_radius >= unload_radius:
		load_radius = unload_radius - 1
