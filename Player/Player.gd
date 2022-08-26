extends KinematicBody

onready var camera = $Head/Camera
onready var ray = $Head/RayCast
onready var block = $BlockOutline
onready var head = $Head

var velocity := Vector3.ZERO

signal place_block(pos)
signal break_block(pos)


func _input(event):	
	if Globals.paused:
		return
	
	if event is InputEventMouseMotion:
		rotate_head(event.relative.x * Globals.mouse_sensitivity.x, -event.relative.y * Globals.mouse_sensitivity.y, Globals.mouse_invert_look)


func rotate_head(amount_lr: float, amount_ud: float, inverted: bool):
	if inverted:
		amount_ud = -amount_ud
	
	# Look left and right.
	rotate_y(deg2rad(-amount_lr))
	
	var head_rotation = head.rotation_degrees.x
	if head_rotation + amount_ud <= Globals.max_look_vertical and \
			head_rotation + amount_ud >= -Globals.max_look_vertical:
		head.rotate_x(deg2rad(amount_ud))


func _physics_process(delta):
	var movement := Vector3.ZERO
	movement.y = velocity.y - (Globals.gravity * delta)
	
	var look_ud = Input.get_axis("Look_Down", "Look_Up") * Globals.controller_sensitivity.y
	var look_lr = Input.get_axis("Look_Left", "Look_Right") * Globals.controller_sensitivity.x
	rotate_head(look_lr, look_ud, Globals.controller_invert_look)
	
	var move_fb = Input.get_axis("Forward", "Backward") * Globals.speed
	var move_lr = Input.get_axis("Left", "Right") * Globals.speed
	
	movement += global_transform.basis.z * move_fb
	movement += global_transform.basis.x * move_lr
	
	if Input.is_action_just_pressed("Jump"):
		movement += Vector3.UP * Globals.jump_speed
	
	velocity = move_and_slide(movement)
	
	if ray.is_colliding():
		var normal = ray.get_collision_normal()
		var pos = ray.get_collision_point() - normal * 0.5
		
		block.global_translation = pos.floor() + (Vector3.ONE / 2)
		block.global_rotation = Vector3.ZERO
		block.visible = true
		
		if Input.is_action_just_pressed("Mine"):
			emit_signal("break_block", pos)
		if Input.is_action_just_pressed("Build"):
			emit_signal("place_block", pos + normal)
	else:
		block.visible = false
