extends Spatial

signal chunk_started(pos)
signal chunk_generated(pos, gen_time)
signal chunk_updated(pos, gen_time)
signal chunk_deactivated(pos)
signal chunk_purged(pos)
signal chunk_reactivated(pos)
signal finished_loading

var chunk_scene
var chunks := {}
var player_chunk_pos := Vector2.ZERO
var loading_complete := false

var active_threads := []
var active_chunks := []
var stale_chunks := []

var generate_radius := 0


# Load all chunks within the load radius, and unload chunks outside.
func update_chunks(player_pos: Vector2):
	if loading_complete and player_chunk_pos == player_pos:
		return
	
	if Globals.skyblock:
		return
	
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
	
	loading_complete = false
	player_chunk_pos = player_pos
	while length < (Globals.load_radius + 1) * 2:
		while 2 * x * direction < length:
			if load_chunk(player_pos, x, y) and (active_threads.size() >= Globals.chunk_loading_threads):
				generate_radius = length / 2
				return
			x = x + direction
		while 2 * y * direction < length:
			if load_chunk(player_pos, x, y) and (active_threads.size() >= Globals.chunk_loading_threads):
				generate_radius = length / 2
				return
			y = y + direction
		direction = -1 * direction
		length = length + 1
	
	loading_complete = true
	emit_signal("finished_loading")


func load_chunk(player_pos, x, y, use_threading := true):
	var created_chunk := false
	var chunk_pos = Vector2(player_pos.x + x, player_pos.y + y)
	
	if (player_pos - chunk_pos).length() <= Globals.load_radius:
		if not chunks.has(chunk_pos):
			var chunk: Chunk = chunk_scene.instance()
			chunk.id = chunk_pos
			chunks[chunk_pos] = chunk
			chunk.update_position()
			_generate_chunk(chunk, use_threading)
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
		chunk.modified = true
	else:
		Print.error("Player placed a block in a chunk that doesn't exist!")


func break_block(global_pos: Vector3, chunk_id: Vector2):
	if chunks.has(chunk_id):
		var chunk = chunks[chunk_id]
		var local_pos = global_pos.posmodv(Globals.chunk_size)
		if local_pos.y > 1:
			chunk.break_block(local_pos)
			chunk.modified = true
		
		if local_pos.x < 1:
			yield(get_tree(),"idle_frame")
			_regen_block(chunk_id + Vector2.LEFT)
		elif local_pos.x > Globals.chunk_size.x - 1:
			yield(get_tree(),"idle_frame")
			_regen_block(chunk_id + Vector2.RIGHT)
		if local_pos.z < 1:
			yield(get_tree(),"idle_frame")
			_regen_block(chunk_id + Vector2.UP)
		elif local_pos.z > Globals.chunk_size.z - 1:
			yield(get_tree(),"idle_frame")
			_regen_block(chunk_id + Vector2.DOWN)
	else:
		Print.error("Player broke a block in a chunk that doesn't exist!")


func _regen_block(chunk_id):
	if chunks.has(chunk_id):
		var chunk: Chunk = chunks[chunk_id]
		chunk.update()
		chunk.finalize()


# Removes the oldest chunk from the chunks array.
func _free_stale_chunks():
	if stale_chunks.size() > 1:
		var chunk = stale_chunks.pop_front()
		if chunk.modified:
			stale_chunks.append(chunk)
		else:
			var _d = chunks.erase(chunk.id)
			emit_signal("chunk_purged", chunk.id)
			chunk.queue_free()


func _generate_chunk(chunk: Chunk, use_threading := true):
	add_child(chunk)
	# Generate the chunk.
	var time = Time.get_ticks_usec()
	emit_signal("chunk_started", chunk.id)
	if use_threading:
		# Generate the noise for the chunk.
		var gen_thread := Thread.new()
		active_threads.append(gen_thread)
		var _d = gen_thread.start(self, "_generate_chunk_thread", [chunk])
		while gen_thread.is_alive():
			yield(get_tree(),"idle_frame")
		gen_thread.wait_to_finish()
		active_threads.erase(gen_thread)
	else:
		chunk.generate()
	emit_signal("chunk_generated", chunk.id, Time.get_ticks_usec() - time)
	
	time = Time.get_ticks_usec()
	if use_threading and !Globals.single_threaded_mode:
		# Update the chunk.
		var up_thread := Thread.new()
		var _d = up_thread.start(self, "_update_chunk_thread", [chunk])
		active_threads.append(up_thread)
		while up_thread.is_alive():
			yield(get_tree(),"idle_frame")
		up_thread.wait_to_finish()
		active_threads.erase(up_thread)
	else:
		chunk.update()
	chunk.finalize()
	emit_signal("chunk_updated", chunk.id, Time.get_ticks_usec() - time)
	active_chunks.append(chunk)


func _generate_chunk_thread(args: Array):
	var chunk = args[0]
	chunk.generate()


func _update_chunk_thread(args: Array):
	var chunk = args[0]
	chunk.update()

