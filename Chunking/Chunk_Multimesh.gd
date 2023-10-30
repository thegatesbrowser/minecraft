extends Chunk

var rendered := false
@onready var multimeshes = [$Dirt, $Grass, $Stone, $Log1, $Leaves1, $Wood1, $Log2, $Leaves2, $Wood2, $Glass]
@onready var block_counts = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var multimesh_arrays = []


func place_block(local_pos: Vector3, type, regen = true):
	var pos = local_pos.floor()
	blocks.set_block(pos, type)
	if regen:
		update()
		finalize()


func break_block(local_pos: Vector3, regen = true):
	place_block(local_pos, WorldGen.AIR, regen)


func update():
	multimesh_arrays = []
	for i in multimeshes.size():
		multimesh_arrays.append([])
	
	for x in Globals.chunk_size.x:
		for z in Globals.chunk_size.z:
			@warning_ignore("narrowing_conversion")
			var height = blocks.get_height(x, z)
			for y in height:
				if blocks.types[x][z][y] != WorldGen.AIR and (blocks.flags[x][z][y] & ChunkData.ALL_SIDES != ChunkData.ALL_SIDES):
					_create_block(x, y, z, blocks.types[x][z][y])
	
	for i in multimeshes.size():
		var size = multimesh_arrays[i].size()
		multimeshes[i].multimesh.instance_count = size
		for j in size:
			multimeshes[i].multimesh.set_instance_transform(j, multimesh_arrays[i][j])


func _create_block(x, y, z, type):
	var t = Transform3D(Basis(), Vector3(x, y, z))
	multimesh_arrays[type - 1].append(t)


func finalize():
	# Finish creating the chunk checked the main thread.
	blocks.depool()
