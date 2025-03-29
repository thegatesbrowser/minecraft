extends PanelContainer

signal Create_User(user,password)

@onready var username: TextEdit = $MarginContainer/VBoxContainer/HBoxContainer/Username
@onready var password: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer2/Password


func _on_submit_button_down() -> void:
	Create_User.emit(username.text,password.text)


func _on_exit_button_down() -> void:
	queue_free()
