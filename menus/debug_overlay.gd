extends Control

enum Chunk_Statistics { INVALID, STARTED, GENERATED, ACTIVE, INACTIVE, PURGED }

@export var chunk_invalid_color := Color.BLACK
@export var chunk_started_color := Color.YELLOW
@export var chunk_generated_color := Color.CYAN
@export var chunk_active_color := Color.CHARTREUSE
@export var chunk_inactive_color := Color.GRAY
@export var chunk_purged_color := Color.CRIMSON
@export var chunk_map_size := 400.0

@onready var grid := $HBoxContainer/MarginContainer/GridContainer
@onready var timing_stats_label = $HBoxContainer/MarginContainer2/Timing_Stats
@onready var chunk_counts_label = $HBoxContainer/MarginContainer3/Chunk_Counts
@onready var fps = $MarginContainer4/Counter
@onready var player_pos_label = $Player_Pos
@onready var chunks = $"../../Chunks"


var grid_width := 1
var screen_radius := 1
var chunk_rects := []
var chunk_stats := {}
var row_to_render := 0
var render_tint := 0.0
var time_since_repaint := 0.0

var generate_time_min := INF
var generate_time_max := 0.0
var generate_time_total := 0.0
var generate_count := 0

var update_time_min := INF
var update_time_max := 0.0
var update_time_total := 0.0
var update_count := 0

var num_generated := 0
var num_updated := 0
var num_loaded_from_cache := 0
var num_unloaded := 0
var num_purged := 0

var num_active := 0
var num_unrendered := 0
var num_inactive := 0

var test_active := false
var test_ending := false
var test_time := 0
var test_end_countdown := 3
var watchdog_elapsed := true

# Test file things.
var test_log_file : FileAccess
const test_header = "Test_Time,Min Chunk Gen Time,Max Chunk Gen Time,Avg Chunk Gen Time," + \
		"Min Chunk Render Time,Max Chunk Render Time,Avg Chunk Render Time," + \
		"# Chunks Generated,# Chunks Updated,# Chunks Disabled,# Chunks Purged," + \
		"Active Chunk Count,Inactive Chunk Count,Chunk Generation Radius," + \
		"Total Memory Used (KiB),Memory Per Chunk (KiB) - Estimated,Min FPS,Max FPS,Avg FPS,Test Status"
const test_types := ["none", "Static", "Dynamic", "Manual"]
const chunk_types := ["No Render", "Simple", "Server", "Mesh", "Tile Set", "Multimesh"]
@export var code_revision_identifier := "_final"


func _ready():
	#Console.add_command("toggle_debug_overlay", self, 'toggle_enabled')\
			#.set_description("Enables or disables the Debugging Overlay.")\
			#.register()
	
	# Limit the grid width to prevent the FPS from dropping too far.
	grid_width = min(200, ((Globals.load_radius + 1) * 2) + 1)
	screen_radius = Globals.load_radius + 1
	grid.columns = grid_width
	
	var map_size = ceil(chunk_map_size / (grid_width + 1))
	var margin = $HBoxContainer/MarginContainer
	margin.add_theme_constant_override("offset_top", map_size)
	margin.add_theme_constant_override("offset_left", map_size)
	margin.add_theme_constant_override("offset_right", map_size)
	margin.add_theme_constant_override("offset_bottom", map_size)
	$HBoxContainer/MarginContainer2.add_theme_constant_override("offset_top", map_size)
	$HBoxContainer/MarginContainer2.add_theme_constant_override("offset_right", map_size)
	$HBoxContainer/MarginContainer3.add_theme_constant_override("offset_top", map_size)
	$MarginContainer4.add_theme_constant_override("offset_top", map_size)
	$MarginContainer4.add_theme_constant_override("offset_right", min(map_size * 2, 40))
	
	chunk_rects.resize(grid_width)
	for i in range(grid_width):
		chunk_rects[i] = []
		for _j in range(grid_width):
			var rect = ColorRect.new()
			rect.color = chunk_invalid_color
			rect.custom_minimum_size = Vector2(map_size, map_size)
			
			grid.add_child(rect)
			chunk_rects[i].append(rect)
	
	if Globals.test_mode != Globals.TestMode.NONE:
		test_active = true
		var mode = "Release"
		if OS.has_feature("editor"):
			mode = "Editor"
		elif OS.has_feature("debug"):
			mode = "Debug"
		
		#if Print.get_logger("Global").print_level < Print.INFO:
			#Print.get_logger("Global").print_level = Logger.LogLevel.INFO
		#Print.from(0, "Test is using preset %s." % Globals.settings_preset, Print.INFO)
		
		var args = ""
		for arg in OS.get_cmdline_args():
			if !arg.contains("res:"):
				args += " " + arg
		if Globals.test_file == null:
			Globals.test_file = "MineMark%s_%s_Test_%s_%s" % \
				[code_revision_identifier, test_types[Globals.test_mode], mode[0],
				Time.get_datetime_string_from_system().replace("T","_").replace(":",".")]
		test_log_file = FileAccess.open("user://" + Globals.test_file + ".csv", FileAccess.WRITE)
		var extra_info = ",Preset: %s, Chunk Type: %s,Release Mode: %s, Time interval: %s seconds, Args: %s" % \
				[Globals.settings_preset, chunk_types[Globals.chunk_type], mode, $Reset_Timer.wait_time, args]
		test_log_file.store_line(test_header + extra_info)
		test_log_file.flush()


func _notification(what):
	if what == MainLoop.NOTIFICATION_CRASH:
		_end_test("Game Crashed - Unknown Reason")


func update_chunks():
	# Update the chunk graph.
	if !visible:
		return
	
	
	# Update the chunk statistics.
	if num_updated > 0: # Avoid divide by zero errors.
		var memory_print = ""
		if OS.is_debug_build():
			@warning_ignore("integer_division")
			var mem_kb = OS.get_static_memory_usage() / 1024
			@warning_ignore("integer_division")
			var mem_per_chunk = mem_kb / (num_active + num_inactive)
			@warning_ignore("integer_division")
			memory_print = "Total Memory Used: %s MiB " % (mem_kb / 1024) + \
					"\n Memory Per Chunk:  %s KiB " % mem_per_chunk
		
		timing_stats_label.text = \
				"\n Chunk Generation Times:       " + \
				"\n     Min: " + _to_seconds_string(generate_time_min) + \
				"\n     Max: " + _to_seconds_string(generate_time_max) + \
				"\n     Avg: " + _to_seconds_string(generate_time_total / generate_count) + \
				"\n\n Chunk Render Times:         " + \
				"\n     Min: " + _to_seconds_string(update_time_min) + \
				"\n     Max: " + _to_seconds_string(update_time_max) + \
				"\n     Avg: " + _to_seconds_string(update_time_total / update_count) + \
				"\n\n " + memory_print +\
				"\n\n Chunk_Generation_Threads: %s" % chunks.active_threads.size() + \
				"\n Chunk_Generate_Radius: %s\n" % chunks.generate_radius
		chunk_counts_label.text = \
				"\n Chunks Awaiting Render: %s" % num_unrendered + \
				"\n Chunks Active:          %s" % num_active + \
				"\n Chunks Disabled:        %s\n" % num_inactive + \
				"\n Total Chunks Generated:  %s  " % num_generated + \
				"\n Total Chunks Rendered:   %s" % num_updated + \
				"\n Total Chunks Unloaded:   %s" % num_unloaded + \
				"\n Total Chunks Purged:     %s" % num_purged + \
				"\n T. Chunks Re-Activated:  %s\n" % num_loaded_from_cache + "\n"


func update_player_pos(pos: Vector3):
	pos = pos.floor()
	player_pos_label.text = "Player Pos:\n%3.0f,%3.0f,%3.0f" % [pos.x - 8, -pos.z + 8, pos.y]


func toggle_enabled():
	visible = !visible


func repaint(player_pos: Vector2, delta):
	time_since_repaint += delta
	
	# Pause checked the first row if we're re-painting too quickly.
	if row_to_render == 0:
		if time_since_repaint >= 0.5:
			time_since_repaint = 0
		else:
			return
	
	# Repaint one row at a time, we were affecting the framerate otherwise.
	_repaint_row(player_pos, row_to_render)
	row_to_render += 1
	if row_to_render >= grid_width:
		row_to_render = 0
		if Globals.repaint_line:
			render_tint = 0.05 - render_tint


func _repaint_row(player_pos: Vector2, i):
	for j in range(grid_width):
		var id = Vector2(j - screen_radius + player_pos.x, i - screen_radius + player_pos.y)
		
		if chunk_stats.has(id):
			match chunk_stats[id]:
				Chunk_Statistics.INVALID:
					chunk_rects[i][j].color = chunk_invalid_color.lightened(render_tint)
				Chunk_Statistics.STARTED:
					chunk_rects[i][j].color = chunk_started_color
				Chunk_Statistics.GENERATED:
					chunk_rects[i][j].color = chunk_generated_color
				Chunk_Statistics.ACTIVE:
					chunk_rects[i][j].color = chunk_active_color
				Chunk_Statistics.INACTIVE:
					chunk_rects[i][j].color = chunk_inactive_color
				Chunk_Statistics.PURGED:
					chunk_rects[i][j].color = chunk_purged_color
			if i == screen_radius or j == screen_radius:
				chunk_rects[i][j].color = chunk_rects[i][j].color.darkened(0.15)
		else:
			chunk_rects[i][j].color = chunk_invalid_color.lightened(render_tint)
			if i == screen_radius or j == screen_radius:
				chunk_rects[i][j].color = chunk_rects[i][j].color.lightened(0.05)


func _end_test(status: String):
	test_log_file.store_line(", , , , , , , , , , , , , , , , , , ," + status)
	test_active = false
	get_tree().quit()


func _to_seconds_string(usec: float):
	var sec = usec / 1000000
	return "%.02f" % sec


func _reset_interval():
	var generate_avg = generate_time_total / generate_count
	var update_avg = update_time_total / update_count
	test_time += 5
	
	var test_status := "Good"
	#if fps.cum_highest < 5:
		#test_status = "Low FPS"
	
	# Save the data for the test.
	if Globals.test_mode != Globals.TestMode.NONE:
		@warning_ignore("integer_division")
		var mem_kb = OS.get_static_memory_usage() / 1024
		@warning_ignore("integer_division")
		var mem_per_chunk = mem_kb / (num_active + num_inactive)
		@warning_ignore("integer_division", "standalone_expression")
		var interval_string = "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [test_time,
				_to_seconds_string(generate_time_min), _to_seconds_string(generate_time_max),
				_to_seconds_string(generate_avg), _to_seconds_string(update_time_min),
				_to_seconds_string(update_time_max), _to_seconds_string(update_avg),
				num_generated, num_updated, num_unloaded, num_purged, num_active, num_inactive,
				chunks.generate_radius, mem_kb, mem_per_chunk,
				fps.cum_lowest, fps.cum_highest, fps.cum_average, test_status]
		
		num_generated = 0
		num_updated = 0
		num_unloaded = 0
		
		test_log_file.store_line(interval_string)
		test_log_file.flush()
		
		if Globals.test_mode == Globals.TestMode.RUN_LOAD:
			if num_purged >= min(500, Globals.max_stale_chunks):
				_end_test("Dynamic Test Complete")
		else:
			num_purged = 0
		
		# End state for static test.
		if test_ending and num_unrendered == 0:
			if test_end_countdown <= 0:
				_end_test("Static Test Complete")
			else:
				test_end_countdown -= 1
		
		# Abort if we're exceeding all system resources.
		if fps.cum_highest < 3:
			#Print.error("Max Framerate is less than 3 FPS! Quitting test due to poor performance!")
			_end_test("Failed - Framerate!")
	
	generate_time_max = generate_avg
	generate_time_min = generate_avg
	generate_time_total = generate_avg
	generate_count = 1

	update_time_max = update_avg
	update_time_min = update_avg
	update_time_total = update_avg
	update_count = 1


func _on_Reset_Timer_timeout():
	_reset_interval()
	if watchdog_elapsed and test_active and !test_ending and Globals.test_mode != Globals.TestMode.RUN_MANUAL:
		#Print.error("Test failed - No chunks have been generated for the past 10 seconds.")
		_end_test("Failed - Watchdog Timeout")
	watchdog_elapsed = true


func _on_Chunks_chunk_started(pos):
	chunk_stats[pos] = Chunk_Statistics.STARTED
	watchdog_elapsed = false


func _on_Chunks_chunk_generated(pos, gen_time):
	chunk_stats[pos] = Chunk_Statistics.GENERATED
	if gen_time < generate_time_min:
		generate_time_min = gen_time
	if gen_time > generate_time_max:
		generate_time_max = gen_time
	generate_time_total += gen_time
	num_generated += 1
	generate_count += 1
	num_unrendered += 1
	watchdog_elapsed = false


func _on_Chunks_chunk_updated(pos, gen_time):
	chunk_stats[pos] = Chunk_Statistics.ACTIVE
	if gen_time < update_time_min:
		update_time_min = gen_time
	if gen_time > update_time_max:
		update_time_max = gen_time
	update_time_total += gen_time
	num_updated += 1
	update_count += 1
	num_unrendered -= 1
	num_active += 1
	watchdog_elapsed = false


func _on_Chunks_chunk_deactivated(pos):
	chunk_stats[pos] = Chunk_Statistics.INACTIVE
	num_unloaded += 1
	num_active -= 1
	num_inactive += 1
	watchdog_elapsed = false


func _on_Chunks_chunk_reactivated(pos):
	chunk_stats[pos] = Chunk_Statistics.ACTIVE
	num_loaded_from_cache += 1
	num_inactive -= 1
	num_active += 1
	watchdog_elapsed = false


func _on_Chunks_chunk_purged(pos):
	chunk_stats[pos] = Chunk_Statistics.PURGED
	num_purged += 1
	num_inactive -= 1
	watchdog_elapsed = false


func _on_Chunks_finished_loading():
	if Globals.test_mode == Globals.TestMode.STATIC_LOAD:
		test_ending = true


func _exit_tree():
	if test_active:
		_end_test("Aborted - Unknown Reason")
