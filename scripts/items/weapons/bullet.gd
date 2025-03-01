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
		queue_free()


func destory() -> void:
	queue_free()
