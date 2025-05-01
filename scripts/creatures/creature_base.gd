extends CharacterBody3D
class_name CreatureBase

var look_at_target:Vector3

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
@onready var jump_2: RayCast3D = $RotationRoot/jump2

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

@export var StateManager:Node
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
	


func _physics_process(delta: float) -> void:
	if Connection.is_server() == false:
		interpolate_client(delta)
		return
		
	if creature_resource.flyies:
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
	else:
		if not is_on_floor():
			velocity.y -= 30 * delta
			
		if !target_reached:
			if jump.is_colliding() and is_on_floor():
				velocity.y += 10
			elif jump_2.is_colliding() and is_on_floor():
				velocity.y += 10
			
		
	rotation_root.look_at(look_at_target)
		
	move_and_slide()
	
	set_sync_properties()


func _process(_delta: float) -> void:
	if not Connection.is_server(): return

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




@rpc("any_peer","call_local")
func tame(owner_id:int):
	var players = get_tree().get_nodes_in_group("Player")
	for i in players:
		if owner_id == i.name.to_int():
			#StateManager._on_child_transition(self,"Follow")
			animal_owner = i
			animal_ownerid = owner_id
			#print(animal_owner)
			#_on_move_timeout()
	
func give(item:ItemBase,id):
	feed_sfx.play()
	if creature_resource.excepted_items.has(item):
		var max_steps = creature_resource.amount
		tame_step += 1
		tame_progress = (tame_step / max_steps) * 100
		
	if tame_progress >= 100:
		if animal_owner == null:
			tame.rpc_id(1,id)
			
	
func show_debug():
	$target.visible = !$target.visible
