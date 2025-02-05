extends Control

@onready var chunk_radius = $SC/CC/VBC/Chunk_Radius
@onready var max_unloaded_chunks = $SC/CC/VBC/Max_Unloaded_Chunks
@onready var thread_count = $SC/CC/VBC/Thread_Count
@onready var custom_button = $SC/CC/VBC/Performance_Label_Container/Custom
@onready var fog_button = $SC/CC/VBC/CC/VB/Fog
@onready var single_threaded_button = $SC/CC/VBC/CC/VB/Single_Threaded
@onready var splash_image = $Splash_Image
@onready var scroll = $SC
enum {POTATO, LOW, MEDIUM, HIGH, EXTREME, CUSTOM}
const preset_names = ["Potato", "Low", "Medium", "High", "F", "Custom"]
@export var splash_sayings: PackedStringArray = [""]

@export var splash_images: Array[Resource]
@export var chunk_radius_presets :Array[int]= [6, 16, 32, 48, 97]
@export var chunk_max_unload_presets :Array[float]= [2., 2., 1., 0.5, 1.]
@export var percent_of_threads_used :Array[float]= [0., 0.25, 0.5, 0.75, 1.]
@export var fog_enabled :Array[bool]= [false, true, true, true, true]
var unloaded_chunks_modifier := 1.0
var max_threads
var setting_preset := false
var large_chunks := false


func _ready():
	if Globals.skip_menu:
		_start_game()
		return
	setting_preset = true
	
	max_threads = OS.get_processor_count()
	thread_count.set_limits(1, max_threads)
	
	if _parse_cmd_args():
		return
	else:
		_change_settings(LOW)
	
	# Set up splash screen.
	var saying = splash_sayings[randi() % splash_sayings.size()]
	$"CenterContainer/Title/Splash".text = saying
	$AnimationPlayer.play("Splash")


func _parse_cmd_args() -> bool:
	var args := OS.get_cmdline_args()
	if args.size() <= 1:
		print("""
You can use command line args to run a test automatically.

The first argument needs to be "static" or "dynamic".
	--dynamic - starts a dynamic test with the specified settings.
	--static - starts a static test with the specified settings.
	
Additional Arguments are as follows:
	
	--chunk=X - select the chunk type to test.
		0: None,       Just pre-generate the world.
		1: Bad,        Try to generate each block as an object in the scene tree.
		2: Server*,    Use Godot's RenderingServer directly.
		3: Mesh,       Generate the triangles for the chunk yourself.
		4: TileSet,    Use a GridMap (3D tile set) for each chunk.
		5: MultiMesh*, Draw one cube thousands of times thanks to GPU instancing magic!
			* Chunk type lacks collision.
	
	--world_seed=X - sets the seed for world generation.
		Setting this to 0 or leaving unset will result in a random seed being used.
	
	--preset=X - select a performance preset to use.
		0: Potato, 2 chunk radius, 32 stale chunks, 1 thread.
		1: Low,    8 chunk radius, 512 stale chunks, 25% of your CPU's thread count.
		2: Medium, 24 chunk radius, 4304 stale chunks, 50% of your CPU's thread count.
		3: High,   48 chunk radius, 4608 stale chunks, 75% of your CPU's thread count.
		4: F,      97 chunk radius, 37636 stale chunks, 100% of your CPU's thread count.
	
	--chunk_radius=X - override the chunk radius for the test.
	
	--thread_count=X - select the number of threads to use.
		It is recommended that you don't use more threads than your CPU has.
		For example, checked a 4 core processor with hyperthreading, 8 is the
		maximum recommended thread count.
	
	--large_chunks - use 64x64 size chunks instead of 16x16
	
	--single_thread - render all chunks checked the main thread instead of in the chunk generation threads.
	
	--file_name=X - override the name of the output file for the test.
		The default file name is MineMark_*RevIdentifier*_*TestType*_*ReleaseMode*_*Date*
		RevIdentifier is a string defined in the DebugOverlay Scene on export
		TestType is Static_Test or Dynamic_Test
		Release Mode is E for editor, D for debug build and R for release build
		Date is the datetime string YYYY-MM-DD_HH.MM.SS
	
	--no_flicker - disables the chunk generation scanlines, which can cause timelapses to flicker.
			""")
		return false
	
	# Display help
	if args[0].to_lower().find("dynamic") >= 0:
		Globals.test_mode = Globals.TestMode.RUN_LOAD
	elif args[0].to_lower().find("static") >= 0:
		Globals.test_mode = Globals.TestMode.STATIC_LOAD
	else:
		print("ERROR: Command Line parameters are invalid!")
		get_tree().quit()
		return false
	
	args.remove_at(0)
	var arguments = {}
	for argument in args:
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			var key = key_value[0].lstrip("--").to_lower()
			if key == "file_name":
				Globals.test_file = key_value[1]
			else:
				arguments[key] = key_value[1].to_int()
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--").to_lower()] = ""
	
	if arguments.has("preset"):
		_on_Settings_Preset_pressed(arguments["preset"])
	
	if arguments.has("chunk"):
		_on_Chunk_Type_pressed(arguments["chunk"])
	
	if arguments.has("world_seed"):
		Globals.world_seed = arguments["world_seed"]
	
	if arguments.has("thread_count"):
		_on_Thread_Count_changed(arguments["thread_count"])
	
	if arguments.has("no_flicker"):
		Globals.repaint_line = false
	
	if arguments.has("large_chunks"):
		_on_Large_Chunks_toggled(true)
	
	if arguments.has("single_thread"):
		Globals.single_threaded_render = true
	
	if arguments.has("chunk_radius"):
		Globals.load_radius = arguments["chunk_radius"]
	
	_start_game()
	return true


func _input_event(event):
	if event.is_pressed() and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll.scroll_vertical -= 5
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll.scroll_vertical += 5


func _change_settings(preset: int):
	if preset < 0 or preset >= preset_names.size():
		Print.error("There is no settings preset %s!" % preset)
		return
	
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
	fog_button.button_pressed = fog_enabled[preset]
	single_threaded_button.button_pressed = false
	setting_preset = false


func _check_for_custom_preset():
	if !setting_preset:
		custom_button.button_pressed = true
		Globals.settings_preset = preset_names[CUSTOM]


func _recompute_max_stale_chunks(load_radius: float):
	var chunks_in_radius = pow((load_radius * 2), 2)
	var min_stale = load_radius * 4
	var max_stale = max(1024, chunks_in_radius * 4)
	max_unloaded_chunks.set_limits(min_stale, max_stale, load_radius * 4)
	max_unloaded_chunks.set_value(chunks_in_radius * unloaded_chunks_modifier)


func _start_game():
	var _d = get_tree().change_scene_to_file("res://Game.tscn")


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
	update_block_radius(value * 16)


func update_block_radius(value):
	value = max(1, value / Globals.chunk_size.x)
	_recompute_max_stale_chunks(value)
	Globals.load_radius = value
	Print.from(0, "Chunk Radius changed to %d." % value, Print.DEBUG)


func _on_Max_Unloaded_Chunks_changed(value):
	_check_for_custom_preset()
	Globals.max_stale_chunks = value
	Print.from(0, "Max Stale Chunk Count changed to %d." % value, Print.DEBUG)


func _on_Thread_Count_changed(value):
	_check_for_custom_preset()
	Globals.chunk_loading_threads = value
	Print.from(0, "Thread count changed to %d." % value, Print.DEBUG)


func _on_Fog_toggled(button_pressed):
	_check_for_custom_preset()
	Globals.no_fog = !button_pressed
	Print.from(0, "Fog set to %s." % button_pressed, Print.DEBUG)


func _on_SingleThreaded_toggled(button_pressed):
	_check_for_custom_preset()
	Globals.single_threaded_render = button_pressed
	Print.from(0, "Single threaded mode set to %s" % button_pressed, Print.DEBUG)


# Non-performance settings.
func _on_Invert_Mouse_toggled(button_pressed):
	Globals.mouse_invert_look = button_pressed
	Print.from(0, "Mouse inversion set to %s" % button_pressed, Print.DEBUG)


func _on_Invert_Controller_toggled(button_pressed):
	Globals.controller_invert_look = button_pressed
	Print.from(0, "Controller inversion set to %s" % button_pressed)


func _on_Chunk_Type_pressed(type):
	if type < 0 or type >= splash_images.size():
		Print.error("There is no settings preset %s!" % type)
		return
	Print.from(0, "Selected chunk type %s" % type, Print.DEBUG)
	splash_image.texture = splash_images[type]
	Globals.chunk_type = type
	Globals.flying = (type == 0)


func _on_Skyblock_toggled(button_pressed):
	Globals.skyblock = button_pressed


func _on_Large_Chunks_toggled(button_pressed):
	var radius = Globals.load_radius * Globals.chunk_size.x
	large_chunks = button_pressed
	if large_chunks:
		Globals.chunk_size = Vector3(64, Globals.chunk_size.y, 64)
	else:
		Globals.chunk_size = Vector3(16, Globals.chunk_size.y, 16)
	update_block_radius(radius)
