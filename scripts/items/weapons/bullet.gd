extends Area3D

var damage:int = 1
var spawner:Node


func _physics_process(_delta: float) -> void:
	var forward_dir = -global_transform.basis.z.normalized()
	global_translate(forward_dir)


func kill(body: Node3D) -> void:
	if "health" in body:
		body.hit()
	else:
		server_kill.rpc()


func destory() -> void:
	server_kill.rpc()

@rpc("any_peer","call_local")
func server_kill():
	#if not multiplayer.is_server(): return
	queue_free()
