extends TextureButton

var focused:bool = false
@export var type:String = 'inventory'
var amount:int = 1

@export var Item_resource:Item_Global

@onready var amount_label: Label = $amount

func _process(delta: float) -> void:
	if focused:
		$pressed.show()
	else:
		$pressed.hide()
		
func _ready() -> void:
	if Item_resource != null:
		texture_normal = Item_resource.item_texture
	update_slot()
	
func _on_pressed() -> void:
	if type == "hotbar":
		if Item_resource != null:
			Globals.hotbar_slot_clicked.emit(self)
			
	if Item_resource != null:
		Globals.slot_clicked.emit(self)
	else:
		if Globals.last_clicked_slot != null:
			Globals.slot_clicked.emit(self)


func update_slot():
	amount_label.text = str(amount)
	if Item_resource != null:
		if amount >= 2:
			amount_label.show()
		texture_normal = Item_resource.item_texture
	else:
		amount_label.hide()
		amount = 0
		texture_normal = null
