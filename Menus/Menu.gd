extends CenterContainer


onready var chunk_radius = $ScrollContainer/VBoxContainer/Chunk_Radius
onready var max_unloaded_chunks = $ScrollContainer/VBoxContainer/Max_Unloaded_Chunks
onready var thread_count = $ScrollContainer/VBoxContainer/Thread_Count
onready var custom_button = $ScrollContainer/VBoxContainer/HBoxContainer/Custom
onready var fog_button = $ScrollContainer/VBoxContainer/Other_Settings/Fog
onready var single_threaded_button = $ScrollContainer/VBoxContainer/Other_Settings/Single_Threaded
enum {POTATO, LOW, MEDIUM, HIGH, EXTREME, CUSTOM}
const preset_names = ["Potato", "Low", "Medium", "High", "F", "Custom"]

export var chunk_radius_presets := [6, 16, 32, 48, 97]
export var chunk_max_unload_presets := [2, 2, 2, 1, 0.5]
export var percent_of_threads_used := [0, 0.25, 0.5, 0.75, 1]
export var fog_enabled = [false, true, true, true, true]
var unloaded_chunks_modifier := 1.0
var max_threads
var setting_preset := false


func _ready():
	setting_preset = true
	max_threads = OS.get_processor_count()
	thread_count.set_limits(1, max_threads)
	_change_settings(HIGH)


func _change_settings(preset: int):
	setting_preset = true
	Globals.settings_preset = preset_names[preset]
	
	match preset:
		POTATO, LOW, MEDIUM, HIGH:
			chunk_radius.set_limits(2, 64)
		EXTREME:
			chunk_radius.set_limits(3, 111)
		CUSTOM:
			return
	
	# Common settings for all presets but custom.
	unloaded_chunks_modifier = chunk_max_unload_presets[preset]
	chunk_radius.set_value(chunk_radius_presets[preset])
	thread_count.set_value(max_threads * percent_of_threads_used[preset])
	fog_button.pressed = fog_enabled[preset]
	single_threaded_button.pressed = false
	setting_preset = false


func _check_for_custom_preset():
	if !setting_preset:
		custom_button.pressed = true
		Globals.settings_preset = preset_names[CUSTOM]


func _recompute_max_stale_chunks(load_radius: float):
	var chunks_in_radius = pow((load_radius * 2), 2)
	var min_stale = load_radius * 4
	var max_stale = max(1024, chunks_in_radius * 4)
	max_unloaded_chunks.set_limits(min_stale, max_stale, load_radius * 4)
	max_unloaded_chunks.set_value(chunks_in_radius * unloaded_chunks_modifier)


func _start_game():
	var _d = get_tree().change_scene("res://Game.tscn")


# Start game signals.
func _on_Play_pressed():
	Globals.test_mode = Globals.TestMode.NONE
	_start_game()


func _on_Test_Static_pressed():
	Globals.test_mode = Globals.TestMode.STATIC_LOAD
	_start_game()


func _on_Test_Dynamic_pressed():
	Globals.test_mode = Globals.TestMode.RUN_LOAD
	_start_game()


func _on_Test_Manual_pressed():
	Globals.test_mode = Globals.TestMode.RUN_MANUAL
	_start_game()


# Change Preset.
func _on_Settings_Preset_pressed(preset):
	_change_settings(preset)


# Change Specific Setting.
func _on_Chunk_Radius_changed(value):
	_check_for_custom_preset()
	_recompute_max_stale_chunks(value)
	Globals.load_radius = value
	Print.debug("Chunk Radius changed to %d." % value)


func _on_Max_Unloaded_Chunks_changed(value):
	_check_for_custom_preset()
	Globals.max_stale_chunks = value
	Print.debug("Max Stale Chunk Count changed to %d." % value)


func _on_Thread_Count_changed(value):
	_check_for_custom_preset()
	Globals.chunk_loading_threads = value
	Print.debug("Thread count changed to %d." % value)


func _on_Fog_toggled(button_pressed):
	_check_for_custom_preset()
	Globals.no_fog = !button_pressed
	Print.debug("Fog set to %s." % button_pressed)


func _on_SingleThreaded_toggled(button_pressed):
	_check_for_custom_preset()
	Globals.single_threaded_mode = button_pressed
	Print.debug("Single threaded mode set to %s" % button_pressed)


# Non-performance settings.
func _on_Invert_Mouse_toggled(button_pressed):
	Globals.mouse_invert_look = button_pressed
	Print.debug("Mouse inversion set to %s" % button_pressed)


func _on_Invert_Controller_toggled(button_pressed):
	Globals.controller_invert_look = button_pressed
	Print.debug("Controller inversion set to %s" % button_pressed)
