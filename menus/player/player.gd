extends CharacterBody3D
class_name Player

signal place_block(pos: Vector3)
signal break_block(pos: Vector3)

@export_range(0.1,1.1,.1) var max_flying_margin = 0.2
@export_range(-1.1,-0.1,.1) var min_flying_margin = -0.2
@export var can_autojump:bool = true
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 8.0
@export var JUMP_VELOCITY = 7.0

@export var body:Node
@export var ANI:AnimationPlayer

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
var far_distance: float = 160
var block_is_inside_character := false

@onready var camera = $Head/Camera3D
@onready var ray = $Head/Camera3D/RayCast3D
@onready var block = $BlockOutline
@onready var head = $Head
@onready var block_collider = $BlockOutline/Area3D
@onready var auto_jump: RayCast3D = $"auto jump"
@onready var can_auto_jump_check: RayCast3D = $"auto jump2"


func _ready():
	Console.add_command("player_flying", self, 'toggle_flying')\
		.set_description("Enables the player to fly (or disables flight).")\
		.register()
	Console.add_command("player_clipping", self, 'toggle_clipping')\
		.set_description("Enables the player to clip through the world (or disables clipping).")\
		.register()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera.far = far_distance
	print("far_distance ", far_distance)

	if is_multiplayer_authority():
		camera.current = true


func set_far(far: float) -> void:
	far_distance = far
	$Head/Camera3D.far = far
	print("set_far ", far_distance)


func _unhandled_input(event):
	if Globals.paused or Globals.test_mode == Globals.TestMode.STATIC_LOAD or Globals.test_mode == Globals.TestMode.RUN_LOAD:
		return
		
	if event is InputEventMouseMotion:
		body.rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		

func _physics_process(delta):
	if Globals.paused:
		block.visible = false
		return

	if !Globals.flying:
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
	var direction = (head.transform.basis * transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	## Normal Controls
	if !Globals.flying:
		if is_on_floor():
			if direction:
				if ANI.current_animation != "walk":
					ANI.play("walk")
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				if ANI.current_animation != "idle":
					ANI.play("idle")
				velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
		## Auto jump
		var moving_forward = input_dir.y < 0
		if can_autojump and moving_forward and is_on_floor():
			auto_jump.rotation.y = head.rotation.y
			can_auto_jump_check.rotation.y = head.rotation.y
			
			if auto_jump.is_colliding() and !can_auto_jump_check.is_colliding():
				velocity.y = JUMP_VELOCITY
	
	## Flying Controls
	if Globals.flying:
		if camera.rotation.x > max_flying_margin:
			velocity.y = camera.rotation.x * speed * 2
		else:
			velocity.y = lerp(velocity.y,0.0,.1)
			
		if  camera.rotation.x < min_flying_margin:
			velocity.y = camera.rotation.x * speed * 2
			
		else:
			velocity.y = lerp(velocity.y,0.0,.1)
			
		if direction:
			if ANI.current_animation != "walk":
					ANI.play("walk")
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			if ANI.current_animation != "idle":
					ANI.play("idle")
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
			
		# Head bob
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# BUILDING / BREAKING
	if ray.is_colliding():
		var normal = ray.get_collision_normal()
		var pos = ray.get_collision_point() - normal * 0.5
		
		block.global_position = pos.floor() + (Vector3.ONE / 2)
		block.global_rotation = Vector3.ZERO
		block.visible = true
		
		if Input.is_action_just_pressed("Mine"):
			break_block.emit(pos)
		if Input.is_action_just_pressed("Build"):
			if Globals.can_build:
				if !block_is_inside_character:
					place_block.emit(pos + normal)
					pass
	else:
		block.visible = false
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	


func rotate_head(amount_lr: float, amount_ud: float, inverted: bool):
	if inverted:
		amount_ud = -amount_ud
	amount_ud = deg_to_rad(amount_ud)
	
	# Look left and right.
	rotate_y(deg_to_rad(-amount_lr))
	
	var head_rotation = head.rotation.x
	if head_rotation + amount_ud <= deg_to_rad(Globals.max_look_vertical) and \
			head_rotation + amount_ud >= deg_to_rad(-Globals.max_look_vertical):
		head.rotate_x(amount_ud)

##
##func _physics_process(delta):
##
	##var movement := Vector3.ZERO
	##if Globals.flying:
		##movement = (velocity * (.75 * (1 - delta)))
	##else:
		##movement.y = velocity.y - (Globals.gravity * delta)
		#
	#if Globals.test_mode == Globals.TestMode.STATIC_LOAD:
		#rotate_head(0.1, 0, false)
		#set_velocity(movement)
		#move_and_slide()
		#return
		#
	#elif Globals.test_mode == Globals.TestMode.RUN_LOAD:
		#movement = global_transform.basis.z * Vector3.FORWARD * Globals.speed
		#set_velocity(movement)
		#move_and_slide()
		#return
	#
	#var look_ud = Input.get_axis("Look_Down", "Look_Up") * Globals.controller_sensitivity.y
	#var look_lr = Input.get_axis("Look_Left", "Look_Right") * Globals.controller_sensitivity.x
	#rotate_head(look_lr, look_ud, Globals.controller_invert_look)
	#
	#var move_fb = Input.get_axis("Forward", "Backward") * Globals.speed
	#var move_lr = Input.get_axis("Left", "Right") * Globals.speed
	#
	#if Globals.flying:
		#movement += head.global_transform.basis.z * move_fb
		#movement += head.global_transform.basis.x * move_lr
	#else:
		#movement += global_transform.basis.z * move_fb
		#movement += global_transform.basis.x * move_lr
	#
	#if Input.is_action_just_pressed("Jump") and abs(velocity.y) < 0.1:
		#movement += Vector3.UP * Globals.jump_speed
	#
	#set_velocity(movement)
	#move_and_slide()
	#
	

func toggle_flying():
	Globals.flying = !Globals.flying


func toggle_clipping():
	$CollisionShape3D.disabled = !$CollisionShape3D.disabled
	if $CollisionShape3D.disabled:
		Globals.flying = true


func _on_Area_body_entered(_body):
	block_is_inside_character = true


func _on_Area_body_exited(_body):
	block_is_inside_character = false


func _exit_tree():
	Console.remove_command("player_flying")
	Console.remove_command("player_clipping")
