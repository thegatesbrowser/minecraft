extends Node3D
class_name Game

@export var is_multiplayer: bool
@export var player_spawner: PlayerSpawner
@export var single_player: Player

signal change_block(global_pos: Vector3, chunk_id: Vector2, type: int)

@onready var break_particle_s = preload("res://other/breakparticle.tscn")
@onready var creature_s = preload("res://creatures/creature base.tscn")
@onready var chunk_scene_0 := preload("res://chunking/chunk_no_render.tscn")
@onready var chunk_scene_1 := preload("res://chunking/chunk_simple.tscn")
@onready var chunk_scene_2 := preload("res://chunking/chunk_server.tscn")
@onready var chunk_scene_3 := preload("res://chunking/chunk_mesh.tscn")
@onready var chunk_scene_4 := preload("res://chunking/chunk_tileset.tscn")
@onready var chunk_scene_5 := preload("res://chunking/chunk_multimesh.tscn")

@onready var breaktime: Timer = $Breaktime

@onready var chunks := $NavigationRegion3D/Chunks
@onready var debug := $Overlay/DebugOverlay

var player: Player
var player_pos := Vector2.ZERO

var is_fullscreen = false

func _ready():
	if Connection.is_server():
		return
	
	if is_multiplayer:
		player = player_spawner.local_player
	else:
		player = single_player
	
	start_game()


func start_game() -> void:
	player.place_block.connect(_on_Player_place_block)
	player.break_block.connect(_on_Player_break_block)
	Globals.spawn_creature.connect(spawn_creature)
	
	WorldGen.set_seed(Globals.world_seed)
	
	if Globals.test_mode == Globals.TestMode.STATIC_LOAD or Globals.test_mode == Globals.TestMode.RUN_LOAD:
		Globals.capture_mouse_on_start = false
		Globals.paused = false
	elif Globals.test_mode == Globals.TestMode.NONE:
		debug.disable_overlay()
	
	var chunk_types = [chunk_scene_0, chunk_scene_1, chunk_scene_2, chunk_scene_3, chunk_scene_4, chunk_scene_5]
	chunks.chunk_scene = chunk_types[Globals.chunk_type]
	var chunk_has_collision = [false, true, false, true, true, false]
	
	if !chunk_has_collision[Globals.chunk_type]:
		Globals.flying = true
	
	# Generate chunk 0 so we don't fall through the world.
	chunks.load_chunk(_player_pos_to_chunk_pos(player.position), 0, 0, false)
	if Globals.test_mode == Globals.TestMode.STATIC_LOAD:
		var pos = player.global_position
		pos = Vector3(pos.x, WorldGen.get_height(pos.x, pos.z) + 20, pos.z)
		if chunk_has_collision[Globals.chunk_type]:
			chunks.place_block(pos, _player_pos_to_chunk_pos(pos), WorldGen.GLASS)
		else:
			player.global_position = pos
	
	# Change the mouse mode only when we're done loading.
	if Globals.capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Set the draw distance to match our settings.
	_set_draw_distance(Globals.load_radius)


func _process(_delta):
	if Connection.is_server() or player == null: return
	
	if Input.is_action_just_pressed("Start"):
		Globals.paused = !Globals.paused
		if Globals.paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("Console"):
		Console.toggle_console()
	
	# Maybe should be in a different script, only available in the actual simulation
	if Input.is_action_just_pressed("Fullscreen Toggle"):
		is_fullscreen = !is_fullscreen
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
	
	player_pos = _player_pos_to_chunk_pos(player.position)
	chunks.update_chunks(player_pos)
	debug.update_chunks()
	debug.update_player_pos(player.position)


func _physics_process(delta):
	debug.repaint(player_pos, delta)


func _set_draw_distance(radius: int):
	var distance = (radius) * Globals.chunk_size.x
	if Globals.no_fog:
		player.set_far(distance * 10)
#		env.fog_enabled = false
#		env.dof_blur_far_enabled = false
	else:
		player.set_far(distance * 1.25)
#		env.fog_enabled = true
#		env.fog_depth_begin = distance - min(50, distance * 0.1)
#		env.fog_depth_end = distance


func _player_pos_to_chunk_pos(pos: Vector3) -> Vector2:
	var pos_round = (pos / Globals.chunk_size).floor()
	return Vector2(pos_round.x, pos_round.z)


func _on_Player_break_block(pos: Vector3):
	var chunk_id = _player_pos_to_chunk_pos(pos)
	
	#print("breaking resource ",chunks.get_type(pos, chunk_id))
	var chunk_resource:Item_Global = load(chunks.get_type(pos, chunk_id))
	
	if chunk_resource != null:
		if breaktime.is_stopped():
			if chunk_resource.break_time - Globals.breaking_efficiency == 0:
				breaktime.wait_time = 0
			else:
				breaktime.wait_time = chunk_resource.break_time - Globals.breaking_efficiency
			breaktime.start()
			
			await breaktime.timeout
			
			if Input.is_action_pressed("Mine"):
				chunks.break_block(pos, chunk_id)
				change_block.emit(pos, chunk_id, WorldGen.AIR)
			else:
				breaktime.stop()


func _on_Player_place_block(pos: Vector3):
	Globals.remove_item_from_hotbar.emit()
	if Globals.custom_block != null:
		var object = Globals.custom_block.place_object.instantiate()
		object.resource = Globals.custom_block.utility
		
		var X = snappedf(pos.x,0.5)
		var Z = snappedf(pos.z,0.5)
		
		if step_decimals(X) == 0:
			X += 0.5
		if step_decimals(Z) == 0:
			Z += 0.5
			
		var new_pos = Vector3(X,pos.y,Z)
		print("new_pos ", new_pos)
		object.position = new_pos
		add_child(object)
		
	else:
		var chunk_id = _player_pos_to_chunk_pos(pos)
		chunks.place_block(pos, chunk_id, Globals.current_block)
		change_block.emit(pos, chunk_id, Globals.current_block)


func spawn_creature(pos:Vector3):
	var creature = creature_s.instantiate()
	creature.position = pos + Vector3(0,1,0)
	add_child(creature)
