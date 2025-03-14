
const VoxelLibrary = preload("res://resources/voxel_block_library.tres")
const Structure = preload("./structure.gd")
var structure:String

var channel := VoxelBuffer.CHANNEL_TYPE

func generate() -> Structure:
	var voxels: Dictionary = {}
	
	var structure_data = load(structure).instantiate()
	
	for i in structure_data.get_children():
		var type = i.name.rstrip(".0123456789") as String
		var type_length = type.length()
		type = type.left(type_length - 1)
		#print("structure block type ",type)
		voxels[Vector3(i.position.x, i.position.y, i.position.z)] =  VoxelLibrary.get_model_index_default(type)
	#structure_data.hide()
	# Let's make crappy trees

	# Make structure
	var aabb: AABB = AABB()
	for pos in voxels:
		aabb = aabb.expand(pos)
	
	var structure: Structure = Structure.new()
	structure.offset = -aabb.position

	var buffer: VoxelBuffer = structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos: Vector3 = pos + structure.offset
		var v: int = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)
	
	return structure
