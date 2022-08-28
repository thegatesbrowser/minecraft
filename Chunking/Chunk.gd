extends Spatial
class_name Chunk


var id := Vector2.ZERO
var blocks := []


func update_position():
	translation = Vector3(id.x * Globals.chunk_size.x, 0, id.y * Globals.chunk_size.z)

func place_block(_local_pos: Vector3, _type, _update = true):
	Print.error("Attempted to call place_block on chunk base class!")


func break_block(_local_pos: Vector3, _update = true):
	Print.error("Attempted to call break_block on chunk base class!")


func update():
	Print.error("Attempted to call update on chunk base class!")


func finalize():
	Print.error("Attempted to call update on chunk base class!")


func generate():
	var pos = translation.floor()
	var chunk_data = WorldGen.start_new_chunk(id)
	blocks = []
	blocks.resize(int(Globals.chunk_size.x))
	for i in range(0, Globals.chunk_size.x):
		blocks[i] = []
		blocks[i].resize(int(Globals.chunk_size.y))
		for j in range(0, Globals.chunk_size.y):
			blocks[i][j] = []
			blocks[i][j].resize(int(Globals.chunk_size.z))
	
	# Work top to botton in the y direction.
	var j = Globals.chunk_size.y - 1
	while j >= 0:
		var i = 0
		while i < Globals.chunk_size.x:
			var k = 0
			while k < Globals.chunk_size.z:
				var block = WorldGen.get_block_type(i + pos.x, j + pos.y, k + pos.z, chunk_data)
				if block == WorldGen.STUMP:
					_generate_tree(i, j, k, pos, chunk_data)
				else:
					blocks[i][j][k] = block
				k += 1
			i += 1
		j -= 1


func _generate_tree(i, j, k, pos, chunk_data):
	# Check if we have room for a tree here.
	var tree := WorldGen.get_tree_dimensions(i + pos.x, j + pos.y, chunk_data)
	
	# Abort!
	if i < tree.brim_width or i + tree.brim_width >= Globals.chunk_size.x or \
			k < tree.brim_width or k + tree.brim_width >= Globals.chunk_size.z:
		blocks[i][j][k] = WorldGen.AIR
		return
	for y in range(WorldGen.tree_heights.x, WorldGen.tree_heights.y):
		if blocks[i][j + y + 1][k] != WorldGen.AIR:
			blocks[i][j][k] = WorldGen.AIR
			return
	
	# Make the tree!
	for y in range(tree.trunk_height + tree.brim_height):
		blocks[i][j + y][k] = tree.trunk_type
	var offset := tree.trunk_height
	for x in range(-tree.brim_width, tree.brim_width + 1):
		for y in range(0, tree.brim_height):
			for z in range(-tree.brim_width, tree.brim_width + 1):
				if blocks[i + x][j + y + offset][k + z] == WorldGen.AIR:
					blocks[i + x][j + y + offset][k + z] = tree.leaf_type
	offset += tree.brim_height
	for x in range(-tree.top_width, tree.top_width + 1):
		for y in range(tree.top_height):
			for z in range(-tree.top_width, tree.top_width + 1):
				blocks[i + x][j + y + offset][k + z] = tree.leaf_type
