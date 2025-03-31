extends TextureButton
class_name Slot

signal item_changed(index:int,item_path:String,amount:int,parent:String,health:float)

@export var pressed_panel: Panel

@export var type: String = "inventory"
@export var amount: int = 1

@export var Item_resource: ItemBase
@export var background_texture:Texture

@onready var background_texturerect: TextureRect = $"CenterContainer/background texture"
@onready var image: TextureRect = $CenterContainer/Image
@onready var amount_label: Label = $amount
@onready var health_label: Label = $health
@onready var health_bar: ProgressBar = $CenterContainer/health


var index:int
var health:float

var played_ani:bool = false
var focused:bool = false


func _process(_delta: float) -> void:
	
	if Item_resource != null:
		health_label.text = str(health)
		health_bar.value = health
		image.texture = Item_resource.texture
	else:
		image.texture = null
		
	amount_label.text = str(amount)
	
	if focused:
		if !played_ani:
			GlobalAnimation._tween(self,"bounce",.3)
			played_ani = true
		pressed_panel.show()
	else:
		played_ani = false
		pressed_panel.hide()
	
	# destorys the item is the amount is 0 (mainly for the furnace)
	if amount <= 0:
		amount = 1
		Item_resource = null
		image.texture = null
		amount_label.hide()
		
func _ready() -> void:
	background_texturerect.texture = background_texture
	index = get_index()
	
	if Item_resource != null:
		image.texture = Item_resource.texture
		
	update_slot()


func _on_pressed() -> void:
	if Globals.paused:
		if type == "hotbar":
			if Item_resource != null:
				Globals.hotbar_slot_clicked.emit(self)
				
		
		if Item_resource != null:
			Globals.slot_clicked(self)
		else:
			if Globals.last_clicked_slot != null:
				Globals.slot_clicked(self)


func update_slot() -> void:
	amount_label.text = str(amount)
	if Item_resource != null:
		
		if amount >= 2:
			amount_label.show()
			
		image.texture = Item_resource.texture

		
		item_changed.emit(index,Item_resource.get_path(),amount,get_parent().name,health)
		
		if not Item_resource is ItemTool:
			health_bar.hide()
		else:
			health_bar.show()

	else:
		amount_label.hide()
		amount = 1
		image.texture = null
		item_changed.emit(index,"",amount,get_parent().name,health)
		health = 0
		health_bar.hide()
		
	if !Connection.is_server():
		Globals.save_player_ui.emit() ## saves the players slots only

func used() -> void:
	health -= Item_resource.degrade_rate
	if health <= 0:
		Item_resource = null
	update_slot()
