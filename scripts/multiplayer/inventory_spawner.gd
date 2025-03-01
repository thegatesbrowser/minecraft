extends MultiplayerSpawner

signal spawned_inventroy(id:int, invetory:Inventory)
#signal creature_despawned(id: int)

var inventory_s = preload("res://scenes/items/inventory.tscn")


func _ready() -> void:
	spawn_function = custom_spawn
	
	Globals.add_subinventory.connect(spawn_inventroy)
	
func spawn_inventroy(id:Vector3) -> void:
	if not multiplayer.is_server(): return
	print("spawn")
	spawn([1, id])



func custom_spawn(data: Array) -> Node:
	var id: int = data[0]
	var code: Vector3 = data[1]
	
	var inventory = inventory_s.instantiate() as Inventory
	inventory.set_multiplayer_authority(id,true)
	inventory.Owner = code
	
	spawned_inventroy.emit(id, inventory)
	return inventory
