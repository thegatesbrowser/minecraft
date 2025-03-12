extends Control

var id:Vector3


func _ready() -> void:
	Globals.open_portal_url.connect(open)


func _on_url_text_submitted(new_text: String) -> void:
	Globals.add_portal_url.emit(id,new_text)
	$PanelContainer/MarginContainer/VBoxContainer/url.text = ""
	hide()
	Globals.paused = false


func open(_id: Vector3) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Globals.paused = true
	id = _id
	show()


func _on_button_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$PanelContainer/MarginContainer/VBoxContainer/url.text = ""
	hide()
	Globals.paused = false
