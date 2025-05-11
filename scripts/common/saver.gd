extends Node

var Terrain:VoxelTerrain

var passcode = "dqaduqiqbnmn1863841hjb"

@export var creaturebase = preload("res://scenes/creatures/creature_base.tscn")
@export var encrypt:bool = false
@export var UIsave_path:String = "res://UISyncer.save"
@export var Creature_save_path:String = "res://CreatureSave.save"
@export var ItemManager:Node

func _ready() -> void:
	#Globals.save_player_ui.connect(save_player_ui)
	Globals.save.connect(save_player_ui)
	Globals.save_slot.connect(save_slot)
	
	if multiplayer.is_server():
		load_inventory()
		#load_creatures()
		
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
	#save_creatures()
	Terrain.save_modified_blocks()

func save_inventorys():
	var save_file
	
	if encrypt:
		save_file = FileAccess.open_encrypted_with_pass(UIsave_path, FileAccess.WRITE,passcode)
	else:
		save_file = FileAccess.open(UIsave_path, FileAccess.WRITE)
	
	var node = get_tree().get_first_node_in_group("UISyncer")
	
	## Check the node is an instanced scene so it can be instanced again during load.
	#if node.scene_file_path.is_empty():
		#print("persistent node '%s' is not an instanced scene, skipped" % node.name)

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
			Globals.send_to_server.emit({"name" : BackendClient.username , "change_name" : ui.name,"change" : data})
			#await get_tree().create_timer(2.0).timeout
			#for i in ui_data:
				#var item = ui_data[i].item_path
				#if item == "":
					#continue

func save_slot(index: int, item_path: String, amount: int,parent: String,health: int, rot:int):
	var BackendClient = get_tree().get_first_node_in_group("BackendClient")
	Globals.send_slot_data.emit({"index":index,"item_path":item_path,"amount":amount,"parent":parent,"health":health,"rot":rot,"username":BackendClient.username})
					
					
					
func save_item(item:ItemBase, _buffer=[], size:Vector2 = Vector2.ZERO):
	var data := {}
	var item_data = inst_to_dict(item)
	
	var image = item.texture.get_image()
	
	var buffer = image.save_png_to_buffer()
	
	var BackendClient = get_tree().get_first_node_in_group("BackendClient")
	if BackendClient.playerdata.item_data != null:
		data = JSON.parse_string(BackendClient.playerdata.item_data)
		
	if data.has(item.unique_name):
		if BackendClient.playerdata.Inventory.has(item.unique_name) == false and BackendClient.playerdata.Hotbar.has(item.unique_name) == false:
			data.erase(item.unique_name)
	else:
		data[item.unique_name] = {
			"texture": buffer
		}
	
	
	var save_data = JSON.stringify(data)
	
	## Save This Data
	Globals.send_data.emit({"name" : BackendClient.username , "change_name" : "item_data","change" : save_data})
	#var new_image = Image.new()
	#new_image.load_png_from_buffer(buffer)
	#
	#new_image.save_png("res://buffer.png")
	

	#Saver.save_item(item,buffer,image.get_size())
	
	#ItemManager.create_item.rpc_id(1,item_data,buffer,size)


func save_creatures():
	var save_file
	
	#if encrypt:
		#save_file = FileAccess.open_encrypted_with_pass(Creature_save_path, FileAccess.WRITE,passcode)

	save_file = FileAccess.open(Creature_save_path, FileAccess.WRITE)
	
	var nodes = get_tree().get_first_node_in_group("CreatureContainer").get_children()
	
	print(nodes)
	for node in nodes:
		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		# Store the save dictionary as a new line in the save file.
		save_file.store_line(json_string)


func load_creatures():
	if not FileAccess.file_exists(Creature_save_path):
		return # Error! We don't have a save to load.
	var save_file
	
	#if encrypt:
		#save_file = FileAccess.open_encrypted_with_pass(Creature_save_path, FileAccess.READ,passcode)
	#else:
	save_file = FileAccess.open(Creature_save_path, FileAccess.READ)
		
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
	
		Globals.spawn_creature.emit(Vector3(node_data["x"],node_data["y"],node_data["z"]),load(node_data["creature_path"]))
		
