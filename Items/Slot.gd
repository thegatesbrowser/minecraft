extends TextureButton

var amount:int = 1

@export var Item_resource:Item_Global

@onready var amount_label: Label = $amount


func _ready() -> void:
	if Item_resource != null:
		texture_normal = Item_resource.item_texture
	
func _on_pressed() -> void:
	Globals.slot_clicked.emit(self)


func update_slot():
	amount_label.text = str(amount)
	if Item_resource != null:
		amount_label.show()
		texture_normal = Item_resource.item_texture
	else:
		amount_label.hide()
		amount = 0
		texture_normal = null
