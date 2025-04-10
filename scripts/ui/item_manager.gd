extends Node

@export var Saver:Node

	
@rpc("any_peer","call_local")
func create_item(json,buffer:PackedByteArray,size:Vector2):
	var item = dict_to_inst(json)
	var item_name = json["unique_name"]
	var save_path = str("res://"+item_name+".tres")

	var new_image = Image.new()
	new_image.load_png_from_buffer(buffer)
	
	new_image.save_png("res://buffermulti.png")
	
	item.texture = ImageTexture.create_from_image(new_image)
	
	ResourceSaver.save(item,"res://meat.tres")

func item():
	var scene:PackedScene
	scene._bundled

	#var item = ItemBase.new()
	#item.unique_name = "test"
	## Load an image of any format supported by Godot from the filesystem.
	#var image = Image.load_from_file("C:/Users/Anita/Downloads/cooked meat (1).png")
	## Optionally, generate mipmaps if displaying the texture on a 3D surface
	## so that the texture doesn't look grainy when viewed at a distance.
	##image.generate_mipmaps()
	#item.texture = ImageTexture.create_from_image(image)
#
	## Save the loaded Image to a PNG image.
	#image.save_png("res://file.png")
#
	## Save the converted ImageTexture to a PNG image.
	##item.texture.get_image().save_png("res://file.png")
	#
	#var buffer = image.save_png_to_buffer()
	#
	#var new_image = Image.new()
	#new_image.load_png_from_buffer(buffer)
	#
	#new_image.save_png("res://buffer.png")
	#
	#item.texture = ImageTexture.create_from_image(new_image)
	#
	#ResourceSaver.save(item,"res://item_name.tres")
	#Saver.save_item(item,buffer,image.get_size())
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("1"):
		item()
	if Input.is_action_just_pressed("0"):
		Saver.save_item(load("res://resources/items/meat.tres"))

func save_textures(item:ItemBase):
	var data = item.texture.get_image().get_data()
	return data
