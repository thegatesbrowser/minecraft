extends Control

# Seconds of frame data to track.
var average_timespan := 10

# Cumulative Stats over multiple seconds.
var latest := 0
var cum_highest := 0
var cum_lowest := INF
var cum_average := 0

# Stats within a single second.
var frames := 0
var highest := 0
var lowest := INF

var enabled := true
var stats := []

@onready var label = $MarginContainer/Label


func _process(_delta):
	if enabled:
		# Measure frames per second directly every second.
		frames += 1
		
		# Update the buffer.
		var fps = Engine.get_frames_per_second()
		if fps > 0 and fps < 999:
			if fps < lowest:
				lowest = fps
			if fps > highest:
				highest = fps


func _update_stats():
	latest = frames
	stats.push_back(Vector3(lowest, latest, highest))
	if stats.size() > average_timespan:
		var _d = stats.pop_front()
	
	var total := 0
	cum_lowest = INF
	cum_highest = 0
	
	for i in stats:
		if i.x < cum_lowest:
			cum_lowest = i.x
		total += i.y
		if i.z > cum_highest:
			cum_highest = i.z
	cum_average = min(cum_highest, total / stats.size())
	
	frames = 0
	highest = 0
	lowest = INF


func _update_label():
	label.text = \
		"Cur. FPS: %3.0f" % latest + \
		"\nMinimum: %3.0f" % cum_lowest + \
		"\nMaximum: %3.0f" % cum_highest + \
		"\nAverage: %3.0f" % cum_average


func _on_Timer_timeout():
	if frames > 0:
		_update_stats()
		_update_label()
