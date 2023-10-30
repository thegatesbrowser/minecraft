extends Chunk


func place_block(_local_pos: Vector3, _type, regen = true):
	# Add a block to the chunk.
	if regen:
		blocks.update()
		update()
		finalize()


func break_block(_local_pos: Vector3, _regen = true):
	# Remove a block from the chunk.
	pass


func update():
	# Render the chunk.
	pass


func finalize():
	# Finish creating the chunk checked the main thread.
	blocks.depool()
