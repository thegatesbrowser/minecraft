extends Chunk

enum Faces{
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

const vertices = [
	Vector3(0, 0, 0), #0	   2 +--------+ 3  a+------+b 
	Vector3(1, 0, 0), #1	    /|       /|     |      |
	Vector3(0, 1, 0), #2	   / |      / |     |      |
	Vector3(1, 1, 0), #3	6 +--------+ 7|    c+------+d
	Vector3(0, 0, 1), #4	  |0 +-----|--+ 1  
	Vector3(1, 0, 1), #5	  | /      | /     b-a-c
	Vector3(0, 1, 1), #6	  |/       |/      b-c-d
	Vector3(1, 1, 1)  #7	4 +--------+ 5
]

const TOP = [2, 3, 6, 7]
const BOTTOM = [4, 5, 0, 1]
const LEFT = [2, 6, 0, 4]
const RIGHT = [7, 3, 5, 1]
const BACK = [6, 7, 4, 5]
const FRONT = [3, 2, 1, 0]

const TEXTURE_ATLAS_SIZE := Vector2(8,2)

const offsets = {
	WorldGen.AIR:{
	},
	WorldGen.DIRT:{
		Faces.TOP:Vector2(2, 0), Faces.BOTTOM:Vector2(2, 0), Faces.LEFT:Vector2(2, 0),
		Faces.RIGHT:Vector2(2,0), Faces.FRONT:Vector2(2, 0), Faces.BACK:Vector2(2, 0),
	},
	WorldGen.GRASS:{
		Faces.TOP:Vector2(0, 0), Faces.BOTTOM:Vector2(2, 0), Faces.LEFT:Vector2(1, 0),
		Faces.RIGHT:Vector2(1, 0), Faces.FRONT:Vector2(1, 0), Faces.BACK:Vector2(1, 0),
	},
	WorldGen.STONE:{
		Faces.TOP:Vector2(3, 0), Faces.BOTTOM:Vector2(3, 0), Faces.LEFT:Vector2(3, 0),
		Faces.RIGHT:Vector2(3, 0), Faces.FRONT:Vector2(3, 0), Faces.BACK:Vector2(3, 0),
	},
	WorldGen.LOG1:{
		Faces.TOP:Vector2(5, 0), Faces.BOTTOM:Vector2(5, 0), Faces.LEFT:Vector2(4, 0),
		Faces.RIGHT:Vector2(4, 0), Faces.FRONT:Vector2(4, 0), Faces.BACK:Vector2(4, 0),
	},
	WorldGen.LEAVES1:{
		Faces.TOP:Vector2(6, 0), Faces.BOTTOM:Vector2(6, 0), Faces.LEFT:Vector2(6, 0),
		Faces.RIGHT:Vector2(6, 0), Faces.FRONT:Vector2(6, 0), Faces.BACK:Vector2(6, 0),
	},
	WorldGen.WOOD1:{
		Faces.TOP:Vector2(7, 0), Faces.BOTTOM:Vector2(7, 0), Faces.LEFT:Vector2(7, 0),
		Faces.RIGHT:Vector2(7,0), Faces.FRONT:Vector2(7, 0), Faces.BACK:Vector2(7, 0),
	},
	WorldGen.LOG2:{
		Faces.TOP:Vector2(5, 1), Faces.BOTTOM:Vector2(5, 1), Faces.LEFT:Vector2(4, 1),
		Faces.RIGHT:Vector2(4, 1), Faces.FRONT:Vector2(4, 1), Faces.BACK:Vector2(4, 1),
	},
	WorldGen.LEAVES2:{
		Faces.TOP:Vector2(6, 1), Faces.BOTTOM:Vector2(6, 1), Faces.LEFT:Vector2(6, 1),
		Faces.RIGHT:Vector2(6, 1), Faces.FRONT:Vector2(6, 1), Faces.BACK:Vector2(6, 1),
	},
	WorldGen.WOOD2:{
		Faces.TOP:Vector2(7, 1), Faces.BOTTOM:Vector2(7, 1), Faces.LEFT:Vector2(7, 1),
		Faces.RIGHT:Vector2(7,1), Faces.FRONT:Vector2(7, 1), Faces.BACK:Vector2(7, 1),
	},
	WorldGen.GLASS:{
		Faces.TOP:Vector2(2, 1), Faces.BOTTOM:Vector2(2, 1), Faces.LEFT:Vector2(2, 1),
		Faces.RIGHT:Vector2(2,1), Faces.FRONT:Vector2(2, 1), Faces.BACK:Vector2(2, 1),
	},
	WorldGen.STUMP:{
	}
}

var st = SurfaceTool.new()
var mesh: Mesh = null
var mesh_instance: MeshInstance = null

var material = preload("res://Assets/Materials/texturemat_mesh.tres")


func _ready():
	material.albedo_texture.set_flags(2)


func place_block(local_pos: Vector3, type, regen = true):
	blocks.set_block(local_pos, type)
	if regen:
		update()
		finalize()


func break_block(local_pos: Vector3, regen = true):
	place_block(local_pos, WorldGen.AIR, regen)


func update():
	# Update the block data.
	blocks.update()
	
	# Unload chunk.
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null
	
	# Generate new chunk.
	mesh = Mesh.new()
	mesh_instance = MeshInstance.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in Globals.chunk_size.x:
		for z in Globals.chunk_size.z:
			create_column(x, z, blocks.types[x][z], blocks.flags[x][z])
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)
	
	mesh_instance.create_trimesh_collision()


func finalize():
	add_child(mesh_instance)
	blocks.depool()


func create_column(x: int, z: int, types: PoolByteArray, faces: PoolByteArray):
	var height = blocks.get_height(x, z)
	for y in height:
		create_block(Vector3(x, y, z), types[y], faces[y])


func create_block(pos: Vector3, type: int, flags: int):
	var block_offsets = offsets[type]
	if type == WorldGen.AIR:
		return
	if (flags & ChunkData.ALL_SIDES == ChunkData.ALL_SIDES):
		return
	
	if !flags & ChunkData.TOP:
		create_face(TOP, pos, block_offsets[Faces.TOP])
	if !flags & ChunkData.BOTTOM:
		create_face(BOTTOM, pos, block_offsets[Faces.BOTTOM])
	if !flags & ChunkData.FRONT:
		create_face(FRONT, pos, block_offsets[Faces.FRONT])
	if !flags & ChunkData.BACK:
		create_face(BACK, pos, block_offsets[Faces.BACK])
	if !flags & ChunkData.LEFT:
		create_face(LEFT, pos, block_offsets[Faces.LEFT])
	if !flags & ChunkData.RIGHT:
		create_face(RIGHT, pos, block_offsets[Faces.RIGHT])


func create_face(face, pos: Vector3, texture_atlas_offset):
	# a+------+b 
	#  |      | b-c-a
	#  |      | b-d-c
	# c+------+d
	var a = vertices[face[0]] + pos
	var b = vertices[face[1]] + pos
	var c = vertices[face[2]] + pos
	var d = vertices[face[3]] + pos
	
	var uv_offset = texture_atlas_offset / TEXTURE_ATLAS_SIZE
	var height = 1.0 / TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(width, 0)
	var uv_c = uv_offset + Vector2(0, height)
	var uv_d = uv_offset + Vector2(width, height)
	
	st.add_triangle_fan([b, c, a], [uv_b, uv_c, uv_a])
	st.add_triangle_fan([b, d, c], [uv_b, uv_d, uv_c])
