extends PanelContainer

@export var input_button_scene: PackedScene
@onready var action_list = $MarginContainer/VBoxContainer/ScrollContainer/ActionList

var is_remapping = false
var action_to_remap = null
var remapping_button = null

var input_actions = {
	"Foward": "Move forward",
	"Backward": "Move backward",
	"Right": "Move right",
	"Left": "Move left",
	"Crouch": "Crouch",
	"Jump": "Jump",
	"Mine": "Mine",
	"Build": "Build",
	"Start": "Pause",
	"Sprint": "Run",
	"Inventory": "Inventory",
	"console_toggle": "Console",
	"chat": "Text Chat",
}


func _ready() -> void:
	_create_action_list()


func _create_action_list() -> void:
	InputMap.load_from_project_settings()
	for item in action_list.get_children():
		item.queue_free()
	
	for action in input_actions:
		var button = input_button_scene.instantiate()
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" (Physical)")
		else:
			input_label.text = ""
			
		action_list.add_child(button)
		button.pressed.connect(_on_input_butt_pressed.bind(button,action))


func _on_input_butt_pressed(button: Node3D, action: StringName) -> void:
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press key to bind..."


func _input(event: InputEvent) -> void:
	if is_remapping:
		if (
			event is InputEventKey ||
			(event is InputEventMouseButton && event.pressed)
		):
			InputMap.action_erase_events(action_to_remap)
			InputMap.action_add_event(action_to_remap, event)
			_update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			accept_event()


func _update_action_list(button: Node3D, event: InputEvent) -> void:
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")


func _on_reset_button_pressed() -> void:
	_create_action_list()
