extends Control

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_scene: PackedScene
@export var loading_bar: ProgressBar

var python_client := Python_Item_Backend_Client.new()

signal checked_for_item
var has_item = false

func _ready() -> void:
	add_child(python_client)
	
	if Connection.is_server():
		start_scene()
		return

	#else:
		#pass
		#start_scene()
		
	Backend.playerdata_updated.connect(start_scene)

func _process(delta):
	if loading_bar.value < 100:
		loading_bar.value += delta * 10
	else:
		loading_bar.value = 0
	
	

func start_scene() -> void:
	get_tree().call_deferred("change_scene_to_packed", multiplayer_scene)

func check_items():
	if Backend.playerdata:
		var inventory_data
		var hotbar_data
		var blueprint_data
		
		if Backend.playerdata.Inventory:
			inventory_data = JSON.parse_string(Backend.playerdata.Inventory)
		
		if Backend.playerdata.Hotbar:
			hotbar_data = JSON.parse_string(Backend.playerdata.Hotbar)
			
		if Backend.playerdata.Blueprints:
			blueprint_data = JSON.parse_string(Backend.playerdata.Blueprints)
			
		if inventory_data:
			for i in inventory_data:
				var item_path = inventory_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item")
					var item_name = item_path.get_file()
					python_client.check_file_exists(item_name, Callable(self, "_on_upload_file_check"))
					
					await checked_for_item
					if has_item == false:
						var files_to_upload = [
						{"path": "res://assets/models/tools/Stone/axe_stone.tscn","local_path": "res://assets/models/axe_stone.tscn"}]
						python_client.upload_files(files_to_upload)
					
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					print("missing item ",item_path)
					
		if hotbar_data:
			for i in hotbar_data:
				var item_path:String = hotbar_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item")
					var item_name = item_path.get_file()
					python_client.check_file_exists(item_name, Callable(self, "_on_upload_file_check"))
					
					await checked_for_item
					if has_item == false:
						var files_to_upload = [
						{"path": "res://assets/models/tools/Stone/axe_stone.tscn","local_path": "res://assets/models/axe_stone.tscn"}]
						python_client.upload_files(files_to_upload)
					
					
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					
					print("missing item ",item_path)
					
		if blueprint_data:
			for i in blueprint_data:
				var item_path:String = blueprint_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					var item_name = item_path.get_file()
					python_client.check_file_exists(item_name, Callable(self, "_on_upload_file_check"))
					
					await checked_for_item
					if has_item == false:
						var files_to_upload = [
						{"path": "res://assets/models/tools/Stone/axe_stone.tscn","local_path": "res://assets/models/axe_stone.tscn"}]
						python_client.upload_files(files_to_upload)
				else:
					var item_name = item_path.get_file()
					print("item_name ",item_name)
					
					python_client.check_file_exists(item_name, Callable(self, "_on_download_file_check"))
					
					print("missing item ",item_path)
					pass
		
	#start_scene()

func _on_download_file_check(result: Dictionary):
	if result.get("exists", false):
		print("File exists on server in folder:", result["folder_id"])
		print("Godot path:", result["local_path"])
		python_client.download_folder_files(result["local_path"].get_file())
	else:
		print("File does not exist on server, safe to upload")

func _on_upload_file_check(result: Dictionary):
	if result.get("exists", false):
		print("File exists on server in folder:", result["folder_id"])
		print("Godot path:", result["local_path"])
		checked_for_item.emit()
		has_item = true
	else:
		checked_for_item.emit()
		has_item = false
		print("File does not exist on server, safe to upload")
