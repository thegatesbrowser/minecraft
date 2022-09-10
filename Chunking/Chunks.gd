extends Spatial

signal chunk_started(pos)
signal chunk_generated(pos, gen_time)
signal chunk_updated(pos, gen_time)
signal chunk_deactivated(pos)
signal chunk_purged(pos)
signal chunk_reactivated(pos)

var chunk_scene
var chunks := {}
var player_chunk_pos := Vector2.ZERO

var active_threads := []
var active_chunks := []
var stale_chunks := []

var generate_radius := 0


# Load all chunks within the load radius, and unload chunks outside.
func update_chunks(player_pos: Vector2):
	var chunks_to_remove = []
	for chunk in active_chunks:
		if player_pos.distance_to(chunk.id) > Globals.load_radius:
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		chunk.visible = false
		active_chunks.erase(chunk)
		stale_chunks.append(chunk)
		emit_signal("chunk_deactivated", chunk.id)
	
	if active_threads.size() < Globals.chunk_loading_threads:
		load_chunks(player_pos)
	
	if stale_chunks.size() > Globals.max_stale_chunks:
		_free_stale_chunks()


func load_chunks(player_pos: Vector2):
	var x = 0
	var y = 0
	var direction = 1
	var length = 1
	
	player_chunk_pos = player_pos
	while length < (Globals.load_radius + 1) * 2:
		while 2 * x * direction < length:
			if load_chunk(player_pos, x, y) and (Globals.single_threaded_mode or \
					active_threads.size() >= Globals.chunk_loading_threads):
				generate_radius = length / 2
				return
			x = x + direction
		while 2 * y * direction < length:
			if load_chunk(player_pos, x, y) and (Globals.single_threaded_mode or \
					active_threads.size() >= Globals.chunk_loading_threads):
				generate_radius = length / 2
				return
			y = y + direction
		direction = -1 * direction
		length = length + 1


func load_chunk(player_pos, x, y, use_threading := true):
	var created_chunk := false
	var chunk_pos = Vector2(player_pos.x + x, player_pos.y + y)
	
	if (player_pos - chunk_pos).length() <= Globals.load_radius:
		if not chunks.has(chunk_pos):
			var chunk: Chunk = chunk_scene.instance()
			chunk.id = chunk_pos
			chunks[chunk_pos] = chunk
			chunk.update_position()
			_generate_chunk(chunk, use_threading and !Globals.single_threaded_mode)
			created_chunk = true
		else:
			var chunk = chunks[chunk_pos]
			if stale_chunks.has(chunk):
				stale_chunks.erase(chunk)
				active_chunks.append(chunk)
				chunk.visible = true
				emit_signal("chunk_reactivated", chunk_pos)
	
	return created_chunk


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
	if stale_chunks.size() < 1:
		Globals.load_radius = int(max(3, Globals.load_radius - 1))
		# This is drastic, but we're trying to generate too many blocks, so we should get rid of the ones that are too far out.
		Print.error("There are no more stale chunks to free! " + "Decreasing the chunk load radius to " +\
			"%s to meet the hardware requirements." % [Globals.load_radius])
	else:
		var chunk = stale_chunks.pop_front()
		var _d = chunks.erase(chunk.id)
		emit_signal("chunk_purged", chunk.id)
		chunk.queue_free()


func _generate_chunk(chunk: Chunk, use_threading := true):
	if use_threading:
		emit_signal("chunk_started", chunk.id)
		# Generate the noise for the chunk.
		var time = Time.get_ticks_usec()
		var gen_thread := Thread.new()
		active_threads.append(gen_thread)
		var _d = gen_thread.start(self, "_generate_chunk_thread", [chunk])
		while gen_thread.is_alive():
			yield(get_tree(),"idle_frame")
		gen_thread.wait_to_finish()
		active_threads.erase(gen_thread)
		emit_signal("chunk_generated", chunk.id, Time.get_ticks_usec() - time)

		# Update the chunk.
		time = Time.get_ticks_usec()
		var up_thread := Thread.new()
		_d = up_thread.start(self, "_update_chunk_thread", [chunk])
		active_threads.append(up_thread)
		while up_thread.is_alive():
			yield(get_tree(),"idle_frame")
		up_thread.wait_to_finish()
		active_threads.erase(up_thread)
		emit_signal("chunk_updated", chunk.id, Time.get_ticks_usec() - time)
	else:
		emit_signal("chunk_started", chunk.id)
		var time = Time.get_ticks_usec()
		chunk.generate()
		emit_signal("chunk_generated", chunk.id, Time.get_ticks_usec() - time)
		time = Time.get_ticks_usec()
		chunk.update()
		emit_signal("chunk_updated", chunk.id, Time.get_ticks_usec() - time)
	chunk.finalize()
	add_child(chunk)
	active_chunks.append(chunk)


func _generate_chunk_thread(args: Array):
	var chunk = args[0]
	chunk.generate()


func _update_chunk_thread(args: Array):
	var chunk = args[0]
	chunk.update()
