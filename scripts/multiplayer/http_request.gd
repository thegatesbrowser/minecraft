extends Node


var http_request:HTTPRequest

func _ready():
	# Create an HTTP request node and connect its completion signal.
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	



func _process(delta: float) -> void:
	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	if Input.is_action_just_pressed("0"):
		
		var test_in = load("res://resources/items/chest.tres")
		var pack = inst_to_dict(test_in)
		print("pack ",pack)
		
		var error = http_request.request_raw("https://raw.githubusercontent.com/SnapGamesStudio/Items/refs/heads/main/chest.tres")
		#var error = http_request.request("https://github.com/SnapGamesStudio/Items/blob/main/chest.tres")
		if error != OK:
			push_error("An error occurred in the HTTP request.")
			
# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body:PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")
	var image = Image.new()
	
	#print(body,"body")
	print(response_code,"response_code")
	print(result)
	#print(body)
	#print(body.get_string_from_utf8())
	var new = body.get_string_from_utf8()

	var data = JSON.stringify(new)
	#print("data",data)
	var item = dict_to_inst(data)
	var resource = ResourceFormatLoader.new()
	#resource.save(item,"res://test.tres")
	#resource
	#var error = image.load_png_from_buffer(body)
	#if error != OK:
		#push_error("Couldn't load the image.")
#
	#var texture = ImageTexture.create_from_image(image)
#
	## Display the image in a TextureRect node.
	#var texture_rect = TextureRect.new()
	#add_child(texture_rect)
	#texture_rect.texture = texture
