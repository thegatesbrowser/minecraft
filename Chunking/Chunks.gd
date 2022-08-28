extends Spatial

var chunks := {}
var active_chunks := []
var stale_chunks := []
var chunks_to_generate := []
var active_threads := 0


func update_chunks(player_pos: Vector2, chunk_scene):
	unload_chunks(player_pos)
		# Only works in debug mode :-( I guess I'll have to actually optimize this thing...
	if OS.get_static_memory_usage() > 1073741824 * Globals.max_game_memory_gb:
		_free_stale_chunks()
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


func load_chunks(player_pos: Vector2, chunk_scene, atomic_load := false):
	var num_new := 0
	for i in range(-Globals.load_radius, Globals.load_radius):
		for j in range(-Globals.load_radius, Globals.load_radius):
			var chunk_pos = Vector2(player_pos.x + i, player_pos.y + j)
			if ((player_pos - chunk_pos).length() > Globals.load_radius) and !atomic_load:
				continue
			
			if chunks.has(chunk_pos):
				var chunk = chunks[chunk_pos]
				if stale_chunks.has(chunk):
					stale_chunks.erase(chunk)
					active_chunks.append(chunk)
					chunk.visible = true
			else:
				num_new += 1
				var chunk: Chunk = chunk_scene.instance()
				chunk.id = chunk_pos
				chunks[chunk_pos] = chunk
				chunk.update_position()
				if atomic_load:
					_generate_chunk(chunk, false)
				else:
					chunks_to_generate.append(chunk)
	if atomic_load:
		Print.debug("Finished loading %s chunks on the main thread." % num_new)
	elif Globals.single_threaded_mode:
		Print.debug("Queued %s chunks to load during idle time." % num_new)
	else:
		Print.debug("Queued %s chunks to load asynchronously." % num_new)

func place_block(global_pos, chunk_id: Vector2, type):
	if chunks.has(chunk_id):
		var chunk = chunks[chunk_id]
		var local_pos = global_pos.posmodv(Globals.chunk_size)
		chunk.place_block(local_pos, type)
	else:
		Print.error("Player placed a block in a chunk that doesn't exist!")


func break_block(global_pos: Vector3, chunk_id: Vector2):
	if chunks.has(chunk_id):
		var chunk = chunks[chunk_id]
		var local_pos = global_pos.posmodv(Globals.chunk_size)
		if local_pos.y > 1:
			chunk.break_block(local_pos)
	else:
		Print.error("Player broke a block in a chunk that doesn't exist!")


# Removes the oldest chunk from the chunks array.
func _free_stale_chunks():
	var num_to_free := Globals.load_radius * 4
	if stale_chunks.size() < num_to_free:
		Globals.unload_radius = int(max(2, Globals.unload_radius - 1))
		# This is drastic, but we're trying to generate too many blocks, so we should get rid of the ones that are too far out.
		Print.error("There are no more stale chunks to free! " + "Decreasing the chunk load and unload radius to " +\
			"%s and %s to meet the hardware requirements." % [Globals.load_radius, Globals.unload_radius])
	else:
		for _i in num_to_free:
			var chunk = stale_chunks[-1]
			var _d = chunks.erase(chunk.id)
			stale_chunks.erase(chunk)
			chunk.queue_free()
		Print.debug("Freed %s Stale Chunks." % num_to_free)


func _process(_delta):
	if active_threads < Globals.chunk_loading_threads and chunks_to_generate.size() > 0:
		_generate_chunk(chunks_to_generate.pop_front(), !Globals.single_threaded_mode)
		if chunks_to_generate.size() == 0:
			Print.debug("Finished loading chunks.")


func _generate_chunk(chunk: Chunk, use_threading := true):
	if use_threading:
		active_threads += 1
		var thread := Thread.new()
		var _d = thread.start(self, "_generate_chunk_thread", [chunk])
		while thread.is_alive():
			yield(get_tree(),"idle_frame")
		thread.wait_to_finish()
		active_threads -= 1
	else:
		chunk.generate()
		chunk.update()
	chunk.finalize()
	call_deferred("add_child", chunk)
	active_chunks.append(chunk)


func _generate_chunk_thread(args: Array):
	var chunk = args[0]
	chunk.generate()
	chunk.update()
