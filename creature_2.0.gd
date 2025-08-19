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
	rotation_root.add_child(body)

	for i in body.get_children(true):
		if i is MeshInstance3D:
			meshs.append(i)


	collision_shape_3d.shape = creature_resource.coll_shape
	attack_coll.shape = creature_resource.coll_shape
	attack_coll.scale = Vector3(1.1,1.1,1.1)

#ani = body.find_child("AnimationPlayer")
	mesh = body.find_child(creature_resource.mesh_name)
#ani.speed_scale = creature_resource.speed / 2

	collision_shape_3d.position.y =  mesh.get_aabb().size.y / 2
	attack_coll.position.y =  mesh.get_aabb().size.y / 2

	if creature_resource.utility != null:
		if creature_resource.utility.has_ui:
			Globals.new_ui.emit(spawn_pos,creature_resource.utility.ui_scene_path)

	var walk_timer = Timer.new()
	walk_timer.name = "walk_timer"
	walk_timer.wait_time = 0.5
	walk_timer.one_shot = false
	walk_timer.autostart = true
	add_child(walk_timer)
	walk_timer.timeout.connect(on_walk_timeout)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if created_nav == false:
			create_points_around(20)
			
	move_and_slide()
func on_walk_timeout():
	var target_world_space = get_random_pos_in_sphere(20) + global_position
	#var path = Nav.get_nav_path(global_position, target_world_space)
	#print("Path found: ", path)

func create_points_around(radius: int):
	var voxel_tool:VoxelToolTerrain = TerrainHelper.get_terrain_tool().get_voxel_tool()
	var area:AABB = AABB(global_position,Vector3(30,30,30))
	voxel_tool.for_each_voxel_metadata_in_area(area,voxel)
	#print("Copy created: ", copy.get_size())
	created_nav = true
	await get_tree().create_timer(1.0).timeout
	Nav.connect_all_points()
	var target_world_space = get_random_pos_in_sphere(6) + global_position
	var path = Nav.get_nav_path(global_position, target_world_space)
	print("path ",path)
	
func voxel(voxel_position: Vector3i, voxel_metadata: Variant):
	print("voxel")
	if voxel_metadata is String:
		if voxel_metadata == "walkable":
			if Nav.has_point(Vector3(voxel_position.x,voxel_position.y,voxel_position.z)) == false:
				Nav.create_point(voxel_position.x,voxel_position.y,voxel_position.z)
		#if voxel_metadata == "walkable":
			#

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
