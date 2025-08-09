extends PanelContainer

signal LoginUser(user,password)
signal CreateUser(user,password)

@export var Create_User_Window:PackedScene

@onready var username: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/Username
@onready var password: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer2/Password
@onready var ui: AudioStreamPlayer = $UI

func _on_cancel_button_down() -> void:
	ui.play()
	queue_free()

func _on_login_button_down() -> void:
	ui.play()
	LoginUser.emit(username.text,password.text)


func _on_create_user_button_down() -> void:
	ui.play()
	var create_user = Create_User_Window.instantiate()
	add_child(create_user)
	create_user.Create_User.connect(Create_user)

func Create_user(user, password):
	CreateUser.emit(user,password)

func SetSystemErrorLabel(text):
	$MarginContainer/VBoxContainer/error.text = text


func sfx(new_text: String) -> void:
	ui.play()
