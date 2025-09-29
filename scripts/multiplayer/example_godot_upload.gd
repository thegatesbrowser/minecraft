extends Node

var http := HTTPRequest.new()
var _save_path: String = ""

func _ready():
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_request_completed"))
	upload_file_multipart("res://resources/items/dirt.tres")
# --------------------
# UPLOAD FILE (multipart/form-data)
# --------------------
func upload_file_multipart(path: String):
	if not FileAccess.file_exists(path):
		print("File not found!")
		return

	# Read file bytes
	var file = FileAccess.open(path, FileAccess.ModeFlags.READ)
	var file_data = file.get_buffer(file.get_length())
	file.close()

	# Multipart boundary
	var boundary = "--------------------GodotBoundary"

	# Build multipart body
	var body_bytes = PackedByteArray()
	var header = "--%s\r\n" % boundary
	header += 'Content-Disposition: form-data; name="file"; filename="%s"\r\n' % path.get_file()
	header += "Content-Type: application/octet-stream\r\n\r\n"
	body_bytes.append_array(header.to_utf8_buffer())
	body_bytes.append_array(file_data)
	body_bytes.append_array(("\r\n--%s--\r\n" % boundary).to_utf8_buffer())

	# Headers
	var headers = ["Content-Type: multipart/form-data; boundary=%s" % boundary]

	# Send POST request
	http.request_raw("http://localhost:8000/upload", headers, HTTPClient.METHOD_POST, body_bytes)

# --------------------
# DOWNLOAD FILE
# --------------------
func download_file(filename: String, save_path: String):
	_save_path = save_path
	http.request("http://localhost:8000/download/%s" % filename, [], HTTPClient.METHOD_GET)

# --------------------
# HTTP REQUEST COMPLETED CALLBACK
# --------------------
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		if _save_path != "":
			# Treat as download
			var file = FileAccess.open(_save_path, FileAccess.ModeFlags.WRITE)
			file.store_buffer(body)
			file.close()
			print("File saved to: ", _save_path)
			_save_path = ""  # Reset save path
		else:
			# Treat as upload
			print("Upload successful", multiplayer.get_unique_id())
	else:
		print("Request failed with code: ", response_code)
