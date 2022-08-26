extends Spatial

signal chunk_loaded(id)

var exiting := false
var chunks := {}
var chunk_stats := {}
var active_chunks := []
var stale_chunks := []
var ungenerated_chunks := []

var chunk_threads := []
var chunk_semaphores := []
var chunk_mutex := Mutex.new()


func _ready():
	if !Globals.single_threaded_mode:
		for i in Globals.chunk_loading_threads:
			var t := Thread.new()
			var err = t.start(self, "_generate_chunks_thread", [i])
			if err:
				Print.error("Chunk thread failed to start with error code %" % err)
			chunk_threads.append(t)
			chunk_semaphores.append(Semaphore.new())


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
	chunk_mutex.lock()
	for i in range(-Globals.load_radius, Globals.load_radius):
		for j in range(-Globals.load_radius, Globals.load_radius):
			var chunk_pos = Vector2(player_pos.x + i, player_pos.y + j)

			if !chunk_stats.has(chunk_pos):
				chunk_stats[chunk_pos] = ChunkStatistics.new()

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
				chunks[chunk_pos] = chunk
				active_chunks.append(chunk)
				
				ungenerated_chunks.push_back(chunk)
	
	if ungenerated_chunks.size() == 0:
		chunk_mutex.unlock()
		return
	
	# Process the data now.
	if use_threading and !Globals.single_threaded_mode:
		Print.debug("Starting multithread chunk loading. # of Chunks: %s" % ungenerated_chunks.size())
		for sem in chunk_semaphores:
			sem.post()
		chunk_mutex.unlock()
	
	else:
		Print.debug("Starting main thread chunk loading. # of Chunks: %s" % ungenerated_chunks.size())
		var ugen_chunks = ungenerated_chunks.duplicate()
		ungenerated_chunks.clear()
		chunk_mutex.unlock()
		for c in ugen_chunks:
			add_child(c)
			c.generate()
			yield(get_tree(),"idle_frame")
			c.update()
			yield(get_tree(),"idle_frame")
		Print.debug("Finished loading %s chunks on main thread." % ugen_chunks.size())


# Removes the oldest chunk from the chunks array.
func free_stale_chunk():
	if stale_chunks.size() > 0:
		var chunk = stale_chunks[-1]
		var _d = chunks.erase(chunk.id)
		stale_chunks.erase(chunk)
		chunk.queue_free()
		Print.debug("Freed Stale Chunk.")
	else:
		Print.error("There are no stale chunks to free! Something is eating up memory!")


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
		chunk.break_block(local_pos)
	else:
		Print.error("Player broke a block in a chunk that doesn't exist!")
	
	chunk_mutex.lock()
	if chunk_stats.has(chunk_id):
		pass
	chunk_mutex.unlock()


# Threadsafe API to generate chunk meshes.
func _generate_chunks_thread(args: Array):
	var thread_num: int = args[0]
	Print.info("Thread %s is online and waiting to start." % thread_num)
	chunk_semaphores[thread_num].wait()
	Print.info("Thread %s is now working." % thread_num)
	
	while !exiting:
		chunk_mutex.lock()
		while ungenerated_chunks.size() > 0 and !exiting:
			var chunk: Chunk = ungenerated_chunks.pop_front()
			chunk_mutex.unlock()
			
			var time: int
			# Generate the chunk (slow)
			time = Time.get_ticks_usec()
			chunk.generate()
			var generate_time = Time.get_ticks_usec() - time

			time = Time.get_ticks_usec()
			chunk.update()
			var update_time = Time.get_ticks_usec() - time
						
			if chunk_stats.has(chunk.id):
				var stats: ChunkStatistics = chunk_stats[chunk.id]
				stats.generate_time = generate_time
				stats.update_time = update_time
				stats.times_generated += 1
			else:
				Print.error("Chunk %s doesn't have any statistics associated!" % chunk.id)
			
			emit_signal("chunk_loaded", chunk.id)
			call_deferred("add_child", chunk)
			chunk_mutex.lock()
		
		chunk_mutex.unlock()
		chunk_semaphores[thread_num].wait()
	Print.info("Thread %s is shutting down." % thread_num)


func _exit_tree():
	exiting = true
	for sem in chunk_semaphores:
		sem.post()
	for i in chunk_threads.size():
		Print.info("Waiting on thread %s." % i)
		var thread: Thread = chunk_threads[i]
		while thread.is_alive():
			chunk_semaphores[i].post()
		thread.wait_to_finish()
	Print.info("All threads have been collected.")
