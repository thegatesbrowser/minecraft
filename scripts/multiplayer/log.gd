extends Node
class_name Debug


static func log_msg(msg: String) -> void:
	if Connection.is_server():
		var timestamp = Time.get_datetime_string_from_system(true, true)
		print(timestamp + " " + msg)
	else:
		print(msg)
