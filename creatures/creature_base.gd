extends CharacterBody3D

@export var creature_resource:Creature

var ani:AnimationPlayer
var body:Node
var mesh:MeshInstance3D
var health:int

@onready var coll = $CollisionShape3D
@onready var nav = $NavigationAgent3D
@export var walk_distance = 20
@onready var auto_jump: RayCast3D = $"auto jump"
@onready var can_auto_jump_check: RayCast3D = $"auto jump2"

var speed : float
var vel : Vector3
var state_machine
enum states {IDLE, WALKING}
var current_state = states.IDLE
var target_pos

func _ready() -> void:
	if creature_resource != null:
		health = creature_resource.max_health
		var _body = creature_resource.body_scene.instantiate()
		body = _body
		add_child(_body)
		
		
		ani = body.find_child("AnimationPlayer")
		mesh = body.find_child("Cube_002")
		
		var aabb = mesh.get_aabb()
		print(aabb)
		#if creature_resource.creature_coll_baseshape == CylinderShape3D:
			#var shape = creature_resource.creature_coll_baseshape
			#shape.height = + mesh.get_aabb().size.y
		var shape = creature_resource.creature_coll_baseshape
		shape.size = creature_resource.coll_size
		coll.shape = shape
		coll.global_position = mesh.global_position
		#coll.position = aabb.position


func change_state(state):
	match state:
		"idle":
			current_state = states.IDLE
			speed = 0.000000001
		"walking":
			current_state = states.WALKING
			speed = creature_resource.speed
			
func _physics_process(delta):
		
	#velocity.y -= 2
	var next_pos = nav.get_next_path_position()
	var current_pos = global_position
	var new_velocity = (next_pos- current_pos).normalized() * speed
	velocity = velocity.move_toward(new_velocity, .25)
	
	if not is_on_floor():
		#print("! ground")
		velocity.y -= 9.8 * delta
		
	if is_on_floor():
		if auto_jump.is_colliding():
			velocity.y = 10.0
		#body.look_at_from_position(self.position,next_pos, Vector3(0,1,0))
	if $guide.position != next_pos:
		$guide.look_at(next_pos)
	
	body.rotation.y = $guide.rotation.y
	auto_jump.rotation.y = $guide.rotation.y
	can_auto_jump_check.rotation.y = $guide.rotation.y
	
	move_and_slide()
	
	## Auto jump
	
func move_to(target_pos):
	change_state("walking")
	var closest_pos = NavigationServer3D.map_get_closest_point(get_world_3d().get_navigation_map(), target_pos)
	nav.target_position = closest_pos

func get_random_pos_in_sphere(radius : float) -> Vector3:
	var x1= randi_range(-1,1)
	var x2= randi_range(-1,1)
	
	while x1*x1 + x2*x2 >=1:
		x1= randi_range(-1,1)
		x2= randi_range(-1,1)
		
	var random_pos_on_unit_sphere = Vector3 (
		1 -2 * (x1*x1 + x2*x2),
		0,
		1 -2 * (x1*x1 + x2*x2))
		
	random_pos_on_unit_sphere.x *= randi_range(-radius, radius)
	random_pos_on_unit_sphere.z *= randi_range(-radius, radius)
	
	return random_pos_on_unit_sphere

func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	set_velocity(safe_velocity)

func move():
	var sphere_point = get_random_pos_in_sphere(20)
	move_to(sphere_point)
	
	
func _on_move_timeout() -> void:
	move()
	change_state("walking")


func _on_navigation_agent_3d_target_reached() -> void:
	change_state("idle")
	print("target_reached")
