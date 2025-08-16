extends PanelContainer

@onready var delete_save_confirm: ConfirmationDialog = $ConfirmationDialog
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_delete_save_pressed() -> void:
	delete_save_confirm.popup_centered()




func _on_confirmation_dialog_confirmed() -> void:
	print("Deleting save...")


func _on_confirmation_dialog_canceled() -> void:
	print("Save deletion canceled.")
	# Optionally, you can reset the UI or perform other actions here.
	delete_save_confirm.hide()
