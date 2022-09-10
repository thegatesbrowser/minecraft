extends Control

enum Chunk_Statistics { INVALID, STARTED, GENERATED, ACTIVE, INACTIVE, PURGED }

class General_Stats:
	var stuff


export var chunk_invalid_color := Color.black
export var chunk_started_color := Color.yellow
export var chunk_generated_color := Color.cyan
export var chunk_active_color := Color.chartreuse
export var chunk_inactive_color := Color.gray
export var chunk_purged_color := Color.crimson
export var chunk_map_size := 400.0

onready var grid := $HBoxContainer/MarginContainer/GridContainer
onready var timing_stats_label = $HBoxContainer/MarginContainer2/Timing_Stats
onready var chunk_counts_label = $HBoxContainer/MarginContainer3/Chunk_Counts
onready var chunks = $"../../Chunks"


var grid_width := 1
var screen_radius := 1
var chunk_rects := []
var chunk_stats := {}

var generate_time_min := INF
var generate_time_max := 0
var generate_time_total := 0.0
var generate_count := 0

var update_time_min := INF
var update_time_max := 0
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


func _ready():
	Console.add_command("toggle_debug_overlay", self, 'toggle_enabled')\
			.set_description("Enables or disables the Debugging Overlay.")\
			.register()
	
	grid_width = (Globals.load_radius * 2) + 1
	screen_radius = Globals.load_radius
	grid.columns = grid_width
	
	var rect_size = ceil(chunk_map_size / (grid_width + 1))
	var margin = $HBoxContainer/MarginContainer
	margin.add_constant_override("margin_top", rect_size)
	margin.add_constant_override("margin_left", rect_size)
	margin.add_constant_override("margin_right", rect_size)
	margin.add_constant_override("margin_bottom", rect_size)
	$HBoxContainer/MarginContainer2.add_constant_override("margin_top", rect_size)
	$HBoxContainer/MarginContainer2.add_constant_override("margin_right", rect_size)
	$HBoxContainer/MarginContainer3.add_constant_override("margin_top", rect_size)
	$MarginContainer4.add_constant_override("margin_top", rect_size)
	$MarginContainer4.add_constant_override("margin_right", rect_size * 2)
	
	chunk_rects.resize(grid_width)
	for i in range(grid_width):
		chunk_rects[i] = []
		for _j in range(grid_width):
			var rect = ColorRect.new()
			rect.color = chunk_invalid_color
			rect.rect_min_size = Vector2(rect_size, rect_size)
			grid.add_child(rect)
			chunk_rects[i].append(rect)


func update_chunks(player_pos: Vector2):
	# Update the chunk graph.
	for i in range(grid_width):
		for j in range(grid_width):
			var id = Vector2(j - screen_radius + player_pos.x, i - screen_radius + player_pos.y)
			
			if chunk_stats.has(id):
				match chunk_stats[id]:
					Chunk_Statistics.INVALID:
						chunk_rects[i][j].color = chunk_invalid_color
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
			else:
				chunk_rects[i][j].color = chunk_invalid_color
			
			if i == screen_radius or j == screen_radius:
				chunk_rects[i][j].color = chunk_rects[i][j].color.darkened(0.2)
	
	# Update the chunk statistics.
	if num_updated > 0: # Avoid divide by zero errors.
		var memory_print = ""
		if OS.is_debug_build():
# warning-ignore:integer_division
			var mem_kb = OS.get_static_memory_usage() / 1024
# warning-ignore:integer_division
			var mem_per_chunk = mem_kb / (num_active + num_inactive)
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


func toggle_enabled():
	visible = !visible


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


func _to_seconds_string(usec: float):
	var sec = usec / 1000000
	return "%.02f" % sec


func _reset_interval():
	var generate_avg = generate_time_total / generate_count
	generate_time_max = generate_avg
	generate_time_min = generate_avg
	generate_time_total = generate_avg
	generate_count = 1

	var update_avg = update_time_total / update_count
	update_time_max = update_avg
	update_time_min = update_avg
	update_time_total = update_avg
	update_count = 1


func _on_Chunks_chunk_deactivated(pos):
	chunk_stats[pos] = Chunk_Statistics.INACTIVE
	num_unloaded += 1
	num_active -= 1
	num_inactive += 1


func _on_Chunks_chunk_purged(pos):
	chunk_stats[pos] = Chunk_Statistics.PURGED
	num_purged += 1
	num_inactive -= 1


func _on_Chunks_chunk_reactivated(pos):
	chunk_stats[pos] = Chunk_Statistics.ACTIVE
	num_loaded_from_cache += 1
	num_inactive -= 1
	num_active += 1


func _on_Reset_Timer_timeout():
	_reset_interval()


func _on_Chunks_chunk_started(pos):
	chunk_stats[pos] = Chunk_Statistics.STARTED
