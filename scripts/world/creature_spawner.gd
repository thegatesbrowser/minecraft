extends MultiplayerSpawner

signal creature_spawned(id: int, creature)
signal creature_despawned(id: int)

var debug:bool
var creature_base = preload("res://scenes/creatures/creature_base.tscn")
@export var view_distance: int = 20

func _ready() -> void:
	spawn_function = custom_spawn
	Globals.spawn_creature.connect(spawn_creature)


func spawn_creature(pos: Vector3, creature:Creature, spawn_pos = null) -> void:
	#print(creature, pos)
	if not multiplayer.is_server(): return
	

	var spawn_position = pos
	print("creature spawn pos ", spawn_position)
	spawn([1, spawn_position,creature.get_path(),spawn_pos])


func destroy_creature(Name: String) -> void:
	if not multiplayer.is_server(): return
	get_node(spawn_path).get_node(Name).queue_free()


func custom_spawn(data: Array) -> Node:
	var id: int = data[0]
	var spawn_position: Vector3 = data[1]
	
	## Loads from the path of the resource
	var creature_resource = load(data[2])
	
	var spawn_pos = data[3] ## start spawn from saving
	
	var creature = creature_base.instantiate() as CreatureBase
	creature.set_multiplayer_authority(id)
	creature.name = str(id)
	creature.position = spawn_position

	if spawn_pos != null:
		creature.spawn_pos = spawn_pos
	else:
		creature.spawn_pos = spawn_position

	creature.creature_resource = creature_resource
	
	create_viewer(id, creature)
	
	creature_spawned.emit(id, creature)
	return creature


func create_viewer(_id: int, creature: CreatureBase) -> void:
	if Connection.is_server():
		var viewer: VoxelViewer = VoxelViewer.new()

		viewer.view_distance = view_distance
		viewer.requires_visuals = true
		viewer.requires_collisions = true
		viewer.set_network_peer_id(1)

		creature.add_child(viewer)
