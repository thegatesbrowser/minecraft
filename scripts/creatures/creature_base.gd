extends CharacterBody3D
class_name CreatureBase

@export var creature_resource: Creature

@export_group("Sync Properties")
@export var _position: Vector3
@export var _velocity: Vector3
@export var _rotation: Vector3 = Vector3.ZERO
@export var _direction: Vector3 = Vector3.ZERO

@export var sync_delta_max := 0.2
@export var sync_delta := 0.0
@export var start_interpolate := false

@export var walk_distance = 50
@onready var jump: RayCast3D = $RotationRoot/jump
@onready var rotation_root: Node3D = $RotationRoot
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var eyes: RayCast3D = $eyes
@onready var attack_coll: CollisionShape3D = $"attack range/CollisionShape3D"
@onready var ground_raycast:RayCast3D = $Ground
@export var walk_timer:Timer
var walk_time := 10.0

@onready var feed_sfx: AudioStreamPlayer3D = $Sounds/feed

@onready var hurt_sfx: AudioStreamPlayer3D = $Sounds/hurt
@onready var death_sfx: AudioStreamPlayer3D = $Sounds/death

@onready var guide: Node3D = $guide

@onready var player_view_distance: float = 128 * sqrt(2)

@export var target_reached: bool = false
@export var _synchronizer:MultiplayerSynchronizer

var health
var tame_step:int = 0
var tame_progress:float = 100.0 ## percent
var animal_owner:Player
var animal_ownerid:int

var position_before_sync: Vector3 = Vector3.ZERO
var last_sync_time_ms: int = 0

var speed : float
var vel : Vector3
var state_machine
enum states {IDLE, WALKING, ATTACKING}
var current_state = states.IDLE
var target_position: Vector3
var gravity:float = 30

var ani: AnimationPlayer
var mesh: MeshInstance3D
var terrain: VoxelTerrain

var is_despawning: bool = false


func _ready() -> void:
	if Connection.is_server():
		terrain = TerrainHelper.get_terrain_tool()
	else:
		#_synchronizer.delta_synchronized.connect(on_synchronized)
		#_synchronizer.synchronized.connect(on_synchronized)
		pass
	
	health = creature_resource.max_health
	
	hurt_sfx.stream = creature_resource.hurt_sound
	death_sfx.stream = creature_resource.death_sound
	#
	var body = creature_resource.body_scene.instantiate()
	rotation_root.add_child(body)
	
	collision_shape_3d.shape = creature_resource.coll_shape
	attack_coll.shape = creature_resource.coll_shape
	attack_coll.scale = Vector3(1.1,1.1,1.1)
	
	ani = body.find_child("AnimationPlayer")
	mesh = body.find_child(creature_resource.mesh_name)
	ani.speed_scale = creature_resource.speed / 2
	
	collision_shape_3d.position.y =  mesh.get_aabb().size.y / 2
	attack_coll.position.y =  mesh.get_aabb().size.y / 2
	
	change_state("idle")


func change_state(state: String) -> void:
	match state:
		"idle":
			#if ani.current_animation != creature_resource.idle_ani_name:
				#ani.play(creature_resource.idle_ani_name)
			current_state = states.IDLE
			speed = 0.000000001
		"walking":
			#if ani.current_animation != creature_resource.walk_ani_name:
				#ani.play(creature_resource.walk_ani_name)
			current_state = states.WALKING
			speed = creature_resource.speed
			
		"attack":
			#if ani.current_animation != creature_resource.walk_ani_name:
				#ani.play(creature_resource.walk_ani_name)
			current_state = 3
			speed = creature_resource.speed


func _physics_process(delta: float) -> void:
	if Connection.is_server() == false:
		interpolate_client(delta)
		return
		
	if creature_resource.flyies:
		flying_movement(delta)
	else:
		ground_movement(delta)
	
	set_sync_properties()


func _process(_delta: float) -> void:
	if not Connection.is_server(): return
	
	if global_position.distance_to(target_position) < 5:
		if target_reached == false:
			change_state("idle")
			target_reached = true
			

		
	if creature_resource.attacks:
		var closest_player = get_closest_player()
	
		if closest_player != null:
			eyes.look_at(closest_player.global_position)
		
		if eyes.is_colliding():
			var coll = eyes.get_collider()
			if coll != null:
				if coll.is_in_group("Player"):
					change_state("attack")
					target_position = coll.global_position
	
	try_despawn()


func try_despawn() -> void:
	if is_despawning: return
	
	var creature_pos = global_position
	creature_pos.y = 0

	var players = get_tree().get_nodes_in_group("Player")
	for player in players:
		var player_pos = player.global_position
		player_pos.y = 0

		if player_pos.distance_to(creature_pos) < player_view_distance:
			return
	
	is_despawning = true
	await get_tree().create_timer(1.0).timeout
	queue_free()


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


func _on_move_timeout() -> void:
	if Connection.is_server() == false: return
	
	if animal_owner == null:
		walk_time = 10
		var sphere_point = get_random_pos_in_sphere(walk_distance)
		target_position = sphere_point + global_position
		target_reached = false
	else:
		walk_time = 10
		target_position = animal_owner.global_position
		#print(animal_owner.global_position)
		target_reached = false
		
	walk_timer.wait_time = walk_time
	change_state("walking")


func hit(damage:int = 1):
	#print("hit")
	hurt_sfx.play()
	health -= damage
	if health <= 0:
		print("creature killed")
		death_sfx.play()
		if creature_resource.drop_items.size() != 0:
			var drop_item = creature_resource.drop_items.pick_random()
			Globals.spawn_item_inventory.emit(drop_item)
		queue_free()


func get_closest_player() -> Node:
	var last_distance: float
	var closest_player: Node
	
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


func set_sync_properties() -> void:
	_position = position
	_velocity = velocity
	_rotation = rotation_root.rotation


func interpolate_client(delta: float) -> void:
	if not start_interpolate: return
	#print("inter")
	# Interpolate rotation
	rotation_root.rotation = _rotation.slerp(rotation_root.rotation, delta)
	
	# Don't interpolate to avoid small jitter when stopping
	if (_position - position).length() > 1 and _velocity.is_zero_approx():
		position = _position.slerp(_position,delta) # Fix misplacement
	
	# Interpolate between position_before_sync and _position
	# and add to ongoing movement to compensate misplacement
	var t = 2 if is_zero_approx(sync_delta) else delta / sync_delta
	sync_delta = clampf(sync_delta - delta, 0, sync_delta_max)
	
	var less_misplacement = position_before_sync.move_toward(_position, t)
	position += less_misplacement - position_before_sync
	position_before_sync = less_misplacement
	
	velocity.y -= gravity * delta
	move_and_slide()


func ground_movement(delta:float):
	if not is_on_floor():
		velocity.y -= 30 * delta
	
	var new_velocity: Vector3
	if !target_reached:
		$target.global_position = target_position
		var current_pos = global_position
		var new_velocity_x = (target_position.x - current_pos.x)
		var new_velocity_z = (target_position.z - current_pos.z)
		new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * speed
	else:
		new_velocity = Vector3(0,0,0)
	
	velocity = velocity.move_toward(new_velocity, .25)
	
	if target_position != null:
		if !target_reached:
			if guide.global_position != target_position:
				guide.look_at(target_position)
	
	rotation_root.rotation.y = lerpf(rotation_root.rotation.y,guide.rotation.y,.2)
	
	if !target_reached:
		if jump.is_colliding() and is_on_floor():
			velocity.y += 10
	
	move_and_slide()

func flying_movement(delta:float):
	if ground_raycast.is_colliding():
			if jump.is_colliding():
				velocity.y += 10 * delta
			else:
				var hit_distance = global_position.distance_to(ground_raycast.get_collision_point())
				#print(hit_distance)
				if hit_distance < creature_resource.flying_height:
					velocity.y += 10 * delta
				else:
					velocity.y -= 10 * delta
		
	var new_velocity: Vector3
	if !target_reached:
		$target.global_position = target_position
		var current_pos = global_position
		var new_velocity_x = (target_position.x - current_pos.x)
		var new_velocity_z = (target_position.z - current_pos.z)
		new_velocity = Vector3(new_velocity_x,0,new_velocity_z).normalized() * speed
	else:
		new_velocity = Vector3(0,0,0)
	
	velocity = velocity.move_toward(new_velocity, .25)
	
	if target_position != null:
		if !target_reached:
			if guide.global_position != target_position:
				guide.look_at(target_position)
	
	rotation_root.rotation.y = lerpf(rotation_root.rotation.y,guide.rotation.y,.2)
	
	
	move_and_slide()

@rpc("any_peer","call_local")
func tame(owner_id:int):
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if owner_id == i.name.to_int():
			animal_owner = i
			animal_ownerid = owner_id
			#print(animal_owner)
			_on_move_timeout()
	
func give(item:ItemBase,id):
	feed_sfx.play()
	if creature_resource.excepted_items.has(item):
		var max_steps = creature_resource.amount
		tame_step += 1
		tame_progress = (tame_step / max_steps) * 100
		
	if tame_progress >= 100:
		if animal_owner == null:
			tame.rpc_id(1,id)
			
	
