extends Spatial
class_name Chunk


var id := Vector2.ZERO
var blocks := []


func set_position(x: float, z: float):
	translation = Vector3(x * Globals.chunk_size.x, 0, z * Globals.chunk_size.z)


func generate():
	var pos = translation.floor()
	blocks = []
	blocks.resize(int(Globals.chunk_size.x))
	for i in range(0, Globals.chunk_size.x):
		blocks[i] = []
		blocks[i].resize(int(Globals.chunk_size.y))
		for j in range(0, Globals.chunk_size.y):
			blocks[i][j] = []
			blocks[i][j].resize(int(Globals.chunk_size.z))
			for k in range(0, Globals.chunk_size.z):
				blocks[i][j][k] = WorldGen.get_block_type(i + pos.x, j + pos.y, k + pos.z)
	update()


func update():
	Print.error("Attempted to call update on chunk base class!")
