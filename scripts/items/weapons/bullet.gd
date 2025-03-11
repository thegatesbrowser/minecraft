extends Area3D

var damage:int = 1
var spawner:Node


func _physics_process(_delta: float) -> void:
	var forward_dir = - global_transform.basis.z.normalized()
	global_translate(forward_dir)


func kill(body: Node3D) -> void:
	if "health" in body:
		if body is Player:
			body.rpc_id(body.get_multiplayer_authority(),"hit",damage)
			destory()
		else:
			body.hit()
			destory()
	else:
		destory()


func destory() -> void:
	server_kill.rpc()

@rpc("any_peer","call_local")
func server_kill():
	#if not multiplayer.is_server(): return
	queue_free()
