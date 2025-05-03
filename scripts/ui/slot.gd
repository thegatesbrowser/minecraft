extends TextureButton
class_name Slot

signal item_changed(index:int,item_path:String,amount:int,parent:String,health:float,rot:int)

@export var locked:bool = false
@export var pressed_panel: Panel

@export var type: String = "inventory"
@export var amount: int = 1

@export var Item_resource: ItemBase
@export var background_texture:Texture

@export var rot_label:Label 
@onready var background_texturerect: TextureRect = $"CenterContainer/background texture"
@onready var image: TextureRect = $CenterContainer/Image
@onready var amount_label: Label = $amount
@onready var health_label: Label = $health
@onready var health_bar: ProgressBar = $CenterContainer/health

var max_rot:int = 0
var rot:int = 0
var index:int
var health:float
var played_ani:bool = false
var focused:bool = false


func _process(_delta: float) -> void:
	
	if Item_resource != null:
		health_label.text = str(health)
		health_bar.value = health
		
		if Item_resource is ItemFood:
			if Item_resource.rot_step_textures.size() >= rot:
				image.texture = Item_resource.rot_step_textures[rot]
			else:
				Item_resource = null
				update_slot()
		else:
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
		
	if Item_resource is ItemFood:
		start_rot(Item_resource.time_rot_step)
	update_slot()


func _on_pressed() -> void:
	if !locked:
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

		if Item_resource is ItemFood:
			max_rot = Item_resource.max_rot_steps
			rot_label.text = str(rot)
			rot_label.show()
		else:
			rot_label.hide()
		
		item_changed.emit(index,Item_resource.get_path(),amount,get_parent().name,health,rot)
		
		if not Item_resource is ItemTool:
			health_bar.hide()
		else:
			health_bar.show()

	else:
		amount = 1
		image.texture = null
		item_changed.emit(index,"",amount,get_parent().name,health,rot)
		health = 0
		health_bar.hide()
		rot_label.hide()
		amount_label.hide()
		
	#if !Connection.is_server():
		#if
		#Globals.save.emit()
		pass

func used() -> void:
	health -= Item_resource.degrade_rate
	if health <= 0:
		Item_resource = null
	update_slot()
	
var _time
var timer:Timer
func start_rot(time:float) -> void:
	var rot_timer = Timer.new()
	rot_timer.wait_time = time
	add_child(rot_timer)
	rot_timer.start()
	rot_timer.timeout.connect(rot_update)
	timer = rot_timer
	_time = time
	
	
func rot_update() -> void:
	
	rot += 1
	if rot >= max_rot:
		Item_resource = null
	update_slot()
