extends CharacterBody3D
class_name Player

signal hunger_updated(hunger)
signal health_updated(health)

var speed_mode = false
var start_position:Vector3
var spawn_position: Vector3
var your_id
var _agrid: VoxelAStarGrid3D = null

@export var defualt_hand_model:PackedScene

@export_group("MOVEMENT")
@export_range(0.1, 1.1, 0.1) var max_flying_margin = 0.2
@export_range(-1.1, -0.1, 0.1) var min_flying_margin = -0.2

@export var SWIMMING_SPEED = 4.0
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 8.0
@export var JUMP_VELOCITY = 7.0
@export var CROUCH_SPEED = 3.0

@export var can_autojump: bool = true

var fall_time:float = 0.0

# Player model rotation speed
@export var rotation_speed := 12.0

@export_subgroup("MULTIPLAYER")
# Clamp sync delta for faster interpolation
@export var sync_delta_max := 0.2
@export var sync_delta := 0.0
@export var start_interpolate := false

@export_group("NODES")
@export var hit_shader:ColorRect
@export var rotation_root: Node3D
@export var ANI: AnimationPlayer
@export var hit_sfx: AudioStreamPlayer3D
@export var pos_label: Label
@export var ping_label: Label
@export var collision: CollisionShape3D
@export var hand_ani: AnimationPlayer
@export var terrain_interation:TerrainInteraction
@export var camera_shake:Node
@export var fall_timer:Timer
@export var floor_ray:RayCast3D
@export var skeleton_3d: Skeleton3D


var backendclient

const SENSITIVITY = 0.004

# Bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.03
var t_bob = 0.0

# FOV variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

var found_ground:bool = false
var swimming:bool = false
var crouching:bool = false
var speed: float
var gravity = 22.5
var position_before_sync: Vector3 = Vector3.ZERO
var last_sync_time_ms: int = 0
var is_flying: bool


@export var camera_transform:Transform3D

@onready var drop_node: Node3D = $RotationRoot/Head/Camera3D/Drop_node

@onready var camera = $RotationRoot/Head/Camera3D
@onready var ray = $RotationRoot/Head/Camera3D/RayCast3D
@onready var auto_jump: RayCast3D = $RotationRoot/AutoJump
@onready var can_auto_jump_check: RayCast3D = $RotationRoot/AutoJump2
@onready var _synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var _move_direction := Vector3.ZERO

@onready var hand = $RotationRoot/Head/Camera3D/Hand

@export_group("SYNC PROPERTIES")
@export var _position: Vector3
@export var _velocity: Vector3
@export var _rotation: Vector3 = Vector3.ZERO
@export var _direction: Vector3 = Vector3.ZERO

@export_group("STATS")
@export var fall_hurt_height:float = 2.0
@export var base_hunger: float = 5.0
var hunger: float = 0
@export var hunger_update_time := 10.0
@export var moving_hunger_times_debuff := 2.0
@export var hunger_step: float = 0.1

@export var max_health: int = 3
var health

@onready var minecraft_player: Node3D = $"RotationRoot/runestone player" # TP
#@onready var fp: Node3D = $RotationRoot/Head/Camera3D/fp # FP

var spawn_point_set := {}

func _ready() -> void:
	_agrid = VoxelAStarGrid3D.new()
	# set _terrain that is the main VoxelTerrain
	

	# little aabb box of 20 by 10 by 20
	print("PLAYER READY")
	
	backendclient = get_tree().get_first_node_in_group("BackendClient")
	Globals.hunger_points_gained.connect(hunger_points_gained)
	Globals.max_health = max_health
	Globals.paused = true
	spawn_position = start_position
	
	if !backendclient.playerdata.is_empty():
		if backendclient.playerdata.hunger == null:
			hunger = base_hunger
		else:
			hunger = backendclient.playerdata.hunger
		if backendclient.playerdata.hunger == null:
			health = max_health
		else:
			health = backendclient.playerdata.health
	else:
		hunger = base_hunger
		health = max_health

	if not is_multiplayer_authority():
		_synchronizer.delta_synchronized.connect(on_synchronized)
		_synchronizer.synchronized.connect(on_synchronized)
		hand.hide()
		minecraft_player.show()
		return
	else:
		hand.show()
		minecraft_player.hide()
	
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # TODO: Move to mouse mode
	
	Globals.add_item_to_hand.connect(add_item_to_hand)
	Globals.remove_item_in_hand.connect(remove_item_in_hand)
	camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority() and Connection.is_peer_connected: return
	if Globals.paused: return
	
	if event is InputEventMouseMotion:
		rotation_root.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	var bone_rot = camera.rotation.x / 100
	var head = skeleton_3d.find_bone("head")
	var t = skeleton_3d.get_bone_pose(head)
	t = t.rotated(Vector3(0.0, 1.0, 0.0),bone_rot)
	skeleton_3d.set_bone_pose(head,t)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	camera_transform = camera.global_transform
	
	if found_ground == false:
		var ClientServer = get_tree().get_first_node_in_group("BackendClient")
		if ClientServer.playerdata.is_empty() == false:
			if ClientServer.playerdata.Position_x != null:
				global_position = Vector3(ClientServer.playerdata.Position_x,ClientServer.playerdata.Position_y,ClientServer.playerdata.Position_z) + Vector3(0,1,0)
		pass
		if floor_ray.is_colliding():
			#Globals.paused = false
			global_position = floor_ray.get_collision_point() + Vector3(0,1,0)
			start_position = floor_ray.get_collision_point() + Vector3(0,1,0)
			found_ground = true
			Globals.paused = false
		
	pos_label.text = str("pos   ", global_position)
	camera.far = Globals.view_range
		
	hunger_update(_delta)
		
	Globals.player_health = health


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() and Connection.is_peer_connected:
		interpolate_client(delta); return
		
	if your_id != get_multiplayer_authority():
		var inventory = get_tree().get_first_node_in_group("Main Inventory")
		your_id = get_multiplayer_authority()
	
	if swimming:
		fall_timer.stop()
		fall_time = 0.0
		
	if !is_flying and found_ground and !swimming:
		# Add the gravity.
		if not is_on_floor():
			if fall_timer.is_stopped():
				fall_timer.start()
			velocity.y -= gravity * delta
		else:
			# Fall Damage
			if fall_time >= fall_hurt_height:
				var damage = fall_time * 2
				hit(damage)
			fall_timer.stop()
			fall_time = 0.0
			
	if !Globals.paused:
		mine_and_place(delta)
	if !is_flying and !Globals.paused and !swimming:
		normal_movement(delta)
	if is_flying and !Globals.paused and !swimming:
		flying_movement(delta)
	if !is_flying and !Globals.paused and swimming:
		swimming_movement(delta)
		
	if Globals.paused and found_ground:
		velocity.x = lerp(velocity.x,0.0,.1)
		velocity.z = lerp(velocity.x,0.0,.1)
	
	# Head bob
	if SettingsManager.headbob:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
	
	# FOV
	if SettingsManager.varing_fov:
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
		
	move_and_slide()
	set_sync_properties()


func set_sync_properties() -> void:
	_position = position
	_velocity = velocity
	_rotation = rotation_root.rotation
	_direction = _move_direction

func save_data():
	#Position
	Globals.send_to_server.emit({"client_id": Globals.client_id,"change_name": "Position_x", "change": position.x})
	Globals.send_to_server.emit({"client_id": Globals.client_id,"change_name": "Position_y", "change": position.y})
	Globals.send_to_server.emit({"client_id": Globals.client_id,"change_name": "Position_z", "change": position.z})
	
	#Stats
	Globals.send_to_server.emit({"client_id": Globals.client_id,"change_name": "health", "change": health})
	Globals.send_to_server.emit({"client_id": Globals.client_id,"change_name": "hunger", "change": hunger})
	
func on_synchronized() -> void:
	velocity = _velocity
	position_before_sync = position
	
	var sync_time_ms = Time.get_ticks_msec()
	sync_delta = clampf(float(sync_time_ms - last_sync_time_ms) / 1000, 0, sync_delta_max)
	last_sync_time_ms = sync_time_ms
	
	if not start_interpolate:
		start_interpolate = true
		position = _position
		rotation_root.rotation = _rotation
	
	if Connection.is_server():
		position = _position


func interpolate_client(delta: float) -> void:
	if not start_interpolate: return
	
	# Interpolate rotation
	rotation_root.rotation = _rotation.slerp(rotation_root.rotation, delta)
	
	if _direction:
		# Don't interpolate to avoid small jitter when stopping
		if (_position - position).length() > 1.0 and _velocity.is_zero_approx():
			position = _position # Fix misplacement
		
		if ANI.current_animation != "waling": ANI.play("waling")
	else:
		# Interpolate between position_before_sync and _position
		# and add to ongoing movement to compensate misplacement
		var t = 1.0 if is_zero_approx(sync_delta) else delta / sync_delta
		sync_delta = clampf(sync_delta - delta, 0, sync_delta_max)
		
		var less_misplacement = position_before_sync.move_toward(_position, t)
		position += less_misplacement - position_before_sync
		position_before_sync = less_misplacement
		
		if ANI.current_animation != "idle": ANI.play("idle")
	
	velocity.y -= gravity * delta
	move_and_slide()


func toggle_flying() -> void:
	is_flying = !is_flying


func toggle_clipping() -> void:
	collision.disabled = !collision.disabled
	if collision.disabled:
		WALK_SPEED = 20.0
		is_flying = true
	else:
		WALK_SPEED = 5.0

func show_pos() -> void:
	pos_label.visible = !pos_label.visible


func show_ping() -> void:
	ping_label.visible = !ping_label.visible


func _headbob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func is_print_logs() -> bool:
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return "--print_logs" in args


func _exit_tree():
	Console.remove_command("player_flying")
	Console.remove_command("player_clipping")

func add_item_to_hand(item: ItemBase, scene:PackedScene) -> void:
	#var hand_empty:bool = true
	#
	#if hand.get_child_count() != 0:
		#hand_empty = false
		
	for i in hand.get_children():
		i.queue_free()
			
	if item != null:
		
			
		if item is ItemTool:
			var tool = item.holdable_mesh.instantiate()
			hand.add_child(tool)
			#if hand_ani:
				#hand_ani.play("pick up")
		else:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = item.holdable_mesh
			hand.add_child(mesh_instance)
			#if hand_ani:
				#hand_ani.play("pick up")
	else:
		var holdable_mesh = scene.instantiate()
		hand.add_child(holdable_mesh) 
		#if hand_ani:
			#hand_ani.play("pick up")

func remove_item_in_hand() -> void:
		
	for i in hand.get_children():
		i.queue_free()
	
		


@rpc("any_peer","call_local")
func hit(damage: int = 1) -> void:
	
	if damage - Globals.protection < 0:
		damage = 0
	
	
	health -= damage
	
	hit_sfx.play()
	camera_shake._shake()
	if health <= 0:
		death()
	if damage != 0:
		var mat = hit_shader.get_material() as ShaderMaterial
		var tween = create_tween()
		tween.tween_property(mat,"shader_parameter/inner_radius",.2,.4)
		tween.tween_property(mat,"shader_parameter/inner_radius", 1,1)
		
	print("hit")

func hunger_update(_delta: float) -> void:
	if _move_direction:
		hunger_update_time -= _delta * moving_hunger_times_debuff
	else:
		hunger_update_time -= _delta
		
	if hunger_update_time <= 0:
		
		if hunger == base_hunger:
			if health + 1 <= base_hunger:
				health += 1
			else:
				health = max_health
				
		if hunger <= 0:
			#print("dying of hunger")
			hit.rpc_id(get_multiplayer_authority(),1)
			health_updated.emit(health)
			
		if _move_direction:
			hunger -= hunger_step * moving_hunger_times_debuff
		else:
			hunger -= hunger_step
		
		hunger_updated.emit(hunger)
			
		hunger_update_time = 10


func death() -> void:
	#terrain_interation.place_block(&"gravestone")
	health = max_health
	hunger = base_hunger
	print("death")
	respawn.rpc(spawn_position)
	camera_shake._shake()
	drop_items()
	global_position = spawn_position


@rpc("any_peer", "call_local", "reliable")
func respawn(pos: Vector3) -> void:
	print("respawn")
	global_position = pos
	velocity = Vector3.ZERO

func drop_items():
	var inventory = get_tree().get_first_node_in_group("Main Inventory")
	var hotbar = get_tree().get_first_node_in_group("Hotbar")
	inventory.drop_all()
	hotbar.drop_all()

func hunger_points_gained(amount: int) -> void:
	if hunger + amount < base_hunger:
		hunger += amount
	else:
		hunger = base_hunger


func _on_fall_time_timeout() -> void:
	if Globals.paused or swimming: return
	fall_time += 1


func _on_update_timeout() -> void:
	if not Connection.is_server():
		save_data()

func normal_movement(delta:float):
	# Handle Sprint.
	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
		# Crouch
		if Input.is_action_pressed("Crouch"):
			crouching = true
			speed = CROUCH_SPEED
		else:
			speed = WALK_SPEED
			crouching = false
			
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	_move_direction = (rotation_root.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if _move_direction:
			if ANI.current_animation != "waling":
				ANI.play("waling")
			if hand_ani.current_animation != "pick up":
				if hand_ani.current_animation != "attack":
					if hand_ani.current_animation != "eat":
						if hand_ani.current_animation != "walk":
							hand_ani.play("walk")
			velocity.x = _move_direction.x * speed
			velocity.z = _move_direction.z * speed
		else:
			if ANI.current_animation != "idle":
				ANI.play("idle")
				
			if hand_ani.current_animation != "pick up":
				if hand_ani.current_animation != "attack":
					if hand_ani.current_animation != "eat":
						if hand_ani.current_animation != "idle":
							hand_ani.play("idle")
					
			velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 3.0)
		
	# Handle Jump.
	if Input.is_action_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	## Auto jump
	var moving_forward = input_dir.y < 0
	if can_autojump and moving_forward and is_on_floor():
		if auto_jump.is_colliding() and !can_auto_jump_check.is_colliding():
			velocity.y = JUMP_VELOCITY
			
			
			
func flying_movement(delta:float):
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	_move_direction = (rotation_root.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if camera.rotation.x > max_flying_margin:
			velocity.y = camera.rotation.x * speed * 2
	else:
		velocity.y = lerp(velocity.y,0.0,.1)
		
	if  camera.rotation.x < min_flying_margin:
		velocity.y = camera.rotation.x * speed * 2
		
	else:
		velocity.y = lerp(velocity.y,0.0,.1)
		
	if _move_direction:
		if ANI.current_animation != "waling":
				ANI.play("waling")
		velocity.x = _move_direction.x * speed
		velocity.z = _move_direction.z * speed
	else:
		if ANI.current_animation != "idle":
				ANI.play("idle")
		velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 7.0)
		velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 7.0)
		
		
	
func mine_and_place(delta:float):
	var hotbar = get_node("/root/Main").find_child("Hotbar") as HotBar
	var hotbar_item:ItemBase = hotbar.get_current().Item_resource

	if Input.is_action_pressed("Mine"):
		if hand_ani.current_animation != "attack":
			if hand_ani.current_animation != "eat":
				hand_ani.play("attack")
	else:
		if hand_ani.current_animation != "idle" and hand_ani.current_animation != "walk":
			if hand_ani.current_animation != "RESET":
				if hand_ani.current_animation != "eat":
					hand_ani.play("RESET")
			
	if Input.is_action_just_pressed("Build"):
		
		if ray.is_colliding():
			var coll = ray.get_collider()
			
			if coll is CreatureBase:
				if coll.creature_resource.tamable:
					if hotbar_item != null:
						coll.give(hotbar_item,name.to_int())
						Globals.remove_item_from_hotbar.emit()
						
				elif coll.creature_resource.utility != null:
					var util = coll.creature_resource.utility as Utilities
					if util.has_ui:
						print(coll.spawn_pos)
						Globals.open_inventory.emit(coll.spawn_pos)
		
	if Input.is_action_just_pressed("Mine"):
		#print(hotbar.get_current().Item_resource)
		
		if ray.is_colliding():
			var coll = ray.get_collider()
			
			if coll is Dropped_Item:
				coll.collect()
				var soundmanager = get_node("/root/Main").find_child("SoundManager")
				soundmanager.play_sound("pick_up",ray.get_collision_point())
			
			if coll is CreatureBase:
				if hotbar_item != null:
					if "damage" in hotbar_item:
						coll.hit(hotbar_item.damage)
					else:
						coll.hit()
				else:
					coll.hit()
					
			if coll is Player:
				if hotbar_item != null:
					if "damage" in hotbar_item:
						coll.hit.rpc_id(coll.get_multiplayer_authority(),hotbar_item.damage)
					else:
						coll.hit.rpc_id(coll.get_multiplayer_authority())
				else:
					coll.hit.rpc_id(coll.get_multiplayer_authority())
	
	if Input.is_action_just_released("Mine"):
		if hotbar_item is ItemTool:
			if hotbar_item.projectable:
				if hotbar_item.throws_self:
					var current_slot = hotbar.get_current() as Slot
					current_slot.amount -= 1
					spawn_throwable.rpc_id(1,[your_id,camera_transform,"res://scenes/items/weapons/projectile.tscn",hotbar_item.projectile_resource.get_path()])
				else:
					var find_item = hotbar_item.projectile_item
					var item_slot = Globals.find_item(find_item)
					if item_slot != null:
						if item_slot.amount - hotbar_item.amount_needed:
							if item_slot.amount >= 0:
								item_slot.amount -= hotbar_item.amount_needed
								spawn_throwable.rpc_id(1,[your_id,camera_transform,"res://scenes/items/weapons/projectile.tscn",hotbar_item.projectile_resource.get_path()])
					
func swimming_movement(delta:float) -> void:

	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	_move_direction = (rotation_root.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if camera.rotation.x > max_flying_margin:
		if !Input.is_action_pressed("Jump"):
			velocity.y = camera.rotation.x * SWIMMING_SPEED * 2
		else:
			velocity.y = JUMP_VELOCITY
	else:
		if !Input.is_action_pressed("Jump"):
			velocity.y = lerp(velocity.y,0.0,.1)
		else:
			velocity.y = JUMP_VELOCITY
		
	if  camera.rotation.x < min_flying_margin:
		if !Input.is_action_pressed("Jump"):
			velocity.y = camera.rotation.x * SWIMMING_SPEED * 2
		else:
			velocity.y = JUMP_VELOCITY
	else:
		if !Input.is_action_pressed("Jump"):
			velocity.y = lerp(velocity.y,0.0,.1)
		else:
			velocity.y = JUMP_VELOCITY
			
	if _move_direction:
		if hand_ani.current_animation != "pick up":
			if ANI.current_animation != "waling":
					ANI.play("waling")
		velocity.x = _move_direction.x * SWIMMING_SPEED
		velocity.z = _move_direction.z * SWIMMING_SPEED
	else:
		if hand_ani.current_animation != "pick up":
			if ANI.current_animation != "idle":
					ANI.play("idle")
		
		velocity.x = lerp(velocity.x, _move_direction.x * SWIMMING_SPEED, delta * 7.0)
		velocity.z = lerp(velocity.z, _move_direction.z * SWIMMING_SPEED, delta * 7.0)
	#if Input.is_action_pressed("Jump") and is_on_floor():
			#velocity.y = JUMP_VELOCITY
			
		
	## Auto jump
	var moving_forward = input_dir.y < 0
	if can_autojump and moving_forward and is_on_floor():
		if auto_jump.is_colliding() and !can_auto_jump_check.is_colliding():
			velocity.y = JUMP_VELOCITY
			
func _speed_mode():
	speed_mode = !speed_mode
	if speed_mode:
		WALK_SPEED = 100
	else:
		WALK_SPEED = 5.0
		
@rpc("any_peer","call_local")
func spawn_throwable(data):
	Globals.add_object.emit(data)
