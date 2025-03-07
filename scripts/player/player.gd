extends CharacterBody3D
class_name Player

signal hunger_updated(hunger)
signal health_updated(health)

var spawn_position:Vector3
var your_id

@export_group("MOVEMENT")
@export_range(0.1,1.1,.1) var max_flying_margin = 0.2
@export_range(-1.1,-0.1,.1) var min_flying_margin = -0.2

@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 8.0
@export var JUMP_VELOCITY = 7.0

@export var can_autojump: bool = true


## Player model rotation speed
@export var rotation_speed := 12.0

@export_subgroup("MULTIPLAYER")
## Clamp sync delta for faster interpolation
@export var sync_delta_max := 0.2
@export var sync_delta := 0.0
@export var start_interpolate := false

@export_group("NODES")
@export var rotation_root: Node3D
@export var ANI: AnimationPlayer

const SENSITIVITY = 0.004

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0

#fov variables
const BASE_FOV = 90.0
const FOV_CHANGE = 1.5

var speed
var gravity = 16.5
var position_before_sync: Vector3 = Vector3.ZERO
var last_sync_time_ms: int = 0
var is_flying: bool

@onready var drop_node: Node3D = $RotationRoot/Head/Camera3D/Drop_node

@onready var camera = $RotationRoot/Head/Camera3D
@onready var ray = $RotationRoot/Head/Camera3D/RayCast3D
@onready var auto_jump: RayCast3D = $RotationRoot/AutoJump
@onready var can_auto_jump_check: RayCast3D = $RotationRoot/AutoJump2
@onready var _synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var _move_direction := Vector3.ZERO

@onready var left_hand: BoneAttachment3D = $"RotationRoot/Head/Camera3D/fp/Model/Skeleton3D/Left Hand"
@onready var right_hand: BoneAttachment3D = $"RotationRoot/minecraft_player/Model/Skeleton3D/Right Hand"

## Weapons
@export var bullet_scene: PackedScene
@export var weapon_base: PackedScene

@export_group("SYNC PROPERTIES")
@export var _position: Vector3
@export var _velocity: Vector3
@export var _rotation: Vector3 = Vector3.ZERO
@export var _direction: Vector3 = Vector3.ZERO

@export_group("STATS")
@export var base_hunger:float = 5.0
var hunger:float = 0
@export var hunger_update_time := 10.0
@export var moving_hunger_times_debuff := 2.0
@export var hunger_step:float = 0.1

@export var max_health: int = 3
var health

@onready var minecraft_player: Node3D = $RotationRoot/minecraft_player ## TP
@onready var fp: Node3D = $RotationRoot/Head/Camera3D/fp ## FP


func _ready():
	Globals.hunger_points_gained.connect(hunger_points_gained)
	Globals.spawn_bullet.connect(spawn_bullet)
	Globals.max_health = max_health
	hunger = base_hunger
	health = max_health

	if not is_multiplayer_authority():
		_synchronizer.delta_synchronized.connect(on_synchronized)
		_synchronizer.synchronized.connect(on_synchronized)
		fp.hide()
		minecraft_player.show()
		return
	else:
		fp.show()
		minecraft_player.hide()
	
	Console.add_command("respawn", self, 'death')\
		.set_description("makes the player position the spawn position).")\
		.register()
	
	Console.add_command("pos", self, 'show_pos')\
		.set_description("shows the position of the player).")\
		.register()
	
	Console.add_command("player_flying", self, 'toggle_flying')\
		.set_description("Enables the player to fly (or disables flight).")\
		.register()
	Console.add_command("player_clipping", self, 'toggle_clipping')\
		.set_description("Enables the player to clip through the world (or disables clipping).")\
		.register()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # TODO: Move to mouse mode
	
	Globals.add_item_to_hand.connect(add_item_to_hand)
	Globals.remove_item_in_hand.connect(remove_item_in_hand)
	camera.current = true


func _unhandled_input(event):
	if not is_multiplayer_authority() and Connection.is_peer_connected: return
	if Globals.paused: return
	if event is InputEventMouseMotion:
		rotation_root.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	$Pos.text = str("pos   ", global_position)
	
	if health <= 0:
		death()
		
	hunger_update(_delta)
		
	Globals.player_health = health


func _physics_process(delta):
	if not is_multiplayer_authority() and Connection.is_peer_connected:
		interpolate_client(delta); return
		
	if Globals.paused: return
	
	if your_id != get_multiplayer_authority():
		var inventory = get_tree().get_first_node_in_group("Main Inventory")
		your_id = get_multiplayer_authority()
	
	if !is_flying:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta
		
		# Handle Jump.
		if Input.is_action_pressed("Jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	
			
	# Handle Sprint.
	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Backward")
	_move_direction = (rotation_root.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	## Normal Controls
	if !is_flying:
		if is_on_floor():
			if _move_direction:
				if ANI.current_animation != "walk":
					ANI.play("walk")
				velocity.x = _move_direction.x * speed
				velocity.z = _move_direction.z * speed
			else:
				if ANI.current_animation != "idle":
					ANI.play("idle")
				velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 3.0)
		
		## Auto jump
		var moving_forward = input_dir.y < 0
		if can_autojump and moving_forward and is_on_floor():
			if auto_jump.is_colliding() and !can_auto_jump_check.is_colliding():
				velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("Mine"):
		var hotbar = get_node("/root/Main").find_child("Selection_Buttons") as HotBar
		var hotbar_item = hotbar.get_current().Item_resource
		#print(hotbar.get_current().Item_resource)
		
		if ray.is_colliding():
			var coll = ray.get_collider()
			
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
						rpc_id(coll.get_multiplayer_authority(),"hit",hotbar_item.damage)
					else:
						rpc_id(coll.get_multiplayer_authority(),"hit")
				else:
					rpc_id(coll.get_multiplayer_authority(),"hit")
			
	## Flying Controls
	if is_flying:
		if camera.rotation.x > max_flying_margin:
			velocity.y = camera.rotation.x * speed * 2
		else:
			velocity.y = lerp(velocity.y,0.0,.1)
			
		if  camera.rotation.x < min_flying_margin:
			velocity.y = camera.rotation.x * speed * 2
			
		else:
			velocity.y = lerp(velocity.y,0.0,.1)
			
		if _move_direction:
			if ANI.current_animation != "walk":
					ANI.play("walk")
			velocity.x = _move_direction.x * speed
			velocity.z = _move_direction.z * speed
		else:
			if ANI.current_animation != "idle":
					ANI.play("idle")
			velocity.x = lerp(velocity.x, _move_direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, _move_direction.z * speed, delta * 7.0)
		
		# Head bob
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
	
	# FOV
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
		
		if ANI.current_animation != "walk": ANI.play("walk")
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


func toggle_flying():
	is_flying = !is_flying


func toggle_clipping():
	$CollisionShape3D.disabled = !$CollisionShape3D.disabled
	if $CollisionShape3D.disabled:
		is_flying = true

func show_pos():
	$Pos.visible = !$Pos.visible
	
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func is_print_logs() -> bool:
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	return "--print_logs" in args


func _exit_tree():
	Console.remove_command("player_flying")
	Console.remove_command("player_clipping")


func add_item_to_hand(item: ItemBase):
	if item != null:
		
		for i in left_hand.get_children():
			i.queue_free()
			
		if item is ItemWeapon:
			var weapon = weapon_base.instantiate()
			weapon.weapon_resource = item
			left_hand.add_child(weapon)
			
		elif item is ItemTool:
			var tool = item.holdable_mesh.instantiate()
			left_hand.add_child(tool)
		else:
			var mesh_instance = MeshInstance3D.new()
			mesh_instance.mesh = item.holdable_mesh
			left_hand.add_child(mesh_instance)


func remove_item_in_hand():
	for i in left_hand.get_children():
		i.queue_free()

@rpc("any_peer","call_local")
func hit(damage:int = 1):
	health -= damage
	$hit.play()
	#health_updated.emit(health)
	print("hit")

func spawn_bullet():
	if is_multiplayer_authority():
		sync_bullet.rpc(camera.global_transform)


@rpc("any_peer","call_local")
func sync_bullet(transform_):
	Globals.add_object.emit(1,transform_,"res://scenes/items/weapons/bullet.tscn")
	
func hunger_update(_delta:float) -> void:
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
			print("dying of hunger")
			health -= 1
			$hit.play()
			health_updated.emit(health)
			
		if _move_direction:
			hunger -= hunger_step * moving_hunger_times_debuff
		else:
			hunger -= hunger_step
		
		hunger_updated.emit(hunger)
			
		print("hunger")
		hunger_update_time = 10

func death():
	health = max_health
	hunger = base_hunger
	respawn.rpc(spawn_position)
	global_position = spawn_position

@rpc("any_peer", "call_remote", "reliable")
func respawn(spawn_position: Vector3) -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO

func hunger_points_gained(amount):
	if hunger + amount < base_hunger:
		hunger += amount
	else:
		hunger = base_hunger
