extends TextureButton
class_name Slot
var index:int

signal item_changed(index:int,item_path:String,amount:int,parent:String)

var played_ani:bool = false
var focused:bool = false

@export var type:String = 'inventory'
@export var amount:int = 1

@export var Item_resource: ItemBase

@onready var image: TextureRect = $CenterContainer/Image
@onready var amount_label: Label = $amount
@export var custom_index:int = 100
@export var can_custom_index:bool = false

func _process(_delta: float) -> void:
	
	if Item_resource != null:
		image.texture = Item_resource.texture
	else:
		image.texture = null
		
	amount_label.text = str(amount)
	
	if focused:
		if !played_ani:
			GlobalAnimation._tween(self,"bounce",.3)
			played_ani = true
		$pressed.show()
	else:
		played_ani = false
		$pressed.hide()
	##
	#if amount <= 0:
		#Item_resource = null
		#amount_label.hide()
		#amount = 1
		#update_slot()

func _ready() -> void:
	if !can_custom_index:
		index = get_index()
	else:
		index = custom_index
	
	if Item_resource != null:
		image.texture = Item_resource.texture
		
	update_slot()


func _on_pressed() -> void:
	if type == "hotbar":
		if Item_resource != null:
			Globals.hotbar_slot_clicked.emit(self)
			
	if Item_resource != null:
		Globals.slot_clicked(self)
	else:
		if Globals.last_clicked_slot != null:
			Globals.slot_clicked(self)

func update_slot():
	amount_label.text = str(amount)
	if Item_resource != null:
		if amount >= 2:
			amount_label.show()
		image.texture = Item_resource.texture
		item_changed.emit(index,Item_resource.get_path(),amount,get_parent().name)
	else:
		amount_label.hide()
		amount = 1
		image.texture = null
		item_changed.emit(index,"",amount,get_parent().name)
	
	
func update_non_sync():
	amount_label.text = str(amount)
	if Item_resource != null:
		if amount >= 2:
			amount_label.show()
		image.texture = Item_resource.texture
	else:
		amount_label.hide()
		amount = 1
		image.texture = null
