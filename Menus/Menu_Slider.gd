extends HBoxContainer

signal changed(val)

onready var label = $Label
onready var slider = $HSlider


func set_value(val):
	slider.value = val


func get_value():
	return slider.value


func set_limits(min_value: int, max_value: int, step := 1):
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step


func _on_HSlider_value_changed(val):
	label.text = "%6d" % val
	emit_signal("changed", val)
