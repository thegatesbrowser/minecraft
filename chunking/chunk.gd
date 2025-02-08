extends Node3D
class_name Chunk


var id := Vector2.ZERO
var blocks := ChunkData.new()
var modified := false


func update_position():
	position = Vector3(id.x * Globals.chunk_size.x, 0, id.y * Globals.chunk_size.z)


func place_block(_local_pos: Vector3, _type, _update = true):
	Print.error("Attempted to call place_block checked chunk base class!")

func break_block(_local_pos: Vector3, _update = true):
	Print.error("Attempted to call break_block checked chunk base class!")
	print("breake")

func update():
	Print.error("Attempted to call update checked chunk base class!")


func finalize():
	Print.error("Attempted to call update checked chunk base class!")


func generate():
	blocks.generate(id, Vector3(id.x * Globals.chunk_size.x, 0, id.y * Globals.chunk_size.z))
