extends PanelContainer

@onready var message_edit: LineEdit = $MarginContainer/VBoxContainer/message_edit
@onready var message_display: TextEdit = $"MarginContainer/VBoxContainer/message display"

var server_messages: Array[String] = []


func open_messages() -> void:
	check_server.rpc_id(1)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("chat"):
		visible = !visible
		if visible:
			message_edit.set_focus_mode(Control.FOCUS_ALL)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Globals.paused = true
			open_messages()
		else:
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_line_edit_text_submitted(new_text: String) -> void:
	message_display.text += str(new_text,"\n")
	message_display.text = ""
	
	send_to_server.rpc_id(1,new_text)
	check_server.rpc_id(1)


@rpc("any_peer","call_local")
func send_to_server(text: String) -> void:
	if multiplayer.is_server():
		server_messages.append(text)


@rpc("any_peer","call_local")
func check_server() -> void:
	if multiplayer.is_server():
		send_to_clients.rpc(server_messages)


@rpc("any_peer","call_local")
func send_to_clients(messages: Array[String]) -> void:
	message_display.text = ""
	for message in messages:
		message_display.text += str(message,"\n")
