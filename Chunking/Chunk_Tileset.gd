extends Chunk

@onready var grid = $GridMap
@onready var grid_mesh = preload("res://Chunking/Blocks_GridMap/Block_Tiles.tres")


func place_block(local_pos: Vector3, type, _regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, type)
	grid.set_cell_item( Vector3(pos.x,pos.y,pos.z) ,type - 1)


func break_block(local_pos: Vector3, _regen = true):
	place_block(local_pos, WorldGen.AIR)
	update()
	finalize()


func update():
	grid.queue_free()
	grid = GridMap.new()
	grid.mesh_library = grid_mesh
	grid.cell_size = Vector3.ONE
	blocks.update()
	
	for x in Globals.chunk_size.x:
		for z in Globals.chunk_size.z:
			@warning_ignore("narrowing_conversion")
			var height = blocks.get_height(x, z)
			for y in height:
				var type = blocks.types[x][z][y]
				if type != WorldGen.AIR and (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
					grid.set_cell_item( Vector3(x,y,z) ,type - 1)


func finalize():
	add_child(grid)
	# Finish creating the chunk checked the main thread.
	blocks.depool()
