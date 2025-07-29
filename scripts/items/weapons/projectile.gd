extends Area3D

var resource:Projectile
var damage:int = 1
var spawner:Node
@onready var coll:CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	#print("thrown")
	if resource:
		if resource.model != null:
			#print("Item ",Item)
			var mesh = resource.model.instantiate()
			add_child(mesh)
			
			if mesh is MeshInstance3D:
				var mesh_aabb = mesh.get_aabb()
				var coll_shape:BoxShape3D = BoxShape3D.new()
				coll_shape.size = mesh_aabb.size
				coll.shape = coll_shape
			else:
				print("error: mesh is not a MeshInstance3D needs to be changed to work!!")
		

func _physics_process(_delta: float) -> void:
	var forward_dir =- global_transform.basis.z.normalized() * resource.speed
	global_translate(forward_dir)

func kill(body: Node3D) -> void:
	if "health" in body:
		if body is Player:
			if body.get_multiplayer_authority() != get_multiplayer_authority():
				body.rpc_id(body.get_multiplayer_authority(),"hit",resource.damage)
				destory()
		else:
			body.hit()
			destory()
	else:
		destory()
			



func destory() -> void:
	server_kill.rpc()
	if resource.explode_on_contact:
		_explode.rpc_id(1,global_position)

@rpc("any_peer","call_local")
func _explode(_position:Vector3):
	TerrainHelper.get_terrain_tool().get_voxel_tool().do_sphere(_position,4.0)
	server_kill.rpc()
	
@rpc("any_peer","call_local")
func server_kill():
	queue_free()
