extends MultiplayerSpawner

signal spawned_object(id:int, object)


func _ready() -> void:
	spawn_function = custom_spawn
	despawned.emit()
	Globals.add_object.connect(spawn_inventroy)
	
func spawn_inventroy(id:int,position,instance_path:String) -> void:
	if not multiplayer.is_server(): return
	spawn([id, position, instance_path])

func custom_spawn(data: Array) -> Node:
	var id: int = data[0]
	var spawn_position = data[1]
	var instance_scene_path:String = data[2]
	var type_pos = typeof(spawn_position) 
	
	var object = load(instance_scene_path).instantiate()
	
	object.global_transform = spawn_position
	object.set_multiplayer_authority(id,true)
	
	spawned_object.emit(id, object)
	return object
	
