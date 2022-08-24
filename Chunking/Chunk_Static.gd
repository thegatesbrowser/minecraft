extends Chunk

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

var st = SurfaceTool.new()
var mesh: Mesh = null
var mesh_instance: MeshInstance = null

var material = preload("res://Assets/texturemat.tres")

func _ready():
	material.albedo_texture.set_flags(2)

func update():
	# Unload chunk.
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null
	
	# Generate new chunk.
	mesh = Mesh.new()
	mesh_instance = MeshInstance.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in Globals.chunk_size.x:
		for y in Globals.chunk_size.y:
			for z in Globals.chunk_size.z:
				create_block(Vector3(x, y, z))
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)
	
	mesh_instance.create_trimesh_collision()
	call_deferred("add_child", mesh_instance)


func check_transparent(pos: Vector3) -> bool:
	if pos.x >= 0 and pos.x < Globals.chunk_size.x and \
		pos.y >= 0 and pos.y < Globals.chunk_size.y and \
		pos.z >= 0 and pos.z < Globals.chunk_size.z:
			return not WorldGen.types[blocks[pos.x][pos.y][pos.z]][WorldGen.SOLID]
	return true


func create_block(pos: Vector3):
	var block = blocks[pos.x][pos.y][pos.z]
	var block_info = WorldGen.types[block]
	if block == WorldGen.AIR:
		return
	
	if check_transparent(pos + Vector3.UP):
		create_face(TOP, pos, block_info[WorldGen.TOP])
	if check_transparent(pos + Vector3.DOWN):
		create_face(BOTTOM, pos, block_info[WorldGen.BOTTOM])
	if check_transparent(pos + Vector3.FORWARD):
		create_face(FRONT, pos, block_info[WorldGen.FRONT])
	if check_transparent(pos + Vector3.BACK):
		create_face(BACK, pos, block_info[WorldGen.BACK])
	if check_transparent(pos + Vector3.LEFT):
		create_face(LEFT, pos, block_info[WorldGen.LEFT])
	if check_transparent(pos + Vector3.RIGHT):
		create_face(RIGHT, pos, block_info[WorldGen.RIGHT])


func create_face(face, pos: Vector3, texture_atlas_offset):
	# a+------+b 
	#  |      | b-b-a
	#  |      | b-d-c
	# c+------+d
	var a = vertices[face[0]] + pos
	var b = vertices[face[1]] + pos
	var c = vertices[face[2]] + pos
	var d = vertices[face[3]] + pos
	
	var uv_offset = texture_atlas_offset / WorldGen.TEXTURE_ATLAS_SIZE
	var height = 1.0 / WorldGen.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / WorldGen.TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(width, 0)
	var uv_c = uv_offset + Vector2(0, height)
	var uv_d = uv_offset + Vector2(width, height)
	
	st.add_triangle_fan([b, c, a], [uv_b, uv_c, uv_a])
	st.add_triangle_fan([b, d, c], [uv_b, uv_d, uv_c])
