extends Resource
class_name ChunkData

# Flags
const TOP = 1 << 0
const BOTTOM = 1 << 1
const LEFT = 1 << 2
const RIGHT = 1 << 3
const FRONT = 1 << 4
const BACK = 1 << 5
const ALL_SIDES = TOP | BOTTOM | LEFT | RIGHT | FRONT | BACK

# Generated Data
var types := []
var flags := []
var heights := []
var stumps := {}

# Chunk info
var chunk_id: Vector2
var chunk_pos: Vector3
var chunk_size: Vector3


func generate(id: Vector2, pos: Vector3):
	chunk_size = Globals.chunk_size
	chunk_id = id
	chunk_pos = pos
	var chunk_data = WorldGen.start_new_chunk(id)
	
	_generate_types(pos, chunk_data)
	_generate_trees(pos, chunk_data)
	_generate_faces(pos, chunk_data)


func update():
	if flags.empty():
		_generate_faces(chunk_pos, null, true)


func depool():
	for i in chunk_size.x:
		for j in chunk_size.z:
			if types[i][j] is PoolByteArray:
				types[i][j] = Array(types[i][j])
	
	# We have to rebuild this anyways if the types array changes.
	flags = []


func check_visible(pos: Vector3, direction: int) -> bool:
	return !bool(flags[pos.x][pos.z][pos.y] & direction)


func _set_visible_safe(i: int, j: int, k: int):
	if i > 0:
		flags[i - 1][j][k] |= RIGHT
	if i < chunk_size.x - 1:
		flags[i + 1][j][k] |= LEFT
	if j > 0:
		flags[i][j - 1][k] |= BACK
	if j < chunk_size.z - 1:
		flags[i][j + 1][k] |= FRONT
	if k > 0:
		flags[i][j][k - 1] |= TOP
	if k < chunk_size.y - 1:
		flags[i][j][k + 1] |= BOTTOM


func get_height(x: int, z: int):
	return heights[x][z]


func get_block(pos: Vector3):
	pos = pos.floor()
	return types[pos.x][pos.z][pos.y]


func set_block(pos: Vector3, t: int):
	pos = pos.floor()
	types[pos.x][pos.z][pos.y] = t
	heights[pos.x][pos.z] = max(pos.y + 1, heights[pos.x][pos.z])
	_generate_faces(pos, null, true)


func _generate_types(pos: Vector3, data):
	var pool_array = PoolByteArray()
	for y in chunk_size.y:
		pool_array.append(0)
	
	types.resize(int(chunk_size.x))
	heights.resize(int(chunk_size.x))
	for i in range(0, chunk_size.x):
		types[i] = []
		types[i].resize(int(chunk_size.z))
		heights[i] = []
		heights[i].resize(int(chunk_size.z))
		for j in range(0, chunk_size.z):
			types[i][j] = pool_array
	
	# Set all blocks within the chunk.
	var block
	for i in chunk_size.x:
		for j in chunk_size.z:
			# Work top to bottom in the y direction.
			var biome_percent = WorldGen.get_biome_percent(i + pos.x, j + pos.z)
			# Use the internal call so we don't waste time re-calculating height or biome percent.
			var height = WorldGen._get_height(i + pos.x, j + pos.z, biome_percent)
			heights[i][j] = height + 1
			var h = height + 2
			for k in h:
				# Use the internal call so we don't waste time re-calculating height or biome percent.
				block = WorldGen._get_block_type(i + pos.x, k + pos.y, j + pos.z, data, biome_percent, height)
				types[i][j][k] = block
				if block == WorldGen.STUMP:
					types[i][j][k] = WorldGen.AIR
					stumps[Vector2(i, j)] = k


func _generate_trees(pos: Vector3, data):
	for v in stumps.keys():
		_generate_tree(v.x, v.y, stumps[v], pos, data)


func _generate_faces(pos: Vector3, data, skip_edges := false):
	var pool_array = PoolByteArray()
	for y in chunk_size.y:
		pool_array.append(0)
	
	flags = []
	flags.resize(int(chunk_size.x))
	for i in range(0, chunk_size.x):
		flags[i] = []
		flags[i].resize(int(chunk_size.z))
		for j in range(0, chunk_size.z):
			flags[i][j] = pool_array
	
	# Set flags internally.
	for i in range(1, chunk_size.x - 1):
		for j in range(1, chunk_size.z - 1):
			# Work top to bottom in the y direction.
			var height = heights[i][j]
			flags[i][j][0] |= (ALL_SIDES ^ TOP)
			flags[i][j][1] |= BOTTOM
			var r = range(1, height)
			for k in r:
				if WorldGen.is_transparent[types[i][j][k]]:
					flags[i - 1][j][k] |= RIGHT
					flags[i + 1][j][k] |= LEFT
					flags[i][j - 1][k] |= BACK
					flags[i][j + 1][k] |= FRONT
					flags[i][j][k - 1] |= TOP
					flags[i][j][k + 1] |= BOTTOM
	
	# Set flags on the outer edges.
	var edges := !Globals.skyblock and !skip_edges
	
	for i in chunk_size.x:
		flags[i][0][0] |= (ALL_SIDES ^ TOP)
		var height = heights[i][0] 
		for k in height:
			if WorldGen.is_transparent[types[i][0][k]]:
				_set_visible_safe(i, 0, k)
			if edges and WorldGen.is_transparent[WorldGen.get_block_type(pos.x + i, pos.y + k, pos.z - 1, data)]:
				flags[i][0][k] |= FRONT
		
		flags[i][chunk_size.z - 1][0] |= (ALL_SIDES ^ TOP)
		height = heights[i][chunk_size.z - 1]
		for k in height:
			if WorldGen.is_transparent[types[i][chunk_size.z - 1][k]]:
# warning-ignore:narrowing_conversion
				_set_visible_safe(i, chunk_size.z - 1, k)
			if edges and WorldGen.is_transparent[WorldGen.get_block_type(pos.x + i, pos.y + k, pos.z + chunk_size.z, data)]:
				flags[i][chunk_size.z - 1][k] |= BACK
	
	for j in chunk_size.z:
		flags[0][j][0] |= (ALL_SIDES ^ TOP)
		var height = heights[0][j]
		for k in height:
			if WorldGen.is_transparent[types[0][j][k]]:
				_set_visible_safe(0, j, k)
			if edges and WorldGen.is_transparent[WorldGen.get_block_type(pos.x - 1, pos.y + k, pos.z + j, data)]:
				flags[0][j][k] |= LEFT
		flags[chunk_size.x - 1][j][0] |= (ALL_SIDES ^ TOP)
		height = heights[chunk_size.x - 1][j]
		for k in height:
			if WorldGen.is_transparent[types[chunk_size.x - 1][j][k]]:
# warning-ignore:narrowing_conversion
				_set_visible_safe(chunk_size.z - 1, j, k)
			if edges and WorldGen.is_transparent[WorldGen.get_block_type(pos.x + chunk_size.x, pos.y + k, pos.z + j, data)]:
				flags[chunk_size.x - 1][j][k] |= RIGHT


func _generate_tree(i: int, j: int, k: int, pos: Vector3, data):
	# Check if we have room for a tree here.
	var tree := WorldGen.get_tree_dimensions(i + pos.x, j + pos.z, data)
	
	# Abort!
	if i < tree.brim_width or i + tree.brim_width >= chunk_size.x or \
			j < tree.brim_width or j + tree.brim_width >= chunk_size.z:
		return
	for y in range(WorldGen.tree_heights.x, WorldGen.tree_heights.y):
		if types[i][j][k + y + 1] != WorldGen.AIR:
			return
	if k + tree.brim_height + tree.trunk_height + tree.top_height >= Globals.chunk_size.y:
		return
	
	# Kill the grass.
	types[i][j][k - 1] = WorldGen.DIRT
	
	# Make the tree!
	for y in range(tree.trunk_height + tree.brim_height):
		types[i][j][k + y] = tree.trunk_type
	
	var offset := tree.trunk_height
	var height := k + tree.trunk_height + tree.brim_height
	for x in range(-tree.brim_width, tree.brim_width + 1):
		for z in range(-tree.brim_width, tree.brim_width + 1):
			for y in range(tree.brim_height):
				if types[i + x][j + z][k + y + offset] == WorldGen.AIR:
					types[i + x][j + z][k + y + offset] = tree.leaf_type
			heights[i + x][j + z] = max(heights[i + x][j + z], height)

	offset += tree.brim_height
	height += tree.top_height
	for x in range(-tree.top_width, tree.top_width + 1):
		for z in range(-tree.top_width, tree.top_width + 1):
			for y in range(tree.top_height):
				if types[i + x][j + z][k + y + offset] == WorldGen.AIR:
					types[i + x][j + z][k + y + offset] = tree.leaf_type
			heights[i + x][j + z] = max(heights[i + x][j + z], height)
