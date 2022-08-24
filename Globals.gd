extends Node

# Chunk Generation Settings.
export var chunk_size := Vector3(16, 256, 16)
export var load_radius := 5
export var unload_radius := 6

# Configurable setting based on user's hardware.
export var max_game_memory_gb := 1

# Physics settings.
export var gravity := 20

# Player Settings.
export var speed := 10
export var jump_speed := 10
export var mouse_sensitivity := Vector2(0.3, 0.3)
export var controller_sensitivity := Vector2(5, 2)
export var max_look_vertical := 75
export var controller_invert_look := false
export var mouse_invert_look := false
