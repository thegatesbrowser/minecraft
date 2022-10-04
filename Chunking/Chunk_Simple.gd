extends Chunk

export(Array, Resource) var block_resources := []

var block_array := []
var block_objects: Node = null
var rendered := false


func place_block(local_pos: Vector3, type, _regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, type)
	_destroy_block(pos.x, pos.y, pos.z)
	_create_block(pos.x, pos.y, pos.z, type)


func break_block(local_pos: Vector3, regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, WorldGen.AIR)
	if regen:
		update()
		blocks.depool()
	else:
		_destroy_block(pos.x, pos.y, pos.z)


func update():
	if !rendered:
		_render()
	else:
		blocks.update()
		for x in Globals.chunk_size.x:
			for z in Globals.chunk_size.z:
				var height = blocks.get_height(x, z)
				for y in height:
					if blocks.types[x][z][y] == WorldGen.AIR:
						_destroy_block(x, y, z)
					elif (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
						if block_array[x][z][y] == null:
							_create_block(x, y, z, blocks.types[x][z][y])


func _render():
	block_array = []
# warning-ignore:narrowing_conversion
	block_array.resize(Globals.chunk_size.x)
	block_objects = Node.new()
	for x in Globals.chunk_size.x:
		block_array[x] = []
		block_array[x].resize(Globals.chunk_size.z)
		for z in Globals.chunk_size.z:
			block_array[x][z] = []
			block_array[x][z].resize(Globals.chunk_size.y)
			var height = blocks.get_height(x, z)
			for y in height:
				if blocks.types[x][z][y] != WorldGen.AIR and (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
					_create_block(x, y, z, blocks.types[x][z][y])


func _create_block(x, y, z, type):
	var block = block_resources[type].instance()
	block.translation = translation + Vector3(x + 0.5, y + 0.5, z + 0.5)
	block_objects.add_child(block)
	block_array[x][z][y] = block


func _destroy_block(x, y, z):
	if block_array[x][z][y] != null:
		var block = block_array[x][z][y]
		block.queue_free()
	block_array[x][z][y] = null


func finalize():
	if !rendered:
		add_child(block_objects)
		rendered = true
	
	# Finish creating the chunk on the main thread.
	blocks.depool()
