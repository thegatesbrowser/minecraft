extends CharacterBody3D

@export var creature_resource:Creature

var health

@export var walk_distance = 20
@onready var nav = $NavigationAgent3D
@onready var jump: RayCast3D = $RotationRoot/jump
@onready var rotation_root: Node3D = $RotationRoot
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var eyes: RayCast3D = $eyes
@onready var attack_coll: CollisionShape3D = $"attack range/CollisionShape3D"

@onready var guide: Node3D = $guide

var target_reached:bool = false
var speed : float
var vel : Vector3
var state_machine
enum states {IDLE, WALKING, ATTACKING}
var current_state = states.IDLE
var target_pos

var ani:AnimationPlayer
var mesh:MeshInstance3D


func _ready() -> void:
	set_physics_process(false)
	health = creature_resource.max_health
	var body = creature_resource.body_scene.instantiate()
	rotation_root.add_child(body)
	collision_shape_3d.shape = creature_resource.coll_shape
	attack_coll.shape = creature_resource.coll_shape
	attack_coll.scale = Vector3(1.1,1.1,1.1)
	#collision_shape_3d.shape.height = creature_resource.coll_height
	#collision_shape_3d.shape.radius = creature_resource.coll_radius
	ani = body.find_child("AnimationPlayer")
	mesh = body.find_child("Object_7")
	collision_shape_3d.position.y =  mesh.get_aabb().size.y / 2
	attack_coll.position.y =  mesh.get_aabb().size.y / 2
	set_physics_process(true)


func change_state(state,_target_pos = null):
	match state:
		"idle":
			target_pos = null
			if ani.current_animation != "idle":
				ani.play("idle")
			current_state = states.IDLE
			speed = 0.000000001
		"walking":
			target_pos = null
			if ani.current_animation != creature_resource.walk_ani_name:
				ani.play(creature_resource.walk_ani_name)
			current_state = states.WALKING
			speed = creature_resource.speed
			
		"attack":
			if ani.current_animation != creature_resource.walk_ani_name:
				ani.play(creature_resource.walk_ani_name)
			current_state = 3
			speed = creature_resource.speed
			move_to(_target_pos)


func _physics_process(delta):
	if creature_resource.attacks:
		var look_at = get_cloest_player()
		eyes.look_at(look_at.global_position)
		
		if eyes.is_colliding():
			var coll = eyes.get_collider()
			if coll != null:
				if coll.is_in_group("Player"):
					change_state("attack",coll.global_position)
		
	if not is_on_floor():
		velocity.y -= 30 * delta
	else:
		#velocity.y -= 2
		pass
		
	var next_pos = nav.get_next_path_position()
	var current_pos = global_position
	var new_velocity_x = (next_pos.x - current_pos.x)
	var new_velocity_z = (next_pos.z - current_pos.z)
	var new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * speed
	velocity = velocity.move_toward(new_velocity, .25)
	
	if next_pos != null:
		if guide.global_position != next_pos:
			guide.look_at(next_pos)
			
	rotation_root.rotation.y = lerpf(rotation_root.rotation.y,guide.rotation.y,.2)
	#rotation_root.rotation.y = guide.rotation.y
	if !target_reached:
		if jump.is_colliding() and is_on_floor():
			velocity.y += 10
		
	move_and_slide()
	
func move_to(target_pos):
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
	var sphere_point = get_random_pos_in_sphere(walk_distance)
	var target = sphere_point + global_position
	if current_state != 3:
		move_to(target)
		change_state("walking")


func _on_move_timeout() -> void:
	move()
	target_reached = false
	#print("move")

func _on_navigation_agent_3d_navigation_finished() -> void:
	change_state("idle")
	target_reached = true
	

func _on_start_timeout() -> void:
	move()
	
func hit(damage:int = 1):
	health -= damage
	if health <= 0:
		print("killed")
		if creature_resource.drop_items.size() != 0:
			var drop_item = creature_resource.drop_items.pick_random()
			Globals.spawn_item_inventory.emit(drop_item)
			queue_free()
		else:
			queue_free()


func get_cloest_player():
	var last_distance
	var closest_player:Node
	for i in get_tree().get_nodes_in_group("Player"):
		if last_distance == null:
			last_distance = global_position.distance_to(i .global_position)
			closest_player = i
		else:
			if last_distance > global_position.distance_to(i .global_position):
				last_distance = global_position.distance_to(i .global_position)
				closest_player = i
		return closest_player


func _on_attack_range_body_entered(body: Node3D) -> void:
	if creature_resource.attacks:
		if body.is_in_group("Player"):
			if body.has_method("hit"):
				body.hit(creature_resource.damage)
