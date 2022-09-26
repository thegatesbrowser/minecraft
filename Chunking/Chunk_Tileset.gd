extends Chunk

onready var grid = $GridMap
onready var grid_mesh = preload("res://Chunking/Blocks_GridMap/Block_Tiles.tres")


func place_block(local_pos: Vector3, type, _regen = true):
	var pos = local_pos.floor()
	grid.set_cell_item(pos.x, pos.y, pos.z, type - 1)


func break_block(local_pos: Vector3, _regen = true):
	place_block(local_pos, WorldGen.AIR)


func update():
	grid.queue_free()
	grid = GridMap.new()
	grid.mesh_library = grid_mesh
	grid.cell_size = Vector3.ONE
	
	for x in Globals.chunk_size.x:
		for z in Globals.chunk_size.z:
			var height = blocks.get_height(x, z)
			for y in height:
				var type = blocks.types[x][z][y]
				if type != WorldGen.AIR and (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
					grid.set_cell_item(x, y, z, type - 1)


func finalize():
	add_child(grid)
	# Finish creating the chunk on the main thread.
	blocks.depool()
