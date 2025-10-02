extends Node
class_name Python_Item_Backend_Client

var SERVER_UPLOAD_URL = "http://localhost:8000/upload"
var SERVER_DOWNLOAD_URL = "http://localhost:8000/download/"
var SERVER_CHECK_URL = "http://localhost:8000/file_exists/"

# Example files to upload and their Godot paths
var files_to_upload = [
	{"path": "res://assets/models/tools/Stone/axe_stone.tscn","local_path": "res://assets/models/axe_stone.tscn"}
]

func _ready():
	#upload_files(files_to_upload)
	#check_file_exists("axe_stone.tres", Callable(self, "_on_file_check"))
	#download_folder_files("axe_stone.tres")
	pass

# -------------------- UPLOAD --------------------
func upload_files(file_list: Array):
	var boundary = "----GodotBoundary123456"
	var body = PackedByteArray()
	var local_paths_array = []

	for file_info in file_list:
		var file_path = file_info["path"]
		var local_path = file_info["local_path"]
		local_paths_array.append(local_path)

		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			var data = file.get_buffer(file.get_length())
			file.close()

			var header_text = "--%s\r\nContent-Disposition: form-data; name=\"files\"; filename=\"%s\"\r\nContent-Type: application/octet-stream\r\n\r\n" % [boundary, file_path.get_file()]
			body.append_array(header_text.to_utf8_buffer())
			body.append_array(data)
			body.append_array("\r\n".to_utf8_buffer())
		else:
			print("File not found:", file_path)

	# Add local_paths as a JSON field
	var local_paths_json = JSON.stringify(local_paths_array)
	var local_paths_field = "--%s\r\nContent-Disposition: form-data; name=\"local_paths\"\r\n\r\n%s\r\n" % [boundary, local_paths_json]
	body.append_array(local_paths_field.to_utf8_buffer())
	body.append_array(("--%s--\r\n" % boundary).to_utf8_buffer())

	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_upload_completed"))

	var headers = ["Content-Type: multipart/form-data; boundary=%s" % boundary]
	var err = request.request_raw(SERVER_UPLOAD_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("Upload request failed:", err)

func _on_upload_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Upload failed with code:", response_code)
		return

	var body_text = body.get_string_from_utf8()
	var parse_result = JSON.parse_string(body_text)
	if parse_result.has("error"):
		print("Failed to parse JSON:", parse_result.error)
		return

	var data = parse_result
	print("Upload completed:", data)

	# Download all files from the folder returned by the server
	#if data.has("files") and data["files"].size() > 0:
		#var first_file = data["files"][0]  # any file in the folder
		#download_folder_files(first_file)

# -------------------- DOWNLOAD --------------------
var current_http_request: HTTPRequest

func download_folder_files(filename: String):
	current_http_request = HTTPRequest.new()
	add_child(current_http_request)
	current_http_request.connect("request_completed", Callable(self, "_on_download_completed"))

	var err = current_http_request.request(SERVER_DOWNLOAD_URL + filename)
	if err != OK:
		print("Download request failed:", err)

func _on_download_completed(result, response_code, headers, body):
	if response_code != 200:
		print("Download failed with code:", response_code)
		return

	var body_text = body.get_string_from_utf8()
	var parse_result = JSON.parse_string(body_text)
	if parse_result.has("error"):
		print("Failed to parse JSON:", parse_result.error)
		return

	var data = parse_result
	var files = data["files"]

	for file_dict in files:
		var save_path = file_dict["local_path"]  # full Godot path provided during upload
		var content_base64 = file_dict["content"]
		var file_data = Marshalls.base64_to_raw(content_base64)

		var file = FileAccess.open(save_path, FileAccess.WRITE)
		file.store_buffer(file_data)
		file.close()
		print("Saved file:", save_path)

	print("All files downloaded successfully from folder:", data["folder_id"])

# -------------------- CHECKS ----------------------
func _on_file_check(result: Dictionary):
	if result.get("exists", false):
		print("File exists on server in folder:", result["folder_id"])
		print("Godot path:", result["local_path"])
	else:
		print("result", result)
		print("File does not exist on server, safe to upload")

func check_file_exists(filename: String, callback: Callable):
	"""
	Check if a file exists on the server.
	`callback` will be called with a dictionary containing:
		{ "exists": bool, "folder_id": str, "local_path": str (if exists) }
	"""
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_check_completed").bind(callback, request))
	
	var err = request.request(SERVER_CHECK_URL + filename)
	if err != OK:
		print("Check request failed:", err)
		callback.call({"exists": false})

func _on_check_completed(result, response_code, headers, body, callback: Callable, request: HTTPRequest):
	request.queue_free()  # remove request node

	if response_code != 200:
		print("Server check failed with code:", response_code)
		callback.call({"exists": false})
		return

	var body_text = body.get_string_from_utf8()
	var parse_result = JSON.parse_string(body_text)
	if parse_result.has("error"):
		print("Failed to parse JSON:", parse_result.error)
		callback.call({"exists": false})
		return

	callback.call(parse_result)
