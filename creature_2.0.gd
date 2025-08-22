extends CharacterBody3D
class_name CreatureBase

var spawn_pos:Vector3

var gravity:float = 30

@export var creature_resource: Creature

@onready var jump: RayCast3D = $RotationRoot/jump
@onready var jump_2: RayCast3D = $RotationRoot/jump2

@onready var rotation_root: Node3D = $RotationRoot
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var eyes: RayCast3D = $eyes
@onready var attack_coll: CollisionShape3D = $"attack range/CollisionShape3D"
@onready var ground_raycast:RayCast3D = $Ground


@onready var guide: Node3D = $guide


var ani: AnimationPlayer
var mesh: MeshInstance3D
var meshs: Array[MeshInstance3D]

var health
var created_nav:bool = false

func _ready() -> void:
	health = creature_resource.max_health


	var body = creature_resource.body_scene.instantiate()
	add_child(body)

	#for i in body.get_children(true):
		#if i is MeshInstance3D:
			#meshs.append(i)


	#collision_shape_3d.shape = creature_resource.coll_shape
	#attack_coll.shape = creature_resource.coll_shape
	#attack_coll.scale = Vector3(1.1,1.1,1.1)

#ani = body.find_child("AnimationPlayer")
	#mesh = body.find_child(creature_resource.mesh_name)
#ani.speed_scale = creature_resource.speed / 2

	#collision_shape_3d.position.y =  mesh.get_aabb().size.y / 2
	#attack_coll.position.y =  mesh.get_aabb().size.y / 2

	#if creature_resource.utility != null:
	#if creature_resource.utility.has_ui:
		#	Globals.new_ui.emit(spawn_pos,creature_resource.utility.ui_scene_path)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if jump.is_colliding():
			print("jump")
			velocity.y += 2

	find_player()

	rotation_root.rotation.y = lerp(rotation_root.rotation.y,guide.rotation.y, delta * 2.0)

	

	move_and_slide()

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

func find_player():
	var pos = global_position
	var player = get_tree().get_first_node_in_group("Player").global_position
	
	var path = Nav.find_path(pos,player)

	print("path ",path)

	for i in path:
		if path.size() >= 2:
			var point = path[1] + Vector3(0.5,0,0.5)

			var direction = global_position.direction_to(point)

			velocity = direction * creature_resource.speed

			guide.look_at(point)

			print("move to",point, "from ", pos)
			
	