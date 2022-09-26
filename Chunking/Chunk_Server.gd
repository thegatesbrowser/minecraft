extends Chunk

var block_mats = [ null,
		preload("res://Chunking/Blocks_Server/Dirt.tres"),
		preload("res://Chunking/Blocks_Server/Grass.tres"),
		preload("res://Chunking/Blocks_Server/Stone.tres"),
		preload("res://Chunking/Blocks_Server/Log1.tres"),
		preload("res://Chunking/Blocks_Server/Leaves1.tres"),
		preload("res://Chunking/Blocks_Server/Wood1.tres"),
		preload("res://Chunking/Blocks_Server/Log2.tres"),
		preload("res://Chunking/Blocks_Server/Leaves2.tres"),
		preload("res://Chunking/Blocks_Server/Wood2.tres"),
		preload("res://Chunking/Blocks_Server/Glass.tres")
	]

var block_ids = []
var block_array := []
var scenario
var material
var collide
var rendered := false
var shape


func _ready():
	scenario = get_world().scenario
	for mat in block_mats:
		if mat == null:
			block_ids.append(null)
		else:
			block_ids.append(mat.get_rid())
	
	var xform = Transform(Basis(), translation)
	collide = PhysicsServer.body_create(PhysicsServer.BODY_MODE_STATIC)
	
	PhysicsServer.body_set_space(collide, get_world().space)
	PhysicsServer.body_set_state(collide, PhysicsServer.BODY_STATE_TRANSFORM, xform)
	PhysicsServer.body_set_collision_layer(collide, 0)
	
	shape = PhysicsServer.shape_create(PhysicsServer.SHAPE_BOX)
	PhysicsServer.shape_set_data(shape, (Vector3.ONE / 2))


func place_block(local_pos: Vector3, type, regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, type)
	if regen:
		update()
		finalize()
	else:
		_destroy_block(pos.x, pos.y, pos.z)
		_create_block(pos.x, pos.y, pos.z, type)
#		_add_collider(pos.x, pos.y, pos.z)


func break_block(local_pos: Vector3, regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, WorldGen.AIR)
	if regen:
		update()
		finalize()
	else:
		_destroy_block(pos.x, pos.y, pos.z)


func update():
	if !rendered:
		_render()
	else:
		PhysicsServer.body_clear_shapes(collide)
		for x in Globals.chunk_size.x:
			for z in Globals.chunk_size.z:
				var height = blocks.get_height(x, z)
				for y in height:
					if blocks.types[x][z][y] == WorldGen.AIR:
						_destroy_block(x, y, z)
					elif (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
						if block_array[x][z][y] == null:
							_create_block(x, y, z, blocks.types[x][z][y])
#						_add_collider(x, y, z)


func _render():
	rendered = true
	block_array = []
# warning-ignore:narrowing_conversion
	block_array.resize(Globals.chunk_size.x)
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
#					_add_collider(x, y, z)


func _create_block(x, y, z, type):
	var xform = Transform(Basis(), translation + Vector3(x, y, z) + Vector3(0.5, 0.5, 0.5))
	var visual = VisualServer.instance_create2(block_ids[type], scenario)
	VisualServer.instance_set_transform(visual, xform)
	block_array[x][z][y] = visual


func _add_collider(x, y, z):
	PhysicsServer.body_add_shape(collide, shape, Transform(Basis(), Vector3(x, y, z)))


func _destroy_block(x, y, z):
	if block_array[x][z][y] != null:
		VisualServer.free_rid(block_array[x][z][y][0])
		PhysicsServer.free_rid(block_array[x][z][y][1])
		block_array[x][z][y] = null


func finalize():
	blocks.depool()
