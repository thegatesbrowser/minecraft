extends Spatial

var chunks := {}
var active_chunks := []
var stale_chunks := []
var chunk_thread_count := 0


func update_chunks(player_pos: Vector2, chunk_scene):
	unload_chunks(player_pos)
	load_chunks(player_pos, chunk_scene)


func unload_chunks(player_pos: Vector2):
	var chunks_to_remove = []
	for chunk in active_chunks:
		if player_pos.distance_to(chunk.id) > Globals.unload_radius:
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		chunk.visible = false
		active_chunks.erase(chunk)
		stale_chunks.append(chunk)


func load_chunks(player_pos: Vector2, chunk_scene, use_threading := true):
	if chunk_thread_count > 6:
		Print.warning("There are too many chunk loading threads! " +\
			"New chunks won't be loaded until more threads are available.")
	var ungenerated_chunks = []
	
	for i in range(-Globals.load_radius, Globals.load_radius):
		for j in range(-Globals.load_radius, Globals.load_radius):
			var chunk_pos = Vector2(player_pos.x + i, player_pos.y + j)
			if chunks.has(chunk_pos):
				var chunk = chunks[chunk_pos]
				if stale_chunks.has(chunk):
					stale_chunks.erase(chunk)
					active_chunks.append(chunk)
					chunk.visible = true
			else:
				var chunk = chunk_scene.instance()
				chunk.id = chunk_pos
				chunk.set_position(chunk_pos.x, chunk_pos.y)
				add_child(chunk)
				chunks[chunk_pos] = chunk
				active_chunks.append(chunk)
				ungenerated_chunks.append(chunk)
	if ungenerated_chunks.size() > 0:
		if use_threading:
			chunk_thread_count += 1
			Print.info("Starting chunk load thread. # of Chunks: %s\tThread Count = %s" %\
				[ungenerated_chunks.size(), chunk_thread_count])
			var thread := Thread.new()
			var _d = thread.start(self, "_generate_chunks", [ungenerated_chunks, thread])
		else:
			for chunk in ungenerated_chunks:
				chunk.generate()


# Removes the oldest chunk from the chunks array.
func free_stale_chunk():
	var chunk = stale_chunks[-1]
	var _d = chunks.erase(chunk.id)
	stale_chunks.remove(stale_chunks.size() - 1)
	chunk.queue_free()
	Print.info("Freed Stale Chunk.")


func place_block(pos, chunk_id: Vector2, type):
	if chunks.has(chunk_id):
		var chunk = chunks[chunk_id]
		var bx = posmod(floor(pos.x), Globals.chunk_size.x)
		var by = posmod(floor(pos.y), Globals.chunk_size.y)
		var bz = posmod(floor(pos.z), Globals.chunk_size.z)
		chunk.blocks[bx][by][bz] = type
		chunk.update()
	else:
		Print.error("Player placed a block in a chunk that doesn't exist!")


func break_block(pos: Vector3, chunk_id: Vector2):
	if chunks.has(chunk_id):
		var chunk = chunks[chunk_id]
		var bx = posmod(floor(pos.x), Globals.chunk_size.x)
		var by = posmod(floor(pos.y), Globals.chunk_size.y)
		var bz = posmod(floor(pos.z), Globals.chunk_size.z)
		chunk.blocks[bx][by][bz] = WorldGen.AIR
		chunk.update()
	else:
		Print.error("Player broke a block in a chunk that doesn't exist!")


# Threadsafe API to generate chunk meshes.
func _generate_chunks(args: Array):
	# Unpack
	var ungenerated_chunks = args[0]
	var thread = args[1]
	
	# Generate the chunk (slow)
	for chunk in ungenerated_chunks:
		chunk.generate()
	
	call_deferred("_join_thread", thread)


func _join_thread(thread: Thread):
	thread.wait_to_finish()
	chunk_thread_count -= 1
	Print.info("Finishing chunk load thread.\tThread Count =" + str(chunk_thread_count))

