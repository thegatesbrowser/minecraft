extends Control

@export var backend_scene:PackedScene = preload("res://scenes/backend.tscn")
@export var multiplayer_scene: PackedScene
@export var loading_bar: ProgressBar


func _ready() -> void:
	if Connection.is_server():
		start_scene()
		return

	else:
		pass
		#start_scene()
	Backend.playerdata_updated.connect(check_items)

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
				else:
					print("missing item ",item_path)
					
		if hotbar_data:
			for i in hotbar_data:
				var item_path = hotbar_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item")
				else:
					print("missing item ",item_path)
					
		if blueprint_data:
			for i in blueprint_data:
				var item_path = blueprint_data[i].item_path
				
				if item_path == "": continue
					
				print(item_path)
				
				var err = ResourceLoader.exists(item_path)
				
				if err:
					print("has item")
				else:
					print("missing item ",item_path)
		
	start_scene()
