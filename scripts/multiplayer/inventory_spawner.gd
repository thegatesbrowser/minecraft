extends MultiplayerSpawner

signal spawned_inventroy(id: int, invetory: Inventory)
#signal creature_despawned(id: int)

var inventory_s: PackedScene = preload("res://scenes/items/inventory.tscn")


func _ready() -> void:
	spawn_function = custom_spawn
	Globals.spawn_ui.connect(spawn_ui)
	#Globals.add_subinventory.connect(spawn_inventroy)


func spawn_ui(id: Vector3, ui_scene_path: String) -> void:
	if not multiplayer.is_server(): return
	print("spawn inventory")
	spawn([1, id,ui_scene_path])


func custom_spawn(data: Array) -> Node:
	var id: int = data[0]
	var code: Vector3 = data[1]
	var ui_path: String = data[2]
	
	var ui = load(ui_path).instantiate()
	ui.set_multiplayer_authority(id,true)
	ui.Owner = code
	ui.hide()
	
	spawned_inventroy.emit(id, ui)
	return ui
