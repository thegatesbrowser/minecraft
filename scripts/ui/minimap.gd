extends TextureRect

@export var player_icon:Texture
@export var treature_icon:Texture

var image_size:Vector2 = Vector2(100,100)


func _ready() -> void:
	var x = 0
	var z = 0
	for i in 19:
		z += 1
		for ih in 19:
			x += 1
			gen(Vector3(x,0,z),Color.GREEN)
			
func gen(pos:Vector3,pixel_colour:Color):
	
	var offset_pos
	
	var new_pos_x = pos.x
	var new_pos_y = pos.z
	
	if new_pos_x < 0:
		new_pos_x = new_pos_x * -1
		new_pos_x += new_pos_x
		
	if new_pos_y < 0:
		new_pos_y = new_pos_y * -1
		new_pos_y += new_pos_y
		
	if image_size.x <= new_pos_x:
		image_size.x += new_pos_x
		
	if image_size.y <= new_pos_y:
		image_size.y += new_pos_y
	#print(new_pos_x)
	
	var new_image:Image
	
	if texture != null:
		new_image = Image.create_from_data(texture.get_image().get_size().x,texture.get_image().get_size().y,true,Image.FORMAT_RGB8,texture.get_image().get_data())
		new_image.resize(image_size.x,image_size.y,Image.INTERPOLATE_NEAREST)
	else:
		new_image = Image.create(image_size.x,image_size.y,true,Image.FORMAT_RGB8)
	
	new_image.set_pixel(new_pos_x,new_pos_y,pixel_colour)
	texture = ImageTexture.create_from_image(new_image)
	


func _on_timer_timeout() -> void:
	pass
