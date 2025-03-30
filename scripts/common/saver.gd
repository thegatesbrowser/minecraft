extends Node

var Terrain:VoxelTerrain

var passcode = "dqaduqiqbnmn1863841hjb"
@export var encrypt:bool = false
@export var UIsave_path:String = "res://UISyncer.save"

func _ready() -> void:
	Globals.save_player_ui.connect(save_player_ui)
	if multiplayer.is_server():
		load_inventory()
		
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	Terrain = get_tree().get_first_node_in_group("VoxelTerrain")

func _on_peer_disconnected(_peer_id: int) -> void:
	if multiplayer.get_peers().size() == 0:
		save()
		print("All peers disconnected, saving modified blocks")


func exit_tree() -> void:
	save()
	print("Closing game, saving modified blocks")


func save():
	if multiplayer.is_server():
		save_inventorys()
	Terrain.save_modified_blocks()

func save_inventorys():
	var save_file
	
	if encrypt:
		save_file = FileAccess.open_encrypted_with_pass(UIsave_path, FileAccess.WRITE,passcode)
	else:
		save_file = FileAccess.open(UIsave_path, FileAccess.WRITE)
	
	var node = get_tree().get_first_node_in_group("UISyncer")
	
	# Check the node is an instanced scene so it can be instanced again during load.
	if node.scene_file_path.is_empty():
		print("persistent node '%s' is not an instanced scene, skipped" % node.name)

	# Check the node has a save function.
	if !node.has_method("save"):
		print("persistent node '%s' is missing a save() function, skipped" % node.name)

	# Call the node's save function.
	var node_data = node.call("save")

	# JSON provides a static method to serialized JSON string.
	var json_string = JSON.stringify(node_data)

	# Store the save dictionary as a new line in the save file.
	save_file.store_line(json_string)
		

func load_inventory():
	if not FileAccess.file_exists(UIsave_path):
		return # Error! We don't have a save to load.
	var save_file
	
	if encrypt:
		save_file = FileAccess.open_encrypted_with_pass(UIsave_path, FileAccess.READ,passcode)
	else:
		save_file = FileAccess.open(UIsave_path, FileAccess.READ)
		
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		# Creates the helper class to interact with JSON.
		var json = JSON.new()

		# Check if there is any error while parsing the JSON string, skip in case of failure.
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		# Get the data from the JSON object.
		var node_data = json.data

		var UI_saver = get_tree().get_first_node_in_group("UISyncer")
		
		UI_saver.server_ui_info = node_data["server_ui_info"]
		
func save_player_ui():
	for ui in get_tree().get_nodes_in_group("PlayersUI"):
		if ui.has_method("save"):
			var ui_data = ui.call("save")
			var data = JSON.stringify(ui_data)
			var BackendClient = get_tree().get_first_node_in_group("BackendClient")
			Globals.send_data.emit({"name" : BackendClient.username , "change_name" : ui.name,"change" : data})


func _on_timer_timeout() -> void:
	save_player_ui()
