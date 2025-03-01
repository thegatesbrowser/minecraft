extends PanelContainer

var server_messages = []

func open_messages():
	check_server.rpc_id(1)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("chat"):
		visible = !visible
		if visible:
			$VBoxContainer/LineEdit.set_focus_mode(Control.FOCUS_ALL)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Globals.paused = true
			open_messages()
		else:
			Globals.paused = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
func _on_line_edit_text_submitted(new_text: String) -> void:
	$VBoxContainer/TextEdit.text += str(new_text,"\n")
	$VBoxContainer/TextEdit.text = ""
	send_to_server.rpc(new_text)
	
@rpc("any_peer","call_local")
func send_to_server(text):
	if multiplayer.is_server():
		server_messages.append(text)
		#print(text)
	
@rpc("any_peer","call_local")
func check_server():
	if multiplayer.is_server():
		send_to_clients.rpc(server_messages)
		#print(server_messages)
		
@rpc("any_peer","call_local")
func send_to_clients(messages):
	$VBoxContainer/TextEdit.text = ""
	for message in messages:
		$VBoxContainer/TextEdit.text += str(message,"\n")
